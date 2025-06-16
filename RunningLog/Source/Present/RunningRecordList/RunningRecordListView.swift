import SwiftUI
import ComposableArchitecture

struct RunningRecordListView: View {
    let store: StoreOf<RunningRecordListFeature>
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                List(viewStore.records) { record in
                    Button {
                        viewStore.send(.selectRecord(record))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.dateString).font(.headline).foregroundColor(.black)
                                Text(record.formattedDistance + "  " + record.formattedTime)
                                    .font(.subheadline).foregroundColor(.black)
                            }
                            Spacer()
                            Text(record.formattedPace)
                                .font(.title3).bold().foregroundColor(.black)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("러닝 기록")
                .onAppear { viewStore.send(.onAppear) }
                .sheet(item: Binding(
                    get: { viewStore.selectedRecord },
                    set: { _ in viewStore.send(.deselectRecord) }
                )) { record in
                    RunningRecordDetailView(record: record)
                }
            }
        }
    }
} 
