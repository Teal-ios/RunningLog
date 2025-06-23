import SwiftUI
import MapKit

// 전체화면 MapView 오버레이
struct MapFullScreenView: View {
    @State private var region = MKCoordinateRegion()
    let routeID: UUID
    let locations: [CLLocation]
    let currentLocation: CLLocation?
    let onClose: () -> Void
    let runningTime: String
    let pace: Double
    let distance: Double
    
    var body: some View {
        ZStack {
            // 지도 (배경)
            MapKitView(
                routeID: routeID,
                locations: locations,
                currentLocation: currentLocation,
                region: $region
            )
            .edgesIgnoringSafeArea(.all) // 화면 전체를 지도로 채움
            
            // UI 요소들을 담는 VStack
            VStack {
                // 상단 정보 오버레이
                HStack(spacing: 24) {
                    // 타이머
                    VStack(spacing: 2) {
                        Text("시간")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(runningTime)
                            .font(.headline)
                            .foregroundColor(Color.primary) // 가독성을 위해 primary로 변경
                    }
                    // 페이스
                    VStack(spacing: 2) {
                        Text("페이스")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(pace > 0 ? String(format: "%.2f", pace) : "--.--")
                            .font(.headline)
                            .foregroundColor(Color.primary)
                    }
                    // 거리
                    VStack(spacing: 2) {
                        Text("거리")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f km", distance / 1000))
                            .font(.headline)
                            .foregroundColor(Color.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.thinMaterial) // 반투명 배경
                .cornerRadius(16)
                .padding(.top, 16) // 상단 안전 영역 고려
                
                Spacer() // 중간 공간을 모두 차지
                
                // 하단 우측 버튼
                HStack {
                    Spacer() // 왼쪽 공간을 모두 차지
                    
                    VStack(spacing: 16) {
                        // 내 위치 버튼
                        Button(action: {
                            if let current = currentLocation {
                                region = MKCoordinateRegion(
                                    center: current.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                                )
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        // 닫기 버튼
                        Button(action: onClose) {
                            Image(systemName: "map")
                                .font(.title2)
                                .padding(16)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 32) // 하단 안전 영역 고려
            }
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all)) // 탭바 영역 포함 전체 배경색 지정
        .onAppear {
            if let current = currentLocation {
                region = MKCoordinateRegion(
                    center: current.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )
            }
        }
    }
} 