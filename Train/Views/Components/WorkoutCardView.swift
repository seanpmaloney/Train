import SwiftUI

/// A card view for displaying workout information
struct WorkoutCardView: View {
    // MARK: - Properties
    
    @ObservedObject var workout: WorkoutEntity
    let viewModel: EnhancedTrainingViewModel
    let isUpcoming: Bool
    let isExpanded: Bool
    let onStartPressed: () -> Void
    let onExpandToggle: () -> Void
    
    // Track if this workout has been started and returned to
    // This is separate from activeWorkoutId to prevent UI changes during navigation
    @AppStorage("lastStartedWorkout") private var lastStartedWorkoutId: String = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse control
            Button(action: onExpandToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.title)
                            .font(.headline)
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        if let date = workout.scheduledDate {
                            Text(viewModel.formatDate(date))
                                .font(.subheadline)
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(AppStyle.Colors.surface)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                // Muscle group tags
                let muscleGroups = viewModel.getMuscleGroups(from: workout)
                if !muscleGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(muscleGroups, id: \.self) { muscle in
                                MusclePill(muscle: muscle)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Exercises list
                if !workout.exercises.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(workout.exercises, id: \.id) { exercise in
                            ExerciseSummaryView(exercise: exercise, isEditable: false)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Action button for upcoming workouts
                if isUpcoming {
                    Button(action: onStartPressed) {
                        HStack {
                            // Adjust button text based on completion status and activity
                            if workout.isComplete {
                                Text("View Workout")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.textSecondary))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.textSecondary))
                            } else if lastStartedWorkoutId == workout.id.uuidString {
                                Text("Continue Workout")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.primary))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.primary))
                            } else {
                                Text("Start Workout")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.primary))
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(Color(AppStyle.Colors.primary))
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyle.Colors.surface)
        )
        .opacity(workout.isComplete ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: workout.isComplete)
    }
}

/// A pill-shaped view for displaying a muscle group
struct MusclePill: View {
    let muscle: MuscleGroup
    
    var body: some View {
        Text(muscle.displayName)
            .font(.caption)
            .foregroundColor(AppStyle.Colors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(muscleColor(for: muscle).opacity(0.2))
            )
    }
    
    private func muscleColor(for muscle: MuscleGroup) -> Color {
        AppStyle.MuscleColors.color(for: muscle)
    }
}

/// A view for summarizing an exercise
struct ExerciseSummaryView: View {
    @ObservedObject var exercise: ExerciseInstanceEntity
    let isEditable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise name and type
            HStack {
                Text(exercise.movement.name)
                    .font(.body)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                let plural = exercise.sets.count <= 1 ? "" : "s"
                Text(exercise.sets.count.description + " Set" + plural)
                    .font(.body)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppStyle.Colors.surfaceTop)
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppStyle.Colors.surfaceTop)
        )
    }
}

#Preview {
    ExerciseSummaryView(exercise: ExerciseInstanceEntity(movement: MovementEntity(type: .pullUps, primaryMuscles: [MuscleGroup.back], secondaryMuscles: [MuscleGroup.biceps], equipment: EquipmentType.machine), exerciseType: "Strength", sets: [ExerciseSetEntity(weight: 300, completedReps: 5, targetReps: 5, isComplete: true)]), isEditable: false)
}
