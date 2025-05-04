import Foundation

/// Model representing user input from the plan questionnaire
struct PlanInput {
    /// The primary training goal (e.g., hypertrophy, strength)
    let goal: TrainingGoal
    
    /// Muscle groups the user wants to prioritize for growth
    let prioritizedMuscles: [MuscleGroup]
    
    /// Number of days per week the user wants to train
    let trainingDaysPerWeek: Int
    
    /// Preferred workout duration
    let workoutDuration: WorkoutDuration
    
    /// Equipment types available to the user
    let equipment: [EquipmentType]
    
    /// Preferred training split style
    let preferredSplit: SplitStyle
    
    /// User's training experience level
    let trainingExperience: TrainingExperience
    
    /// Create plan input from preferences
    static func fromPreferences(_ preferences: PlanPreferences) -> PlanInput? {
        guard let goal = preferences.trainingGoal,
              let daysPerWeek = preferences.daysPerWeek,
              let workoutDuration = preferences.workoutDuration,
              let splitStyle = preferences.splitStyle,
              let trainingExperience = preferences.trainingExperience,
              !preferences.availableEquipment.isEmpty else {
            return nil
        }
        
        return PlanInput(
            goal: goal,
            prioritizedMuscles: Array(preferences.priorityMuscles),
            trainingDaysPerWeek: Self.daysToInt(daysPerWeek),
            workoutDuration: workoutDuration,
            equipment: Array(preferences.availableEquipment),
            preferredSplit: splitStyle,
            trainingExperience: trainingExperience
        )
    }
    
    /// Convert DaysPerWeek enum to Int
    private static func daysToInt(_ days: DaysPerWeek) -> Int {
        switch days {
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        }
    }
}

/// Generates a personalized training plan based on user input
@MainActor
struct PlanGenerator {
    
    // MARK: - Dependencies
    
    private let workoutBuilder: WorkoutBuilder?
    private let exerciseSelector: ExerciseSelector?
    private let volumeStrategy: VolumeRampStrategy?
    
    init(
        workoutBuilder: WorkoutBuilder? = nil,
        exerciseSelector: ExerciseSelector? = nil,
        volumeStrategy: VolumeRampStrategy? = nil
    ) {
        self.workoutBuilder = workoutBuilder
        self.exerciseSelector = exerciseSelector
        self.volumeStrategy = volumeStrategy
    }
    
    // MARK: - Plan Generation
    
    /// Generates a complete training plan based on user input
    /// - Parameters:
    ///   - input: User preferences from the plan questionnaire
    ///   - weeks: Number of weeks to generate for the plan
    /// - Returns: A complete training plan with schedule and muscle preferences
    func generatePlan(from input: PlanInput, forWeeks weeks: Int = 4) -> TrainingPlanEntity {
        // Convert prioritized muscles to MuscleTrainingPreference objects
        let musclePreferences = convertToMusclePreferences(from: input.prioritizedMuscles)
        
        // Create a descriptive note for the plan
        let planDesc = "Custom plan based on your preferences"
        
        // Create the training plan with basic information
        let plan = TrainingPlanEntity(
            name: "Plan",
            notes: planDesc,
            startDate: Date(),
            daysPerWeek: input.trainingDaysPerWeek,
            isCompleted: false
        )
        
        // Set muscle preferences and training goal (explicit for plan)
        plan.musclePreferences = musclePreferences
        plan.trainingGoal = input.goal
        

        generateWorkouts(
            for: plan,
            input: input,
            weeks: weeks
        )
        
        return plan
    }
    
    /// Legacy method signature for compatibility with existing code
    func generatePlan(from input: PlanInput) -> TrainingPlanEntity {
        return generatePlan(from: input, forWeeks: 4)
    }
    
