//
//  RunningClient.swift
//  RunningLog
//
//  Created by Den on 5/26/25.
//

import Foundation
import CoreLocation
import ComposableArchitecture

// MARK: - Running Models
struct RunningSession: Equatable {
    let id = UUID()
    var startTime: Date?
    var endTime: Date?
    var distance: Double = 0.0 // meters
    var currentPace: Double = 0.0 // minutes per km
    var averagePace: Double = 0.0
    var heartRate: Int = 0 // bpm
    var isActive: Bool = false
    var isPaused: Bool = false
    var elapsedTime: TimeInterval = 0
    
    var formattedDistance: String {
        String(format: "%.2f", distance / 1000)
    }
    
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedPace: String {
        if currentPace == 0 { return "--'--\"" }
        let minutes = Int(currentPace)
        let seconds = Int((currentPace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

// MARK: - Running Client Protocol
protocol RunningClient {
    func startRunning() async throws -> Void
    func pauseRunning() async throws -> Void
    func resumeRunning() async throws -> Void
    func stopRunning() async throws -> Void
    func updateLocation(_ location: CLLocation) async throws -> Void
    func updateHeartRate(_ heartRate: Int) async throws -> Void
    func getSession() async -> RunningSession?
}

// MARK: - Running Client Implementation
extension RunningClient {
    static var live: RunningClient {
        RunningClientImpl()
    }
    
    static var mock: RunningClient {
        MockRunningClient()
    }
}

class RunningClientImpl: RunningClient {
    private var session = RunningSession()
    private var locations: [CLLocation] = []
    private var lastLocation: CLLocation?
    
    func startRunning() async throws -> Void {
        session.isActive = true
        session.isPaused = false
        session.startTime = Date()
        session.elapsedTime = 0
        session.distance = 0
        locations.removeAll()
        lastLocation = nil
    }
    
    func pauseRunning() async throws -> Void {
        session.isPaused = true
    }
    
    func resumeRunning() async throws -> Void {
        session.isPaused = false
    }
    
    func stopRunning() async throws -> Void {
        session.isActive = false
        session.isPaused = false
        session.endTime = Date()
        
        // Calculate average pace
        if session.distance > 0 && session.elapsedTime > 0 {
            let distanceInKm = session.distance / 1000.0
            let timeInMinutes = session.elapsedTime / 60.0
            session.averagePace = timeInMinutes / distanceInKm
        }
    }
    
    func updateLocation(_ location: CLLocation) async throws -> Void {
        guard session.isActive && !session.isPaused else { return }
        
        locations.append(location)
        
        // Calculate distance
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            session.distance += distance
            
            // Calculate current pace (simplified)
            if session.elapsedTime > 0 {
                let distanceInKm = session.distance / 1000.0
                let timeInMinutes = session.elapsedTime / 60.0
                session.currentPace = timeInMinutes / distanceInKm
            }
        }
        
        lastLocation = location
    }
    
    func updateHeartRate(_ heartRate: Int) async throws -> Void {
        session.heartRate = heartRate
    }
    
    func getSession() async -> RunningSession? {
        return session
    }
}

struct MockRunningClient: RunningClient {
    func startRunning() async throws -> Void {
        // Mock implementation
    }
    
    func pauseRunning() async throws -> Void {
        // Mock implementation
    }
    
    func resumeRunning() async throws -> Void {
        // Mock implementation
    }
    
    func stopRunning() async throws -> Void {
        // Mock implementation
    }
    
    func updateLocation(_ location: CLLocation) async throws -> Void {
        // Mock implementation
    }
    
    func updateHeartRate(_ heartRate: Int) async throws -> Void {
        // Mock implementation
    }
    
    func getSession() async -> RunningSession? {
        return RunningSession(
            distance: 3120, // 3.12km
            currentPace: 5.5,
            averagePace: 5.3,
            heartRate: 145,
            isActive: false,
            isPaused: true,
            elapsedTime: 1623 // 27분 3초
        )
    }
} 