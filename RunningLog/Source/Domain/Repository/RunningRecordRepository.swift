import Foundation

protocol RunningRecordRepository {
    func save(record: RunningRecord) throws
    func fetchAll() throws -> [RunningRecord]
}

extension RunningRecordRepository {
    func fetch(by id: UUID) throws -> RunningRecord? {
        return try fetchAll().first(where: { $0.id == id })
    }
} 