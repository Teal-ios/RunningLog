
import Foundation
import CoreData
import CoreLocation
import RunningLog
import ComposableArchitecture

enum CoreDataRepositoryError: Error {
    case recordNotFound(UUID)
    case transactionFailed(Error)
}

final class CoreDataRunningRecordRepository: RunningRecordRepository {
    private let context: NSManagedObjectContext
    
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
    
    private func fetchManagedObject(for id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RunningRecordEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try self.context.fetch(request) as? [NSManagedObject]
        return results?.first
    }
    
    
    func save(record: RunningRecord) throws {
        print("[CoreData] save() 진입, context: \(context)")
        let entityName = "RunningRecordEntity"
        let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        entity.setValue(record.id, forKey: "id")
        entity.setValue(record.startTime, forKey: "startTime")
        entity.setValue(record.endTime, forKey: "endTime")
        entity.setValue(record.distance, forKey: "distance")
        entity.setValue(record.calories, forKey: "calories")
        entity.setValue(record.elapsedTime, forKey: "elapsedTime")
        entity.setValue(record.averagePace, forKey: "averagePace")
        
        do {
            let pathData = try NSKeyedArchiver.archivedData(withRootObject: record.path, requiringSecureCoding: true)
            entity.setValue(pathData, forKey: "path")
        } catch {
            print("[CoreData] CLLocation path archiving error: \(error)")
            entity.setValue(nil, forKey: "path")
        }
        
        try context.save()
    }
    
    func fetchAll() throws -> [RunningRecord] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RunningRecordEntity")
        let results = try context.fetch(request) as! [NSManagedObject]
        return results.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let startTime = obj.value(forKey: "startTime") as? Date,
                let endTime = obj.value(forKey: "endTime") as? Date,
                let distance = obj.value(forKey: "distance") as? Double,
                let calories = obj.value(forKey: "calories") as? Double,
                let elapsedTime = obj.value(forKey: "elapsedTime") as? Double,
                let averagePace = obj.value(forKey: "averagePace") as? Double,
                let pathData = obj.value(forKey: "path") as? Data
            else { return nil }
            
            var path: [CLLocation]
            if let decodedPath = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, CLLocation.self], from: pathData) as? [CLLocation] {
                path = decodedPath
            } else if let codablePath = try? JSONDecoder().decode([CodableCoordinate].self, from: pathData) {
                path = codablePath.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            } else {
                path = []
            }
            
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
    
    func delete(record: RunningRecord) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RunningRecordEntity")
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
        let results = try context.fetch(request) as! [NSManagedObject]
        
        for object in results {
            context.delete(object)
        }
        
        try context.save()
    }
    
    func delete(records: [RunningRecord]) throws {
        
        try context.performAndWait {
            
            for record in records {
                guard let objectToDelete = try self.fetchManagedObject(for: record.id) else {
                    throw CoreDataRepositoryError.recordNotFound(record.id)
                }
                
                self.context.delete(objectToDelete)
                print("[CoreData Transaction] Deletion marked for: \(record.id)")
            }
            
            if self.context.hasChanges {
                do {
                    try self.context.save()
                    print("[CoreData Transaction] Save successful (Commit)")
                } catch {
                    self.context.rollback()
                    print("🚨 [CoreData Transaction] Save failed. Rollback executed.")
                    throw CoreDataRepositoryError.transactionFailed(error)
                }
            } else {
                 print("[CoreData Transaction] No changes to save.")
            }
        }
    }
}
