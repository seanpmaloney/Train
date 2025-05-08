import Foundation

@MainActor
struct PlanGenerator {
    public var excludedMovements:[MovementEntity] = []
    // Entry point
    mutating func generatePlan(input: PlanInput, forWeeks weeks: Int) -> TrainingPlanEntity {
        // 1. Initialize Plan with metadata
        let plan = initializePlan(from: input)
        
        // 2. Generate workouts for all weeks
        generateWorkouts(for: plan, input: input, weeks: weeks)
        
        // 3. Post-process the plan to ensure constraints are met
        //avoidBackToBackMuscleUse(plan: plan)
        
        return plan
    }
    
    // Helper method to initialize a TrainingPlanEntity with metadata
    private func initializePlan(from input: PlanInput) -> TrainingPlanEntity {
        // Convert prioritized muscles to MuscleTrainingPreference objects
        let musclePreferences = convertToMusclePreferences(from: input.prioritizedMuscles)
        
        // Calculate end date based on weeks
        let startDate = Date()
        
        // Create and configure the plan entity
        let plan = TrainingPlanEntity(
            name: "Custom \(input.goal.rawValue) Plan",
            notes: "Generated based on your preferences",
            startDate: startDate,
            daysPerWeek: input.trainingDaysPerWeek,
            isCompleted: false,
        )
        
        // Set metadata
        plan.musclePreferences = musclePreferences
        plan.trainingGoal = input.goal
        
        return plan
    }
    
    // Convert muscle groups to MuscleTrainingPreference objects
    private func convertToMusclePreferences(from prioritizedMuscles: [MuscleGroup]) -> [MuscleTrainingPreference] {
        var preferences: [MuscleTrainingPreference] = []
        
        // Add prioritized muscles as 'grow'
        for muscle in prioritizedMuscles {
            preferences.append(MuscleTrainingPreference(
                muscleGroup: muscle,
                goal: .grow
            ))
        }
        
        // Add remaining muscles as 'maintain'
        for muscle in MuscleGroup.allCases {
            if muscle != .unknown && !prioritizedMuscles.contains(muscle) {
                preferences.append(MuscleTrainingPreference(
                    muscleGroup: muscle,
                    goal: .maintain
                ))
            }
        }
        
        return preferences
    }
    
    // Core workout generation
    mutating func generateWorkouts(for plan: TrainingPlanEntity, input: PlanInput, weeks: Int) {
        // STEP 1: Generate a base week of workouts
        let baseWeekWorkouts = generateBaseWeek(for: plan, input: input)
        
        // STEP 2: Apply base week to plan
        for workout in baseWeekWorkouts {
            plan.workouts.append(workout)
            workout.trainingPlan = plan
        }
        
        // STEP 3: Copy and adjust for subsequent weeks
        if weeks > 1 {
            for weekNumber in 2...weeks {
                copyAndAdjustWeek(
                    from: baseWeekWorkouts,
                    to: plan,
                    weekNumber: weekNumber,
                    input: input
                )
            }
        }
    }
    
    /// Generate one week of workouts as the base template
    private mutating func generateBaseWeek(for plan: TrainingPlanEntity, input: PlanInput) -> [WorkoutEntity] {
        var baseWeekWorkouts: [WorkoutEntity] = []
        // Create a map of how many days per week each muscle is trained
        let muscleFrequencyMap = createMuscleFrequencyMap(for: plan, input: input, weekNumber: 1)
        
        // For each training day in the week
        for dayIndex in 0..<input.trainingDaysPerWeek {
            // Determine workout type based on split style
            let dayNumber = dayIndex + 1
            let dayType = getDayType(day: dayNumber, split: input.preferredSplit, totalDays: input.trainingDaysPerWeek)
            
            // Create the workout with the muscle frequency map for intelligent volume distribution
            let (workout, _) = createWorkout(
                for: dayType,
                in: plan,
                input: input,
                weekNumber: 1,
                dayNumber: dayNumber,
                muscleFrequencyMap: muscleFrequencyMap
            )
            
            // Add to base week
            baseWeekWorkouts.append(workout)
        }
        
        return baseWeekWorkouts
    }
    
    /// Copy workouts from base week and adjust for progressive overload
    private func copyAndAdjustWeek(
        from baseWeek: [WorkoutEntity],
        to plan: TrainingPlanEntity,
        weekNumber: Int,
        input: PlanInput
    ) {
        for (dayIndex, baseWorkout) in baseWeek.enumerated() {
            // Calculate new date for this workout
            let dayNumber = dayIndex + 1
            let newDate = calculateDate(weekNumber: weekNumber, dayNumber: dayNumber, startDate: plan.startDate)
            
            // Create a copy of the base workout
            let newWorkout = copyWorkout(baseWorkout, withNewDate: newDate)
            
            // Apply progressive overload to exercises
            applyProgressiveOverload(
                to: newWorkout,
                originalWorkout: baseWorkout,
                weekNumber: weekNumber,
                input: input
            )
            
            // Add to plan
            plan.workouts.append(newWorkout)
            newWorkout.trainingPlan = plan
        }
    }
    
