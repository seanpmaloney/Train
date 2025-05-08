//import Foundation
//
///// Model representing user input from the plan questionnaire
//struct PlanInput {
//    /// The primary training goal (e.g., hypertrophy, strength)
//    let goal: TrainingGoal
//    
//    /// Muscle groups the user wants to prioritize for growth
//    let prioritizedMuscles: [MuscleGroup]
//    
//    /// Number of days per week the user wants to train
//    let trainingDaysPerWeek: Int
//    
//    /// Preferred workout duration
//    let workoutDuration: WorkoutDuration
//    
//    /// Equipment types available to the user
//    let equipment: [EquipmentType]
//    
//    /// Preferred training split style
//    let preferredSplit: SplitStyle
//    
//    /// User's training experience level
//    let trainingExperience: TrainingExperience
//    
//    /// Create plan input from preferences
//    static func fromPreferences(_ preferences: PlanPreferences) -> PlanInput? {
//        guard let goal = preferences.trainingGoal,
//              let daysPerWeek = preferences.daysPerWeek,
//              let workoutDuration = preferences.workoutDuration,
//              let splitStyle = preferences.splitStyle,
//              let trainingExperience = preferences.trainingExperience,
//              !preferences.availableEquipment.isEmpty else {
//            return nil
//        }
//        
//        return PlanInput(
//            goal: goal,
//            prioritizedMuscles: Array(preferences.priorityMuscles),
//            trainingDaysPerWeek: Self.daysToInt(daysPerWeek),
//            workoutDuration: workoutDuration,
//            equipment: Array(preferences.availableEquipment),
//            preferredSplit: splitStyle,
//            trainingExperience: trainingExperience
//        )
//    }
//    
//    /// Convert DaysPerWeek enum to Int
//    private static func daysToInt(_ days: DaysPerWeek) -> Int {
//        switch days {
//        case .two: return 2
//        case .three: return 3
//        case .four: return 4
//        case .five: return 5
//        case .six: return 6
//        }
//    }
//}
//
///// Generates a personalized training plan based on user input
//@MainActor
//struct PlanGenerator {
//    
//    // MARK: - Dependencies
//    
//    private let workoutBuilder: WorkoutBuilder?
//    private let exerciseSelector: ExerciseSelector?
//    private let volumeStrategy = StandardVolumeRampStrategy()
//    
//    init(
//        workoutBuilder: WorkoutBuilder? = nil,
//        exerciseSelector: ExerciseSelector? = nil,
//    ) {
//        self.workoutBuilder = workoutBuilder
//        self.exerciseSelector = exerciseSelector
//    }
//    
//    // MARK: - Plan Generation
//    
//    /// Generates a complete training plan based on user input
//    /// - Parameters:
//    ///   - input: User preferences from the plan questionnaire
//    ///   - weeks: Number of weeks to generate for the plan
//    /// - Returns: A complete training plan with schedule and muscle preferences
//    func generatePlan(from input: PlanInput, forWeeks weeks: Int = 4) -> TrainingPlanEntity {
//        // Convert prioritized muscles to MuscleTrainingPreference objects
//        let musclePreferences = convertToMusclePreferences(from: input.prioritizedMuscles)
//        
//        // Create a descriptive note for the plan
//        let planDesc = "Custom plan based on your preferences"
//        
//        // Create the training plan with basic information
//        let plan = TrainingPlanEntity(
//            name: "Plan",
//            notes: planDesc,
//            startDate: Date(),
//            daysPerWeek: input.trainingDaysPerWeek,
//            isCompleted: false
//        )
//        
//        // Set muscle preferences and training goal (explicit for plan)
//        plan.musclePreferences = musclePreferences
//        plan.trainingGoal = input.goal
//        
//        generateWorkouts(
//            for: plan,
//            input: input,
//            weeks: weeks
//        )
//        
//        return plan
//    }
//    
//    /// Legacy method signature for compatibility with existing code
//    func generatePlan(from input: PlanInput) -> TrainingPlanEntity {
//        return generatePlan(from: input, forWeeks: 4)
//    }
//    
//    /// Creates a standard custom training plan without muscle preferences
//    /// - Parameters:
//    ///   - name: Name of the plan
//    ///   - daysPerWeek: Number of training days per week
//    /// - Returns: A custom training plan without specific muscle preferences
//    func createCustomPlan(name: String, daysPerWeek: Int) -> TrainingPlanEntity {
//        // Create a basic training plan without specific muscle priorities
//        let plan = TrainingPlanEntity(
//            name: name,
//            notes: "Custom training plan",
//            startDate: Date(),
//            daysPerWeek: daysPerWeek
//        )
//        
//        // Custom plans don't explicitly set muscle preferences
//        // This allows the isPlan property to correctly return false
//        
//        return plan
//    }
//    
//    // MARK: - Helper Methods
//    
//    /// Generate workouts for a training plan
//    /// - Parameters:
//    ///   - plan: The training plan to add workouts to
//    ///   - builder: The workout builder
//    ///   - input: User preferences
//    ///   - weeks: Number of weeks to generate
//    private func generateWorkouts(
//        for plan: TrainingPlanEntity,
//        input: PlanInput,
//        weeks: Int
//    ) {
//        // STEP 1: Generate a base week of workouts
//        var baseWeekWorkouts: [WorkoutEntity] = []
//        
//        // For each training day in the week
//        for dayIndex in 0..<input.trainingDaysPerWeek {
//            // Determine workout type based on split style
//            let dayNumber = dayIndex + 1
//            let dayType = getDayType(day: dayNumber, split: input.preferredSplit, totalDays: input.trainingDaysPerWeek)
//            
//            // Get target muscles for this day type
//            let targetMuscles = getMusclesForDayType(dayType)
//            
//            // Create a workout shell
//            let workoutName = dayTypeToName(dayType)
//            let workoutDescription = "Targets: " + targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
//            let workout = WorkoutEntity(title: workoutName, description: workoutDescription, isComplete: false)
//            
//            // Get max exercise count based on duration
//            let maxExerciseCount = getExerciseCountForDuration(input.workoutDuration)
//            
//            // Track volume distribution for each muscle
//            var setsCompletedForMuscle: [MuscleGroup: Double] = [:]
//            var targetSetsForMuscle: [MuscleGroup: Int] = [:]
//            
//            // Calculate target volumes for each muscle for week 1
//            for muscle in targetMuscles {
//                // Check if this muscle is prioritized
//                let isPrioritized = input.prioritizedMuscles.contains(muscle)
//                
//                // Calculate target sets for this muscle using volume strategy
//                let targetSets = calculateSetsForMuscle(
//                    muscle,
//                    goal: input.goal,
//                    isEmphasized: isPrioritized,
//                    week: 1, // Base week
//                    totalWeeks: weeks,
//                    trainingExperience: input.trainingExperience
//                )
//                
//                // Store target sets and initialize tracking
//                targetSetsForMuscle[muscle] = targetSets
//                setsCompletedForMuscle[muscle] = 0.0
//            }
//            
//            // Calculate daily targets (divide weekly targets by frequency)
//            var dailyTargetsForMuscle: [MuscleGroup: Int] = [:]
//            for (muscle, weeklyTarget) in targetSetsForMuscle {
//                // Determine how many days this muscle is trained per week
//                let trainingDaysForMuscle = countTrainingDaysForMuscle(muscle, split: input.preferredSplit, daysPerWeek: input.trainingDaysPerWeek)
//                // Calculate daily volume (rounded up to ensure we meet weekly targets)
//                let dailyTarget = Int(ceil(Double(weeklyTarget) / Double(trainingDaysForMuscle)))
//                dailyTargetsForMuscle[muscle] = dailyTarget
//            }
//            
//            // Select exercises for this workout
//            var selectedExercises: [MovementEntity] = []
//            
//            // Get candidate exercises that match our criteria
//            let candidateExercises = exerciseSelector?.selectExercises(
//                targeting: targetMuscles,
//                withPriority: input.prioritizedMuscles,
//                availableEquipment: input.equipment,
//                exerciseCount: maxExerciseCount * 2 // Get extra to choose from
//            ) ?? []
//            
//            // Sort exercises - compounds first, then by number of muscles targeted
//            let sortedExercises = candidateExercises.sorted { first, second in
//                // Prioritize compound movements
//                if isCompoundMovement(first) && !isCompoundMovement(second) {
//                    return true
//                } else if !isCompoundMovement(first) && isCompoundMovement(second) {
//                    return false
//                }
//                
//                // Avoid technical lifts for beginners
//                if input.trainingExperience == .beginner {
//                    let firstIsTechnical = isTechnicalMovement(first)
//                    let secondIsTechnical = isTechnicalMovement(second)
//                    
//                    if firstIsTechnical && !secondIsTechnical {
//                        return false
//                    } else if !firstIsTechnical && secondIsTechnical {
//                        return true
//                    }
//                }
//                
//                // Then prioritize by number of muscles involved (more is better)
//                let firstMuscleCount = 1 + first.secondaryMuscles.count
//                let secondMuscleCount = 1 + second.secondaryMuscles.count
//                return firstMuscleCount > secondMuscleCount
//            }
//            
//            // Add exercises until we fulfill volume requirements or hit max count
//            for exercise in sortedExercises {
//                // Stop if we've hit our exercise limit
//                if selectedExercises.count >= maxExerciseCount {
//                    break
//                }
//                
//                // Get primary muscle and confirm it's a target for this day
//                let primaryMuscle = getPrimaryMuscle(exercise)
//                if !targetMuscles.contains(primaryMuscle) {
//                    continue
//                }
//                
//                // Check if we already have enough exercises for this muscle group
//                let muscleExerciseCount = selectedExercises.filter {
//                    getPrimaryMuscle($0) == primaryMuscle
//                }.count
//                
//                // Enforce muscle balance - don't add too many exercises for one muscle
//                let maxExercisesPerMuscle = input.trainingExperience == .beginner ? 1 : 2
//                if muscleExerciseCount >= maxExercisesPerMuscle {
//                    continue
//                }
//                
//                // Skip if primary muscle already has enough volume
//                let dailyTarget = dailyTargetsForMuscle[primaryMuscle, default: 0]
//                if setsCompletedForMuscle[primaryMuscle, default: 0] >= Double(dailyTarget) {
//                    continue
//                }
//                
//                // Add this exercise to our selected list
//                selectedExercises.append(exercise)
//            }
//            
//            // Create exercise instances from our selected movements
//            for movement in selectedExercises {
//                // Determine primary muscle and daily target
//                let primaryMuscle = getPrimaryMuscle(movement)
//                let dailyTarget = dailyTargetsForMuscle[primaryMuscle, default: 0]
//                
//                // Calculate how many sets to perform
//                var setsNeeded = dailyTarget - Int(setsCompletedForMuscle[primaryMuscle, default: 0])
//                
//                // Enforce minimum set count based on experience level
//                let minSets = input.trainingExperience == .beginner ? 2 : 3
//                let maxSets = input.trainingExperience == .beginner ? 3 : 4
//                
//                // Clamp set count to reasonable range
//                let setCount = min(maxSets, max(minSets, setsNeeded))
//                
//                // Create the sets for this exercise
//                let exerciseSets = createSetsForExercise(
//                    exercise: movement,
//                    setCount: setCount,
//                    goal: input.goal,
//                    experience: input.trainingExperience
//                )
//                
//                // Create the exercise instance
//                let exerciseInstance = ExerciseInstanceEntity(
//                    movement: movement,
//                    sets: exerciseSets
//                )
//                
//                // Add to workout
//                workout.exercises.append(exerciseInstance)
//                
//                // Update volume tracking
//                // Primary muscle gets full credit
//                setsCompletedForMuscle[primaryMuscle, default: 0] += Double(setCount)
//                
//                // Secondary muscles get half credit
//                for secondaryMuscle in movement.secondaryMuscles {
//                    if targetMuscles.contains(secondaryMuscle) {
//                        setsCompletedForMuscle[secondaryMuscle, default: 0] += Double(setCount) * 0.5
//                    }
//                }
//            }
//            
//            // Add this workout to our base week
//            baseWeekWorkouts.append(workout)
//        }
//        
//        // STEP 2: Clone and adjust workouts for each week in the plan
//        for weekIndex in 1...weeks {
//            for (dayIndex, baseWorkout) in baseWeekWorkouts.enumerated() {
//                // For week 1, use the base workouts directly
//                if weekIndex == 1 {
//                    // Set the date for this workout
//                    let scheduledDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: plan.startDate)
//                    baseWorkout.scheduledDate = scheduledDate
//                    
//                    // Set training plan reference
//                    baseWorkout.trainingPlan = plan
//                    
//                    // Add to plan
//                    plan.workouts.append(baseWorkout)
//                }
//                // For later weeks, clone and adjust volume
//                else {
//                    // Create a copy of the base workout
//                    var workout = baseWorkout.copy()
//                    
//                    // assign the plan
//                    workout.trainingPlan = plan
//                    
//                    // Adjust volume for the current week
//                    adjustWorkoutVolume(
//                        workout: workout,
//                        goal: input.goal,
//                        week: weekIndex,
//                        totalWeeks: weeks,
//                        experience: input.trainingExperience
//                    )
//                    
//                    // Calculate the date for this workout
//                    let dayOffset = (weekIndex - 1) * 7 + dayIndex
//                    if let scheduledDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: plan.startDate) {
//                        workout.scheduledDate = scheduledDate
//                    }
//                    
//                    // Set training plan reference
//                    workout.trainingPlan = plan
//                    
//                    // Add to plan
//                    plan.workouts.append(workout)
//                }
//            }
//        }
//    }
//    
//    /// Count how many days a muscle is trained per week based on split type
//    private func countTrainingDaysForMuscle(_ muscle: MuscleGroup, split: SplitStyle, daysPerWeek: Int) -> Int {
//        var count = 0
//        
//        for day in 1...daysPerWeek {
//            let dayType = getDayType(day: day, split: split, totalDays: daysPerWeek)
//            let musclesForDay = getMusclesForDayType(dayType)
//            
//            if musclesForDay.contains(muscle) {
//                count += 1
//            }
//        }
//        
//        return max(1, count) // Ensure at least 1 to avoid division by zero
//    }
//    
//    /// Create appropriate sets for an exercise based on training goal and experience
//    private func createSetsForExercise(
//        exercise: MovementEntity,
//        setCount: Int,
//        goal: TrainingGoal,
//        experience: TrainingExperience
//    ) -> [ExerciseSetEntity] {
//        var sets: [ExerciseSetEntity] = []
//        
//        // Get appropriate rep range
//        let (minReps, maxReps) = volumeStrategy.getRepRange(for: goal, experience: experience)
//        
//        // For beginners, use the same rep target for all sets
//        // For intermediate+, create a slight rep drop-off for later sets
//        let repDropPerSet = experience == .beginner ? 0 : 1
//        
//        // Create sets
//        for i in 0..<setCount {
//            // Calculate target reps, reducing slightly for later sets
//            let targetReps = max(minReps, maxReps - (i * repDropPerSet))
//            
//            let set = ExerciseSetEntity(
//                weight: 0, // Weight will be determined during the workout
//                completedReps: 0,
//                targetReps: targetReps,
//                isComplete: false
//            )
//            
//            sets.append(set)
//        }
//        
//        return sets
//    }
//    
//    /// Adjust a workout's volume based on the current week in the plan
//    private func adjustWorkoutVolume(
//        workout: WorkoutEntity,
//        goal: TrainingGoal,
//        week: Int,
//        totalWeeks: Int,
//        experience: TrainingExperience
//    ) {
//        // 📊 Print adjusting workout volume at the very beginning
//        print("📊 Adjusting workout volume for week \(week)")
//        print("Workout title: \(workout.title)")
//        guard let trainingPlan = workout.trainingPlan else {
//            return
//        }
//        
//        
//        // MARK: - Step 1: Analyze current and target volumes for all muscles across the entire week
//        
//        // Track data across the entire week
//        var currentWeeklySetsByMuscle: [MuscleGroup: Int] = [:]
//        var targetWeeklySetsByMuscle: [MuscleGroup: Int] = [:]
//        var muscleStimulationDeficit: [MuscleGroup: Int] = [:]
//        var exercisesByMuscleGroup: [MuscleGroup: [ExerciseInstanceEntity]] = [:]
//        var remainingProgressionAllocation: [MuscleGroup: Int] = [:]
//        
//        // Gather all workouts for the current week
//        let startOfWeek = Calendar.current.date(byAdding: .day, value: (week - 1) * 7, to: trainingPlan.startDate)!
//        let endOfWeek = Calendar.current.date(byAdding: .day, value: week * 7, to: trainingPlan.startDate)!
//
//        print("🔎 Plan start: \(trainingPlan.startDate)")
//        for workout in trainingPlan.workouts {
//            if let date = workout.scheduledDate {
//                let days = Calendar.current.dateComponents([.day], from: trainingPlan.startDate, to: date).day ?? -999
//                print("📅 Workout: \(workout.title), scheduled: \(date), offset: \(days)")
//            } else {
//                print("⚠️ Workout has no scheduledDate")
//            }
//        }
//        
//        let weeklyWorkouts = trainingPlan.workouts.filter {
//            guard let date = $0.scheduledDate else { return false }
//            return date >= startOfWeek && date < endOfWeek && $0 !== workout
//        }
//        let fullWeekWorkouts = weeklyWorkouts + [workout]
//        print("📦 Included current workout in volume analysis. Total workouts now: \(fullWeekWorkouts.count)")
//        print("🗓️ Found \(weeklyWorkouts.count) workouts for week \(week)")
//        
//        // First pass: gather volume data across all workouts
//        for weekWorkout in fullWeekWorkouts {
//            for exercise in weekWorkout.exercises {
//                // Track exercises by primary muscle for later distribution
//                for muscle in exercise.movement.primaryMuscles {
//                    if exercisesByMuscleGroup[muscle] == nil {
//                        exercisesByMuscleGroup[muscle] = []
//                    }
//                    exercisesByMuscleGroup[muscle]?.append(exercise)
//
//                    // Count sets
//                    currentWeeklySetsByMuscle[muscle, default: 0] += exercise.sets.count
//                    print("💪 Primary: \(muscle) -> +\(exercise.sets.count) sets (total so far: \(currentWeeklySetsByMuscle[muscle, default: 0]))")
//
//                    // Calculate target volume for this muscle if not already done
//                    if targetWeeklySetsByMuscle[muscle] == nil {
//                        // Get emphasis status for this muscle
//                        let isEmphasized = isMusclePrioritized(muscle, in: trainingPlan)
//
//                        // Get the base recommendation
//                        let baseRecommendation = volumeStrategy.calculateVolume(
//                            for: muscle,
//                            goal: goal,
//                            experience: experience,
//                            isEmphasized: isEmphasized
//                        )
//
//                        // Calculate target for current week
//                        let weekSets = volumeStrategy.calculateVolumeForWeek(
//                            targetSets: baseRecommendation.setsPerWeek,
//                            currentWeek: week,
//                            totalWeeks: totalWeeks,
//                            isMaintenance: !isEmphasized
//                        )
//
//                        // Calculate how much to scale vs. week 1
//                        let baseWeek1Sets = volumeStrategy.calculateVolumeForWeek(
//                            targetSets: baseRecommendation.setsPerWeek,
//                            currentWeek: 1,
//                            totalWeeks: totalWeeks,
//                            isMaintenance: !isEmphasized
//                        )
//
//                        print("📅 \(muscle): week \(week) target = \(weekSets), week 1 = \(baseWeek1Sets)")
//                        targetWeeklySetsByMuscle[muscle] = weekSets
//                        print("📈 Forced target sets for \(muscle): \(weekSets)")
//                    }
//                }
//
//                // Secondary muscles count for half a set
//                for muscle in exercise.movement.secondaryMuscles {
//                    // Count sets (give half credit for secondary muscles)
//                    let secondarySets = Int(ceil(Double(exercise.sets.count) / 2.0))
//                    currentWeeklySetsByMuscle[muscle, default: 0] += secondarySets
//                    print("🦾 Secondary: \(muscle) -> +\(secondarySets) sets (total so far: \(currentWeeklySetsByMuscle[muscle, default: 0]))")
//
//                    // Calculate target volume for this muscle if not already done
//                    if targetWeeklySetsByMuscle[muscle] == nil {
//                        // Get emphasis status for this muscle
//                        let isEmphasized = isMusclePrioritized(muscle, in: trainingPlan)
//
//                        // Get the base recommendation
//                        let baseRecommendation = volumeStrategy.calculateVolume(
//                            for: muscle,
//                            goal: goal,
//                            experience: experience,
//                            isEmphasized: isEmphasized
//                        )
//
//                        // Calculate target for current week
//                        let weekSets = volumeStrategy.calculateVolumeForWeek(
//                            targetSets: baseRecommendation.setsPerWeek,
//                            currentWeek: week,
//                            totalWeeks: totalWeeks,
//                            isMaintenance: !isEmphasized
//                        )
//
//                        // Calculate how much to scale vs. week 1
//                        let baseWeek1Sets = volumeStrategy.calculateVolumeForWeek(
//                            targetSets: baseRecommendation.setsPerWeek,
//                            currentWeek: 1,
//                            totalWeeks: totalWeeks,
//                            isMaintenance: !isEmphasized
//                        )
//
//                        targetWeeklySetsByMuscle[muscle] = weekSets
//                        print("📈 Forced target sets for \(muscle): \(weekSets)")
//                    }
//                }
//            }
//        }
//        
//        // MARK: - Step 2: Calculate deficits and allocate progression
//        
//        // Calculate weekly stimulation deficits for each muscle
//        for muscle in targetWeeklySetsByMuscle.keys {
//            let target = targetWeeklySetsByMuscle[muscle] ?? 0
//            let current = currentWeeklySetsByMuscle[muscle] ?? 0
//
//            // Only track if there's a deficit
//            if current < target {
//                let deficit = target - current
//                muscleStimulationDeficit[muscle] = deficit
//                remainingProgressionAllocation[muscle] = deficit
//                print("📉 Deficit for \(muscle): \(deficit) sets")
//            }
//        }
//        
//        // MARK: - Step 3: Prioritize progression in the current workout
//        
//        // Sort muscles by deficit (largest first)
//        let musclesSortedByDeficit = muscleStimulationDeficit.keys.sorted {
//            muscleStimulationDeficit[$0] ?? 0 > muscleStimulationDeficit[$1] ?? 0
//        }
//        
//        // Get exercises in the current workout
//        let currentWorkoutExercises = workout.exercises
//        
//        // Group by primary muscle in the current workout
//        var exercisesByPrimaryMuscleInCurrentWorkout: [MuscleGroup: [ExerciseInstanceEntity]] = [:]
//        
//        for exercise in currentWorkoutExercises {
//            for primaryMuscle in exercise.movement.primaryMuscles {
//                if exercisesByPrimaryMuscleInCurrentWorkout[primaryMuscle] == nil {
//                    exercisesByPrimaryMuscleInCurrentWorkout[primaryMuscle] = []
//                }
//                exercisesByPrimaryMuscleInCurrentWorkout[primaryMuscle]?.append(exercise)
//            }
//        }
//        
//        // Allocate progression volume to current workout based on muscle priority
//        for muscle in musclesSortedByDeficit {
//            guard let totalDeficit = muscleStimulationDeficit[muscle],
//                  let remainingDeficit = remainingProgressionAllocation[muscle],
//                  remainingDeficit > 0,
//                  let exercisesForMuscle = exercisesByPrimaryMuscleInCurrentWorkout[muscle],
//                  !exercisesForMuscle.isEmpty else {
//                continue
//            }
//
//            // Determine how many exercises will get progression in this workout
//            let totalExercisesForMuscleAcrossWeek = exercisesByMuscleGroup[muscle]?.count ?? 1
//            let exercisesInCurrentWorkout = exercisesForMuscle.count
//
//            // Calculate fair share of progression for current workout
//            let progressionFraction = Double(exercisesInCurrentWorkout) / Double(totalExercisesForMuscleAcrossWeek)
//            let idealProgressionForWorkout = Int(ceil(Double(totalDeficit) * progressionFraction))
//            let actualProgressionForWorkout = min(idealProgressionForWorkout, remainingDeficit)
//
//            print("🧩 Applying \(actualProgressionForWorkout) set(s) to \(muscle) in this workout (\(exercisesForMuscle.count) exercises)")
//
//            // Distribute progression across exercises for this muscle in current workout
//            var remainingProgressionForWorkout = actualProgressionForWorkout
//
//            for exercise in exercisesForMuscle {
//                if remainingProgressionForWorkout <= 0 {
//                    break
//                }
//
//                // Progress the exercise
//                let wasProgressed = progressExerciseVolumeStrategy(
//                    exercise: exercise,
//                    primaryMuscle: muscle,
//                    goal: goal,
//                    experience: experience
//                )
//
//                if wasProgressed {
//                    print("✅ Progressed exercise: \(exercise.movement.name)")
//                    remainingProgressionForWorkout -= 1
//                    remainingProgressionAllocation[muscle] = remainingProgressionAllocation[muscle]! - 1
//                }
//            }
//        }
//        print("🔚 Done adjusting volume for this workout.")
//    }
//    
//    /// Progress exercise based on optimal strategy
//    /// Returns true if progression was applied successfully
//    private func progressExerciseVolumeStrategy(
//        exercise: ExerciseInstanceEntity,
//        primaryMuscle: MuscleGroup,
//        goal: TrainingGoal,
//        experience: TrainingExperience
//    ) -> Bool {
//        // Determine if this is a bodyweight movement
//        let isBodyweight = exercise.movement.equipment == .bodyweight
//
//        // Get rep range for this exercise
//        let (minReps, maxReps) = volumeStrategy.getRepRange(for: goal, experience: experience)
//
//        // If we can still add sets, prioritize that
//        if exercise.sets.count < 5 {
//            print("➕ Adding new set to exercise: \(exercise.movement.name)")
//            let newSet = exercise.sets.first!.copy()
//            exercise.sets.append(newSet)
//            return true
//        }
//
//        // For bodyweight movements, we can only add reps
//        if isBodyweight {
//            print("📌 Bodyweight movement — attempting to add reps only")
//            let repsProgressed = tryProgressReps(for: exercise, maxReps: maxReps)
//            print("➡️ tryProgressReps result: \(repsProgressed)")
//            return repsProgressed
//        }
//
//        // Check if any set is at or near the upper rep limit
//        let isNearUpperLimit = exercise.sets.contains { set in
//            set.targetReps >= maxReps - 1 // Within 1 rep of max
//        }
//        print("🔍 isNearUpperLimit: \(isNearUpperLimit)")
//
//        // For sets near their upper rep limit, try transitioning to higher weight
//        if isNearUpperLimit {
//            // Try increasing weight and reducing reps
//            let weightProgressed = tryWeightTransition(
//                for: exercise,
//                minReps: minReps,
//                maxReps: maxReps
//            )
//            print("➡️ tryProgressWeight result: \(weightProgressed)")
//            if weightProgressed {
//                return true
//            }
//        }
//
//        // For large muscles, prioritize weight if not near rep limit
//        if primaryMuscle.muscleSize == .large && !isNearUpperLimit {
//            print("🏋️ Large muscle — attempting weight progression")
//            // Try just adding weight first
//            let weightProgressed = tryProgressWeight(for: exercise, minReps: minReps)
//            print("➡️ tryProgressWeight result: \(weightProgressed)")
//            // If we couldn't add weight, try adding reps
//            if !weightProgressed {
//                let repsProgressed = tryProgressReps(for: exercise, maxReps: maxReps)
//                print("➡️ tryProgressReps result: \(repsProgressed)")
//                if repsProgressed {
//                    return true
//                }
//            } else {
//                return true
//            }
//        } else {
//            // For small muscles, prioritize reps if not near rep limit
//            if !isNearUpperLimit {
//                print("💪 Small muscle — attempting rep progression")
//                let repsProgressed = tryProgressReps(for: exercise, maxReps: maxReps)
//                print("➡️ tryProgressReps result: \(repsProgressed)")
//                // If we couldn't add reps, try adding weight
//                if !repsProgressed {
//                    let weightProgressed = tryProgressWeight(for: exercise, minReps: minReps)
//                    print("➡️ tryProgressWeight result: \(weightProgressed)")
//                    if weightProgressed {
//                        return true
//                    }
//                } else {
//                    return true
//                }
//            }
//        }
//
//        return false
//    }
//    
//    /// Try to increase weight by appropriate increment
//    private func tryProgressWeight(
//        for exercise: ExerciseInstanceEntity,
//        minReps: Int
//    ) -> Bool {
//        // Weight increments based on equipment type
//        let weightIncrement = getWeightIncrementForEquipment(exercise.movement.equipment)
//        
//        // Skip if incrementing weight would be too much
//        if weightIncrement <= 0 {
//            return false
//        }
//        
//        // Check if all sets are currently using the same weight
//        let currentWeight = exercise.sets.first?.weight ?? 0
//        let allSameWeight = exercise.sets.allSatisfy { $0.weight == currentWeight }
//        
//        // Only progress if all sets have the same weight currently
//        if allSameWeight {
//            // Calculate new weight
//            let newWeight = currentWeight + weightIncrement
//            
//            // Calculate expected rep decrease using one-rep max formula
//            for set in exercise.sets {
//                // Use Epley formula: weight * (1 + reps/30)
//                let currentOneRM = currentWeight * (1.0 + Double(set.targetReps) / 30.0)
//                
//                // Calculate new reps that would match the same one-rep max
//                let estimatedNewReps = 30 * ((currentOneRM / newWeight) - 1)
//                let newTargetReps = max(minReps, Int(floor(estimatedNewReps)))
//                
//                // Only increment weight if estimated reps would be at or above minimum
//                if newTargetReps >= minReps {
//                    // Apply new weight and adjust target reps
//                    set.weight = newWeight
//                    set.targetReps = newTargetReps
//                } else {
//                    // If we would drop below minimum rep range, don't increase weight
//                    return false
//                }
//            }
//            return true
//        }
//        
//        return false
//    }
//    
//    /// Transition from high reps to higher weight with lower reps
//    private func tryWeightTransition(
//        for exercise: ExerciseInstanceEntity,
//        minReps: Int,
//        maxReps: Int
//    ) -> Bool {
//        // Weight increments based on equipment type
//        let weightIncrement = getWeightIncrementForEquipment(exercise.movement.equipment)
//        
//        // Skip if incrementing weight would be too much
//        if weightIncrement <= 0 {
//            return false
//        }
//        
//        // Check if all sets are currently using the same weight
//        let currentWeight = exercise.sets.first?.weight ?? 0
//        let allSameWeight = exercise.sets.allSatisfy { $0.weight == currentWeight }
//        
//        // Only progress if all sets have the same weight currently
//        if allSameWeight {
//            // Calculate new weight
//            let newWeight = currentWeight + weightIncrement
//            
//            // Find sets at or near max reps
//            let highRepSets = exercise.sets.filter { $0.targetReps >= maxReps - 1 }
//            
//            // Skip if no sets are near max reps
//            if highRepSets.isEmpty {
//                return false
//            }
//            
//            // Transition all high-rep sets to higher weight, lower reps
//            for set in highRepSets {
//                // Use Epley formula: weight * (1 + reps/30)
//                let currentOneRM = currentWeight * (1.0 + Double(set.targetReps) / 30.0)
//                
//                // Calculate new reps that would match the same one-rep max
//                let estimatedNewReps = 30 * ((currentOneRM / newWeight) - 1)
//                
//                // Target the middle of the rep range
//                let targetRepRange = minReps + Int((maxReps - minReps) / 2)
//                let newTargetReps = max(minReps, min(targetRepRange, Int(floor(estimatedNewReps))))
//                
//                // Only transition if estimated reps would be at or above minimum
//                if newTargetReps >= minReps {
//                    // Apply new weight and adjust target reps
//                    set.weight = newWeight
//                    set.targetReps = newTargetReps
//                } else {
//                    // If we would drop below minimum rep range, don't transition
//                    return false
//                }
//            }
//            return true
//        }
//        
//        return false
//    }
//    
//    /// Try to increase reps by 1 if within rep range
//    private func tryProgressReps(
//        for exercise: ExerciseInstanceEntity,
//        maxReps: Int
//    ) -> Bool {
//        // Check if any sets can have reps increased
//        for set in exercise.sets {
//            // Skip if the set is already at max rep count
//            if set.targetReps >= maxReps {
//                continue
//            }
//            
//            // Increase reps by 1 if we're not at max rep range
//            set.targetReps += 1
//            return true
//        }
//        
//        return false
//    }
//    
//    /// Determine if a muscle is prioritized in the training plan
//    private func isMusclePrioritized(_ muscle: MuscleGroup, in plan: TrainingPlanEntity?) -> Bool {
//        guard let preferences = plan?.musclePreferences else {
//            return false
//        }
//        
//        for preference in preferences {
//            if preference.muscleGroup == muscle && preference.goal == .grow {
//                return true
//            }
//        }
//        
//        return false
//    }
//    
//    /// Progress an exercise intelligently based on muscle size and equipment type
//    /// Returns true if progression was applied successfully
//    private func progressExercise(
//        exercise: ExerciseInstanceEntity,
//        primaryMuscle: MuscleGroup,
//        goal: TrainingGoal,
//        week: Int,
//        experience: TrainingExperience
//    ) -> Bool {
//        // Check if we already modified sets or reps for this exercise
//        var wasProgressed = false
//        
//        // Determine if this is a bodyweight movement
//        let isBodyweight = exercise.movement.equipment == .bodyweight
//        
//        // For bodyweight movements, we can only add reps
//        if isBodyweight {
//            // Only add reps for bodyweight movements if within range
//            wasProgressed = tryProgressReps(for: exercise, goal: goal, experience: experience)
//            return wasProgressed
//        }
//        
//        // For weighted movements, follow muscle size based progression
//        if primaryMuscle.muscleSize == .large {
//            // For large muscles, prioritize weight increases
//            wasProgressed = tryProgressWeight(for: exercise, goal: goal, experience: experience)
//            
//            // If we couldn't add weight, try adding reps instead
//            if !wasProgressed {
//                wasProgressed = tryProgressReps(for: exercise, goal: goal, experience: experience)
//            }
//        } else {
//            // For small muscles, prioritize rep increases
//            wasProgressed = tryProgressReps(for: exercise, goal: goal, experience: experience)
//            
//            // If we couldn't add reps, try adding weight instead
//            if !wasProgressed {
//                wasProgressed = tryProgressWeight(for: exercise, goal: goal, experience: experience)
//            }
//        }
//        
//        // If we couldn't progress either weight or reps, consider adding a set
//        if !wasProgressed && exercise.sets.count < 5 {
//            // Add a full set if we couldn't progress weight or reps
//            let newSet = exercise.sets.first!.copy()
//            exercise.sets.append(newSet)
//            wasProgressed = true
//        }
//        
//        return wasProgressed
//    }
//    
//    /// Try to increase weight based on equipment type
//    private func tryProgressWeight(
//        for exercise: ExerciseInstanceEntity,
//        goal: TrainingGoal,
//        experience: TrainingExperience
//    ) -> Bool {
//        // Weight increments based on equipment type
//        let weightIncrement = getWeightIncrementForEquipment(exercise.movement.equipment)
//        
//        // Skip if incrementing weight would be too much
//        if weightIncrement <= 0 {
//            return false
//        }
//        
//        // Check if all sets are currently using the same weight
//        let currentWeight = exercise.sets.first?.weight ?? 0
//        let allSameWeight = exercise.sets.allSatisfy { $0.weight == currentWeight }
//        
//        // Only progress if all sets have the same weight currently
//        if allSameWeight {
//            // Calculate new weight
//            let newWeight = currentWeight + weightIncrement
//            
//            // Get appropriate rep range for this exercise
//            let (minReps, _) = volumeStrategy.getRepRange(for: goal, experience: experience)
//            
//            // Calculate expected rep decrease using one-rep max formula
//            for set in exercise.sets {
//                // Use Epley formula: weight * (1 + reps/30)
//                let currentOneRM = currentWeight * (1.0 + Double(set.targetReps) / 30.0)
//                
//                // Calculate new reps that would match the same one-rep max
//                // weight = oneRM / (1 + reps/30)
//                // => weight * (1 + reps/30) = oneRM
//                // => 1 + reps/30 = oneRM / weight
//                // => reps/30 = (oneRM / weight) - 1
//                // => reps = 30 * ((oneRM / weight) - 1)
//                let estimatedNewReps = 30 * ((currentOneRM / newWeight) - 1)
//                let newTargetReps = max(minReps, Int(floor(estimatedNewReps)))
//                
//                // Only increment weight if estimated reps would be at or above minimum
//                if newTargetReps >= minReps {
//                    // Apply new weight and adjust target reps
//                    set.weight = newWeight
//                    set.targetReps = newTargetReps
//                } else {
//                    // If we would drop below minimum rep range, don't increase weight
//                    return false
//                }
//            }
//            return true
//        }
//        
//        return false
//    }
//    
//    /// Try to increase reps
//    private func tryProgressReps(
//        for exercise: ExerciseInstanceEntity,
//        goal: TrainingGoal,
//        experience: TrainingExperience
//    ) -> Bool {
//        // Get appropriate rep range for this exercise
//        let (_, maxReps) = volumeStrategy.getRepRange(for: goal, experience: experience)
//        
//        // Check if adding 1 rep would exceed rep range for the goal
//        for set in exercise.sets {
//            // Skip if the set is already at max rep count for the goal
//            if set.targetReps >= maxReps {
//                continue
//            }
//            
//            // Increase reps by 1 if we're not at max rep range
//            set.targetReps += 1
//            return true
//        }
//        
//        return false
//    }
//    
//    /// Get the appropriate weight increment based on equipment type
//    private func getWeightIncrementForEquipment(_ equipment: EquipmentType) -> Double {
//        switch equipment {
//        case .barbell:
//            return 5.0
//        case .dumbbell:
//            return 2.5
//        case .machine:
//            return 2.5
//        case .cable:
//            return 2.5
//        case .bodyweight:
//            return 0.0 // Cannot increment weight for bodyweight exercises
//        }
//    }
//    
//    /// Determine if a movement is technically complex (not ideal for beginners)
//    private func isTechnicalMovement(_ movement: MovementEntity) -> Bool {
//        // Examples of technical movements to avoid for beginners
//        let technicalMovements: [MovementType] = [
//            //.snatch, .clean, .jerk, // Olympic lifts
//            .barbellDeadlift, // Complex compound
//            .barbellFrontSquat, // Technical barbell position
//            .romanianDeadlift // Technical hinge pattern
//            // Add more as needed
//        ]
//        
//        return technicalMovements.contains(movement.movementType)
//    }
//    
//    /// Determine workout day type based on split style
//    private func getDayType(day: Int, split: SplitStyle, totalDays: Int) -> WorkoutDayType {
//        switch split {
//        case .fullBody:
//            return .fullBody
//        case .upperLower:
//            return day % 2 == 0 ? .upper : .lower
//        case .pushPullLegs:
//            let dayMod = day % 3
//            if dayMod == 1 { return .push }
//            if dayMod == 2 { return .pull }
//            return .legs
//        }
//    }
//    
//    /// Convert day type to workout name
//    private func dayTypeToName(_ dayType: WorkoutDayType) -> String {
//        switch dayType {
//        case .fullBody: return "Full Body Workout"
//        case .upper: return "Upper Body Workout"
//        case .lower: return "Lower Body Workout"
//        case .push: return "Push Workout"
//        case .pull: return "Pull Workout"
//        case .legs: return "Legs Workout"
//        }
//    }
//    
//    /// Converts prioritized muscle groups to MuscleTrainingPreference objects
//    /// - Parameter prioritizedMuscles: Array of muscle groups the user wants to prioritize
//    /// - Returns: Array of MuscleTrainingPreference objects with appropriate goals
//    private func convertToMusclePreferences(from prioritizedMuscles: [MuscleGroup]) -> [MuscleTrainingPreference] {
//        // Create a set for easy lookup of prioritized muscles
//        let prioritySet = Set(prioritizedMuscles)
//        
//        // Create a preference for each muscle group
//        return MuscleGroup.allCases.map { muscle in
//            let goal: MuscleGoal = prioritySet.contains(muscle) ? .grow : .maintain
//            return MuscleTrainingPreference(muscleGroup: muscle, goal: goal)
//        }
//    }
//    
//    /// Calculate appropriate volume for a muscle group in a specific week
//    /// - Parameters:
//    ///   - muscleGroup: The muscle group to calculate volume for
//    ///   - goal: Training goal (hypertrophy or strength)
//    ///   - isEmphasized: Whether this muscle is prioritized
//    ///   - week: Current week number (1-based)
//    ///   - totalWeeks: Total weeks in the plan
//    ///   - trainingExperience: User's training experience level
//    /// - Returns: Number of sets to assign for this muscle in this week
//    func calculateSetsForMuscle(
//        _ muscleGroup: MuscleGroup,
//        goal: TrainingGoal,
//        isEmphasized: Bool,
//        week: Int,
//        totalWeeks: Int,
//        trainingExperience: TrainingExperience
//    ) -> Int {
//        let strategy = StandardVolumeRampStrategy()
//        
//        // Get the baseline recommendation
//        let recommendation = strategy.calculateVolume(
//            for: muscleGroup,
//            goal: goal,
//            experience: trainingExperience,
//            isEmphasized: isEmphasized
//        )
//        
//        return strategy.calculateVolumeForWeek(
//            targetSets: recommendation.setsPerWeek,
//            currentWeek: week,
//            totalWeeks: totalWeeks,
//            isMaintenance: goal == .strength || !isEmphasized
//        )
//    }
//    
//    /// Get muscles targeted on a specific day type
//    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
//        switch dayType {
//        case .fullBody:
//            return MuscleGroup.allCases
//        case .upper:
//            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
//        case .lower:
//            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
//        case .push:
//            return [.chest, .shoulders, .triceps]
//        case .pull:
//            return [.back, .biceps, .forearms, .traps]
//        case .legs:
//            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
//        }
//    }
//    
//    /// Determine appropriate number of exercises based on workout duration
//    private func getExerciseCountForDuration(_ duration: WorkoutDuration) -> Int {
//        switch duration {
//        case .short: return 4
//        case .medium: return 6
//        case .long: return 8
//        }
//    }
//    
//    /// Determine if a movement is a compound exercise (uses multiple major muscle groups)
//    private func isCompoundMovement(_ movement: MovementEntity) -> Bool {
//        // Compound movements typically involve multiple joints and muscle groups
//        // A simple heuristic is to check if it has 2+ secondary muscles or specific movement types
//        
//        let compoundMovementTypes: [MovementType] = [
//            .barbellBenchPress, .barbellDeadlift, .barbellBackSquat, .barbellFrontSquat,
//            .overheadPress, .pullUps, .chinUps, .dips, .bentOverRow, .romanianDeadlift
//        ]
//        
//        // Either has a compound movement type or has multiple secondary muscles
//        return compoundMovementTypes.contains(movement.movementType) || movement.secondaryMuscles.count >= 2
//    }
//    
//    /// Get the primary muscle for a movement (first in the primaryMuscles array)
//    private func getPrimaryMuscle(_ movement: MovementEntity) -> MuscleGroup {
//        return movement.primaryMuscles.first ?? .unknown
//    }
//}
//
///// Types of workout days based on muscle targeting
//enum WorkoutDayType {
//    case fullBody
//    case upper
//    case lower
//    case push
//    case pull
//    case legs
//}
//
///// Volume recommendation for a muscle group
//struct VolumeRecommendation {
//    /// Total sets per week
//    let setsPerWeek: Int
//    
//    /// Lower bound of rep range
//    let repRangeLower: Int
//    
//    /// Upper bound of rep range
//    let repRangeUpper: Int
//    
//    /// Relative intensity (percentage of 1RM)
//    let intensity: Double
//}
//
//// MARK: - Builder Protocols
//
///// Protocol for building workouts based on user constraints
//protocol WorkoutBuilder {
//    /// Build a workout targeting specific muscles with available equipment
//    func buildWorkout(
//        for dayType: WorkoutDayType,
//        prioritizedMuscles: [MuscleGroup],
//        equipment: [EquipmentType],
//        duration: WorkoutDuration
//    ) -> WorkoutEntity
//}
//
///// Protocol for selecting appropriate exercises based on constraints
//protocol ExerciseSelector {
//    /// Select exercises that target specified muscles with available equipment
//    func selectExercises(
//        targeting: [MuscleGroup],
//        withPriority: [MuscleGroup],
//        availableEquipment: [EquipmentType],
//        exerciseCount: Int
//    ) -> [MovementEntity]
//}
//
//// MARK: - Default Implementations
//
///// Default implementation of the workout builder
//class DefaultWorkoutBuilder: WorkoutBuilder {
//    private let exerciseSelector: ExerciseSelector
//    
//    init(exerciseSelector: ExerciseSelector) {
//        self.exerciseSelector = exerciseSelector
//    }
//    
//    func buildWorkout(
//        for dayType: WorkoutDayType,
//        prioritizedMuscles: [MuscleGroup],
//        equipment: [EquipmentType],
//        duration: WorkoutDuration
//    ) -> WorkoutEntity {
//        // Determine target muscles based on day type
//        let targetMuscles = getMusclesForDayType(dayType)
//        let exerciseCount = getExerciseCountForDuration(duration)
//        
//        // Select appropriate exercises
//        let selectedExercises = exerciseSelector.selectExercises(
//            targeting: targetMuscles,
//            withPriority: prioritizedMuscles,
//            availableEquipment: equipment,
//            exerciseCount: exerciseCount
//        )
//        
//        // Create workout description
//        let workoutName = dayTypeToName(dayType)
//        let workoutDescription = "Targets: " + targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", ")
//        
//        // Create and return a workout entity
//        return WorkoutEntity(
//            title: workoutName,
//            description: workoutDescription,
//            isComplete: false
//        )
//    }
//    
//    /// Convert day type to workout name
//    private func dayTypeToName(_ dayType: WorkoutDayType) -> String {
//        switch dayType {
//        case .fullBody: return "Full Body Workout"
//        case .upper: return "Upper Body Workout"
//        case .lower: return "Lower Body Workout"
//        case .push: return "Push Workout"
//        case .pull: return "Pull Workout"
//        case .legs: return "Legs Workout"
//        }
//    }
//    
//    /// Get muscles targeted on a specific day type
//    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
//        switch dayType {
//        case .fullBody:
//            return MuscleGroup.allCases
//        case .upper:
//            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
//        case .lower:
//            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
//        case .push:
//            return [.chest, .shoulders, .triceps]
//        case .pull:
//            return [.back, .biceps, .forearms, .traps]
//        case .legs:
//            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
//        }
//    }
//    
//    /// Determine appropriate number of exercises based on workout duration
//    private func getExerciseCountForDuration(_ duration: WorkoutDuration) -> Int {
//        switch duration {
//        case .short: return 4
//        case .medium: return 6
//        case .long: return 8
//        }
//    }
//}
//
//
//
///// New plan generator:
//
