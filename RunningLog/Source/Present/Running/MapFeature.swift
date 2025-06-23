import Foundation
import ComposableArchitecture
import CoreLocation

// MARK: - 2D Kalman Filter 구현
final class KalmanFilter2D {
    private var lat: Double?
    private var lon: Double?
    private var varLat: Double = 1
    private var varLon: Double = 1
    private let processNoise: Double
    private let measurementNoise: Double
    
    init(processNoise: Double = 1e-3, measurementNoise: Double = 1e-2) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
    }
    
    func filter(latitude: Double, longitude: Double) -> (Double, Double) {
        if lat == nil || lon == nil {
            lat = latitude
            lon = longitude
            return (latitude, longitude)
        }
        // 예측 단계
        varLat += processNoise
        varLon += processNoise
        // 측정 단계
        let kLat = varLat / (varLat + measurementNoise)
        let kLon = varLon / (varLon + measurementNoise)
        lat = lat! + kLat * (latitude - lat!)
        lon = lon! + kLon * (longitude - lon!)
        varLat = (1 - kLat) * varLat
        varLon = (1 - kLon) * varLon
        return (lat!, lon!)
    }
    func reset() {
        lat = nil
        lon = nil
        varLat = 1
        varLon = 1
    }
}

// MARK: - TCA DependencyKey/DependencyValues
import ComposableArchitecture
import CoreLocation

private enum KalmanFilterManagerKey: DependencyKey {
    static let liveValue: KalmanFilterManagerProtocol = DefaultKalmanFilterManager()
}

extension DependencyValues {
    var kalmanFilterManager: KalmanFilterManagerProtocol {
        get { self[KalmanFilterManagerKey.self] }
        set { self[KalmanFilterManagerKey.self] = newValue }
    }
}

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        var routeID: UUID?
        var locations: [CLLocation] = []
        var currentLocation: CLLocation?
        var isTracking: Bool = false
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case startTracking
        case stopTracking
        case updateLocation(CLLocation)
        case locationError(String)
    }
    
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.kalmanFilterManager) var kalmanFilterManager: KalmanFilterManagerProtocol
    
    private enum CancelID { case locationTracking }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("[MapFeature] locationClient 인스턴스 주소: \(Unmanaged.passUnretained(locationClient as AnyObject).toOpaque())")
                return .none
            case .startTracking:
                state.isTracking = true
                state.errorMessage = nil
                state.locations = []
                state.routeID = UUID()
                kalmanFilterManager.reset()
                return .run { send in
                    do {
                        for try await location in try await locationClient.requestLocationUpdates() {
                            await send(.updateLocation(location))
                        }
                    } catch {
                        await send(.locationError(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.locationTracking)
            case .stopTracking:
                state.isTracking = false
                state.routeID = nil
                return .cancel(id: CancelID.locationTracking)
            case let .updateLocation(location):
                print("🟣 MapFeature - updateLocation: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                if let filteredLocation = kalmanFilterManager.filter(location: location) {
                    state.currentLocation = filteredLocation
                    state.locations.append(filteredLocation)
                }
                return .none
            case let .locationError(msg):
                state.errorMessage = msg
                state.isTracking = false
                return .none
            }
        }
    }
} 