import SwiftUI

/// A swipeable exercise card that allows navigating through exercise history with gestures
struct SwipeableExerciseCard: View {
    // MARK: - Properties
    
    @ObservedObject var exercise: ExerciseInstanceEntity
    @ObservedObject var viewModel: EnhancedActiveWorkoutViewModel
    
    @State private var exerciseHistory: [ExerciseInstanceEntity] = []
    @State private var currentIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var showingInitialHint = false
    @State private var hintTimer: Timer?
    
    // Computed property to determine if we have any history to display
    private var hasHistory: Bool {
        // Need at least 2 exercises to have history (current + at least one past)
        exerciseHistory.count > 1
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // History icon that appears when card is moved
            if hasHistory {
                HStack {
                    VStack {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.7))
                        Text("History")
                            .font(.caption)
                            .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.8))
                        Spacer()
                    }
                    .frame(width: 80)
                    .padding(.trailing, 16)
                    Spacer()
                }
            }
            
            // Exercise card content
            VStack(alignment: .leading, spacing: 12) {
                // Exercise header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentDisplayExercise?.movement.name ?? exercise.movement.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(isViewingHistory ? AppStyle.Colors.textSecondary : AppStyle.Colors.textPrimary)
                        
                        // Muscle group pills
                        if let displayExercise = currentDisplayExercise, !displayExercise.movement.primaryMuscles.isEmpty {
                            // Only show the first muscle group (as mentioned by the user)
                            // This ensures it's static and doesn't affect swiping
                            if let primaryMuscle = displayExercise.movement.primaryMuscles.first {
                                MusclePill(muscle: primaryMuscle)
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Date display for historical cards only
                    if isViewingHistory, let displayExercise = currentDisplayExercise, let date = viewModel.getDateForExercise(displayExercise) {
                        Text(formatDate(date))
                            .font(.caption)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppStyle.Colors.surface.opacity(0.7))
                            )
                            .padding(2)
                    }
                }
                
                // Sets list
                VStack(spacing: 12) {
                    if let displayExercise = currentDisplayExercise {
                        ForEach(displayExercise.sets) { set in
                            SetEditRow(
                                set: set,
                                exercise: displayExercise,
                                isEditable: !isViewingHistory && !viewModel.isComplete,
                                viewModel: viewModel
                            )
                            .id("\(displayExercise.id)-\(set.id)")
                            .transition(.opacity)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                .opacity(isViewingHistory ? 0.6 : 1.0)
                
                // History indicator dots (minimal)
                if hasHistory {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            ForEach(0..<exerciseHistory.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppStyle.Colors.surface)
            )
            .offset(x: offset + (showingInitialHint ? 80 : 0))
            .simultaneousGesture(
                DragGesture()
                    .onChanged { gesture in
                        // Only allow drag if there's history
                        if hasHistory {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        // Only process if there's history
                        if hasHistory {
                            let dragThreshold: CGFloat = 50
                            
                            // Determine direction and whether to change index
                            if gesture.translation.width > dragThreshold && currentIndex > 0 {
                                // Swipe right to go back in history
                                currentIndex -= 1
                            } else if gesture.translation.width < -dragThreshold && currentIndex < exerciseHistory.count - 1 {
                                // Swipe left to go forward in history
                                currentIndex += 1
                            }
                            
                            // Reset offset with animation
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .padding(.horizontal, 4)
        .onAppear {
            // Load exercise history when view appears
            exerciseHistory = viewModel.getExerciseHistory(for: exercise)
            
            // Default to current exercise (most recent)
            currentIndex = exerciseHistory.count - 1
            
            // Perform initial animation hint if there's history to see
            if hasHistory {
                // Give a moment for the view to load before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showingInitialHint = true
                    }
                    
                    // Reset after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showingInitialHint = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private func muscleGroupsText(for exercise: ExerciseInstanceEntity) -> String {
        let primaryNames = exercise.movement.primaryMuscles.map { $0.displayName }
        return primaryNames.joined(separator: ", ")
    }
    
    private var currentDisplayExercise: ExerciseInstanceEntity? {
        guard !exerciseHistory.isEmpty, currentIndex < exerciseHistory.count else { return exercise }
        return exerciseHistory[currentIndex]
    }
    
    private var isViewingHistory: Bool {
        guard let displayExercise = currentDisplayExercise else { return false }
        return !viewModel.isCurrentExercise(displayExercise)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    SwipeableExerciseCard(
        exercise: ExerciseInstanceEntity(
            movement: MovementEntity(
                type: .pullUps,
                primaryMuscles: [MuscleGroup.back],
                secondaryMuscles: [MuscleGroup.biceps],
                equipment: EquipmentType.machine
            ),
            exerciseType: "Strength",
            sets: [
                ExerciseSetEntity(weight: 300, completedReps: 5, targetReps: 5, isComplete: true)
            ]
        ),
        viewModel: EnhancedActiveWorkoutViewModel(
            workout: WorkoutEntity(
                title: "Workout",
                description: "Workout description",
                isComplete: false
            )
        )
    )
    .padding()
    .background(AppStyle.Colors.background)
    .preferredColorScheme(.dark)
}
