import Foundation
import ComposableArchitecture
import RunningLog

@Reducer
struct RunningRecordListFeature {
    @ObservableState
    struct State: Equatable {
        var records: [RunningRecord] = []
        var isLoading = false
        var errorMessage: String?
        var selectedRecord: RunningRecord?
        var repository: RunningRecordRepository? = nil
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.records == rhs.records &&
            lhs.isLoading == rhs.isLoading &&
            lhs.errorMessage == rhs.errorMessage &&
            lhs.selectedRecord == rhs.selectedRecord
        }
    }
    enum Action {
        case onAppear
        case loadRecords
        case recordsResponse(Result<[RunningRecord], Error>)
        case selectRecord(RunningRecord)
        case deselectRecord
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
                    state.errorMessage = "기록 데이터베이스가 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요."
                    state.isLoading = false
                    return .none
                }
            case .loadRecords:
                state.isLoading = true
                guard let repository = state.repository else {
                    state.errorMessage = "기록 데이터베이스가 준비되지 않았습니다."
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
                guard let repository = state.repository else {
                    state.errorMessage = "기록 데이터베이스가 준비되지 않았습니다."
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
            case let .recordsResponse(.success(records)):
                state.records = records
                state.isLoading = false
                state.errorMessage = nil
                return .none
            case let .recordsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case let .selectRecord(record):
                state.selectedRecord = record
                return .none
            case .deselectRecord:
                state.selectedRecord = nil
                return .none
            case let .deleteRecord(record):
                state.isLoading = true
                guard let repository = state.repository else {
                    state.errorMessage = "기록 데이터베이스가 준비되지 않았습니다."
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
            case let .deleteRecordResponse(.success):
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
