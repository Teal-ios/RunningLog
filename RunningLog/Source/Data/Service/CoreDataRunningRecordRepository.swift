import Foundation
import CoreData
import CoreLocation
import RunningLog
import ComposableArchitecture

final class CoreDataRunningRecordRepository: RunningRecordRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        print("[CoreData] context init: \(context)")
        if let coordinator = context.persistentStoreCoordinator {
            print("[CoreData] context.persistentStoreCoordinator: \(coordinator)")
        } else {
            print("[CoreData] context.persistentStoreCoordinator: nil (초기화 실패)")
        }
        guard context.persistentStoreCoordinator != nil else {
            fatalError("NSManagedObjectContext가 올바르게 초기화되지 않았습니다.")
        }
        self.context = context
    }
    
    // Codable 변환용 구조체 추가
    private struct CodableCoordinate: Codable {
        let latitude: Double
        let longitude: Double
        init(_ coord: CLLocationCoordinate2D) {
            self.latitude = coord.latitude
            self.longitude = coord.longitude
        }
        var clLocationCoordinate2D: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func save(record: RunningRecord) throws {
        print("[CoreData] save() 진입, context: \(context)")
        print("[CoreData] context.persistentStoreCoordinator: \(String(describing: context.persistentStoreCoordinator))")
        let entityName = "RunningRecordEntity"
        print("[CoreData] entityName: \(entityName)")
        let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        print("[CoreData] entity 생성: \(entity)")
        entity.setValue(record.id, forKey: "id")
        entity.setValue(record.startTime, forKey: "startTime")
        entity.setValue(record.endTime, forKey: "endTime")
        entity.setValue(record.distance, forKey: "distance")
        entity.setValue(record.calories, forKey: "calories")
        entity.setValue(record.elapsedTime, forKey: "elapsedTime")
        entity.setValue(record.averagePace, forKey: "averagePace")
        // 좌표 배열을 Codable로 변환해 저장
        let codablePath = record.path.map { CodableCoordinate($0) }
        let pathData = try JSONEncoder().encode(codablePath)
        entity.setValue(pathData, forKey: "path")
        print("[CoreData] entity 값 세팅 완료")
        try context.save()
        print("[CoreData] context.save() 완료")
    }
    
    func fetchAll() throws -> [RunningRecord] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RunningRecordEntity")
        let results = try context.fetch(request) as! [NSManagedObject]
        print("[CoreData] fetchAll 결과 개수: \(results.count)")
        return results.compactMap { obj in
            print("[CoreData] fetch row: \(obj)")
            let id = obj.value(forKey: "id")
            let startTime = obj.value(forKey: "startTime")
            let endTime = obj.value(forKey: "endTime")
            let distance = obj.value(forKey: "distance")
            let calories = obj.value(forKey: "calories")
            let elapsedTime = obj.value(forKey: "elapsedTime")
            let averagePace = obj.value(forKey: "averagePace")
            let pathData = obj.value(forKey: "path")
            if id == nil { print("[CoreData] id nil") }
            if startTime == nil { print("[CoreData] startTime nil") }
            if endTime == nil { print("[CoreData] endTime nil") }
            if distance == nil { print("[CoreData] distance nil") }
            if calories == nil { print("[CoreData] calories nil") }
            if elapsedTime == nil { print("[CoreData] elapsedTime nil") }
            if averagePace == nil { print("[CoreData] averagePace nil") }
            if pathData == nil { print("[CoreData] path nil") }
            guard
                let id = id as? UUID,
                let startTime = startTime as? Date,
                let endTime = endTime as? Date,
                let distance = distance as? Double,
                let calories = calories as? Double,
                let elapsedTime = elapsedTime as? Double,
                let averagePace = averagePace as? Double,
                let pathData = pathData as? Data,
                let codablePath = try? JSONDecoder().decode([CodableCoordinate].self, from: pathData)
            else {
                print("[CoreData] guard문 통과 실패, row 스킵")
                return nil
            }
            let path = codablePath.map { $0.clLocationCoordinate2D }
            return RunningRecord(
                id: id,
                startTime: startTime,
                endTime: endTime,
                distance: distance,
                calories: calories,
                elapsedTime: elapsedTime,
                averagePace: averagePace,
                path: path
            )
        }
    }
} 