    /// Creates a standard custom training plan without muscle preferences
    /// - Parameters:
    ///   - name: Name of the plan
    ///   - daysPerWeek: Number of training days per week
    /// - Returns: A custom training plan without specific muscle preferences
    func createCustomPlan(name: String, daysPerWeek: Int) -> TrainingPlanEntity {
        // Create a basic training plan without specific muscle priorities
        let plan = TrainingPlanEntity(
            name: name,
            notes: "Custom training plan",
            startDate: Date(),
            daysPerWeek: daysPerWeek
        )
        
        // Custom plans don't explicitly set muscle preferences
        // This allows the isPlan property to correctly return false
        
        return plan
    }
    
    // MARK: - Helper Methods
    
    /// Generate workouts for a training plan
    /// - Parameters:
    ///   - plan: The training plan to add workouts to
    ///   - builder: The workout builder
    ///   - input: User preferences
    ///   - weeks: Number of weeks to generate
    private func generateWorkouts(
        for plan: TrainingPlanEntity,
        input: PlanInput,
        weeks: Int
    ) {
        // STEP 1: Generate a base week of workouts
        var baseWeekWorkouts: [WorkoutEntity] = []
        
        // For each training day in the week
        for dayIndex in 0..<input.trainingDaysPerWeek {
            // Determine workout type based on split style
            let dayNumber = dayIndex + 1
            let dayType = getDayType(day: dayNumber, split: input.preferredSplit, totalDays: input.trainingDaysPerWeek)
            
            // Get target muscles for this day type
            let targetMuscles = getMusclesForDayType(dayType)
            
            // Create a workout shell
            let workoutName = dayTypeToName(dayType)
            let workoutDescription = "Targets: " + targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
            let workout = WorkoutEntity(title: workoutName, description: workoutDescription, isComplete: false)
            
            // Get max exercise count based on duration
            let maxExerciseCount = getExerciseCountForDuration(input.workoutDuration)
            
            // Track volume distribution for each muscle
            var setsCompletedForMuscle: [MuscleGroup: Double] = [:]
            var targetSetsForMuscle: [MuscleGroup: Int] = [:]
            
            // Calculate target volumes for each muscle for week 1
            for muscle in targetMuscles {
                // Check if this muscle is prioritized
                let isPrioritized = input.prioritizedMuscles.contains(muscle)
                
                // Calculate target sets for this muscle using volume strategy
                let targetSets = calculateSetsForMuscle(
                    muscle,
                    goal: input.goal,
                    isEmphasized: isPrioritized,
                    week: 1, // Base week
                    totalWeeks: weeks,
                    trainingExperience: input.trainingExperience
                )
                
                // Store target sets and initialize tracking
                targetSetsForMuscle[muscle] = targetSets
                setsCompletedForMuscle[muscle] = 0.0
            }
            
            // Calculate daily targets (divide weekly targets by frequency)
            var dailyTargetsForMuscle: [MuscleGroup: Int] = [:]
            for (muscle, weeklyTarget) in targetSetsForMuscle {
                // Determine how many days this muscle is trained per week
                let trainingDaysForMuscle = countTrainingDaysForMuscle(muscle, split: input.preferredSplit, daysPerWeek: input.trainingDaysPerWeek)
                // Calculate daily volume (rounded up to ensure we meet weekly targets)
                let dailyTarget = Int(ceil(Double(weeklyTarget) / Double(trainingDaysForMuscle)))
                dailyTargetsForMuscle[muscle] = dailyTarget
            }
            
            // Select exercises for this workout
            var selectedExercises: [MovementEntity] = []
            

                // Get candidate exercises that match our criteria
                let candidateExercises = exerciseSelector?.selectExercises(
                    targeting: targetMuscles,
                    withPriority: input.prioritizedMuscles,
                    availableEquipment: input.equipment,
                    exerciseCount: maxExerciseCount * 2 // Get extra to choose from
                ) ?? []
                
                // Sort exercises - compounds first, then by number of muscles targeted
                let sortedExercises = candidateExercises.sorted { first, second in
                    // Prioritize compound movements
                    if isCompoundMovement(first) && !isCompoundMovement(second) {
                        return true
                    } else if !isCompoundMovement(first) && isCompoundMovement(second) {
                        return false
                    }
                    
                    // Avoid technical lifts for beginners
                    if input.trainingExperience == .beginner {
                        let firstIsTechnical = isTechnicalMovement(first)
                        let secondIsTechnical = isTechnicalMovement(second)
                        
                        if firstIsTechnical && !secondIsTechnical {
                            return false
                        } else if !firstIsTechnical && secondIsTechnical {
                            return true
                        }
                    }
                    
                    // Then prioritize by number of muscles involved (more is better)
                    let firstMuscleCount = 1 + first.secondaryMuscles.count
                    let secondMuscleCount = 1 + second.secondaryMuscles.count
                    return firstMuscleCount > secondMuscleCount
                }
                
                // Add exercises until we fulfill volume requirements or hit max count
                for exercise in sortedExercises {
                    // Stop if we've hit our exercise limit
                    if selectedExercises.count >= maxExerciseCount {
                        break
                    }
                    
                    // Get primary muscle and confirm it's a target for this day
                    let primaryMuscle = getPrimaryMuscle(exercise)
                    if !targetMuscles.contains(primaryMuscle) {
                        continue
                    }
                    
                    // Check if we already have enough exercises for this muscle group
                    let muscleExerciseCount = selectedExercises.filter { 
                        getPrimaryMuscle($0) == primaryMuscle 
                    }.count
                    
                    // Enforce muscle balance - don't add too many exercises for one muscle
                    let maxExercisesPerMuscle = input.trainingExperience == .beginner ? 1 : 2
                    if muscleExerciseCount >= maxExercisesPerMuscle {
                        continue
                    }
                    
                    // Skip if primary muscle already has enough volume
                    let dailyTarget = dailyTargetsForMuscle[primaryMuscle, default: 0]
                    if setsCompletedForMuscle[primaryMuscle, default: 0] >= Double(dailyTarget) {
                        continue
                    }
                    
                    // Add this exercise to our selected list
                    selectedExercises.append(exercise)
                }
                
                // Create exercise instances from our selected movements
                for movement in selectedExercises {
                    // Determine primary muscle and daily target
                    let primaryMuscle = getPrimaryMuscle(movement)
                    let dailyTarget = dailyTargetsForMuscle[primaryMuscle, default: 0]
                    
                    // Calculate how many sets to perform
                    var setsNeeded = dailyTarget - Int(setsCompletedForMuscle[primaryMuscle, default: 0])
                    
                    // Enforce minimum set count based on experience level
                    let minSets = input.trainingExperience == .beginner ? 2 : 3
                    let maxSets = input.trainingExperience == .beginner ? 3 : 4
                    
                    // Clamp set count to reasonable range
                    let setCount = min(maxSets, max(minSets, setsNeeded))
                    
                    // Create the sets for this exercise
                    let exerciseSets = createSetsForExercise(
                        exercise: movement,
                        setCount: setCount,
                        goal: input.goal,
                        experience: input.trainingExperience
                    )
                    
                    // Create the exercise instance
                    let exerciseInstance = ExerciseInstanceEntity(
                        movement: movement,
                        sets: exerciseSets
                    )
                    
                    // Add to workout
                    workout.exercises.append(exerciseInstance)
                    
                    // Update volume tracking
                    // Primary muscle gets full credit
                    setsCompletedForMuscle[primaryMuscle, default: 0] += Double(setCount)
                    
                    // Secondary muscles get half credit
                    for secondaryMuscle in movement.secondaryMuscles {
                        if targetMuscles.contains(secondaryMuscle) {
                            setsCompletedForMuscle[secondaryMuscle, default: 0] += Double(setCount) * 0.5
                        }
                    }
                }
            
            // Add this workout to our base week
            baseWeekWorkouts.append(workout)
        }
        
        // STEP 2: Clone and adjust workouts for each week in the plan
        for weekIndex in 1...weeks {
            for (dayIndex, baseWorkout) in baseWeekWorkouts.enumerated() {
                // For week 1, use the base workouts directly
                if weekIndex == 1 {
                    // Set the date for this workout
                    let scheduledDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: plan.startDate)
                    baseWorkout.scheduledDate = scheduledDate
                    
                    // Set training plan reference
                    baseWorkout.trainingPlan = plan
                    
                    // Add to plan
                    plan.workouts.append(baseWorkout)
                } 
                // For later weeks, clone and adjust volume
                else {
                    // Create a copy of the base workout
                    let workout = baseWorkout.copy() as! WorkoutEntity
                    
                    // Adjust volume for the current week
                    adjustWorkoutVolume(
                        workout: workout,
                        goal: input.goal,
                        week: weekIndex,
                        totalWeeks: weeks,
                        experience: input.trainingExperience
                    )
                    
                    // Calculate the date for this workout
                    let dayOffset = (weekIndex - 1) * 7 + dayIndex
                    if let scheduledDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: plan.startDate) {
                        workout.scheduledDate = scheduledDate
                    }
                    
                    // Set training plan reference
                    workout.trainingPlan = plan
                    
                    // Add to plan
                    plan.workouts.append(workout)
                }
            }
        }
    }
    
    /// Count how many days a muscle is trained per week based on split type
    private func countTrainingDaysForMuscle(_ muscle: MuscleGroup, split: SplitStyle, daysPerWeek: Int) -> Int {
        var count = 0
        
        for day in 1...daysPerWeek {
            let dayType = getDayType(day: day, split: split, totalDays: daysPerWeek)
            let musclesForDay = getMusclesForDayType(dayType)
            
            if musclesForDay.contains(muscle) {
                count += 1
            }
        }
        
        return max(1, count) // Ensure at least 1 to avoid division by zero
    }
    
    /// Create appropriate sets for an exercise based on training goal and experience
    private func createSetsForExercise(
        exercise: MovementEntity,
        setCount: Int,
        goal: TrainingGoal,
        experience: TrainingExperience
    ) -> [ExerciseSetEntity] {
        var sets: [ExerciseSetEntity] = []
        
        // Get appropriate rep range
        let (minReps, maxReps) = getRepRangeForExercise(
            exercise: exercise,
            goal: goal,
            experience: experience
        )
        
        // For beginners, use the same rep target for all sets
        // For intermediate+, create a slight rep drop-off for later sets
        let repDropPerSet = experience == .beginner ? 0 : 1
        
        // Create sets
        for i in 0..<setCount {
            // Calculate target reps, reducing slightly for later sets
            let targetReps = max(minReps, maxReps - (i * repDropPerSet))
            
            let set = ExerciseSetEntity(
                weight: 0, // Weight will be determined during the workout
                completedReps: 0,
                targetReps: targetReps,
                isComplete: false
            )
            
            sets.append(set)
        }
        
        return sets
    }
    
    /// Get appropriate rep range for an exercise based on training goal and experience
    private func getRepRangeForExercise(
        exercise: MovementEntity,
        goal: TrainingGoal,
        experience: TrainingExperience
    ) -> (Int, Int) {
        // For compound exercises with beginner trainees, bump the min rep range up slightly
        if isCompoundMovement(exercise) && experience == .beginner {
            switch goal {
            case .hypertrophy:
                return (10, 15)
            case .strength:
                return (6, 10)
            }
        }
        
        // Otherwise, use standard rep ranges based on goal
        switch goal {
        case .hypertrophy:
            if experience == .beginner {
                return (8, 15)
            } else {
                return (8, 12)
            }
        case .strength:
            if experience == .beginner {
                return (5, 10)
            } else {
                return (3, 6)
            }
        }
    }
    
    /// Adjust a workout's volume based on the current week in the plan
    private func adjustWorkoutVolume(
        workout: WorkoutEntity,
        goal: TrainingGoal,
        week: Int,
        totalWeeks: Int,
        experience: TrainingExperience
    ) {
        // Get the appropriate volume strategy
        let strategy = getVolumeStrategy()
        guard let standardStrategy = strategy as? StandardVolumeRampStrategy else {
            return
        }
        
        // Adjust each exercise's volume based on the current week
        for exercise in workout.exercises {
            let primaryMuscle = getPrimaryMuscle(exercise.movement)
            
            // Break down the complex expression into smaller parts
            var isEmphasized = false
            if let preferences = workout.trainingPlan?.musclePreferences {
                for preference in preferences {
                    if preference.muscleGroup == primaryMuscle && preference.goal == .grow {
                        isEmphasized = true
                        break
                    }
                }
            }
            
            // Get the base recommendation for week 1
            let baseRecommendation = strategy.calculateVolume(
                for: primaryMuscle,
                goal: goal,
                trainingAge: experience.trainingAge,
                isEmphasized: isEmphasized
            )
            
            // Calculate the appropriate number of sets for the current week
            let weekSets = standardStrategy.calculateVolumeForWeek(
                targetSets: baseRecommendation.setsPerWeek,
                currentWeek: week,
                totalWeeks: totalWeeks,
                isMaintenance: !isEmphasized
            )
            
            // Calculate how much to scale vs. week 1
            let baseWeek1Sets = standardStrategy.calculateVolumeForWeek(
                targetSets: baseRecommendation.setsPerWeek,
                currentWeek: 1,
                totalWeeks: totalWeeks,
                isMaintenance: !isEmphasized
            )
            
            // Only adjust if we need to increase volume
            if weekSets > baseWeek1Sets {
                // Add sets or reps based on the difference
                let setDifference = weekSets - baseWeek1Sets
                
                if setDifference >= 2 && exercise.sets.count < 5 {
                    // Add a full set if the difference is substantial
                    let newSet = exercise.sets.first!.copy() as! ExerciseSetEntity
                    exercise.sets.append(newSet)
                } else if setDifference > 0 {
                    // Otherwise, increase reps on existing sets
                    for set in exercise.sets {
                        set.targetReps += 1
                    }
                }
            }
        }
    }
    
    /// Determine if a movement is technically complex (not ideal for beginners)
    private func isTechnicalMovement(_ movement: MovementEntity) -> Bool {
        // Examples of technical movements to avoid for beginners
        let technicalMovements: [MovementType] = [
            //.snatch, .clean, .jerk, // Olympic lifts
            .barbellDeadlift, // Complex compound
            .barbellFrontSquat, // Technical barbell position
            .romanianDeadlift // Technical hinge pattern
            // Add more as needed
        ]
        
        return technicalMovements.contains(movement.movementType)
    }
    
    /// Determine workout day type based on split style
    private func getDayType(day: Int, split: SplitStyle, totalDays: Int) -> WorkoutDayType {
        switch split {
        case .fullBody:
            return .fullBody
        case .upperLower:
            return day % 2 == 0 ? .upper : .lower
        case .pushPullLegs:
            let dayMod = day % 3
            if dayMod == 1 { return .push }
            if dayMod == 2 { return .pull }
            return .legs
        }
    }
    
    /// Convert day type to workout name
    private func dayTypeToName(_ dayType: WorkoutDayType) -> String {
        switch dayType {
        case .fullBody: return "Full Body Workout"
        case .upper: return "Upper Body Workout"
        case .lower: return "Lower Body Workout"
        case .push: return "Push Workout"
        case .pull: return "Pull Workout"
        case .legs: return "Legs Workout"
        }
    }
    
    /// Converts prioritized muscle groups to MuscleTrainingPreference objects
    /// - Parameter prioritizedMuscles: Array of muscle groups the user wants to prioritize
    /// - Returns: Array of MuscleTrainingPreference objects with appropriate goals
    private func convertToMusclePreferences(from prioritizedMuscles: [MuscleGroup]) -> [MuscleTrainingPreference] {
        // Create a set for easy lookup of prioritized muscles
        let prioritySet = Set(prioritizedMuscles)
        
        // Create a preference for each muscle group
        return MuscleGroup.allCases.map { muscle in
            let goal: MuscleGoal = prioritySet.contains(muscle) ? .grow : .maintain
            return MuscleTrainingPreference(muscleGroup: muscle, goal: goal)
        }
    }
    
    /// Get a volume ramp strategy, using the default implementation if none is provided
    private func getVolumeStrategy() -> VolumeRampStrategy {
        return volumeStrategy ?? StandardVolumeRampStrategy()
    }
    
    /// Calculate appropriate volume for a muscle group in a specific week
    /// - Parameters:
    ///   - muscleGroup: The muscle group to calculate volume for
    ///   - goal: Training goal (hypertrophy or strength)
    ///   - isEmphasized: Whether this muscle is prioritized
    ///   - week: Current week number (1-based)
    ///   - totalWeeks: Total weeks in the plan
    ///   - trainingExperience: User's training experience level
    /// - Returns: Number of sets to assign for this muscle in this week
    func calculateSetsForMuscle(
        _ muscleGroup: MuscleGroup,
        goal: TrainingGoal,
        isEmphasized: Bool,
        week: Int,
        totalWeeks: Int,
        trainingExperience: TrainingExperience
    ) -> Int {
        let strategy = getVolumeStrategy()
        
        // Get the baseline recommendation
        let recommendation = strategy.calculateVolume(
            for: muscleGroup,
            goal: goal,
            trainingAge: trainingExperience.trainingAge,
            isEmphasized: isEmphasized
        )
        
        // Apply the weekly ramp
        if let standardStrategy = strategy as? StandardVolumeRampStrategy {
            return standardStrategy.calculateVolumeForWeek(
                targetSets: recommendation.setsPerWeek,
                currentWeek: week,
                totalWeeks: totalWeeks,
                isMaintenance: goal == .strength || !isEmphasized
            )
        }
        
        // Fallback if we're not using the standard strategy
        return recommendation.setsPerWeek
    }
    
    /// Get muscles targeted on a specific day type
    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
        switch dayType {
        case .fullBody:
            return MuscleGroup.allCases
        case .upper:
            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
        case .lower:
            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
        case .push:
            return [.chest, .shoulders, .triceps]
        case .pull:
            return [.back, .biceps, .forearms, .traps]
        case .legs:
            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
        }
    }
    
    /// Determine appropriate number of exercises based on workout duration
    private func getExerciseCountForDuration(_ duration: WorkoutDuration) -> Int {
        switch duration {
        case .short: return 4
        case .medium: return 6
        case .long: return 8
        }
    }
    
    /// Determine if a movement is a compound exercise (uses multiple major muscle groups)
    private func isCompoundMovement(_ movement: MovementEntity) -> Bool {
        // Compound movements typically involve multiple joints and muscle groups
        // A simple heuristic is to check if it has 2+ secondary muscles or specific movement types
        
        let compoundMovementTypes: [MovementType] = [
            .barbellBenchPress, .barbellDeadlift, .barbellBackSquat, .barbellFrontSquat,
            .overheadPress, .pullUps, .chinUps, .dips, .bentOverRow, .romanianDeadlift
        ]
        
        // Either has a compound movement type or has multiple secondary muscles
        return compoundMovementTypes.contains(movement.movementType) || movement.secondaryMuscles.count >= 2
    }
    
    /// Get the primary muscle for a movement (first in the primaryMuscles array)
    private func getPrimaryMuscle(_ movement: MovementEntity) -> MuscleGroup {
        return movement.primaryMuscles.first ?? .unknown
    }
}

