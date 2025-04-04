//
//  ContentView.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI

struct CircularStatView: View {
    let title: String
    let value: String
    let status: String
    let ringColor: Color
    let progress: Double // 0.0 to 1.0
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(white: 0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                // Value
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            
            Text(status)
                .font(.caption2)
                .foregroundColor(ringColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VitalStat: View {
    let icon: String
    let label: String
    let value: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Top row with icon, label, and value
            VStack(spacing: 2) {
                // Label row
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Value
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Status label below
            Text(status)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VitalsRow: View {
    @StateObject private var healthKit = HealthKitManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                // HRV
                VitalStat(
                    icon: "heart.fill",
                    label: "HRV",
                    value: formatHRV(healthKit.hrvValue),
                    status: getHRVStatus(healthKit.hrvValue).status,
                    statusColor: getHRVStatus(healthKit.hrvValue).color
                )
                
                // Sleep
                VitalStat(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: formatSleep(healthKit.sleepHours),
                    status: getSleepStatus(healthKit.sleepHours).status,
                    statusColor: getSleepStatus(healthKit.sleepHours).color
                )
                
                // Resting HR
                VitalStat(
                    icon: "waveform.path.ecg",
                    label: "Resting HR",
                    value: formatHeartRate(healthKit.restingHeartRate),
                    status: getHeartRateStatus(healthKit.restingHeartRate).status,
                    statusColor: getHeartRateStatus(healthKit.restingHeartRate).color
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.17))
        )
        .padding(.horizontal)
    }
    
    private func formatHRV(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        return "\(Int(value)) ms"
    }
    
    private func formatSleep(_ hours: Double?) -> String {
        guard let hours = hours else { return "--" }
        let totalMinutes = Int(hours * 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%dh %dm", hrs, mins)
    }
    
    private func formatHeartRate(_ bpm: Double?) -> String {
        guard let bpm = bpm else { return "--" }
        return "\(Int(bpm)) bpm"
    }
    
    private func getHRVStatus(_ value: Double?) -> (status: String, color: Color) {
        guard let value = value else { return ("No Data", .gray) }
        if value > 50 { return ("Good", .green) }
        if value > 30 { return ("Average", .yellow) }
        return ("Poor", .red)
    }
    
    private func getSleepStatus(_ hours: Double?) -> (status: String, color: Color) {
        guard let hours = hours else { return ("No Data", .gray) }
        if hours >= 7 { return ("Good", .green) }
        if hours >= 6 { return ("Average", .yellow) }
        return ("Poor", .red)
    }
    
    private func getHeartRateStatus(_ bpm: Double?) -> (status: String, color: Color) {
        guard let bpm = bpm else { return ("No Data", .gray) }
        if bpm < 60 { return ("Excellent", .green) }
        if bpm < 70 { return ("Good", .yellow) }
        return ("Average", .red)
    }
}

struct ContentView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(white: 0.12)
                    .ignoresSafeArea()
                
                Group {
                    switch selectedTab {
                    case 0:
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                // Header
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
                                .padding(.top, 8)
                                
                                // Dashboard Content
                                VStack(spacing: 24) {
                                    // Vitals Row
                                    VitalsRow()
                                    
                                    // Today's Training
                                    EnhancedTrainingPlanCard(selectedTab: $selectedTab)
                                        .padding(.horizontal)
                                    
                                    // Tomorrow's Training
                                    TomorrowTrainingCard()
                                        .padding(.horizontal)
                                    
                                    // Recovery Status
                                    RecoveryStatusCard()
                                        .padding(.horizontal)
                                }
                            }
                            // Add bottom padding to clear the tab bar
                            .padding(.bottom, 100)
                        }
                        
                    case 1:
                        Text("History")
                            .foregroundColor(.white)
                    case 2:
                        TrainingView()
                    case 3:
                        Text("Profile")
                            .foregroundColor(.white)
                    default:
                        EmptyView()
                    }
                }
                
