import SwiftUI

/// Enhanced view for active workout sessions
struct EnhancedActiveWorkoutView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: EnhancedActiveWorkoutViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndWorkoutConfirmation = false
    @State private var isTimerExpanded = false
    
    // MARK: - Initialization
    
    init(workout: WorkoutEntity) {
        // Create view model with the workout but don't connect to appState yet
        _viewModel = StateObject(wrappedValue: EnhancedActiveWorkoutViewModel(workout: workout))
        
        print("EnhancedActiveWorkoutView initialized with workout: \(workout.title)")
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main scrolling content
            ScrollView {
                VStack(spacing: 24) {
                    // Workout header with progress
                    workoutHeaderView
                        .padding(.bottom, 8)
                    
                    // Exercise list
                    exerciseListView
                    
                    // Action buttons
                    actionButtonsView
                        .padding(.vertical, 16)
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
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
        .alert("End Workout", isPresented: $showingEndWorkoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End Workout", role: .destructive) {
                viewModel.completeWorkout(appState: appState)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this workout? This will mark it as complete.")
        }
        .onAppear {
            // Connect view model to appState when the view appears
            viewModel.connectAppState(appState)
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
                    ExerciseEditView(exercise: exercise, viewModel: viewModel)
                }
            }
        }
    }
    
    /// Action buttons view
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingEndWorkoutConfirmation = true
            }) {
                HStack {
                    Spacer()
                    Text("End Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppStyle.Colors.danger)
                )
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
}