/// Types of workout days based on muscle targeting
enum WorkoutDayType {
    case fullBody
    case upper
    case lower
    case push
    case pull
    case legs
}

/// Volume recommendation for a muscle group
struct VolumeRecommendation {
    /// Total sets per week
    let setsPerWeek: Int
    
    /// Lower bound of rep range
    let repRangeLower: Int
    
    /// Upper bound of rep range
    let repRangeUpper: Int
    
    /// Relative intensity (percentage of 1RM)
    let intensity: Double
}

// MARK: - Builder Protocols

/// Protocol for building workouts based on user constraints
protocol WorkoutBuilder {
    /// Build a workout targeting specific muscles with available equipment
    func buildWorkout(
        for dayType: WorkoutDayType,
        prioritizedMuscles: [MuscleGroup],
        equipment: [EquipmentType],
        duration: WorkoutDuration
    ) -> WorkoutEntity
}

/// Protocol for selecting appropriate exercises based on constraints
protocol ExerciseSelector {
    /// Select exercises that target specified muscles with available equipment
    func selectExercises(
        targeting: [MuscleGroup],
        withPriority: [MuscleGroup],
        availableEquipment: [EquipmentType],
        exerciseCount: Int
    ) -> [MovementEntity]
}

/// Protocol for determining appropriate volume progression
protocol VolumeRampStrategy {
    /// Calculate appropriate volume for a muscle group based on goal and training history
    func calculateVolume(
        for muscleGroup: MuscleGroup,
        goal: TrainingGoal,
        trainingAge: Int, // In weeks
        isEmphasized: Bool
    ) -> VolumeRecommendation
}

