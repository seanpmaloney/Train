import SwiftUI

/// View for setting up an adaptive plan through a series of questions
struct AdaptivePlanSetupView: View {
    // MARK: - Properties
    
    // Dependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Preferences data model
    @State private var preferences = PlanPreferences()
    
    // Plan generation state
    @State private var generatedPlan: TrainingPlanEntity?
    @State private var showPlanEditor = false
    
    // State for question navigation
    @State private var currentQuestion = 0
    @State private var animateIn = false
    
    // Total number of questions
    private let totalQuestions = 7
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            AdaptivePlanComponents.ProgressBar(current: currentQuestion, total: totalQuestions)
                .padding(.horizontal)
                .padding(.top)
            
            // Question container
            ScrollView {
                // Question content - aligned to top with .frame and .alignmentGuide
                ZStack {
                    // Show the appropriate question based on currentQuestion
                    switch currentQuestion {
                    case 0:
                        trainingGoalQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 1:
                        musclePriorityQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 2:
                        daysPerWeekQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 3:
                        workoutDurationQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 4:
                        equipmentQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 5:
                        splitStyleQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case 6:
                        trainingExperienceQuestion
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    default:
                        EmptyView()
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentQuestion)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Align to top
                .padding(.bottom, 80) // Add bottom padding for the buttons
            }
            
            // Navigation buttons
            AdaptivePlanComponents.NavigationButtons(
                currentQuestion: currentQuestion,
                totalQuestions: totalQuestions,
                canProceed: canProceedToNextQuestion,
                onBack: goToPreviousQuestion,
                onNext: proceedToNextQuestion
            )
            .padding()
        }
        .background(AppStyle.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateIn = true
        }
        .navigationDestination(isPresented: $showPlanEditor) {
            if let plan = generatedPlan {
                // Pass the generated plan to our specialized editor view
                GeneratedPlanEditorView(generatedPlan: plan, appState: appState, planCreated: .constant(true))
            }
        }
    }
    
    // MARK: - Question Views
    
    /// Q1: Training Goal
    private var trainingGoalQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "What is your main training goal?")
            
            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases) { goal in
                    AdaptivePlanComponents.OptionButton(
                        option: goal,
                        title: goal.rawValue,
                        description: goal.description,
                        isSelected: preferences.trainingGoal == goal,
                        action: { preferences.trainingGoal = goal }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question1")
    }
    
    /// Q2: Muscle Priority
    private var musclePriorityQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "Which muscle groups do you want to prioritize for growth?")
            
            Text("Unselected muscles will focus on maintenance rather than growth")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 12) {
                    // Upper body section
                    muscleGroupSection(
                        title: "Upper Body",
                        muscles: [.chest, .back, .shoulders, .biceps, .triceps, .forearms]
                    )
                    
                    // Core section
                    muscleGroupSection(
                        title: "Core",
                        muscles: [.abs, .obliques, .lowerBack]
                    )
                    
                    // Lower body section
                    muscleGroupSection(
                        title: "Lower Body",
                        muscles: [.quads, .hamstrings, .glutes, .calves]
                    )
                    
                    // Other section
                    muscleGroupSection(
                        title: "Other",
                        muscles: [.traps, .neck]
                    )
                }
            }
            .frame(maxHeight: 400)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question2")
    }
    
    /// Q3: Days Per Week
    private var daysPerWeekQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "How many days per week can you train?")
            
            VStack(spacing: 12) {
                ForEach(DaysPerWeek.allCases) { option in
                    AdaptivePlanComponents.OptionButton(
                        option: option,
                        title: option.rawValue,
                        description: option.description,
                        isSelected: preferences.daysPerWeek == option,
                        action: { preferences.daysPerWeek = option }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question3")
    }
    
    /// Q4: Workout Duration
    private var workoutDurationQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "How long do you want each workout to be?")
            
            VStack(spacing: 12) {
                ForEach(WorkoutDuration.allCases) { option in
                    AdaptivePlanComponents.OptionButton(
                        option: option,
                        title: option.rawValue,
                        description: option.description,
                        isSelected: preferences.workoutDuration == option,
                        action: { preferences.workoutDuration = option }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question4")
    }
    
    /// Q5: Equipment
    private var equipmentQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "What equipment do you have access to?")
            Text("Select all that apply")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            VStack(spacing: 12) {
                ForEach(EquipmentType.allCases, id: \.self) { equipmentType in
                    AdaptivePlanComponents.CheckboxOption(
                        title: equipmentType.rawValue,
                        isSelected: preferences.availableEquipment.contains(equipmentType),
                        action: {
                            if preferences.availableEquipment.contains(equipmentType) {
                                preferences.availableEquipment.remove(equipmentType)
                            } else {
                                preferences.availableEquipment.insert(equipmentType)
                            }
                        },
                        icon: getEquipmentIcon(for: equipmentType)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question5")
    }
    
    /// Q6: Split Style
    private var splitStyleQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "What training split do you prefer?")
            
            VStack(spacing: 12) {
                ForEach(SplitStyle.allCases) { option in
                    AdaptivePlanComponents.OptionButton(
                        option: option,
                        title: option.rawValue,
                        description: option.description,
                        isSelected: preferences.splitStyle == option,
                        action: { preferences.splitStyle = option }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question6")
    }
    
    /// Q7: Training Experience
    private var trainingExperienceQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            AdaptivePlanComponents.QuestionHeader(title: "What is your training experience level?")
            
            VStack(spacing: 12) {
                ForEach(TrainingExperience.allCases) { option in
                    AdaptivePlanComponents.OptionButton(
                        option: option,
                        title: option.rawValue,
                        description: option.description,
                        isSelected: preferences.trainingExperience == option,
                        action: { preferences.trainingExperience = option }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .id("question7")
    }
    
    // MARK: - Helper Methods
    
    /// Section of muscle groups with title
    private func muscleGroupSection(title: String, muscles: [MuscleGroup]) -> some View {
        AdaptivePlanComponents.SectionWithTitle(title: title) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(muscles, id: \.self) { muscle in
                    AdaptivePlanComponents.MuscleButton(
                        muscle: muscle,
                        isSelected: preferences.priorityMuscles.contains(muscle),
                        action: {
                            if preferences.priorityMuscles.contains(muscle) {
                                preferences.priorityMuscles.remove(muscle)
                            } else {
                                preferences.priorityMuscles.insert(muscle)
                            }
                        }
                    )
                }
            }
        }
    }
    
    /// Get icon for equipment type
    private func getEquipmentIcon(for equipmentType: EquipmentType) -> String {
        switch equipmentType {
        case .barbell: return "figure.strengthtraining.functional"
        case .dumbbell: return "dumbbell"
        case .machine: return "figure.strengthtraining.traditional"
        case .bodyweight: return "figure.highintensity.intervaltraining"
        case .cable: return "figure.cross.training"
        }
    }
    
    // MARK: - Navigation Logic
    
    /// Whether the user can proceed to the next question
    private var canProceedToNextQuestion: Bool {
        switch currentQuestion {
        case 0:
            return preferences.trainingGoal != nil
        case 1:
            return true // Can proceed even with no muscles selected (will default to maintain all)
        case 2:
            return preferences.daysPerWeek != nil
        case 3:
            return preferences.workoutDuration != nil
        case 4:
            return !preferences.availableEquipment.isEmpty
        case 5:
            return preferences.splitStyle != nil
        case 6:
            return preferences.trainingExperience != nil
        default:
            return false
        }
    }
    
    /// Navigate to previous question
    private func goToPreviousQuestion() {
        withAnimation {
            if currentQuestion > 0 {
                currentQuestion -= 1
            }
        }
    }
    
    /// Proceed to next question or finish
    private func proceedToNextQuestion() {
        withAnimation {
            if currentQuestion < totalQuestions - 1 {
                if canProceedToNextQuestion {
                    currentQuestion += 1
                }
            } else {
                finishSetup()
            }
        }
    }
    
    /// Finish setup and create adaptive plan
    private func finishSetup() {
        guard let input = PlanInput.fromPreferences(preferences) else {
            // Handle incomplete data
            print("Error: Incomplete preferences data")
            return
        }
        
        // Create the plan using PlanGenerator within MainActor context
        Task { @MainActor in
            // Create exercise selector using the factory method
//            let exerciseSelector = DefaultExerciseSelector.create()
            
            // Initialize plan generator with our dependencies
            var generator = PlanGenerator()
            
            // Generate the plan
            let plan = generator.generatePlan(input: input, forWeeks: 4)
            
            // Store the generated plan and show the editor
            generatedPlan = plan
            showPlanEditor = true
        }
    }
}

// MARK: - Preview
struct AdaptivePlanSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AdaptivePlanSetupView()
                .environmentObject(AppState())
        }
        .preferredColorScheme(.dark)
    }
}
