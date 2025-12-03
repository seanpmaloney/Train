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
    @State private var showingPlansView = false
    @State private var initialPlanId: UUID?
    
    // Track the previous plan ID to detect plan changes
    @State private var previousPlanId: UUID?
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: EnhancedTrainingViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContentView()
            .onChange(of: appState.currentPlan?.id) { oldValue, newValue in
                handlePlanChange(oldValue: oldValue, newValue: newValue)
            }
            .onAppear {
                // Store initial plan ID for change detection
                previousPlanId = appState.currentPlan?.id
            }
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
                            if appState.currentPlan == nil {
                                // No plan state - show empty view
                                emptyStateView(for: true)
                            } else if let plan = appState.currentPlan, !plan.weeklyWorkouts.isEmpty, selectedWeekIndex < plan.weeklyWorkouts.count {
                                // Current plan with weekly workouts
                                workoutSection(
                                    title: nil,
                                    workouts: plan.weeklyWorkouts[selectedWeekIndex],
                                    isUpcoming: true
                                )
                            } else if appState.currentPlan != nil {
                                // Plan exists but no weekly workouts data
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
                // Add NavigationLink in the main view hierarchy
                .background(
                    NavigationLink(isActive: $showActiveWorkout, destination: {
                        if let workout = activeWorkout {
                            EnhancedActiveWorkoutView(workout: workout)
                                .environmentObject(appState)
                        } else {
                            Text("Loading workout...")
                        }
                    }, label: { EmptyView() })
                )
                .onChange(of: appState.activeWorkoutId) { newId in
                    handleActiveWorkoutChange(newId: newId)
                }
                
                // Full screen cover for viewing all plans
                .fullScreenCover(isPresented: $showingPlansView) {
                    NavigationStack {
                        PlansView()
                            .environmentObject(appState)
                            .environmentObject(navigationCoordinator)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        showingPlansView = false
                                        navigationCoordinator.returnToRoot()
                                    }
                                }
                            }
                    }
                    // No need for onDisappear as we handle this reactively in the parent view
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
                
    // MARK: - State Management
    
    /// Handles changes to the current plan
    private func handlePlanChange(oldValue: UUID?, newValue: UUID?) {
        // If plan was archived (plan changed to nil) or plan changed
        if oldValue != newValue {
            // Reset week index to default when plan changes
            selectedWeekIndex = 0
            
            // The ViewModel is already observing appState.currentPlan
            // so it automatically updates workouts on plan changes
            // We just need to force a UI refresh in some cases
            viewModel.objectWillChange.send()
            
            // If we have a new plan with weekly workouts, refresh the grouping
            if newValue != nil {
                refreshWeekGroups()
            }
        }
        
        // Update tracking state
        previousPlanId = newValue
        initialPlanId = newValue
    }
    
    /// Handles changes to the active workout
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
            // NavigationLink was moved to the main view hierarchy
            // Refresh week groups when returning from workout
            refreshWeekGroups()
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
            
            if (isUpcoming) {
                Button(action: {
                    showingPlanCreation = true
                }) {
                    Text("Create a plan to get started")
                        .font(.subheadline)
                        .foregroundColor(AppStyle.Colors.primary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Complete workouts to see them here")
                    .font(.subheadline)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
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
                    Menu {
                        Button(action: {
                            showingPlanCreation = true
                        }) {
                            Label("Create New Plan", systemImage: "plus")
                        }
                        Button(action: {
                            showingPlansView = true
                        }) {
                            Label("View Plans", systemImage: "list.bullet")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .foregroundColor(AppStyle.Colors.textPrimary)
                                .multilineTextAlignment(.leading)
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
                // No plan message with dropdown
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        
                        // Dropdown menu for plan actions
                        Menu {
                            Button(action: {
                                showingPlanCreation = true
                            }) {
                                Label("Create New Plan", systemImage: "plus")
                            }
                            Button(action: {
                                showingPlansView = true
                            }) {
                                Label("View Plans", systemImage: "list.bullet")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("No active plan")
                                    .font(.headline)
                                    .foregroundColor(AppStyle.Colors.primary)
                                    .multilineTextAlignment(.leading)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
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

// MARK: - Preview

// Helper function for creating sample sets (outside preview closure)
private func createSampleSets(weight: Double = 135.0, reps: Int = 8, count: Int = 3) -> [ExerciseSetEntity] {
    (0..<count).map { _ in
        ExerciseSetEntity(weight: weight, completedReps: 0, targetReps: reps, isComplete: false)
    }
}

#Preview {
    // Create the preview content in a closure to avoid void return issues
    let previewContent = {
        let appState = AppState()
        let navigationCoordinator = NavigationCoordinator()
        
        // Create sample movements
        let benchPress = MovementEntity(
            type: MovementType.barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .barbell
        )
        
        let squat = MovementEntity(
            type: MovementType.barbellBackSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        )
        
        let deadlift = MovementEntity(
            type: MovementType.barbellDeadlift,
            primaryMuscles: [.back],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        )
        
        let pullUps = MovementEntity(
            type: MovementType.pullUps,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .bodyweight
        )
        
        // Create sample workouts for Week 1
        let upperBodyWorkout = WorkoutEntity(
            title: "Upper Body Strength",
            description: "Chest, shoulders, and back focus",
            isComplete: false,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 0, to: Date())
        )
        
        // Create exercises separately to avoid protocol conformance issues
        let benchExercise = ExerciseInstanceEntity(
            movement: benchPress,
            exerciseType: "Strength",
            sets: createSampleSets(weight: 185.0, reps: 5)
        )
        
        let pullUpExercise = ExerciseInstanceEntity(
            movement: pullUps,
            exerciseType: "Hypertrophy",
            sets: createSampleSets(weight: 0, reps: 12)
        )
        
        upperBodyWorkout.exercises = [benchExercise, pullUpExercise]
        
        let lowerBodyWorkout = WorkoutEntity(
            title: "Lower Body Power",
            description: "Legs and glutes development",
            isComplete: false,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
        
        let squatExercise = ExerciseInstanceEntity(
            movement: squat,
            exerciseType: "Strength",
            sets: createSampleSets(weight: 225.0, reps: 5)
        )
        
        let deadliftExercise = ExerciseInstanceEntity(
            movement: deadlift,
            exerciseType: "Strength",
            sets: createSampleSets(weight: 275.0, reps: 3)
        )
        
        lowerBodyWorkout.exercises = [squatExercise, deadliftExercise]
        
        let fullBodyWorkout = WorkoutEntity(
            title: "Full Body Conditioning",
            description: "Complete body workout",
            isComplete: true,
            scheduledDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
        )
        
        let benchHypertrophyExercise = ExerciseInstanceEntity(
            movement: benchPress,
            exerciseType: "Hypertrophy",
            sets: createSampleSets(weight: 155.0, reps: 10)
        )
        
        fullBodyWorkout.exercises = [benchHypertrophyExercise]
        
        // Create sample plan with weekly workouts
        let samplePlan = TrainingPlanEntity(
            name: "Strength & Hypertrophy Program",
            notes: "12-week progressive overload program",
            startDate: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
            daysPerWeek: 3,
            isCompleted: false
        )
        
        // Set up weekly workouts (3 weeks worth)
        samplePlan.weeklyWorkouts = [
            [upperBodyWorkout, lowerBodyWorkout, fullBodyWorkout], // Week 1
            [upperBodyWorkout, lowerBodyWorkout, fullBodyWorkout], // Week 2  
            [upperBodyWorkout, lowerBodyWorkout, fullBodyWorkout]  // Week 3
        ]
        
        // Set the current plan in AppState
        appState.currentPlan = samplePlan
        
        return EnhancedTrainingView(appState: appState)
            .environmentObject(appState)
            .environmentObject(navigationCoordinator)
            .preferredColorScheme(.dark)
    }
    
    return previewContent()
}