// MARK: - Default Implementations

/// Default implementation of the workout builder
class DefaultWorkoutBuilder: WorkoutBuilder {
    private let exerciseSelector: ExerciseSelector
    
    init(exerciseSelector: ExerciseSelector) {
        self.exerciseSelector = exerciseSelector
    }
    
    func buildWorkout(
        for dayType: WorkoutDayType,
        prioritizedMuscles: [MuscleGroup],
        equipment: [EquipmentType],
        duration: WorkoutDuration
    ) -> WorkoutEntity {
        // Determine target muscles based on day type
        let targetMuscles = getMusclesForDayType(dayType)
        let exerciseCount = getExerciseCountForDuration(duration)
        
        // Select appropriate exercises
        let selectedExercises = exerciseSelector.selectExercises(
            targeting: targetMuscles,
            withPriority: prioritizedMuscles,
            availableEquipment: equipment,
            exerciseCount: exerciseCount
        )
        
        // Create workout description
        let workoutName = dayTypeToName(dayType)
        let workoutDescription = "Targets: " + targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
        
        // Create and return a workout entity
        return WorkoutEntity(
            title: workoutName,
            description: workoutDescription,
            isComplete: false
        )
    }
    
    /// Convert day type to workout name
    private func dayTypeToName(_ dayType: WorkoutDayType) -> String {
        switch dayType {
        case .fullBody: return "Full Body Workout"
        case .upper: return "Upper Body Workout"
        case .lower: return "Lower Body Workout"
        case .push: return "Push Workout"
        case .pull: return "Pull Workout"
        case .legs: return "Legs Workout"
        }
    }
    
    /// Get muscles targeted on a specific day type
    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
        switch dayType {
        case .fullBody:
            return MuscleGroup.allCases
        case .upper:
            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
        case .lower:
            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
        case .push:
            return [.chest, .shoulders, .triceps]
        case .pull:
            return [.back, .biceps, .forearms, .traps]
        case .legs:
            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
        }
    }
    
    /// Determine appropriate number of exercises based on workout duration
    private func getExerciseCountForDuration(_ duration: WorkoutDuration) -> Int {
        switch duration {
        case .short: return 4
        case .medium: return 6
        case .long: return 8
        }
    }
}
