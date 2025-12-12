import SwiftUI

/// Enhanced view for active workout sessions
struct EnhancedActiveWorkoutView: View {
    // MARK: - Properties
    
    // Environment objects
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Track last started workout for UI state
    @AppStorage("lastStartedWorkout") private var lastStartedWorkoutId: String = ""
    
    // View model
    @StateObject private var viewModel: EnhancedActiveWorkoutViewModel
    @State private var showingEndWorkoutConfirmation = false
    @State private var isTimerExpanded = false
    
    // Feedback system state
    @State private var showingPreWorkoutFeedback = true
    @State private var showingExerciseFeedback = false
    @State private var showingPostWorkoutFeedback = false
    @State private var currentExerciseForFeedback: ExerciseInstanceEntity? = nil
    @State private var isCollectingExerciseFeedback = false
    
    // MARK: - Initialization
    
    init(workout: WorkoutEntity) {
        // Create view model with the workout but don't connect to appState yet
        _viewModel = StateObject(wrappedValue: EnhancedActiveWorkoutViewModel(workout: workout))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main scrolling content
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise list
                    exerciseListView
                }
                .padding()
                .padding(.bottom, 60) // Extra padding for safe area
            }
            
            // Floating timer overlay
            if isTimerExpanded {
                GeometryReader { geometry in
                    VStack {
                        HStack {
                            Spacer()
                            
                            RestTimer(isExpanded: $isTimerExpanded)
                                .padding(.top, 10)
                                .padding(.trailing)
                        }
                        Spacer()
                    }
                }
                .background(Color.clear)
                .transition(.opacity)
            }
        }
        .background(AppStyle.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Clear the active workout ID on dismiss (like original ActiveWorkoutView)
                    appState.activeWorkoutId = nil
                    
                    // Keep lastStartedWorkoutId so button shows "Continue Workout" when returning
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(viewModel.workout.title)
                    .font(.headline)
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isTimerExpanded.toggle()
                    }
                }) {
                    Image(systemName: "clock.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppStyle.Colors.surface)
                                .shadow(color: .black.opacity(0.2), radius: 5)
                        )
                        .contentShape(Circle())
                }
            }
        }
        // Pre-Workout Feedback Sheet
        .sheet(isPresented: $showingPreWorkoutFeedback) {
            PreWorkoutFeedbackView(workout: viewModel.workout)
        }
        
        // Exercise-specific Feedback Sheet - using sheet(item:) instead of sheet(isPresented:)
        .sheet(item: $currentExerciseForFeedback, onDismiss: {
            // Reset the feedback collection state
            isCollectingExerciseFeedback = false
            
            // Check if the entire workout is complete
            if viewModel.getCompletionPercentage() >= 1.0 && !viewModel.isComplete && !showingPostWorkoutFeedback {
                // Check if this is the final workout in the plan
                if appState.isLastWorkoutInPlan(viewModel.workout) {
                    // Skip post-workout feedback and go straight to plan completion
                    appState.endWorkout(with: .normal) // Use default fatigue
                } else {
                    // Show post-workout feedback for non-final workouts
                    showingPostWorkoutFeedback = true
                }
            }
        }) { exercise in
            ExerciseFeedbackView(
                exercise: exercise,
                workout: viewModel.workout,
                isCollectingFeedback: $isCollectingExerciseFeedback
            )
            .environmentObject(appState)
        }
        
        // Post-Workout Feedback Sheet
        .sheet(isPresented: $showingPostWorkoutFeedback) {
            PostWorkoutFeedbackView()
                .environmentObject(appState) // Ensure app state is passed to the view
        }
        
        
        .onAppear {
            // Set the active workout ID when the view appears
            appState.activeWorkoutId = viewModel.workout.id
            
            // Mark this workout as started for the UI state to show "Continue Workout" button
            lastStartedWorkoutId = viewModel.workout.id.uuidString
            
            // Connect view model to appState
            viewModel.connectAppState(appState)
            
            // Only show pre-workout feedback for workouts that haven't started yet
            // (i.e., none of the sets are completed)
            let hasStartedSets = viewModel.exercises.flatMap { $0.sets }.contains { $0.isComplete }
            showingPreWorkoutFeedback = !hasStartedSets && !viewModel.workout.isComplete
        }
    }
    
    // MARK: - Component Views
    
    /// Header view showing workout info and progress
    private var workoutHeaderView: some View {
        VStack(spacing: 16) {
            // Title and date
            VStack(spacing: 4) {
                Text(viewModel.workout.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                if let date = viewModel.workout.scheduledDate {
                    Text(formatDate(date))
                        .font(.subheadline)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
            
            // Progress bar
            ProgressView(value: viewModel.getCompletionPercentage())
                .progressViewStyle(LinearProgressViewStyle(tint: AppStyle.Colors.primary))
                .padding(.horizontal)
                .padding(.top, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppStyle.Colors.surface)
                        .opacity(0.3)
                )
            
            // Progress text
            let percentage = Int(viewModel.getCompletionPercentage() * 100)
            Text("\(percentage)% Complete")
                .font(.caption)
                .foregroundColor(AppStyle.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyle.Colors.surface)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Exercise list view
    private var exerciseListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            VStack(spacing: 16) {
                ForEach(viewModel.exercises) { exercise in
                    SwipeableExerciseCard(
                        exercise: exercise, 
                        viewModel: viewModel,
                        onExerciseProgress: { completedExercise in
                                isCollectingExerciseFeedback = true
                                currentExerciseForFeedback = completedExercise
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Feedback Flow Methods
    
    /// Check for overall workout completion status
    private func checkForCompletedExercises() {
        // Only check if the whole workout is complete - individual exercises are handled via callbacks
        if viewModel.getCompletionPercentage() >= 1.0 && !viewModel.isComplete && !showingPostWorkoutFeedback {
            // Check if this is the final workout in the plan
            if appState.isLastWorkoutInPlan(viewModel.workout) {
                // Skip post-workout feedback and go straight to plan completion
                appState.endWorkout(with: .normal) // Use default fatigue
            } else {
                // Show post-workout feedback for non-final workouts
                showingPostWorkoutFeedback = true
            }
        }
    }
    
}
