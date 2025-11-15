import Foundation
import ComposableArchitecture

@Reducer
struct RunningRecordListFeature {
    @ObservableState
    struct State: Equatable {
        var records: [RunningRecord] = []
        var isLoading = false
        var errorMessage: String?
        var repository: RunningRecordRepository? = nil
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.records == rhs.records &&
            lhs.isLoading == rhs.isLoading &&
            lhs.errorMessage == rhs.errorMessage
        }
    }
    enum Action {
        case onAppear
        case loadRecords
        case recordsResponse(Result<[RunningRecord], Error>)
        case repositoryReady
        case deleteRecord(RunningRecord)
        case deleteRecordResponse(Result<Void, Error>)
    }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                if PersistenceController.shared.isStoreLoaded {
                    print("[기록탭] store 준비됨, repository 생성")
                    state.repository = CoreDataRunningRecordRepository(context: PersistenceController.shared.container.viewContext)
                    return .send(.repositoryReady)
                } else {
                    print("[기록탭] store 미준비, 로딩 안내")
                    state.errorMessage = NSLocalizedString("database_not_ready_wait", comment: "")
                    state.isLoading = false
                    return .none
                }
            case .loadRecords:
                state.isLoading = true
                guard let repository = state.repository else {
                    state.errorMessage = NSLocalizedString("database_not_ready", comment: "")
                    state.isLoading = false
                    return .none
                }
                return .run { send in
                    do {
                        let records = try repository.fetchAll().sorted { $0.startTime > $1.startTime }
                        await send(.recordsResponse(.success(records)))
                    } catch {
                        await send(.recordsResponse(.failure(error)))
                    }
                }
                
            case .repositoryReady:
                return .send(.loadRecords)
                
            case let .recordsResponse(.success(records)):
                
                // 1. 최소 기준 설정
                let minDuration: Double = 60.0  // 1분 (60초)
                let minDistance: Double = 100.0 // 100 미터
                
                // 2. 삭제 대상 및 유지 대상 분리
                let recordsToDelete = records.filter { record in
                    record.elapsedTime <= minDuration || record.distance <= minDistance
                }
                
                let filteredRecords = records.filter { record in
                    record.elapsedTime > minDuration && record.distance > minDistance
                }
                
                state.records = filteredRecords
                
                // 3. 삭제할 레코드가 없으면 로딩 종료
                if recordsToDelete.isEmpty {
                    state.isLoading = false
                    state.errorMessage = nil
                    return .none
                } else {
                    print("[기록탭] 필터링 기준 미달 \(recordsToDelete.count)개 발견, ACID 트랜잭션 삭제 시작")
                    
                    state.isLoading = true // 삭제 작업이 완료될 때까지 로딩 유지
                    
                    guard let repository = state.repository else {
                         state.errorMessage = NSLocalizedString("database_not_ready_for_deletion", comment: "")
                         state.isLoading = false
                         return .none
                    }

                    // 4. 새로운 일괄 삭제 트랜잭션 실행
                    return .run { send in
                        do {
                            // ⭐️ Repository의 일괄 삭제 메서드를 호출 (내부적으로 롤백/커밋 처리)
                            try repository.delete(records: recordsToDelete)
                            
                            // 삭제 성공 후, 최신 목록을 다시 불러옵니다.
                            await send(.loadRecords)
                        } catch {
                            // 롤백이 성공적으로 발생했다고 가정
                            print("🚨 트랜잭션 실패: 모든 변경 사항 롤백됨. 에러: \(error.localizedDescription)")
                            
                            // 삭제 실패 메시지를 표시하고, 화면에 보이는 records는 롤백 이전 상태이므로
                            // 다시 .loadRecords를 호출하여 DB의 원래 상태(삭제 실패)를 화면에 반영합니다.
                            await send(.recordsResponse(.failure(error))) // 에러 메시지 업데이트용
                            await send(.loadRecords) // DB의 원래 상태로 목록 갱신
                        }
                    }
                }
            case let .recordsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case let .deleteRecord(record):
                state.isLoading = true
                guard let repository = state.repository else {
                    state.errorMessage = NSLocalizedString("database_not_ready", comment: "")
                    state.isLoading = false
                    return .none
                }
                return .run { send in
                    do {
                        try repository.delete(record: record)
                        await send(.deleteRecordResponse(.success(())))
                    } catch {
                        await send(.deleteRecordResponse(.failure(error)))
                    }
                }
            case .deleteRecordResponse(.success):
                state.isLoading = false
                return .send(.loadRecords)
            case let .deleteRecordResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
