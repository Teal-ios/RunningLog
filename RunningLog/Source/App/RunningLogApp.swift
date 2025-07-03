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
    let persistenceController = PersistenceController.shared
    @State private var isStoreLoaded = false
    
    init() {
        // CoreData store 준비 시작
        _ = persistenceController
        
        // TabBar 외형 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isStoreLoaded {
                    MainTabView(store: Store(initialState: MainTabFeature.State(), reducer: {
                        MainTabFeature()
                    }))
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    VStack {
                        Spacer()
                        ProgressView("loading_database")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                        Spacer()
                    }
                }
            }
            .onAppear {
                if persistenceController.isStoreLoaded {
                    isStoreLoaded = true
                } else {
                    NotificationCenter.default.addObserver(forName: PersistenceController.storeLoadedNotification, object: nil, queue: .main) { _ in
                        isStoreLoaded = true
                    }
                }
            }
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
