import Foundation
import ComposableArchitecture
import CoreLocation

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
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
                return .cancel(id: CancelID.locationTracking)
            case let .updateLocation(location):
                print("🟣 MapFeature - updateLocation: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                state.currentLocation = location
                state.locations.append(location)
                return .none
            case let .locationError(msg):
                state.errorMessage = msg
                state.isTracking = false
                return .none
            }
        }
    }
} 