import SwiftUI
import ComposableArchitecture

struct RunningRecordListView: View {
    let store: StoreOf<RunningRecordListFeature>
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                List(viewStore.records) { record in
                    NavigationLink {
                        RunningRecordDetailView(record: record)
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewStore.send(.deleteRecord(record))
                        } label: {
                            Label("delete", systemImage: "trash")
                        }
                    }
                }
                .navigationTitle("running_records")
                .onAppear { viewStore.send(.onAppear) }
            }
        }
    }
} 
