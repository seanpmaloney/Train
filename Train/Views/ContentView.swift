//
//  ContentView.swift
//  Train
//
//  Created by Sean Maloney on 4/2/25.
//

import SwiftUI

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
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
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
                .fill(AppStyle.Colors.surface)
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
        guard let value = value else { return ("No Data", AppStyle.Colors.textSecondary) }
        if value > 50 { return ("Good", AppStyle.Colors.success) }
        if value > 30 { return ("Average", AppStyle.Colors.secondary) }
        return ("Poor", AppStyle.Colors.danger)
    }
    
    private func getSleepStatus(_ hours: Double?) -> (status: String, color: Color) {
        guard let hours = hours else { return ("No Data", AppStyle.Colors.textSecondary) }
        if hours >= 7 { return ("Good", AppStyle.Colors.success) }
        if hours >= 6 { return ("Average", AppStyle.Colors.secondary) }
        return ("Poor", AppStyle.Colors.danger)
    }
    
    private func getHeartRateStatus(_ bpm: Double?) -> (status: String, color: Color) {
        guard let bpm = bpm else { return ("No Data", AppStyle.Colors.textSecondary) }
        if bpm < 60 { return ("Excellent", AppStyle.Colors.success) }
        if bpm < 70 { return ("Good", AppStyle.Colors.secondary) }
        return ("Average", AppStyle.Colors.danger)
    }
}

struct ContentView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(AppStyle.Colors.background)
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
                                            .foregroundColor(AppStyle.Colors.textSecondary)
                                        Text("Sean")
                                            .font(.title)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    
                                    Circle()
                                        .fill(AppStyle.Colors.surface)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "bell")
                                                .foregroundColor(AppStyle.Colors.textSecondary)
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
                                    
                                    CollapsibleCard(
                                        title: "Calendar",
                                        storageKey: "isCalendarCollapsed",
                                        defaultCollapsed: false
                                    ) {
                                        CalendarCardView()
                                    }
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
                        PlansView()
                            .environmentObject(appState)
                    case 2:
                        TrainingView()
                    case 3:
                        Text("Profile")
                            .foregroundColor(AppStyle.Colors.textPrimary)
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

struct CollapsibleCard<Content: View>: View {
    let title: String
    let content: Content
    let storageKey: String
    let defaultCollapsed: Bool
    
    @AppStorage private var isCollapsed: Bool
    
    init(
        title: String,
        storageKey: String,
        defaultCollapsed: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.storageKey = storageKey
        self.defaultCollapsed = defaultCollapsed
        self._isCollapsed = AppStorage(wrappedValue: defaultCollapsed, storageKey)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with toggle
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isCollapsed.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                }
            }
            
            // Collapsible content
            if !isCollapsed {
                content
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppStyle.Colors.surface)
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct EnhancedTrainingPlanCard: View {
    @Binding var selectedTab: Int
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    let workouts = [
        WorkoutEntity(
            title: "Upper Body Power",
            description: "Explosive pushing movements focusing on power development"
        ),
        WorkoutEntity(
            title: "Core Stability",
            description: "Dynamic core training with anti-rotation focus"
        )
    ]
    
    var body: some View {
        CollapsibleCard(
            title: "Today's Training",
            storageKey: "isTodayTrainingCollapsed",
            defaultCollapsed: false
        ) {
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
    }
}

struct WorkoutRowButton: View {
    let workout: WorkoutEntity
    @Binding var selectedTab: Int
    @Binding var activeWorkoutId: String?
    
    var body: some View {
        Button(action: {
            // Set active workout and switch to training tab
            activeWorkoutId = workout.title
            selectedTab = 2 // Index of Training tab
        }) {
            HStack {
                // Workout Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text(workout.exercises.first?.exerciseType ?? "Strength")
                        .font(.subheadline)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppStyle.Colors.surface)
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
                .fill(AppStyle.Colors.surface)
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
                .fill(AppStyle.Colors.surface)
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
        CollapsibleCard(
            title: "Recovery Status",
            storageKey: "isRecoveryCollapsed",
            defaultCollapsed: true
        ) {
            VStack(spacing: 12) {
                RecoveryRow(muscle: "Chest", status: "Fresh", color: AppStyle.Colors.success)
                RecoveryRow(muscle: "Legs", status: "Recovering", color: AppStyle.Colors.secondary)
                RecoveryRow(muscle: "Back", status: "Ready", color: AppStyle.Colors.success)
            }
        }
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
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            Spacer()
            Text(sets)
                .foregroundColor(AppStyle.Colors.textSecondary)
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
                    .foregroundColor(AppStyle.Colors.textPrimary)
                Text(title)
                    .fontWeight(.medium)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(status)
                .font(.subheadline)
                .foregroundColor(AppStyle.Colors.textSecondary)
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
                    .foregroundColor(selectedTab == index ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(AppStyle.Colors.surface)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "list.bullet.clipboard.fill"
        case 1: return "chart.bar.fill"
        case 2: return "dumbbell.fill"
        case 3: return "person.fill"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Dashboard"
        case 1: return "Plans"
        case 2: return "Training"
        case 3: return "Profile"
        default: return ""
        }
    }
}

struct TomorrowTrainingCard: View {
    let workouts = [
        (title: "Long Run", type: "Endurance", duration: "60 min"),
        (title: "Lower Body", type: "Strength", duration: "5 sets")
    ]
    
    var body: some View {
        CollapsibleCard(
            title: "Tomorrow's Training",
            storageKey: "isTomorrowTrainingCollapsed",
            defaultCollapsed: true
        ) {
            VStack(spacing: 16) {
                ForEach(workouts, id: \.title) { workout in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(workout.title)
                                .font(.headline)
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            
                            Text(workout.type)
                                .font(.subheadline)
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(workout.duration)
                            .font(.subheadline)
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppStyle.Colors.surface)
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
