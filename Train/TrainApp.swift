//
//  TrainApp.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI

@main
struct TrainApp: App {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    
    // Track previous phase to prevent duplicate refreshes
    @State private var previousPhase: ScenePhase = .inactive
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Initial authorization and data fetch
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
        }
    }
}

