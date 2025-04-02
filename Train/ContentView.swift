//
//  ContentView.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI

struct ContentView: View {
    // Mock data
    @State private var hrv: Int = 67
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(white: 0.12)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good morning")
                                .foregroundColor(.gray)
                            Text("Sean")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "bell")
                                    .foregroundColor(.gray)
                            )
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // Today's Training Plan
                            TrainingPlanCard()
                            
                            // Vitals Section
                            VitalsCard(hrv: hrv)
                            
                            // Recovery Status
                            RecoveryStatusCard()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            
            // Tab Bar
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TrainingPlanCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Training")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                WorkoutRow(name: "Upper Body Power", type: "Chest & Shoulders", sets: "4 sets")
                WorkoutRow(name: "Core Stability", type: "Abs & Lower Back", sets: "3 sets")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct VitalsCard: View {
    let hrv: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Vitals")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VitalMetric(
                    icon: "heart.fill",
                    title: "HRV",
                    value: "\(hrv) ms",
                    status: "Good"
                )
                
                VitalMetric(
                    icon: "bed.double.fill",
                    title: "Sleep",
                    value: "7h 30m",
                    status: "Average"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct RecoveryStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Status")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                RecoveryRow(muscle: "Chest", status: "Fresh", color: .green)
                RecoveryRow(muscle: "Legs", status: "Recovering", color: .orange)
                RecoveryRow(muscle: "Back", status: "Ready", color: .green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct WorkoutRow: View {
    let name: String
    let type: String
    let sets: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .fontWeight(.semibold)
                Text(type)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(sets)
                .foregroundColor(.gray)
        }
    }
}

struct VitalMetric: View {
    let icon: String
    let title: String
    let value: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .fontWeight(.medium)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(status)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecoveryRow: View {
    let muscle: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(muscle)
                .fontWeight(.medium)
            Spacer()
            Text(status)
                .foregroundColor(color)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.system(size: 20))
                        Text(tabTitle(for: index))
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == index ? .white : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "dumbbell.fill"
        case 1: return "clock.fill"
        case 2: return "chart.bar.fill"
        case 3: return "person.fill"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Workout"
        case 1: return "History"
        case 2: return "Training"
        case 3: return "Profile"
        default: return ""
        }
    }
}

#Preview {
    ContentView()
}
