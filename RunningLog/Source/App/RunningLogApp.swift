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
    @State private var isFirstLaunch: Bool? = nil
    
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
    
    @Dependency(\.userDefaults) var userDefaultsClient
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let isFirstLaunch = isFirstLaunch {
                    if !isFirstLaunch {
                        if isStoreLoaded {
                            mainContentView()
                        } else {
                            VStack {
                                Spacer()
                                ProgressView("loading_database")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                                Spacer()
                            }
                        }
                    } else {
                        OnboardingView(onCompletion: {
                            // 1. 상태 업데이트 (MainTabView로 전환)
                            self.isFirstLaunch = false
                            
                            // 2. UserDefaults에 완료 기록 저장 (다음 실행부터 건너뛰도록)
                            Task {
                                do {
                                    try userDefaultsClient.save(false, forKey: "firstLaunch")
                                } catch {
                                    print("Error saving firstLaunch state: \(error)")
                                }
                            }
                        })                    }
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
                
                Task {
                    
                    let userDefaultsClient = DependencyValues.live.userDefaults
                    
                    do {
                        let isFirst = try userDefaultsClient.load(forKey: "firstLaunch") as Bool?
                        
                        isFirstLaunch = isFirst ?? true
                        
                        if isFirstLaunch == true {
                            try userDefaultsClient.save(false, forKey: "firstLaunch")
                        }
                        
                    } catch {
                        print("Error loading firstLaunch state: \(error)")
                        isFirstLaunch = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func mainContentView() -> some View {
        MainTabView(store: Store(initialState: MainTabFeature.State(), reducer: {
            MainTabFeature()
        }))
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
