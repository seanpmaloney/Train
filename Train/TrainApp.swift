//
//  TrainApp.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI
// Firebase will need to be added via Swift Package Manager in Xcode
// import Firebase

@main
struct TrainApp: App {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var userSessionManager = UserSessionManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Track previous phase to prevent duplicate refreshes
    @State private var previousPhase: ScenePhase = .inactive
    
    init() {
        // Initialize Firebase
        // In a real implementation, this would be uncommented:
        // FirebaseApp.configure()
        
        print("TrainApp initialized with user accounts")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Initial authorization and data fetch
                    appState.loadPlans()
                    if !healthKit.isAuthorized {
                        if await healthKit.requestAuthorization() {
                            await healthKit.fetchTodayData()
                        }
                    } else {
                        await healthKit.fetchTodayData()
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Only refresh when becoming active from a non-active state
                    if newPhase == .active && oldPhase != .active {
                        Task {
                            print("App became active, refreshing health data...")
                            await healthKit.fetchTodayData()
                        }
                    }
                }
                .environmentObject(appState)
                .environmentObject(navigationCoordinator)
                .environmentObject(userSessionManager)
        }
    }
}

