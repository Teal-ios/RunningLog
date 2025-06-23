import SwiftUI
import MapKit

struct RunningRecordDetailView: View {
    let record: RunningRecord
    @State private var region: MKCoordinateRegion = .init()
    var body: some View {
        VStack(spacing: 0) {
            // 상단 정보
            VStack(spacing: 8) {
                Text(record.dateString).font(.title2).bold()
                HStack(spacing: 16) {
                    Label(record.formattedDistance, systemImage: "figure.run")
                    Label(record.formattedTime, systemImage: "clock")
                }
                .font(.headline)
                HStack(spacing: 16) {
                    Label(record.formattedPace, systemImage: "speedometer")
                    Label("\(Int(record.calories)) kcal", systemImage: "flame")
                }
                .font(.subheadline)
            }
            .padding()
            Divider()
            // 하단 지도: PolylineShape → MapKitView로 변경
            MapKitView(
                routeID: record.id,
                locations: record.path,
                currentLocation: nil,
                region: $region
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            if let first = record.path.first {
                region = MKCoordinateRegion(center: first.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
    }
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapPolylineView: View {
    let coordinates: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion = .init()
    var body: some View {
        Map(coordinateRegion: $region)
            .overlay(
                PolylineShape(coordinates: coordinates)
                    .stroke(Color.accentColor, lineWidth: 4)
            )
            .onAppear {
                if let first = coordinates.first {
                    region = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                }
            }
    }
}

struct PolylineShape: Shape {
    let coordinates: [CLLocationCoordinate2D]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !coordinates.isEmpty else { return path }
        let points = coordinates.map { CGPoint(x: $0.longitude, y: $0.latitude) }
        path.addLines(points)
        return path
    }
} 
