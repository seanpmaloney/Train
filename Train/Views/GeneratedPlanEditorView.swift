import SwiftUI

/// View for displaying and editing auto-generated training plans
struct GeneratedPlanEditorView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: GeneratedPlanEditorViewModel
    @State private var scrollTarget: ScrollTarget?
    @State private var requiredPadding: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigation: NavigationCoordinator
    @Binding var planCreated: Bool
    
    private let numberPadHeight: CGFloat = 390
    private let desiredSpaceAboveKeyboard: CGFloat = 40
    
    // MARK: - View State
    
    enum ActiveSheet: Identifiable {
        case movementPicker(workoutIndex: Int)
        case datePicker
        case replaceMovementPicker(exerciseIndex: Int, workoutIndex: Int)

        var id: String {
            switch self {
            case .movementPicker(let workoutIndex):
                return "movementPicker_\(workoutIndex)"
            case .replaceMovementPicker(let exerciseIndex, let workoutIndex):
                return "replaceMovementPicker_\(workoutIndex)"
            case .datePicker:
                return "datePicker"
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    struct ScrollTarget: Equatable {
        let id: UUID
        let buttonFrame: CGRect
        
        static func == (lhs: ScrollTarget, rhs: ScrollTarget) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Initialization
    
    init(generatedPlan: TrainingPlanEntity, appState: AppState, planCreated: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: GeneratedPlanEditorViewModel(generatedPlan: generatedPlan, appState: appState))
        _planCreated = planCreated
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppStyle.Layout.compactSpacing) {
                        planDetailsSection
                        planLengthPicker
                        workoutsSection
                        
                        // Dynamic padding based on button position
                        Color.clear
                            .frame(height: requiredPadding)
                            .animation(.easeInOut(duration: 0.25), value: requiredPadding)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, AppStyle.Layout.standardSpacing)
                    .onChange(of: scrollTarget) { target in
                        if let target = target {
                            // Calculate if and how much padding we need
                            let screenHeight = UIScreen.main.bounds.height
                            let buttonBottomY = target.buttonFrame.maxY + 20
                            let keyboardTopY = screenHeight - numberPadHeight
                            
                            // If button would be hidden by keyboard
                            if buttonBottomY > keyboardTopY {
                                // Calculate padding needed to show button above keyboard
                                let overlap = buttonBottomY - keyboardTopY
                                let padding = overlap + desiredSpaceAboveKeyboard
                                
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    requiredPadding = padding
                                    proxy.scrollTo(target.id, anchor: .center)
                                }
                            } else {
                                // Button is already visible above keyboard
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    requiredPadding = 0
                                }
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                requiredPadding = 0
                            }
                        }
                    }
                }
                .background(AppStyle.Colors.background)
                .navigationTitle("Your Custom Plan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            viewModel.finalizePlan()
                            planCreated = true
                            // Return to root view
                            navigation.returnToRoot()
                        }
                        .bold()
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .movementPicker(let workoutIndex):
                        MovementPickerView { movements in
                            for movement in movements {
                                viewModel.addMovement(movement, to: workoutIndex)
                            }
                        }
                    case .replaceMovementPicker(let exerciseIndex, let workoutIndex):
                        let currentExercise = viewModel.workouts[workoutIndex].exercises[exerciseIndex]
                        let primaryMuscles = currentExercise.movement.primaryMuscles
                        
                        MovementPickerView(filterByMuscles: primaryMuscles) { movements in
                            for movement in movements {
                                viewModel.replaceMovement(at: exerciseIndex, from: workoutIndex, newMovement: movement)
                            }
                        }
                    case .datePicker:
                        DatePicker(
                            "Start Date",
                            selection: $viewModel.planStartDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .presentationDetents([.medium])
                    }
                }
            }
        }
    }
    
    // MARK: - Plan Details Section
    
    private var planDetailsSection: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            TextField("Plan Name", text: $viewModel.planName)
                .font(AppStyle.Typography.body())
            
            Divider()
            
            HStack {
                Text("Start Date")
                    .font(AppStyle.Typography.body())
                
                Spacer()
                
                Button {
                    activeSheet = .datePicker
                } label: {
                    HStack {
                        Text(formattedDate)
                            .font(AppStyle.Typography.body())
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        Image(systemName: "calendar")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Plan Length Section
    
    private var planLengthPicker: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            HStack {
                Text("Plan Length")
                    .font(AppStyle.Typography.headline())
                
                Spacer()
            }
            
            Stepper(value: $viewModel.planLength, in: viewModel.minWeeks...viewModel.maxWeeks) {
                HStack {
                    Text("\(viewModel.planLength) weeks")
                        .font(AppStyle.Typography.body())
                    
                    Spacer()
                    
                    Text("Tap to change")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
            .tint(AppStyle.Colors.primary)
            
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Workouts Section
    
    private var workoutsSection: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            ForEach(viewModel.workouts.indices, id: \.self) { workoutIndex in
                let workout = viewModel.workouts[workoutIndex]
                
                WorkoutView(
                    workout: workout,
                    workoutIndex: workoutIndex,
                    viewModel: viewModel,
                    scrollTarget: $scrollTarget,
                    activeSheet: $activeSheet,
                    onAddExercise: {
                        activeSheet = .movementPicker(workoutIndex: workoutIndex)
                    }
                )
                .transition(.opacity)
            }
            .animation(.snappy, value: viewModel.workouts.map { $0.id })
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.planStartDate)
    }
}

// MARK: - Workout View

struct WorkoutView: View {
    let workout: GeneratedPlanEditorViewModel.WorkoutModel
    let workoutIndex: Int
    let viewModel: GeneratedPlanEditorViewModel
    @Binding var scrollTarget: GeneratedPlanEditorView.ScrollTarget?
    @Binding var activeSheet: GeneratedPlanEditorView.ActiveSheet?
    let onAddExercise: () -> Void
    
    @State private var showingDayPicker = false
    
    var body: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            workoutHeader
            
            if workout.exercises.isEmpty {
                emptyStateView
            } else {
                exercisesList
            }
            
            addButton
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
        .transition(.opacity)
    }
    
    private var workoutHeader: some View {
        HStack {
            Text(workout.title)
                .font(AppStyle.Typography.headline())
            
            Spacer()
            
            Button(action: {
                showingDayPicker.toggle()
            }) {
                HStack {
                    Text(workout.dayOfWeek?.displayName ?? "Select day")
                        .font(AppStyle.Typography.body())
                    
                    Image(systemName: "calendar")
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppStyle.Colors.surface)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
            }
            .popover(isPresented: $showingDayPicker) {
                DayPickerView(
                    selectedDay: workout.dayOfWeek,
                    selectedDays: viewModel.selectedDays,
                    onSelect: { selectedDay in
                        viewModel.updateSelectedDay(selectedDay, for: workoutIndex)
                        showingDayPicker = false
                    }
                )
                .presentationCompactAdaptation(.none)
            }
        }
    }
    
    private var exercisesList: some View {
        VStack(spacing: AppStyle.Layout.standardSpacing) {
            ForEach(workout.exercises.indices, id: \.self) { exerciseIndex in
                let exercise = workout.exercises[exerciseIndex]
                
                ExerciseRow(
                    exercise: exercise,
                    viewModel: viewModel,
                    workoutIndex: workoutIndex,
                    scrollTarget: $scrollTarget,
                    activeSheet: $activeSheet,
                    onDelete: {
                        viewModel.removeMovement(at: exerciseIndex, from: workoutIndex)
                    }
                )
            }
        }
        .padding(.vertical, AppStyle.Layout.compactSpacing)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            Text("No exercises added yet")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            Text("Tap the + button to add exercises")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var addButton: some View {
        Button(action: onAddExercise) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .frame(maxWidth: .infinity)
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppStyle.Colors.surfaceTop, lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: GeneratedPlanEditorViewModel.ExerciseModel
    let viewModel: GeneratedPlanEditorViewModel
    let workoutIndex: Int
    @Binding var scrollTarget: GeneratedPlanEditorView.ScrollTarget?
    @Binding var activeSheet: GeneratedPlanEditorView.ActiveSheet?
    let onDelete: () -> Void
    
    @State private var showingSetsEditor = false
    @State private var showingRepsEditor = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: AppStyle.Layout.compactSpacing) {
                // Main content row with aligned elements
                HStack(spacing: AppStyle.Layout.standardSpacing) {
                    // Left side: Exercise name and information
                    HStack(spacing: AppStyle.Layout.standardSpacing) {
                        // Exercise name and tags
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.movement.name)
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                equipmentTag
                                
                                ForEach(exercise.movement.primaryMuscles, id: \.self) { muscle in
                                    muscleTag(muscle: muscle)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Right side: Action buttons
                    VStack(spacing: AppStyle.Layout.compactSpacing) {
                        // Delete button (aligned with movement title)
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppStyle.Colors.danger)
                        }
                        
                        // Replace button with similar primary muscle
                        Button(action: {
                            let parent = viewModel.workouts[workoutIndex]
                            let exerciseIndex = parent.exercises.firstIndex { $0.id == exercise.id } ?? 0
                            activeSheet = .replaceMovementPicker(exerciseIndex: exerciseIndex, workoutIndex: workoutIndex)
                        }) {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 18))
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        .padding(.trailing, 4)
                    }
                    .padding(.top, 2) // Slight adjustment to align with text
                }
                
                // Sets and reps
                HStack {
                    Button(action: {
                        let frame = geometry.frame(in: .global)
                        scrollTarget = GeneratedPlanEditorView.ScrollTarget(id: exercise.id, buttonFrame: frame)
                        showingSetsEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sets")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                            Text("\(exercise.targetSets)")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        let frame = geometry.frame(in: .global)
                        scrollTarget = GeneratedPlanEditorView.ScrollTarget(id: exercise.id, buttonFrame: frame)
                        showingRepsEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reps")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                            Text("\(exercise.targetReps)")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .id(exercise.id)
            .padding()
            .background(AppStyle.Colors.background.opacity(0.5))
            .cornerRadius(8)
            .sheet(isPresented: $showingSetsEditor) {
                CustomNumberPadView(
                    title: "Sets",
                    initialValue: Double(exercise.targetSets),
                    mode: .reps
                ) { newValue in
                    viewModel.updateSets(Int(newValue), for: exercise.id, in: workoutIndex)
                    scrollTarget = nil
                }
                .presentationDetents([.height(350)])
                .onDisappear {
                    scrollTarget = nil
                }
            }
            .sheet(isPresented: $showingRepsEditor) {
                CustomNumberPadView(
                    title: "Reps",
                    initialValue: Double(exercise.targetReps),
                    mode: .reps
                ) { newValue in
                    viewModel.updateReps(Int(newValue), for: exercise.id, in: workoutIndex)
                    scrollTarget = nil
                }
                .presentationDetents([.height(350)])
                .onDisappear {
                    scrollTarget = nil
                }
            }
        }
        .frame(height: 140)
    }
    
    private var equipmentTag: some View {
        Text(exercise.movement.equipment.rawValue)
            .font(AppStyle.Typography.caption())
            .foregroundColor(AppStyle.Colors.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(AppStyle.Colors.secondary.opacity(0.2))
            .cornerRadius(4)
    }
    
    private func muscleTag(muscle: MuscleGroup) -> some View {
        Text(muscle.displayName)
            .font(AppStyle.Typography.caption())
            .foregroundColor(muscle.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(muscle.color.opacity(0.2))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let appState = AppState()
        let planInput = PlanInput(
            goal: .hypertrophy,
            prioritizedMuscles: [.chest, .back],
            trainingDaysPerWeek: 4,
            workoutDuration: .long,
            equipment: [.barbell, .dumbbell],
            preferredSplit: .upperLower,
            trainingExperience: .intermediate
        )
        var generator = PlanGenerator()
        var plan = generator.generatePlan(input: planInput, forWeeks: 4)
        
        GeneratedPlanEditorView(
            generatedPlan: plan,
            appState: appState,
            planCreated: .constant(false)
        )
    }
    .preferredColorScheme(.dark)
}

