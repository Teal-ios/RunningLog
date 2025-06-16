import SwiftUI
import MapKit
import ComposableArchitecture
import CoreLocation

struct MapView: View {
    let store: StoreOf<MapFeature>
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002) // 약 200m
    )
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack(alignment: .bottom) {
                MapKitView(
                    locations: viewStore.locations,
                    currentLocation: viewStore.currentLocation,
                    region: $region
                )
                .ignoresSafeArea(edges: .top)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            if let loc = viewStore.currentLocation {
                                region = MKCoordinateRegion(
                                    center: loc.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                                )
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
                
                HStack {
                    Button(action: {
                        if viewStore.isTracking {
                            viewStore.send(.stopTracking)
                        } else {
                            viewStore.send(.startTracking)
                        }
                    }) {
                        Image(systemName: viewStore.isTracking ? "pause.circle.fill" : "location.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewStore.isTracking ? .orange : .blue)
                        Text(viewStore.isTracking ? "추적 중지" : "위치 추적")
                            .font(.headline)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                viewStore.send(.onAppear)
                if let loc = viewStore.currentLocation {
                    region = MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    )
                }
            }
            .onChange(of: viewStore.currentLocation) { loc in
                if let loc = loc {
                    region = MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    )
                }
            }
        }
    }
}

private struct MapPin: Identifiable {
    let id = UUID()
    let location: CLLocation
} 