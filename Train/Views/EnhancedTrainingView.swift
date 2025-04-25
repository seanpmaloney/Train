import SwiftUI

/// Enhanced training view that separates past and upcoming workouts
struct EnhancedTrainingView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: EnhancedTrainingViewModel
    @EnvironmentObject private var appState: AppState
    @State private var isPastWorkoutsExpanded = true
    @State private var activeWorkout: WorkoutEntity? = nil
    @State private var showActiveWorkout = false
    @State private var hasActiveWorkoutDismissedByGesture = false
    @State private var selectedWeekIndex = 0
    @State private var weekGroups: [EnhancedTrainingViewModel.WeekGroup] = []
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: EnhancedTrainingViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
        
            NavigationStack {
                // Floating action button for resuming active workout
                if hasActiveWorkoutDismissedByGesture, let workout = activeWorkout {
                    activeWorkoutFloatingButton(workout: workout)
                }
                
                VStack(spacing: 0) {
                    // Week selector
                    if !weekGroups.isEmpty {
                        WeekSelectorView(
                            weekGroups: weekGroups,
                            currentWeekIndex: selectedWeekIndex,
                            onWeekSelected: { index in
                                withAnimation {
                                    selectedWeekIndex = index
                                }
                            }
                        )
                        .padding(.top, 8)
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current week workouts section
                            if !weekGroups.isEmpty {
                                workoutSection(
                                    title: nil,
                                    workouts: weekGroups[selectedWeekIndex].workouts,
                                    isUpcoming: true
                                )
                            } else {
                                // Show upcoming workouts as fallback if no week groups
                                workoutSection(
                                    title: nil,
                                    workouts: viewModel.upcomingWorkouts,
                                    isUpcoming: true
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 60)
                    }
                    .background(AppStyle.Colors.background.ignoresSafeArea())
                }
                .onAppear {
                    refreshWeekGroups()
                }
                .onChange(of: appState.activeWorkoutId) { newId in
                    if let id = newId {
                        if let workout = findWorkout(with: id) {
                            activeWorkout = workout
                            showActiveWorkout = true
                            hasActiveWorkoutDismissedByGesture = false
                        }
                    } else {
                        activeWorkout = nil
                        showActiveWorkout = false
                        hasActiveWorkoutDismissedByGesture = false
                        
                        // Refresh week groups when returning from workout
                        refreshWeekGroups()
                    }
                }
            }
            
            // Use NavigationLink to present the active workout instead of sheet
            NavigationLink(
                isActive: $showActiveWorkout,
                destination: {
                    if let workout = activeWorkout {
                        EnhancedActiveWorkoutView(workout: workout)
                    } else {
                        // Fallback if workout is nil (should never happen)
                        Text("Loading workout...")
                    }
                },
                label: { EmptyView() }
            )
            .hidden()
            .onDisappear {
                // Handle the case when NavigationLink is dismissed but workout is still active
                if appState.activeWorkoutId != nil && !showActiveWorkout {
                    hasActiveWorkoutDismissedByGesture = true
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// Creates a floating button to resume an active workout
    private func activeWorkoutFloatingButton(workout: WorkoutEntity) -> some View {
        Button(action: {
            showActiveWorkout = true
            hasActiveWorkoutDismissedByGesture = false
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Workout")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(workout.title)
                        .font(.footnote)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppStyle.Colors.primary)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: hasActiveWorkoutDismissedByGesture)
    }
    
    /// Creates a section of workouts (upcoming or past)
    private func workoutSection(
        title: String?,
        workouts: [WorkoutEntity],
        isUpcoming: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
                if (title != nil) {
                    Text(title!)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                }
            
            // Workouts list
                if workouts.isEmpty {
                    emptyStateView(for: isUpcoming)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(workouts) { workout in
                            WorkoutCardView(
                                workout: workout,
                                viewModel: viewModel,
                                isUpcoming: isUpcoming,
                                isExpanded: isUpcoming || viewModel.isWorkoutExpanded(workout),
                                onStartPressed: {
                                    // If this workout is already active, just navigate to it
                                    if viewModel.isWorkoutActive(workout) {
                                        activeWorkout = workout
                                        showActiveWorkout = true
                                        hasActiveWorkoutDismissedByGesture = false
                                    } else {
                                        // Otherwise start a new workout
                                        viewModel.startWorkout(workout)
                                    }
                                },
                                onExpandToggle: {
                                    if !isUpcoming {
                                        viewModel.toggleWorkoutExpanded(workout)
                                    }
                                }
                            )
                        }
                    }
                }
        }
    }
    
    /// Creates an empty state view based on the section
    private func emptyStateView(for isUpcoming: Bool) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: isUpcoming ? "calendar.badge.exclamationmark" : "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(AppStyle.Colors.textSecondary)
                .padding(.bottom, 8)
            
            Text(isUpcoming ? "No upcoming workouts" : "No past workouts")
                .font(.headline)
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text(isUpcoming ? "Create a plan to get started" : "Complete workouts to see them here")
                .font(.subheadline)
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppStyle.Colors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    /// Finds a workout by ID in both upcoming and past workouts
    private func findWorkout(with id: UUID) -> WorkoutEntity? {
        if let workout = viewModel.upcomingWorkouts.first(where: { $0.id == id }) {
            return workout
        }
        return viewModel.pastWorkouts.first(where: { $0.id == id })
    }
    
    // Function to refresh week groups and set the correct current week
    private func refreshWeekGroups() {
        weekGroups = viewModel.getWeekGroups()
        
        // Set the selected week to the current week if we have week groups
        if !weekGroups.isEmpty {
            if let currentWeekGroup = viewModel.getCurrentWeekGroup(),
               let currentWeekIndex = weekGroups.firstIndex(where: { $0.weekNumber == currentWeekGroup.weekNumber }) {
                selectedWeekIndex = currentWeekIndex
            } else {
                // Default to the first week if we can't find the current week
                selectedWeekIndex = 0
            }
        }
    }
}
