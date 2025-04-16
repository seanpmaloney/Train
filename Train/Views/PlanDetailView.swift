import SwiftUI

struct PlanDetailView: View {
    let plan: TrainingPlanEntity
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppStyle.Layout.standardSpacing) {
                // Header Card
                VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
                    Text(plan.name)
                        .font(AppStyle.Typography.title())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    HStack(spacing: AppStyle.Layout.standardSpacing) {
                        planMetric(
                            icon: "chart.bar.fill",
                            title: "Progress",
                            value: plan.percentageCompleted().formatted(.percent)
                        )
                        planMetric(
                            icon: "calendar",
                            title: "Frequency",
                            value: "\(plan.daysPerWeek) days/week"
                        )
                    }
                }
                .padding()
                .background(AppStyle.Colors.surface)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10)
                
                // Weekly Schedule
                VStack(alignment: .leading, spacing: AppStyle.Layout.standardSpacing) {
                    Text("Weekly Schedule")
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    VStack(spacing: AppStyle.Layout.standardSpacing) {
                        ForEach(0..<7) { day in
                            dayCard(for: day)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !plan.isCompleted {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditor = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            PlanEditorView(template: nil, appState: appState)
        }
    }
    
    private func dayCard(for day: Int) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            // Day Header
            HStack {
                Text(Calendar.current.weekdaySymbols[day])
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                // Rest Day Indicator
                if !hasWorkout(for: day) {
                    Text("Rest Day")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppStyle.Colors.surface.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            
            if hasWorkout(for: day) {
                // Movement List
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(movementsForDay(day), id: \.id) { movement in
                        HStack(spacing: 8) {
                            Text(movement.name)
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(movement.primaryMuscles, id: \.self) { muscle in
                                        musclePill(muscle, isPrimary: true)
                                    }
                                    ForEach(movement.secondaryMuscles, id: \.self) { muscle in
                                        musclePill(muscle, isPrimary: false)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func planMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppStyle.Colors.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                Text(value)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppStyle.Colors.surface.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func musclePill(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        Text(muscle.displayName)
            .font(AppStyle.Typography.caption())
            .foregroundColor(isPrimary ? muscle.color : AppStyle.Colors.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isPrimary ? muscle.color : AppStyle.Colors.textSecondary).opacity(0.2))
            .clipShape(Capsule())
    }
    
    // Helper functions to get workout data
    private func hasWorkout(for day: Int) -> Bool {
        // Get workouts scheduled for this day of the week
        return plan.workouts.contains { workout in
            guard let scheduledDate = workout.scheduledDate else { return false }
            let weekday = Calendar.current.component(.weekday, from: scheduledDate)
            // weekday is 1-based (Sunday = 1), we need 0-based
            return (weekday - 1) == day
        }
    }
    
    private func movementsForDay(_ day: Int) -> [MovementEntity] {
        // Find workout for this day and return its movements
        let workout = plan.workouts.first { workout in
            guard let scheduledDate = workout.scheduledDate else { return false }
            let weekday = Calendar.current.component(.weekday, from: scheduledDate)
            return (weekday - 1) == day
        }
        
        // Flatten exercises into movements
        return workout?.exercises.flatMap { exercise in
            [exercise.movement]
        } ?? []
    }
}

#Preview {
    NavigationStack {
        PlanDetailView(plan: TrainingPlanEntity(
            name: "Sample Plan",
            notes: "Sample",
            startDate: Date(),
            daysPerWeek: 5,
            isCompleted: false
        ))
    }
    .preferredColorScheme(.dark)
}