    /// Create a single workout with exercises
    private mutating func createWorkout(
        for dayType: WorkoutDayType,
        in plan: TrainingPlanEntity,
        input: PlanInput,
        weekNumber: Int,
        dayNumber: Int,
        muscleFrequencyMap: [MuscleGroup: Int]
    ) -> (WorkoutEntity, [MuscleGroup: (current: Int, target: Int)]) {
        // Create a workout shell
        let workoutName = dayTypeToName(dayType)
        
        // Get target muscles for this day type
        let targetMuscles = getMusclesForDayType(dayType)
        let workoutDescription = "Targets: " + targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
        
        let workout = WorkoutEntity(
            title: workoutName,
            description: workoutDescription,
            isComplete: false
        )
        
        // Set scheduled date
        let workoutDate = calculateDate(weekNumber: weekNumber, dayNumber: dayNumber, startDate: plan.startDate)
        workout.scheduledDate = workoutDate
        
        // Create muscle volume tracking dictionary
        // This tracks (current: how many sets so far, target: how many sets needed)
        var muscleTargets: [MuscleGroup: (current: Int, target: Int)] = [:]
        // Initialize muscle targets based on the workout's day type
        for muscle in targetMuscles {
            let isPrioritized = input.prioritizedMuscles.contains(muscle)
            
            // Calculate weekly volume target for this muscle
            let weeklyTarget = calculateWeeklyVolumeForMuscle(
                muscle: muscle,
                goal: input.goal,
                isPrioritized: isPrioritized,
                experienceLevel: input.trainingExperience,
                weekNumber: weekNumber
            )
            
            // Get how many workouts per week this muscle is trained in
            let workoutsPerWeek = muscleFrequencyMap[muscle] ?? 1
            
            // Per-workout target is weekly target divided by frequency
            let perWorkoutTarget = Int(ceil(Double(weeklyTarget) / Double(workoutsPerWeek)))
            
            // Initialize tracking with 0 current sets and the target
            muscleTargets[muscle] = (current: 0, target: perWorkoutTarget)
        }
        
        // Select exercises and create instances to hit volume targets
        populateWorkoutWithExercises(
            workout: workout,
            muscleTargets: &muscleTargets,
            input: input,
            weekNumber: weekNumber,
            muscleFrequencyMap: muscleFrequencyMap,
            excludedMovements: excludedMovements
        )
        
        return (workout, muscleTargets)
    }
    
