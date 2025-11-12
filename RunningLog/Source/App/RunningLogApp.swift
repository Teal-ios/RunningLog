//
//  RunningLogApp.swift
//  RunningLog
//
//  Created by Den on 5/22/25.
//

import SwiftUI
import ComposableArchitecture
import CoreData


@main
struct RunningLogApp: App {
    private let rootStore: StoreOf<RootFeature> = Store(initialState: RootFeature.State()) {
        RootFeature()
    }
    
    let persistenceController = PersistenceController.shared
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(store: rootStore)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    private(set) var isStoreLoaded = false
    static let storeLoadedNotification = Notification.Name("CoreDataStoreLoaded")
    private init() {
        container = NSPersistentContainer(name: "RunningRecord")
        print("[CoreData] NSPersistentContainer 생성")
        container.loadPersistentStores { desc, error in
            if let error = error as NSError? {
                print("[CoreData] loadPersistentStores 에러: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("[CoreData] loadPersistentStores 완료: \(desc)")
            print("[CoreData] viewContext.persistentStoreCoordinator: \(String(describing: self.container.viewContext.persistentStoreCoordinator))")
            self.isStoreLoaded = true
            NotificationCenter.default.post(name: Self.storeLoadedNotification, object: nil)
        }
    }
}