                // Tab Bar
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct EnhancedTrainingPlanCard: View {
    @Binding var selectedTab: Int
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    // Sample workouts (should match TrainingView data)
    let workouts = [
        Workout(
            id: "upper-power-01",
            title: "Upper Body Power",
            type: "Chest & Shoulders",
            description: "Explosive pushing movements focusing on power development"
        ),
        Workout(
            id: "core-01",
            title: "Core Stability",
            type: "Abs & Lower Back",
            description: "Dynamic core training with anti-rotation focus"
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text("Today's Training")
                .font(.title2)
                .fontWeight(.bold)
            
            // Workouts List
            VStack(spacing: 16) {
                ForEach(workouts) { workout in
                    WorkoutRowButton(
                        workout: workout,
                        selectedTab: $selectedTab,
                        activeWorkoutId: $activeWorkoutId
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct WorkoutRowButton: View {
    let workout: Workout
    @Binding var selectedTab: Int
    @Binding var activeWorkoutId: String?
    
    var body: some View {
        Button(action: {
            // Set active workout and switch to training tab
            activeWorkoutId = workout.id
            selectedTab = 2 // Index of Training tab
        }) {
            HStack {
                // Workout Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(workout.type)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.2))
            )
        }
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
    @StateObject private var healthKit = HealthKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Vitals")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VitalMetric(
                    icon: "heart.fill",
                    title: "HRV",
                    value: formatHRV(healthKit.hrvValue),
                    status: getHRVStatus(healthKit.hrvValue)
                )
                
                VitalMetric(
                    icon: "bed.double.fill",
                    title: "Sleep",
                    value: formatSleep(healthKit.sleepHours),
                    status: getSleepStatus(healthKit.sleepHours)
                )
                
                VitalMetric(
                    icon: "heart.circle.fill",
                    title: "Resting HR",
                    value: formatHeartRate(healthKit.restingHeartRate),
                    status: getHeartRateStatus(healthKit.restingHeartRate)
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
        .task {
            if !healthKit.isAuthorized {
                _ = await healthKit.requestAuthorization()
            }
            await healthKit.fetchTodayData()
        }
    }
    
    private func formatHRV(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        return String(format: "%.0f ms", value)
    }
    
    private func formatSleep(_ hours: Double?) -> String {
        guard let hours = hours else { return "--" }
        let totalMinutes = Int(hours * 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%dh %dm", hrs, mins)
    }
    
    private func formatHeartRate(_ bpm: Double?) -> String {
        guard let bpm = bpm else { return "--" }
        return String(format: "%.0f bpm", bpm)
    }
    
    private func getHRVStatus(_ value: Double?) -> String {
        guard let value = value else { return "No Data" }
        if value > 50 { return "Good" }
        if value > 30 { return "Average" }
        return "Poor"
    }
    
    private func getSleepStatus(_ hours: Double?) -> String {
        guard let hours = hours else { return "No Data" }
        if hours >= 7 { return "Good" }
        if hours >= 6 { return "Average" }
        return "Poor"
    }
    
    private func getHeartRateStatus(_ bpm: Double?) -> String {
        guard let bpm = bpm else { return "No Data" }
        if bpm < 60 { return "Excellent" }
        if bpm < 70 { return "Good" }
        return "Average"
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
        case 0: return "Dashboard"
        case 1: return "History"
        case 2: return "Training"
        case 3: return "Profile"
        default: return ""
        }
    }
}

struct TomorrowTrainingCard: View {
    // Sample workouts for tomorrow
    let workouts = [
        (
            title: "Long Run",
            type: "Endurance",
            duration: "60 min"
        ),
        (
            title: "Lower Body",
            type: "Strength",
            duration: "5 sets"
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text("Tomorrow's Training")
                .font(.title2)
                .fontWeight(.bold)
            
            // Workouts List
            VStack(spacing: 16) {
                ForEach(workouts, id: \.title) { workout in
                    HStack {
                        // Workout Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(workout.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(workout.type)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Duration/Sets
                        Text(workout.duration)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2))
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

#Preview {
    ContentView()
}