    /// Add exercises to a workout based on muscle targets
    private mutating func populateWorkoutWithExercises(
        workout: WorkoutEntity,
        muscleTargets: inout [MuscleGroup: (current: Int, target: Int)],
        input: PlanInput,
        weekNumber: Int,
        muscleFrequencyMap: [MuscleGroup: Int],
        excludedMovements: [MovementEntity]
    ) {
        // Determine max number of exercises based on duration
        let maxExerciseCount = getExerciseCount(for: input.workoutDuration)
        
        // Get all target muscles in priority order
        let targetMuscles = muscleTargets.keys.sorted { muscle1, muscle2 in
            // Prioritized muscles first
            let isPrioritized1 = input.prioritizedMuscles.contains(muscle1)
            let isPrioritized2 = input.prioritizedMuscles.contains(muscle2)
            
            if isPrioritized1 != isPrioritized2 {
                return isPrioritized1
            }
            
            // Then large muscles before small
            return muscle1.muscleSize == .large && muscle2.muscleSize == .small
        }
        
        // Track selected exercise movements to avoid duplicates
        var selectedMovements: [MovementEntity] = []
        
        // First pass: select primary compound movements for main muscle groups
        for muscle in targetMuscles {
            // Skip if we already have enough exercises
            if selectedMovements.count >= maxExerciseCount {
                break
            }
            
            // Only consider muscles with remaining volume targets
            if let targetInfo = muscleTargets[muscle], targetInfo.current < targetInfo.target {
                // Find a suitable compound movement for this muscle
                if let movement = findSuitableMovement(
                    targeting: muscle,
                    excludedMovements: selectedMovements + excludedMovements,
                    availableEquipment: input.equipment
                ) {
                    selectedMovements.append(movement)
                    self.excludedMovements.append(movement)
                    
                    // Calculate sets needed using our intelligent volume allocation
                    let setCount = calculateSetsForMovement(
                        movement: movement,
                        in: workout,
                        muscleTargets: &muscleTargets,
                        weekNumber: weekNumber,
                        daysPerMuscle: muscleFrequencyMap,
                        goal: input.goal,
                        experienceLevel: input.trainingExperience,
                        input: input
                    )
                    
                    // Get rep range based on goal and muscle
                    let (minReps, maxReps) = getRepRange(
                        for: muscle,
                        goal: input.goal,
                        experienceLevel: input.trainingExperience
                    )
                    
                    // Start with the bottom of the rep range
                    let targetReps = minReps
                    
                    // Only add the exercise if we allocated sets to it
                    if setCount > 0 {
                        // Create exercise instance with sets
                        let exerciseInstance = createExerciseInstance(
                            from: movement,
                            setCount: setCount,
                            targetReps: targetReps
                        )
                        
                        // Add to workout
                        workout.exercises.append(exerciseInstance)
                    }
                }
            }
        }
        
        // Second pass: add isolation movements to fill remaining volume targets
        // First sort muscles by how much volume they still need
        let remainingVolumeNeeded = targetMuscles.filter { muscle in
            if let info = muscleTargets[muscle] {
                return info.current < info.target
            }
            return false
        }.sorted { muscle1, muscle2 in
            let remaining1 = (muscleTargets[muscle1]?.target ?? 0) - (muscleTargets[muscle1]?.current ?? 0)
            let remaining2 = (muscleTargets[muscle2]?.target ?? 0) - (muscleTargets[muscle2]?.current ?? 0)
            return remaining1 > remaining2
        }
        
        // Now add isolation movements focusing on muscles with highest remaining needs
        for muscle in remainingVolumeNeeded {
            // Skip if we already have enough exercises
            if selectedMovements.count >= maxExerciseCount || workout.exercises.count >= maxExerciseCount {
                break
            }
            
            // Only consider muscles that still need volume
            if let targetInfo = muscleTargets[muscle], targetInfo.current < targetInfo.target {
                // Find a suitable isolation movement for this muscle
                if let movement = findSuitableMovement(
                    targeting: muscle,
                    isCompound: false, // Isolation movements
                    excludedMovements: selectedMovements,
                    availableEquipment: input.equipment
                ) {
                    selectedMovements.append(movement)
                    
                    // Calculate sets needed
                    let setCount = calculateSetsForMovement(
                        movement: movement,
                        in: workout,
                        muscleTargets: &muscleTargets,
                        weekNumber: weekNumber,
                        daysPerMuscle: muscleFrequencyMap,
                        goal: input.goal,
                        experienceLevel: input.trainingExperience,
                        input: input
                    )
                    
                    // Get rep range based on goal and muscle
                    let (minReps, maxReps) = getRepRange(
                        for: muscle,
                        goal: input.goal,
                        experienceLevel: input.trainingExperience
                    )
                    
                    // Target the middle of the rep range
                    let targetReps = (minReps + maxReps) / 2
                    
                    // Only add the exercise if we allocated sets to it
                    if setCount > 0 {
                        // Create exercise instance with sets
                        let exerciseInstance = createExerciseInstance(
                            from: movement,
                            setCount: setCount,
                            targetReps: targetReps
                        )
                        
                        // Add to workout
                        workout.exercises.append(exerciseInstance)
                    }
                }
            }
        }
        
        // Ensure movement variety
        enforceMovementVariety(for: workout, input: input)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the date for a workout
    /// - Parameters:
    ///   - weekNumber: Week in the plan (1-based)
    ///   - dayNumber: Day in the week (1-based)
    ///   - startDate: The start date of the plan
    /// - Returns: The date for the specified workout
    private func calculateDate(weekNumber: Int, dayNumber: Int, startDate: Date) -> Date {
        let calendar = Calendar.current
        
        // Calculate day offset from start date
        let dayOffset = (weekNumber - 1) * 7 + (dayNumber - 1)
        
        // Add days to start date
        return calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
    }
    
    /// Create a copy of a workout with a new date
    /// - Parameters:
    ///   - original: The workout to copy
    ///   - date: The new date for the copy
    /// - Returns: A new workout entity with copied properties and exercises
    private func copyWorkout(_ original: WorkoutEntity, withNewDate date: Date) -> WorkoutEntity {
        let copy = WorkoutEntity(
            title: original.title,
            description: original.description,
            isComplete: false
        )
        copy.scheduledDate = date
        
        // Copy exercises
        for originalExercise in original.exercises {
            let exerciseCopy = copyExercise(originalExercise)
            copy.exercises.append(exerciseCopy)
        }
        
        return copy
    }
    
    /// Copy an exercise instance
    /// - Parameter original: The exercise to copy
    /// - Returns: A new exercise instance with copied properties
    private func copyExercise(_ original: ExerciseInstanceEntity) -> ExerciseInstanceEntity {
        let copy = ExerciseInstanceEntity(
            movement: original.movement,
            exerciseType: original.exerciseType,
            sets: []
        )
        
        // Copy sets
        for originalSet in original.sets {
            let setCopy = ExerciseSetEntity(
                weight: originalSet.weight,
                completedReps: 0,
                targetReps: originalSet.targetReps,
                isComplete: false
            )
            copy.sets.append(setCopy)
        }
        
        return copy
    }
    
    /// Apply progressive overload to exercises in a workout for a future week
    /// - Parameters:
    ///   - workout: The workout to modify
    ///   - originalWorkout: The workout from the base week
    ///   - weekNumber: The week number (1-based)
    ///   - input: User preferences and settings
    private func applyProgressiveOverload(
        to workout: WorkoutEntity,
        originalWorkout: WorkoutEntity,
        weekNumber: Int,
        input: PlanInput
    ) {
        for exercise in workout.exercises {
            // Get the primary muscle targeted by this exercise
            guard let primaryMuscle = exercise.movement.primaryMuscles.first else {
                continue
            }
            
            // Check if this muscle is prioritized
            let isPrioritized = input.prioritizedMuscles.contains(primaryMuscle)
            
            // Only ramp volume for prioritized muscles
            if isPrioritized {
                // For each subsequent week, progressively add:
                // - Beginners: Add 1 rep per week for first 2 weeks, then 1 set
                // - Intermediate: Add 1 set every other week
                // - Advanced: Add 1 set per week for prioritized muscles
                
                let weeksSinceStart = weekNumber - 1
                
                switch input.trainingExperience {
                case .beginner:
                    if weeksSinceStart <= 2 {
                        // First, increase reps by 1-2 per week
                        for set in exercise.sets {
                            set.targetReps += weeksSinceStart
                        }
                    } else {
                        // After initial weeks, add a set
                        let additionalSets = (weeksSinceStart - 2) / 2
                        for _ in 0..<additionalSets {
                            if exercise.sets.count < 5 { // Cap at 5 sets
                                addProgressiveSet(to: exercise)
                            }
                        }
                    }
                    
                case .intermediate:
                    // Add a set every other week for prioritized muscles
                    let additionalSets = weeksSinceStart / 2
                    for _ in 0..<additionalSets {
                        if exercise.sets.count < 5 { // Cap at 5 sets
                            addProgressiveSet(to: exercise)
                        }
                    }
                    
                case .advanced:
                    // Add sets more aggressively for advanced lifters
                    let additionalSets = min(weeksSinceStart, 5 - exercise.sets.count)
                    for _ in 0..<additionalSets {
                        if exercise.sets.count < 5 { // Cap at 5 sets
                            addProgressiveSet(to: exercise)
                        }
                    }
                }
                
                // Weight progression for non-bodyweight exercises
                if exercise.movement.equipment != .bodyweight {
                    let increment = getWeightIncrementForEquipment(exercise.movement.equipment)
                    for set in exercise.sets {
                        set.weight += increment * Double(weeksSinceStart)
                    }
                }
            }
        }
    }
    
    /// Get appropriate weight increment based on equipment
    /// - Parameter equipment: The equipment type
    /// - Returns: The weight increment in pounds/kg
    private func getWeightIncrementForEquipment(_ equipment: EquipmentType) -> Double {
        switch equipment {
        case .barbell:
            return 5.0  // 5 lb increments for barbell
        case .dumbbell:
            return 2.5  // 2.5 lb increments for dumbbells
        case .machine, .cable:
            return 5.0  // 5 lb increments for machines
        case .bodyweight:
            return 0.0  // No increments for bodyweight
        }
    }

    
    /// Add a new set to an exercise as part of progression
    /// - Parameter exercise: The exercise to add a set to
    private func addProgressiveSet(to exercise: ExerciseInstanceEntity) {
        // Get values from the last set as a template
        guard let lastSet = exercise.sets.last else { return }
        
        // Create a new set with the same parameters
        let newSet = ExerciseSetEntity(
            weight: lastSet.weight,
            completedReps: 0,
            targetReps: lastSet.targetReps,
            isComplete: false
        )
        
        // Add to the exercise
        exercise.sets.append(newSet)
    }
        
    /// Find a suitable movement that targets a specific muscle
    /// - Parameters:
    ///   - targeting: The primary muscle to target
    ///   - isCompound: Whether a compound movement is preferred
    ///   - excludedMovements: Movements that cannot be selected
    ///   - availableEquipment: Equipment types available to the user
    /// - Returns: A suitable movement entity or nil if none found
     func findSuitableMovement(
        targeting muscle: MuscleGroup,
        movementPattern: MovementPattern? = nil,
        isCompound: Bool? = nil,
        excludedMovements: [MovementEntity],
        availableEquipment: [EquipmentType]
    ) -> MovementEntity? {
        // In a real implementation, this would query a movement database
        // For now, we'll inject a movement library dependency
        let library = MovementLibrary.allMovements
        
        // Filter movements
        let candidateMovements = library.filter { movement in
            // Must target this muscle as primary
            guard movement.primaryMuscles.contains(muscle) else {
                return false
            }
            
            if (isCompound != nil) {
                // Match compound/isolation requirement
                guard movement.isCompound == isCompound else {
                    return false
                }
            }
            
            // Must use available equipment
            guard availableEquipment.contains(movement.equipment) else {
                return false
            }
            
            // Don't reuse movements
            guard !excludedMovements.contains(where: { $0.id == movement.id }) else {
                return false
            }
            
            if (movementPattern != nil) {
                guard movementPattern == movement.movementPattern else {
                    return false;
                }
            }
            
            return true
        }
        
        // Sort by priority:
        // 1. Movements that have this muscle as the FIRST primary target
        // 2. Prefer technical movements over non-technical
        // 3. Prefer movements with fewer secondary targets (more focused)
        let sortedMovements = candidateMovements.sorted { first, second in
            // Prioritize movements where this muscle is the first primary
            if first.primaryMuscles.first == muscle && second.primaryMuscles.first != muscle {
                return true
            }
            if first.primaryMuscles.first != muscle && second.primaryMuscles.first == muscle {
                return false
            }
            
            // Then prioritize by movement pattern, favoring technically demanding movements
            let firstIsComplex = isComplexMovementPattern(first.movementPattern)
            let secondIsComplex = isComplexMovementPattern(second.movementPattern)
            if firstIsComplex && !secondIsComplex {
                return true
            }
            if !firstIsComplex && secondIsComplex {
                return false
            }
            
            // Lastly prefer more focused (fewer secondary targets) for isolation
            if (isCompound != nil) {
                if !isCompound! {
                    return first.secondaryMuscles.count < second.secondaryMuscles.count
                }
            }
            
            // For compounds, prefer more secondary targets
            return first.secondaryMuscles.count > second.secondaryMuscles.count
        }
        
        return sortedMovements.first
    }
    
    /// Determine if a movement pattern is technically complex
    /// - Parameter pattern: The movement pattern to evaluate
    /// - Returns: Whether the pattern requires higher technical proficiency
    private func isComplexMovementPattern(_ pattern: MovementPattern) -> Bool {
        switch pattern {
        case .squat, .hinge, .lunge, .verticalPush, .verticalPull, .horizontalPull, .horizontalPush:
            return true // More technical movements
        default:
            return false
        }
    }
    
    /// Convert workout day type to a readable name
    /// - Parameter dayType: The workout day type
    /// - Returns: A human-readable name for the workout type
    func dayTypeToName(_ dayType: WorkoutDayType) -> String {
        switch dayType {
        case .fullBody: return "Full Body Workout"
        case .upper: return "Upper Body Workout"
        case .lower: return "Lower Body Workout"
        case .push: return "Push Workout"
        case .pull: return "Pull Workout"
        case .legs: return "Legs Workout"
        }
    }
    
    /// Count how many days per week a muscle is trained based on split
    /// - Parameters:
    ///   - muscle: The muscle group to check
    ///   - split: The training split style
    ///   - daysPerWeek: Number of training days per week
    /// - Returns: Number of times the muscle is trained per week
    func countTrainingDaysForMuscle(
        _ muscle: MuscleGroup,
        split: SplitStyle,
        daysPerWeek: Int
    ) -> Int {
        var frequency = 0
        
        // For each training day, check if this muscle is trained
        for dayNumber in 1...daysPerWeek {
            let dayType = getDayType(day: dayNumber, split: split, totalDays: daysPerWeek)
            let targetMuscles = getMusclesForDayType(dayType)
            
            if targetMuscles.contains(muscle) {
                frequency += 1
            }
        }
        
        return frequency
    }
    
        /// Create an exercise instance with appropriate sets based on parameters
        /// - Parameters:
        ///   - movement: The movement to create an exercise from
        ///   - setCount: Number of sets to create
        ///   - targetReps: Target repetitions per set
        /// - Returns: A configured ExerciseInstanceEntity
        func createExerciseInstance(
            from movement: MovementEntity,
            setCount: Int,
            targetReps: Int
        ) -> ExerciseInstanceEntity {
            // Create the exercise instance
            let exerciseInstance = ExerciseInstanceEntity(
                movement: movement,
                exerciseType: "Normal",
                sets: []
            )
            
            // Calculate appropriate starting weight based on equipment
            let weight = 0.0
            
            // Create each set
            for _ in 0..<setCount {
                let set = ExerciseSetEntity(
                    weight: weight,
                    completedReps: 0,
                    targetReps: targetReps,
                    isComplete: false
                )
                exerciseInstance.sets.append(set)
            }
            
            return exerciseInstance
        }
        
        
        /// Prevent training the same primary muscle on consecutive days
        /// - Parameter plan: The training plan to modify
         func avoidBackToBackMuscleUse(plan: TrainingPlanEntity) {
            // Get workouts sorted by date
            let sortedWorkouts = plan.workouts.filter { $0.scheduledDate != nil }
                .sorted {
                    guard let date1 = $0.scheduledDate, let date2 = $1.scheduledDate else {
                        return false
                    }
                    return date1 < date2
                }
            
            // Check each adjacent pair of workouts
            for i in 0..<(sortedWorkouts.count - 1) {
                let workout1 = sortedWorkouts[i]
                let workout2 = sortedWorkouts[i + 1]
                
                // Skip if not consecutive days
                guard let date1 = workout1.scheduledDate,
                      let date2 = workout2.scheduledDate,
                      Calendar.current.isDate(date2, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: date1)!) else {
                    continue
                }
                
                // Get primary muscles used in workout 1
                let primaryMuscles1 = getPrimaryMusclesInWorkout(workout1)
                
                // For workout 2, check for overlapping primary muscles and swap exercises if needed
                swapOverlappingExercises(in: workout2, toAvoid: primaryMuscles1)
            }
        }
    
