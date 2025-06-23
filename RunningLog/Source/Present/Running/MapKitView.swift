import SwiftUI
import MapKit

// MARK: - SpeedPolyline
// 속도에 따른 색상 정보를 저장하기 위한 커스텀 MKPolyline
class SpeedPolyline: MKPolyline {
    var color: UIColor = .black
}

// MARK: - MapKitView
struct MapKitView: UIViewRepresentable {
    let routeID: UUID
    let locations: [CLLocation]
    let currentLocation: CLLocation?
    @Binding var region: MKCoordinateRegion
    
    // region 변경 감지용
    private class RegionBox {
        var lastRegion: MKCoordinateRegion?
    }
    private static var regionBox = RegionBox()
    
    // region 비교 함수
    private func isRegionEqual(_ lhs: MKCoordinateRegion?, _ rhs: MKCoordinateRegion) -> Bool {
        guard let lhs = lhs else { return false }
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
               lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.setRegion(region, animated: false)
        MapKitView.regionBox.lastRegion = region
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateOverlays(mapView: mapView, context: context)

        // 현재 위치 마커(파란 핀)
        mapView.removeAnnotations(mapView.annotations)
        if let current = currentLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = current.coordinate
            annotation.title = "현재 위치"
            mapView.addAnnotation(annotation)
        }
        
        // region 바인딩 반영 (변경 시에만 호출)
        if !isRegionEqual(MapKitView.regionBox.lastRegion, region) {
            mapView.setRegion(region, animated: true)
            MapKitView.regionBox.lastRegion = region
        }
    }
    
    private func updateOverlays(mapView: MKMapView, context: Context) {
        // ID가 변경되었는지 확인하여 새로운 경로인지 판단
        if context.coordinator.lastRouteID != routeID {
            // ID가 다르면 새로운 경로이므로 기존 오버레이를 모두 제거
            let oldOverlays = mapView.overlays.filter { $0 is SpeedPolyline }
            mapView.removeOverlays(oldOverlays)
            // 추적용 ID와 카운트 초기화
            context.coordinator.lastRouteID = routeID
            context.coordinator.processedLocationCount = 0
        }

        let startIndex = max(1, context.coordinator.processedLocationCount)
        guard locations.count > startIndex else { return }

        // 새로 추가된 위치 데이터에 대해서만 Polyline 조각을 생성
        for i in startIndex..<locations.count {
            let startLocation = locations[i-1]
            let endLocation = locations[i]
            var speed = endLocation.speed
            
            // speed 값이 유효하지 않은 경우(-1), 직접 계산합니다.
            if speed < 0 {
                let distance = endLocation.distance(from: startLocation)
                let time = endLocation.timestamp.timeIntervalSince(startLocation.timestamp)
                
                // 시간이 유효한 경우에만 속도 계산
                if time > 0 {
                    speed = distance / time
                } else {
                    // 타임스탬프 정보가 없는 이전 데이터의 경우, 기본 속도(0)로 처리하여
                    // 최소한 단색 라인이라도 그려지도록 합니다.
                    speed = 0
                }
            }

            let color = context.coordinator.colorForSpeed(speed: speed)
            
            let coordinates = [startLocation.coordinate, endLocation.coordinate]
            let polyline = SpeedPolyline(coordinates: coordinates, count: 2)
            polyline.color = color
            mapView.addOverlay(polyline, level: .aboveRoads)
        }
        
        // 처리된 위치 카운트 업데이트
        context.coordinator.processedLocationCount = locations.count
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, region: $region)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitView
        @Binding var region: MKCoordinateRegion
        var lastRouteID: UUID?
        var processedLocationCount = 0
        
        init(parent: MapKitView, region: Binding<MKCoordinateRegion>) {
            self.parent = parent
            _region = region
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.region = mapView.region
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // SpeedPolyline 타입일 경우, 저장된 color를 사용하여 렌더링
            if let polyline = overlay as? SpeedPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = polyline.color
                renderer.lineWidth = 6
                renderer.lineCap = .round // 라인 끝을 둥글게 처리
                renderer.lineJoin = .round // 라인 연결부를 둥글게 처리
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        /// 속도(m/s)를 기반으로 프로젝트 디자인 시스템에 맞는 색상을 결정하는 함수
        /// - 느림: 밝은 파랑 (accent)
        /// - 중간: 중간 파랑 (secondary)
        /// - 빠름: 짙은 파랑 (primary)
        func colorForSpeed(speed: CLLocationSpeed) -> UIColor {
            // 프로젝트 디자인 시스템 색상을 UIColor로 정의
            let slowColor = UIColor(red: 161/255, green: 227/255, blue: 249/255, alpha: 0.85) // accent
            let mediumColor = UIColor(red: 87/255, green: 143/255, blue: 202/255, alpha: 0.85) // secondary
            let fastColor = UIColor(red: 52/255, green: 116/255, blue: 181/255, alpha: 0.85)   // primary

            // m/s 기준 속도 범위 설정 (예: 2 m/s ~ 5 m/s)
            let minSpeed: CLLocationSpeed = 2.0  // 약 7.2 km/h, 8:20 min/km 페이스
            let maxSpeed: CLLocationSpeed = 5.0  // 약 18 km/h, 3:20 min/km 페이스
            
            // 속도를 0.0 ~ 1.0 범위로 정규화
            let clampedSpeed = max(minSpeed, min(speed, maxSpeed))
            let normalizedSpeed = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)
            
            // 정규화된 속도에 따라 색상 보간
            if normalizedSpeed < 0.5 {
                // 0.0 ~ 0.5 구간: slowColor -> mediumColor
                let t = normalizedSpeed * 2.0
                return lerp(from: slowColor, to: mediumColor, at: CGFloat(t))
            } else {
                // 0.5 ~ 1.0 구간: mediumColor -> fastColor
                let t = (normalizedSpeed - 0.5) * 2.0
                return lerp(from: mediumColor, to: fastColor, at: CGFloat(t))
            }
        }
        
        /// 두 UIColor 사이의 색상을 선형 보간하는 헬퍼 함수
        private func lerp(from color1: UIColor, to color2: UIColor, at t: CGFloat) -> UIColor {
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            let r = r1 + (r2 - r1) * t
            let g = g1 + (g2 - g1) * t
            let b = b1 + (b2 - b1) * t
            let a = a1 + (a2 - a1) * t
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
    }
} 