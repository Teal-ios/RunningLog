

import SwiftUI
import ComposableArchitecture

// 📌 커스텀 러닝 기록 셀 뷰 (RecordRow)
struct RecordRow: View {
    let record: RunningRecord
    
    var body: some View {
        HStack {
            // 날짜/시간/거리/페이스 정보를 포함하는 내부 VStack
            VStack(alignment: .leading, spacing: 8) {
                
                // --- 상단: 날짜 및 거리 캡슐 ---
                HStack {
                    // 왼쪽: 날짜 및 요일 (예: 2025년 11월 10일 월)
                    VStack(alignment: .leading) {
                        // 날짜 및 요일
                        Text(record.dateString) // "2025년 11월 10일 월"
                            .font(.headline)
                            .foregroundColor(.black)

                        // 시간 (예: 오후 05:09)
                        Text(record.endTimeString)
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                    }
                    
                    Spacer()
                    
                    // 우측 상단: 거리 (주황색 캡슐 배경)
                    Text(record.formattedDistance) // 예: 5.2 km
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.orange))
                }
                
                Spacer()

                // --- 하단: 기록 시간 및 페이스 ---
                HStack(spacing: 16) {
                    // 기록 시간
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.subheadline)
                        Text(record.formattedTime) // 예: 26:00
                    }
                    .foregroundColor(Color(.systemGray))
                    
                    // 페이스 (스크린샷과 유사하게 굵게 표시)
                    HStack(spacing: 4) {
                        Image(systemName: "waveform") // 스크린샷의 파동 아이콘
                            .font(.subheadline)
                        Text(record.formattedPace) // 예: 5'00"/km
                    }
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                }
                .font(.subheadline)
            }
            .padding(20) // 셀 내부 패딩
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    // 스크린샷 디자인의 그림자 효과
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
        }
        .padding(0)
    }
}

// 📌 메인 뷰: RunningRecordListView
struct RunningRecordListView: View {
    // Feature Store 유지
    let store: StoreOf<RunningRecordListFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                // 1. List 대신 ScrollView와 VStack 사용
                ZStack {
                    // 로딩 또는 에러 메시지 표시를 위한 배경
                    Color(.systemGray6).edgesIgnoringSafeArea(.all)
                    
                    if viewStore.isLoading && viewStore.records.isEmpty {
                        ProgressView()
                    } else if let errorMessage = viewStore.errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                    } else if viewStore.records.isEmpty {
                        Text("기록이 없습니다.").foregroundColor(.gray)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewStore.records) { record in
                                    
                                    NavigationLink {
                                        RunningRecordDetailView(record: record)
                                    } label: {
                                        RecordRow(record: record)
                                            .contentShape(Rectangle())
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            viewStore.send(.deleteRecord(record))
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
                .navigationTitle("러닝 기록")
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
}