    /// Get primary muscles trained in a workout
    /// - Parameter workout: The workout to analyze
    /// - Returns: Set of primary muscle groups
    private func getPrimaryMusclesInWorkout(_ workout: WorkoutEntity) -> Set<MuscleGroup> {
        var primaryMuscles: Set<MuscleGroup> = []
        
        for exercise in workout.exercises {
            for muscle in exercise.movement.primaryMuscles {
                primaryMuscles.insert(muscle)
            }
        }
        
        return primaryMuscles
    }
        
        /// Swap exercises to avoid consecutive day overlap
        /// - Parameters:
        ///   - workout: The workout to modify
        ///   - muscleGroups: Muscle groups to avoid as primary targets
         private func swapOverlappingExercises(in workout: WorkoutEntity, toAvoid muscleGroups: Set<MuscleGroup>) {
            // Track exercises with overlapping primary muscles
            var overlappingExercises: [ExerciseInstanceEntity] = []
            
            // Identify exercises that target muscles from previous day
            for exercise in workout.exercises {
                for muscle in exercise.movement.primaryMuscles {
                    if muscleGroups.contains(muscle) {
                        overlappingExercises.append(exercise)
                        break
                    }
                }
            }
            
            // For each overlapping exercise, try to find an alternative
            for exercise in overlappingExercises {
                // Get the index of this exercise
                guard let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) else {
                    continue
                }
                
                // Try to find an alternative exercise for the same muscle group
                // that doesn't overlap with previous day
                if let alternative = findAlternativeExercise(
                    for: exercise,
                    avoidingMuscles: muscleGroups
                ) {
                    // Replace with alternative
                    workout.exercises[index] = alternative
                }
            }
        }
        
        /// Find an alternative exercise that doesn't target the muscles to avoid
        /// - Parameters:
        ///   - exercise: The original exercise to replace
        ///   - avoidingMuscles: Muscle groups to avoid targeting as primary
        /// - Returns: Alternative exercise or nil if none available
         private func findAlternativeExercise(
            for exercise: ExerciseInstanceEntity,
            avoidingMuscles: Set<MuscleGroup>
        ) -> ExerciseInstanceEntity? {
            // Get muscles targeted by the original exercise that aren't in the avoid list
            let originalPrimaryMuscles = Set(exercise.movement.primaryMuscles)
            let safeTargetMuscles = originalPrimaryMuscles.subtracting(avoidingMuscles)
            
            // If all primary muscles overlap, try finding an exercise that targets
            // a secondary muscle group as primary
            if safeTargetMuscles.isEmpty {
                // Look at secondary muscles from original
                let secondaryMuscles = Set(exercise.movement.secondaryMuscles)
                let potentialTargets = secondaryMuscles.subtracting(avoidingMuscles)
                
                if let targetMuscle = potentialTargets.first,
                   let movement = findSuitableMovement(
                    targeting: targetMuscle,
                    isCompound: exercise.movement.isCompound,
                    excludedMovements: [exercise.movement],
                    availableEquipment: [exercise.movement.equipment]
                   ) {
                    // Create a new exercise instance with the same set/rep scheme
                    return createExerciseInstance(
                        from: movement,
                        setCount: exercise.sets.count,
                        targetReps: exercise.sets.first?.targetReps ?? 10
                    )
                }
                
                return nil
            }
            
            // Try to find alternative targeting safe muscles
            if let targetMuscle = safeTargetMuscles.first,
               let movement = findSuitableMovement(
                targeting: targetMuscle,
                isCompound: exercise.movement.isCompound,
                excludedMovements: [exercise.movement],
                availableEquipment: [exercise.movement.equipment]
               ) {
                // Create a new exercise instance with the same set/rep scheme
                return createExerciseInstance(
                    from: movement,
                    setCount: exercise.sets.count,
                    targetReps: exercise.sets.first?.targetReps ?? 10
                )
            }
            
            return nil
        }
        
        // Enforce variety of movement patterns
        /// Ensures a workout includes a healthy variety of movement patterns
        /// - Parameter workout: The workout to modify for movement pattern variety
    func enforceMovementVariety(for workout: WorkoutEntity, input: PlanInput) {
        // Skip if workout has fewer than 3 exercises (not enough to enforce variety)
        if workout.exercises.count < 3 {
            return
        }
        
        // STEP 1: Count movements by pattern
        var patternCounts: [MovementPattern: Int] = [:]
        let exercisesByPattern: [MovementPattern: [ExerciseInstanceEntity]] = workout.exercises.reduce(into: [:]) { result, exercise in
            let pattern = exercise.movement.movementPattern
            if result[pattern] == nil {
                result[pattern] = []
            }
            result[pattern]?.append(exercise)
            patternCounts[pattern, default: 0] += 1
        }
        
        // STEP 2: Check for complementary movement pattern pairs
        let patternPairs: [(primary: MovementPattern, complementary: MovementPattern)] = [
            (.horizontalPush, .verticalPush),
            (.horizontalPull, .verticalPull),
            (.squat, .hinge)
        ]
        
        // For each pattern pair, ensure there's at least one of each if multiple of either exist
        for pair in patternPairs {
            let primaryCount = patternCounts[pair.primary, default: 0]
            let complementaryCount = patternCounts[pair.complementary, default: 0]
            
            // If we have 2+ primary but no complementary, try to replace one with complementary
            if primaryCount >= 2 && complementaryCount == 0 {
                replaceExerciseMovementPattern(in: workout,
                                               from: pair.primary,
                                               to: pair.complementary,
                                               exercisesByPattern: exercisesByPattern, input: input)
            }
            
            // If we have 2+ complementary but no primary, try to replace one with primary
            if complementaryCount >= 2 && primaryCount == 0 {
                replaceExerciseMovementPattern(in: workout,
                                               from: pair.complementary,
                                               to: pair.primary,
                                               exercisesByPattern: exercisesByPattern, input: input)
            }
        }
        // STEP 3: If we have access to more than 1 equipment type, then make sure we have good equipment variety
        // count movements by equipment type
        if input.equipment.count <= 2 { return }
        var equipmentCounts: [EquipmentType: Int] = [:]
        let exercisesByEquipment: [EquipmentType: [ExerciseInstanceEntity]] = workout.exercises.reduce(into: [:]) { result, exercise in
            let equipment = exercise.movement.equipment
            if result[equipment] == nil {
                result[equipment] = []
            }
            result[equipment]?.append(exercise)
            equipmentCounts[equipment, default: 0] += 1
        }
        // for each instance in exercisesByEquipment where we use the same equipment >= 2
        for (_, exercises) in exercisesByEquipment where exercises.count >= 2 {
            replaceExerciseEquipment(in: workout, from: exercises.last!.movement.equipment, exercisesByPattern: exercisesByEquipment, input: input)
        }
        
    }
        
        /// Helper method to replace an exercise with one of a different movement pattern
        /// - Parameters:
        ///   - workout: The workout to modify
        ///   - fromPattern: The movement pattern to replace
        ///   - toPattern: The desired movement pattern for the replacement
        ///   - exercisesByPattern: Dictionary mapping patterns to exercises
         private func replaceExerciseMovementPattern(in workout: WorkoutEntity,
                                     from fromPattern: MovementPattern,
                                     to toPattern: MovementPattern,
                                     exercisesByPattern: [MovementPattern: [ExerciseInstanceEntity]], input: PlanInput) {
            // Skip unknown patterns
            if fromPattern == .unknown || toPattern == .unknown {
                return
            }
            
            // Get candidate exercises of the pattern we want to replace
            guard let candidatesToReplace = exercisesByPattern[fromPattern], !candidatesToReplace.isEmpty else {
                return
            }
            
            // Find a suitable replacement for one of our exercises
            for exerciseToReplace in candidatesToReplace {
                // Get the primary muscle to ensure we're still targeting it
                guard let primaryMuscle = exerciseToReplace.movement.primaryMuscles.first else {
                    continue
                }
                
                // Find a movement with the desired pattern that targets the same primary muscle
                if let replacementMovement = findSuitableMovement(
                    targeting: primaryMuscle,
                    movementPattern: toPattern,
                    excludedMovements: workout.exercises.map { $0.movement },
                    availableEquipment: input.equipment
                ) {
                    // Create new exercise with the same set/rep scheme
                    let replacementExercise = createExerciseInstance(
                        from: replacementMovement,
                        setCount: exerciseToReplace.sets.count,
                        targetReps: exerciseToReplace.sets.first?.targetReps ?? 10
                    )
                    
                    // Get the index of the exercise to replace
                    if let indexToReplace = workout.exercises.firstIndex(where: { $0.id == exerciseToReplace.id }) {
                        // Replace the exercise
                        workout.exercises[indexToReplace] = replacementExercise
                        
                        // We only need to replace one exercise, so we're done
                        return
                    }
                }
            }
        }
    
    /// Helper method to replace an exercise with one that uses different equipment
    /// - Parameters:
    ///   - workout: The workout to modify
    ///   - fromEquipment: The equipment to replace
    ///   - exercisesByPattern: Dictionary mapping patterns to exercises
     private func replaceExerciseEquipment(in workout: WorkoutEntity,
                                 from fromPattern: EquipmentType,
                                 exercisesByPattern: [EquipmentType: [ExerciseInstanceEntity]], input: PlanInput) {
        // Get candidate exercises of the pattern we want to replace
        guard let candidatesToReplace = exercisesByPattern[fromPattern], !candidatesToReplace.isEmpty else {
            return
        }
        
        // Find a suitable replacement for one of our exercises
        for exerciseToReplace in candidatesToReplace {
            // Get the primary muscle to ensure we're still targeting it
            guard let primaryMuscle = exerciseToReplace.movement.primaryMuscles.first else {
                continue
            }
            // remove the fromPattern equipment from the input equipment
            var updatedInputEquipment = input.equipment
            updatedInputEquipment.removeAll { $0 == fromPattern }
            
            // Find a movement with the desired pattern that targets the same primary muscle
            if let replacementMovement = findSuitableMovement(
                targeting: primaryMuscle,
                movementPattern: nil,
                excludedMovements: workout.exercises.map { $0.movement },
                availableEquipment: updatedInputEquipment
            ) {
                // Create new exercise with the same set/rep scheme
                let replacementExercise = createExerciseInstance(
                    from: replacementMovement,
                    setCount: exerciseToReplace.sets.count,
                    targetReps: exerciseToReplace.sets.first?.targetReps ?? 10
                )
                
                // Get the index of the exercise to replace
                if let indexToReplace = workout.exercises.firstIndex(where: { $0.id == exerciseToReplace.id }) {
                    // Replace the exercise
                    workout.exercises[indexToReplace] = replacementExercise
                    
                    // We only need to replace one exercise, so we're done
                    return
                }
            }
        }
    }
        
        // Determine set targets for a muscle based on week and experience
        func calculateInitialSets(for muscle: MuscleGroup, week: Int, experience: TrainingExperience) -> Int {
            // Return set count based on experience and week index
            fatalError("Not implemented")
        }
        
        // Adjust future workout based on completed one
        func adjustProgressionAfterWorkout(plan: TrainingPlanEntity, completedWorkout: WorkoutEntity) {
            // Modify matching workout next week
            // Increase sets, reps, or weight based on rules
        }
        
        /// Calculate appropriate weekly set targets for a muscle based on factors
        /// - Parameters:
        ///   - muscle: The target muscle group
        ///   - goal: Training goal (strength, hypertrophy, etc.)
        ///   - isEmphasized: Whether the muscle is prioritized
        ///   - week: Current week number (1-based)
        ///   - totalWeeks: Total planned training weeks
        ///   - trainingExperience: User's training experience level
        /// - Returns: Target number of sets per week
         func calculateSetsForMuscle(
            _ muscle: MuscleGroup,
            goal: TrainingGoal,
            isEmphasized: Bool,
            week: Int,
            totalWeeks: Int,
            trainingExperience: TrainingExperience
        ) -> Int {
            // Get the base volume from week 1
            let baseVolume = calculateInitialWeeklyVolume(
                for: muscle,
                isPrioritized: isEmphasized,
                experienceLevel: trainingExperience,
                trainingGoal: goal
            )
            
            // For week 1, use the base volume
            if week == 1 {
                return baseVolume
            }
            
            // For subsequent weeks, apply progressive overload for prioritized muscles
            if isEmphasized {
                // The rate of progression depends on muscle size and experience
                let weeklyIncrease = muscle.muscleSize == .large ? 2 : 1
                let weeklyProgression = trainingExperience == .beginner ? weeklyIncrease / 2 : weeklyIncrease
                
                // Calculate the progression
                let progression = (week - 1) * weeklyProgression
                
                // Cap the progression at the max recommended for hypertrophy
                let maxSets = muscle.trainingGuidelines.maxHypertrophySets
                return min(baseVolume + progression, maxSets)
            } else {
                // For non-prioritized muscles, maintain the base volume
                return baseVolume
            }
        }
        
        /// Calculate the appropriate initial weekly volume for a muscle
        /// - Parameters:
        ///   - muscle: The target muscle group
        ///   - isPrioritized: Whether the muscle is prioritized
        ///   - experienceLevel: User's training experience
        ///   - trainingGoal: Primary training goal
        /// - Returns: Initial weekly set target
        private func calculateInitialWeeklyVolume(
            for muscle: MuscleGroup,
            isPrioritized: Bool,
            experienceLevel: TrainingExperience,
            trainingGoal: TrainingGoal
        ) -> Int {
            let guidelines = muscle.trainingGuidelines
            
            // Determine the appropriate volume range based on goal and prioritization
            let volumeRange: ClosedRange<Int>
            if trainingGoal == .strength || trainingGoal == .hypertrophy {
                // For hypertrophy/strength, use the appropriate range
                volumeRange = isPrioritized ? guidelines.hypertrophySetsRange : guidelines.maintenanceSetsRange
            } else {
                // For general fitness, use maintenance volume
                volumeRange = guidelines.maintenanceSetsRange
            }
            
            // Adjust for experience level
            let volumeFactor: Double
            switch experienceLevel {
            case .beginner:
                volumeFactor = 0.5  // Start beginners at 50% of recommended volume
            case .intermediate:
                volumeFactor = 0.85 // Start intermediates at 85% of recommended volume
            case .advanced:
                volumeFactor = 1.0  // Advanced users get full volume
            }
            
            // Get base target (lower bound for maintenance, middle point for prioritized)
            let baseTarget = isPrioritized 
                ? (volumeRange.lowerBound + volumeRange.upperBound) / 2
                : volumeRange.lowerBound
            
            // Apply experience factor and round to nearest integer
            return max(1, Int(Double(baseTarget) * volumeFactor))
        }
        
        /// Calculate the weekly set target for a specific muscle group
        /// - Parameters:
        ///   - muscle: The muscle to calculate weekly volume for
        ///   - goal: The training goal (hypertrophy, strength, etc.)
        ///   - isPrioritized: Whether this muscle is a priority focus
        ///   - experienceLevel: User's training experience level
        ///   - weekNumber: Current week in the plan for progressive overload
        /// - Returns: Target number of weekly sets for the muscle
        func calculateWeeklyVolumeForMuscle(
            muscle: MuscleGroup,
            goal: TrainingGoal,
            isPrioritized: Bool,
            experienceLevel: TrainingExperience,
            weekNumber: Int
        ) -> Int {
            // 1. Get initial volume range for muscle
            let volumeRange = initialWeeklyVolumeRange(for: muscle, isPrioritized: isPrioritized)
            
            // 2. Determine base target value - higher for prioritized muscles
            let baseTarget = isPrioritized
                ? volumeRange.lowerBound // start at lower bound for hypertrophy
                : volumeRange.upperBound // start and stay at upper bound of maintenence range
            
            // 3. Apply experience multiplier for priority muscles since maintenence is already low
            let experienceFactor: Double
            if (isPrioritized) {
                switch experienceLevel {
                case .beginner: experienceFactor = 0.7  // Beginners start with lower volume
                case .intermediate: experienceFactor = 0.85
                case .advanced: experienceFactor = 1.0  // Advanced lifters use full volume
                }
            } else { experienceFactor = 1.0 }
            
            // 4. Apply progressive overload based on week number
            // increase each week by 10%
            let weeklyProgressionFactor = 1.1
            
            // 5. Calculate final target and ensure it's at least 1 set
            let weeklyTarget = max(1, Int(Double(baseTarget) * experienceFactor * weeklyProgressionFactor))
            
            // 6. Cap weekly volume based on muscle size to prevent overtraining
            let maxWeeklyVolume: Int
            switch muscle.muscleSize {
            case .small: maxWeeklyVolume = 20
            case .large: maxWeeklyVolume = 30
            }
            
            return min(weeklyTarget, maxWeeklyVolume)
        }
        
        /// Returns the initial weekly volume range based on muscle size and training goal
        /// Based on scientific literature on effective training volumes
        /// - Parameters:
        ///   - muscle: The muscle group being trained
        ///   - goal: Training goal (hypertrophy or strength)
        /// - Returns: Range representing min-max sets per week
    private func initialWeeklyVolumeRange(for muscle: MuscleGroup, isPrioritized: Bool) -> ClosedRange<Int> {
        return isPrioritized ? muscle.trainingGuidelines.hypertrophySetsRange : muscle.trainingGuidelines.maintenanceSetsRange
        }
        
        /// Allocates an appropriate number of sets to a movement based on weekly volume targets
        /// - Parameters:
        ///   - movement: The movement to allocate sets for
        ///   - workout: Current workout being built
        ///   - muscleTargets: Dictionary tracking current and target sets per muscle
        ///   - weekNumber: Current week in the plan
        ///   - daysPerMuscle: Dictionary tracking how many workouts per week target each muscle
        ///   - goal: Training goal (hypertrophy, strength, etc.)
        ///   - experienceLevel: User's training experience level
        ///   - input: User preferences and constraints
        /// - Returns: Number of sets to assign to this movement
        func calculateSetsForMovement(
            movement: MovementEntity,
            in workout: WorkoutEntity,
            muscleTargets: inout [MuscleGroup: (current: Int, target: Int)],
            weekNumber: Int,
            daysPerMuscle: [MuscleGroup: Int],
            goal: TrainingGoal,
            experienceLevel: TrainingExperience,
            input: PlanInput
        ) -> Int {
            // Maximum sets to assign to any single movement to keep workouts balanced
            let maxSetsPerMovement = 5
            
            // Calculate appropriate set targets for each muscle involved in this movement
            let allTargetedMuscles = Set(movement.primaryMuscles + movement.secondaryMuscles)
            var requiredSets: [MuscleGroup: Int] = [:]
            
            // Step 1: Initialize volume tracking for all muscles if needed
            for muscle in allTargetedMuscles {
                if muscleTargets[muscle] == nil {
                    // Calculate weekly target for this muscle
                    let weeklyTarget = calculateWeeklyVolumeForMuscle(
                        muscle: muscle,
                        goal: goal,
                        isPrioritized: input.prioritizedMuscles.contains(muscle),
                        experienceLevel: experienceLevel,
                        weekNumber: weekNumber
                    )
                    
                    // Get how many workouts per week this muscle is trained
                    let workoutsPerWeek = daysPerMuscle[muscle] ?? 1
                    
                    // Per-workout target is weekly target divided by frequency
                    let perWorkoutTarget = Int(ceil(Double(weeklyTarget) / Double(workoutsPerWeek)))
                    
                    // Initialize tracking with 0 current sets and the target
                    muscleTargets[muscle] = (current: 0, target: perWorkoutTarget)
                }
                
                // Calculate how many more sets needed for this muscle
                if let targetInfo = muscleTargets[muscle] {
                    let remaining = max(0, targetInfo.target - targetInfo.current)
                    requiredSets[muscle] = remaining
                }
            }
            
            // No sets required for any muscle this movement targets
            if requiredSets.isEmpty || requiredSets.values.allSatisfy({ $0 == 0 }) {
                return 0
            }
            
            // Step 2: Calculate appropriate number of sets based on muscle needs without
            // prioritizing compound over isolation movements
            var setsToAssign: Int
            
            // Get average needed sets for primary muscles (these are the main target)
            let primaryMuscleNeeds = movement.primaryMuscles.compactMap { requiredSets[$0] }
            let avgPrimaryNeeds = primaryMuscleNeeds.isEmpty ? 0 : 
                primaryMuscleNeeds.reduce(0, +) / primaryMuscleNeeds.count
                
            // Consider the total volume needs for this specific exercise
            // without regard to whether it's compound or isolation
            if avgPrimaryNeeds >= 3 {
                // If primary muscles need significant volume, focus on them
                setsToAssign = min(maxSetsPerMovement, avgPrimaryNeeds)
            } else {
                // If primary muscles don't need much volume, consider all muscles
                let avgAllNeeds = requiredSets.values.reduce(0, +) / max(1, requiredSets.count)
                setsToAssign = min(maxSetsPerMovement, max(2, avgAllNeeds))
            }
            
            // Balance volume allocation - compounds tend to be more fatiguing 
            // so we put a slight cap on them for hypertrophy-focused training
            if movement.isCompound && goal == .hypertrophy {
                // For hypertrophy, slightly limit compound volume to manage fatigue
                // This helps distribute more volume to isolation work
                setsToAssign = min(setsToAssign, 4)
            }
            
            // Step 3: Adjust based on experience level
            switch experienceLevel {
            case .beginner:
                // Beginners should have simpler workouts with fewer sets per exercise
                setsToAssign = min(setsToAssign, movement.isCompound ? 3 : 2) 
            case .intermediate:
                // No additional adjustments
                break
            case .advanced:
                // Advanced lifters can handle slightly more volume per exercise
                // but still capped to prevent excessive volume in single movements
                setsToAssign = min(setsToAssign + 1, maxSetsPerMovement)
            }
            
            // Step 4: Update volume tracking using the 1:0.5 rule
            if setsToAssign > 0 {
                // Primary muscles get 1.0 set credit per set
                for muscle in movement.primaryMuscles {
                    if var tracking = muscleTargets[muscle] {
                        tracking.current += setsToAssign  // Full credit (1.0)
                        muscleTargets[muscle] = tracking
                    }
                }
                
                // Secondary muscles get 0.5 set credit per set
                for muscle in movement.secondaryMuscles {
                    // Skip if already counted as primary to avoid double-counting
                    if movement.primaryMuscles.contains(muscle) {
                        continue
                    }
                    
                    if var tracking = muscleTargets[muscle] {
                        // Half credit (0.5) for secondary muscles
                        let halfCredit = Int(ceil(Double(setsToAssign) / 2.0))
                        tracking.current += halfCredit
                        muscleTargets[muscle] = tracking
                    }
                }
            }
            
            return setsToAssign
        }
        
        /// Creates a helper function for the workout creation process to track volume targets
        /// - Parameters:
        ///   - plan: The training plan being created
        ///   - input: User preferences and constraints
        ///   - weekNumber: Current week in the plan
        /// - Returns: A dictionary tracking how many workouts per week target each muscle group
        func createMuscleFrequencyMap(for plan: TrainingPlanEntity, input: PlanInput, weekNumber: Int) -> [MuscleGroup: Int] {
            // Dictionary to track how many workouts per week target each muscle group
            var daysPerMuscle: [MuscleGroup: Int] = [:]
            
            // For each muscle group, count how many days in the week it's trained
            for muscle in MuscleGroup.allCases {
                let count = countTrainingDaysForMuscle(muscle, split: input.preferredSplit, daysPerWeek: input.trainingDaysPerWeek)
                if count > 0 {
                    daysPerMuscle[muscle] = count
                }
            }
            
            return daysPerMuscle
        }
    }
