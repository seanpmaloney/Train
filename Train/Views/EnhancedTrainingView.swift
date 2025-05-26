import SwiftUI

/// Enhanced training view that separates past and upcoming workouts
struct EnhancedTrainingView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: EnhancedTrainingViewModel
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var isPastWorkoutsExpanded = true
    @State private var activeWorkout: WorkoutEntity? = nil
    @State private var showActiveWorkout = false
    @State private var hasActiveWorkoutDismissedByGesture = false
    @State private var selectedWeekIndex = 0
    @State private var showingPlanCreation = false
    @State private var initialPlanId: UUID?
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: EnhancedTrainingViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContentView()    
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func mainContentView() -> some View {
        ZStack(alignment: .bottomTrailing) {
        
            NavigationStack {
                // Floating action button for resuming active workout
                if hasActiveWorkoutDismissedByGesture, let workout = activeWorkout {
                    activeWorkoutFloatingButton(workout: workout)
                }
                
                VStack(spacing: 0) {
                    // Combined plan header and week selector
                    planHeaderView()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current week workouts section
                            if let plan = appState.currentPlan, !plan.weeklyWorkouts.isEmpty, selectedWeekIndex < plan.weeklyWorkouts.count {
                                workoutSection(
                                    title: nil,
                                    workouts: plan.weeklyWorkouts[selectedWeekIndex],
                                    isUpcoming: true
                                )
                            } else {
                                // Show upcoming workouts as fallback if no week data
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
                    initialPlanId = appState.currentPlan?.id
                    refreshWeekGroups()
                }
                .fullScreenCover(isPresented: $showingPlanCreation) {
                    planCreationView()
                }
                .onChange(of: appState.activeWorkoutId) { newId in
                    handleActiveWorkoutChange(newId: newId)
                }
            }
        }
    }
    
    @ViewBuilder
    private func planCreationView() -> some View {
        NavigationStack(path: $navigationCoordinator.path) {
            PlanTemplatePickerView()
                .environmentObject(appState)
                .environmentObject(navigationCoordinator)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingPlanCreation = false
                            navigationCoordinator.returnToRoot()
                        }
                    }
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .templatePicker:
                        PlanTemplatePickerView()
                            .environmentObject(appState)
                            .environmentObject(navigationCoordinator)
                    case .adaptivePlanSetup:
                        AdaptivePlanSetupView()
                            .environmentObject(appState)
                            .environmentObject(navigationCoordinator)
                    case .generatedPlanEditor(let planId):
                        if let plan = appState.findPlan(with: planId) {
                            GeneratedPlanEditorView(generatedPlan: plan, appState: appState, planCreated: .constant(false))
                                .environmentObject(navigationCoordinator)
                        } else {
                            Text("Plan not found")
                        }
                    case .planEditor(_):
                        PlanEditorView(template: nil, appState: appState)
                            .environmentObject(navigationCoordinator)
                    case .planDetail(let planId):
                        if let plan = appState.findPlan(with: planId) {
                            PlanDetailView(plan: plan)
                                .environmentObject(appState)
                                .environmentObject(navigationCoordinator)
                        }
                    }
                }
        }
        .onChange(of: appState.currentPlan?.id) { newId in
            if let newId = newId, newId != initialPlanId {
                showingPlanCreation = false
                navigationCoordinator.returnToRoot()
            }
        }
    }
                
    // MARK: - Navigation Logic
    
    private func handleActiveWorkoutChange(newId: UUID?) {
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
            // Use NavigationLink to present the active workout instead of sheet
            NavigationLink(
                isActive: $showActiveWorkout,
                destination: {
                    if let workout = activeWorkout {
                        // The original TrainingView directly passed the workout to ActiveWorkoutView
                        // so we'll do the same and let the view handle setting activeWorkoutId in onAppear
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
                                    // Set the activeWorkout to prepare for navigation
                                    activeWorkout = workout
                                    showActiveWorkout = true
                                    hasActiveWorkoutDismissedByGesture = false
                                    
                                    // Don't set activeWorkoutId here, let the view do it in onAppear
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
    
    /// Creates a header view showing current plan with option to create a new plan
    /// and integrated week navigation
    private func planHeaderView() -> some View {
        HStack(alignment: .center) {
            if let plan = appState.currentPlan {
                // Left side: Plan info with dropdown
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    HStack(spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        // Dropdown menu for plan actions
                        Menu {
                            Button(action: {
                                showingPlanCreation = true
                            }) {
                                Label("Create New Plan", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Right side: Week navigation (only if plan has weekly workouts)
                if !plan.weeklyWorkouts.isEmpty {
                    HStack(spacing: 12) {
                        // Week indicator with navigation
                        Button(action: {
                            if selectedWeekIndex > 0 {
                                withAnimation {
                                    selectedWeekIndex -= 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12))
                                .foregroundColor(selectedWeekIndex > 0 ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.3))
                        }
                        .disabled(selectedWeekIndex <= 0)
                        
                        Text("Week \(selectedWeekIndex + 1)")
                            .font(.subheadline)
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .frame(minWidth: 60, alignment: .center)
                        
                        Button(action: {
                            if selectedWeekIndex < plan.weeklyWorkouts.count - 1 {
                                withAnimation {
                                    selectedWeekIndex += 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(selectedWeekIndex < plan.weeklyWorkouts.count - 1 ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.3))
                        }
                        .disabled(selectedWeekIndex >= plan.weeklyWorkouts.count - 1)
                    }
                }
            } else {
                // No plan message
                Text("No active plan")
                    .font(.headline)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    showingPlanCreation = true
                }) {
                    Text("Create Plan")
                        .font(.headline)
                        .foregroundColor(AppStyle.Colors.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
    
    /// Finds a workout by ID in all available workouts
    private func findWorkout(with id: UUID) -> WorkoutEntity? {
        // First search in weeklyWorkouts if available
        if let plan = appState.currentPlan, !plan.weeklyWorkouts.isEmpty {
            for weekWorkouts in plan.weeklyWorkouts {
                if let workout = weekWorkouts.first(where: { $0.id == id }) {
                    return workout
                }
            }
        }
        
        // Fallback to the old approach if not found
        if let workout = viewModel.upcomingWorkouts.first(where: { $0.id == id }) {
            return workout
        }
        return viewModel.pastWorkouts.first(where: { $0.id == id })
    }
    
    // Function to refresh week data and set the current week
    private func refreshWeekGroups() {
        guard let plan = appState.currentPlan else { return }
        
        let weeks = plan.weeklyWorkouts
        guard !weeks.isEmpty else { return }
        
        // If there's an active workout, find which week it belongs to
        if let activeId = appState.activeWorkoutId,
           let (weekIdx, _) = weeks.enumerated().first(where: { (_, weekWorkouts) in 
               weekWorkouts.contains(where: { workout in workout.id == activeId })
           }) {
            selectedWeekIndex = weekIdx
        } else {
            // If there's no active workout, find the first incomplete week
            if let firstIncompleteIndex = weeks.firstIndex(where: { week in
                week.contains(where: { !$0.isComplete })
            }) {
                selectedWeekIndex = firstIncompleteIndex
            } else {
                // If all weeks are complete, show the last one
                selectedWeekIndex = weeks.count - 1
            }
        }
    }
}
