//
//  TrainApp.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI
// Firebase will need to be added via Swift Package Manager in Xcode
import Firebase

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
        FirebaseApp.configure()
        
        print("TrainApp initialized with user accounts")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Initial authorization and data fetch
                    appState.loadPlans()
                    
                    // Fetch health data
                    if !healthKit.isAuthorized {
                        if await healthKit.requestAuthorization() {
                            await healthKit.fetchTodayData()
                        }
                    } else {
                        await healthKit.fetchTodayData()
                    }
                }
                // Using onReceive with the isLoaded publisher provides a clean, reactive way
                // to respond when the app state finishes loading from disk
                .onReceive(appState.$isLoaded) { isLoaded in
                    if isLoaded {
                        // Sync the user session when app state is loaded
                        print("AppState loaded, syncing UserSessionManager...")
                        if let persistedUser = appState.currentUser {
                            print("Found persisted user: \(persistedUser.id), name: \(persistedUser.displayName ?? "None")")
                        } else {
                            print("No persisted user found in AppState")
                        }
                        // This ensures authentication persists across app launches
                        userSessionManager.syncWithAppState(appState)
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

