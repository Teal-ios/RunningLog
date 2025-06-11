import SwiftUI
import MapKit

struct MapKitView: UIViewRepresentable {
    let locations: [CLLocation]
    let currentLocation: CLLocation?
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 경로(Polyline) 업데이트
        mapView.removeOverlays(mapView.overlays)
        if locations.count > 1 {
            let coords = locations.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(polyline)
        }
        // 현재 위치 마커(파란 핀)
        mapView.removeAnnotations(mapView.annotations)
        if let current = currentLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = current.coordinate
            annotation.title = "현재 위치"
            mapView.addAnnotation(annotation)
        }
        // region 바인딩 반영 (항상 호출)
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var region: MKCoordinateRegion
        init(region: Binding<MKCoordinateRegion>) {
            _region = region
        }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            region = mapView.region
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemRed
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
} 