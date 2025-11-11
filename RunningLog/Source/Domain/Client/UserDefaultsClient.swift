//
//  UserDefaultsClient.swift
//  RunningLog
//
//  Created by Den on 11/11/25.
//

import Foundation
import ComposableArchitecture

// MARK: - Errors

enum UserDefaultsError: Error {
    case encodingFailed
    case decodingFailed
}

// MARK: - Client Protocol

protocol UserDefaultsClient {
    func load<T: Codable>(forKey key: String) throws -> T?
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func remove(forKey key: String)
}

// MARK: - Live Implementation

struct UserDefaultsClientLive: UserDefaultsClient {
    private let userDefaults: UserDefaults = .standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw UserDefaultsError.decodingFailed
        }
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            throw UserDefaultsError.encodingFailed
        }
    }

    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
}

struct MockUserDefaultsClientLive: UserDefaultsClient {


    func load<T: Codable>(forKey key: String) throws -> T? {
        return nil
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        
    }

    func remove(forKey key: String) {
    }
    
}
// MARK: - TCA Dependency Integration

private enum UserDefaultsClientKey: DependencyKey {
    static let liveValue: UserDefaultsClient = UserDefaultsClientLive()
    static let testValue: UserDefaultsClient = MockUserDefaultsClientLive()
}

extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClientKey.self] }
        set { self[UserDefaultsClientKey.self] = newValue }
    }
}
