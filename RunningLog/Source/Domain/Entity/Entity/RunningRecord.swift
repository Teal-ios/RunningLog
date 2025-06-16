import Foundation
import CoreLocation

struct RunningRecord: Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let distance: Double
    let calories: Double
    let elapsedTime: Double
    let averagePace: Double
    let path: [CLLocationCoordinate2D]
    
    static func == (lhs: RunningRecord, rhs: RunningRecord) -> Bool {
        lhs.id == rhs.id &&
        lhs.startTime == rhs.startTime &&
        lhs.endTime == rhs.endTime &&
        lhs.distance == rhs.distance &&
        lhs.calories == rhs.calories &&
        lhs.elapsedTime == rhs.elapsedTime &&
        lhs.averagePace == rhs.averagePace &&
        lhs.path.count == rhs.path.count &&
        zip(lhs.path, rhs.path).allSatisfy { l, r in
            l.latitude == r.latitude && l.longitude == r.longitude
        }
    }
}

extension RunningRecord {
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: startTime)
    }
    var formattedDistance: String {
        String(format: "%.2f km", distance / 1000)
    }
    var formattedTime: String {
        let h = Int(elapsedTime) / 3600
        let m = (Int(elapsedTime) % 3600) / 60
        let s = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    var formattedPace: String {
        guard distance > 0 else { return "-" }
        let pace = elapsedTime / (distance / 1000)
        let min = Int(pace) / 60
        let sec = Int(pace) % 60
        return String(format: "%d'%02d\"/km", min, sec)
    }
} 