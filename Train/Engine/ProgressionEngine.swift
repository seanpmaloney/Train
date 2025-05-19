/**
 * @file ProgressionEngine.swift
 * @brief Applies feedback-driven progression logic to structured weekly workouts.
 *
 * The ProgressionEngine is responsible for intelligently adjusting training volume based on a user's feedback and performance.
 * It uses principles from hypertrophy-focused training to optimize long-term muscle growth while minimizing risk of overtraining.
 *
 * ### Intended Behavior:
 * - Adds up to +2 total sets per muscle per week across all workouts if:
 *   - The muscle is prioritized in the plan
 *   - Current volume is below the hypertrophy upper bound
 *   - No soreness, pain, or fatigue-related feedback blocks progression
 * - Soreness:
 *   - If a muscle is sore *and being trained that day*, one set is removed from the previous workout that caused the soreness, in the following week of the plan.
 *     This is to ensure that when the next week comes around, the user is not still sore on the day that they need to train the muscle again
 * - Joint Pain:
 *   - Flags next week's exercises that target muscles near the affected joint.
 *   - Block progression for those muscles and flag the UI for user awareness.
 * - Fatigue:
 *   - If a workout receives `.completelyDrained` feedback, 2 sets are removed from high-volume exercises in that workout next week.
 *   - That workout is skipped during volume progression.
 * - "Too Much" Feedback:
 *   - If a user gives `.tooMuch` feedback on an exercise, that exercise loses 1 set in the same slot next week (if > 1 set).
 *   - No new sets will be added to it.
 *
 * ### Usage:
 * - The engine is triggered once per week after the final workout of that week is completed.
 * - It receives two consecutive weeks of workouts via a 2D array (`weeklyWorkouts[week][day]`).
 * - Feedback is attached directly to the `WorkoutEntity` and `ExerciseInstanceEntity` types.
 * - Progression is applied only to the second week in the input array.
 *
 */
import Foundation

/// ProgressionEngine applies feedback-driven training progression to workouts
/// Based on scientific principles of progressive overload for hypertrophy
@MainActor
struct ProgressionEngine {
    
    // MARK: - Models
    
    /// Represents the progression result for a muscle group
    struct MuscleProgression {
        let muscle: MuscleGroup
        var setsAdded: Int = 0
        var setsRemoved: Int = 0
        var isProgressing: Bool { setsAdded > 0 }
        var isRegressing: Bool { setsRemoved > 0 }
        var netChange: Int { setsAdded - setsRemoved }
    }
    
    /// Warning applied to movements affected by joint pain
    struct JointWarning {
        let painArea: JointArea
        let affectedMuscles: [MuscleGroup]
        let severity: Int // 1-3 scale
    }
    
    // MARK: - Public API
    
    /// Apply progression to next week's workouts based on current week's feedback
    /// - Parameters:
    ///   - weeklyWorkouts: 2D array of workouts organized by [week][day]
    ///   - debug: Whether to output debug information
    /// - Returns: A detailed log of progression changes
    @discardableResult
    static func applyProgression(
        to weeklyWorkouts: inout [[WorkoutEntity]],
        debug: Bool = false
    ) -> [String] {
        guard weeklyWorkouts.count >= 2 else {
            if debug { print("DEBUG: Need at least 2 weeks of workouts to apply progression") }
            return ["Need at least 2 weeks of workouts to apply progression"]
        }
        
        var progressionLog = [String]()
        var muscleProgressions = [MuscleGroup: MuscleProgression]()
        
        // Use the first two week indices provided in the array
        // First one is current week, second is next week
        let currentWeekIndex = 0 // Current week
        let nextWeekIndex = 1    // Next week
        
        // Get the workouts for analysis
        let currentWeek = weeklyWorkouts[currentWeekIndex]
        var nextWeek = weeklyWorkouts[nextWeekIndex]
        
        if debug {
            progressionLog.append("Starting progression analysis")
            progressionLog.append("Current week has \(currentWeek.count) workouts")
            progressionLog.append("Next week has \(nextWeek.count) workouts")
        }
        
        // 1. Calculate current volume by muscle group
        let currentVolume = calculateVolumeByMuscle(from: currentWeek)
        
        // 2. Initialize muscle progressions with target information
        for (muscle, volume) in currentVolume {
            let hypertrophyRange = muscle.trainingGuidelines.hypertrophySetsRange
            var progression = MuscleProgression(muscle: muscle)
            
            // Only progress if under the upper bound and muscle can be trained more
            if volume < hypertrophyRange.upperBound {
                if debug {
                    progressionLog.append("Muscle \(muscle.rawValue) at \(volume) sets, target range \(hypertrophyRange.lowerBound)-\(hypertrophyRange.upperBound)")
                }
                muscleProgressions[muscle] = progression
            } else {
                if debug {
                    progressionLog.append("Muscle \(muscle.rawValue) already at or above upper target (\(volume) sets)")
                }
            }
        }
        
        // 1. Process soreness feedback
        processSorenessFeedback(
            forCurrentWeek: currentWeek,
            nextWeek: &nextWeek,
            muscleProgressions: &muscleProgressions,
            log: &progressionLog,
            debug: debug
        )
        
        // 2. Process joint pain feedback
        let jointWarnings = processJointPainFeedback(
            forCurrentWeek: currentWeek,
            nextWeek: &nextWeek,
            log: &progressionLog,
            debug: debug
        )
        
        // 3. Process complete fatigue feedback and track which workouts had sets reduced
        let fatigueReducedWorkouts = processFatigueFeedback(
            forCurrentWeek: currentWeek,
            nextWeek: &nextWeek,
            log: &progressionLog,
            debug: debug
        )
        
        if debug && !fatigueReducedWorkouts.isEmpty {
            progressionLog.append("FATIGUE: \(fatigueReducedWorkouts.count) workouts had sets reduced due to fatigue")
        }
        
        // 4. Apply volume progression for muscles under their targets
        applyVolumeProgression(
            fromCurrentWeek: currentWeek,
            toNextWeek: &nextWeek,
            currentVolume: currentVolume,
            muscleProgressions: &muscleProgressions,
            jointWarnings: jointWarnings,
            fatigueReducedWorkouts: fatigueReducedWorkouts,
            log: &progressionLog,
            debug: debug
        )
        
        // 5. Apply weight progression based on feedback
        applyWeightProgression(
            fromCurrentWeek: currentWeek,
            toNextWeek: &nextWeek,
            log: &progressionLog,
            debug: debug
        )
        
        // Update the workouts array with our modified next week
        weeklyWorkouts[nextWeekIndex] = nextWeek
        
        if debug {
            progressionLog.append("Progression complete")
        }
        
        return progressionLog
    }
    
    // MARK: - Private Implementation
    
    /// Calculates total weekly volume per muscle group, with secondary muscles counting at 0.5 sets
    private static func calculateVolumeByMuscle(from workouts: [WorkoutEntity]) -> [MuscleGroup: Int] {
        var volumeByMuscle = [MuscleGroup: Int]()
        
        for workout in workouts {
            for exercise in workout.exercises {
                let setCount = exercise.sets.count
                
                // Add full credit for primary muscles
                for muscle in exercise.movement.primaryMuscles {
                    volumeByMuscle[muscle, default: 0] += setCount
                }
                
                // Add half credit for secondary muscles
                for muscle in exercise.movement.secondaryMuscles {
                    volumeByMuscle[muscle, default: 0] += Int(round(Double(setCount) * 0.5))
                }
            }
        }
        
        return volumeByMuscle
    }
    
    /// Process soreness feedback and adjust next week's workouts
    /// When a muscle is reported sore before a workout, finds the previous workout that trained
    /// that muscle and removes a set from it in the next week
    private static func processSorenessFeedback(
        forCurrentWeek currentWeek: [WorkoutEntity],
        nextWeek: inout [WorkoutEntity],
        muscleProgressions: inout [MuscleGroup: MuscleProgression],
        log: inout [String],
        debug: Bool
    ) {
        // Track which muscles have been reported sore and in which workout
        var soreMuscleReports = [MuscleGroup: [WorkoutEntity]]()
        
        // Track muscles we've already reduced sets for (to avoid multiple reductions per week)
        var processedMuscles = Set<MuscleGroup>()
        
        // Sort workouts chronologically by date for proper sequencing
        let sortedCurrentWeek = currentWeek.sorted { w1, w2 in
            guard let d1 = w1.scheduledDate, let d2 = w2.scheduledDate else { return false }
            return d1 < d2
        }
        
        // 1. First pass: Collect information about which muscles are trained in each workout
        // Build a map of muscle → workouts that train it
        var workoutsByMuscle = [MuscleGroup: [WorkoutEntity]]()
        
        for workout in sortedCurrentWeek {
            for exercise in workout.exercises {
                for muscle in exercise.movement.primaryMuscles {
                    if !workoutsByMuscle[muscle, default: []].contains(where: { $0.id == workout.id }) {
                        workoutsByMuscle[muscle, default: []].append(workout)
                    }
                }
            }
        }
        
        // 2. Second pass: Collect soreness reports from pre-workout feedback
        for workout in sortedCurrentWeek {
            // Get pre-workout feedback directly from the workout entity
            if let preFeedback = workout.preWorkoutFeedback {
                for soreMuscle in preFeedback.soreMuscles {
                    // Add this workout to the list of workouts where this muscle was reported sore
                    if !soreMuscleReports[soreMuscle, default: []].contains(where: { $0.id == workout.id }) {
                        soreMuscleReports[soreMuscle, default: []].append(workout)
                    }
                }
            }
        }
        
        // 3. Third pass: Find soreness reports and which workouts they affect
        for workout in sortedCurrentWeek {
            // Get scheduled date and feedbacks
            guard let workoutDate = workout.scheduledDate else { continue }
            let feedbacks: [WorkoutFeedback] = {
                var all: [WorkoutFeedback] = []
                if let pre = workout.preWorkoutFeedback {
                    all.append(pre)
                }
                all.append(contentsOf: workout.exercises.compactMap { $0.feedback })
                if let post = workout.postWorkoutFeedback {
                    all.append(post)
                }
                return all
            }()
            
            // Get pre-workout feedback with soreness reports
            let soreMuscles = feedbacks.compactMap { feedback -> [MuscleGroup]? in
                if let preFeedback = feedback as? PreWorkoutFeedback {
                    return preFeedback.soreMuscles
                }
                return nil
            }.flatMap { $0 }
            
            if debug && !soreMuscles.isEmpty {
                log.append("SORENESS: Workout \(workout.title) reported soreness in: \(soreMuscles.map { $0.rawValue }.joined(separator: ", "))")
            }
            
            // For each sore muscle being trained in this workout
            for soreMuscle in soreMuscles {
                // Skip if we've already processed this muscle this week
                if processedMuscles.contains(soreMuscle) { continue }
                
                // Check if this workout trains the sore muscle
                let trainsThisMuscle = workout.exercises.contains { exercise in
                    exercise.movement.primaryMuscles.contains(soreMuscle)
                }
                
                // If this workout trains the sore muscle, we need to find a previous workout
                // that also trains it and reduce sets there
                if trainsThisMuscle {
                    if debug {
                        log.append("SORENESS: \(soreMuscle.rawValue) is trained in \(workout.title) and was reported sore")
                    }
                    
                    // Get all workouts that train this muscle
                    let trainingWorkouts = workoutsByMuscle[soreMuscle, default: []]
                    
                    // Find an earlier workout in the week that also trains this muscle
                    let previousTrainingWorkouts = trainingWorkouts.filter { w in
                        guard let date = w.scheduledDate else { return false }
                        return date < workoutDate && w.id != workout.id
                    }
                    
                    if let previousWorkout = previousTrainingWorkouts.sorted(by: {
                        guard let d1 = $0.scheduledDate, let d2 = $1.scheduledDate else { return false }
                        return d1 > d2 // Sort most recent first
                    }).first {
                        // Found a previous workout - reduce sets in the next week's corresponding workout
                        if let previousWorkoutIndex = sortedCurrentWeek.firstIndex(where: { $0.id == previousWorkout.id }),
                           previousWorkoutIndex < nextWeek.count {
                            
                            // Get the next week's corresponding workout
                            var nextWeekPreviousWorkout = nextWeek[previousWorkoutIndex]
                            
                            // Find exercises in this workout that train the sore muscle
                            let exercisesForMuscle = previousWorkout.exercises.filter { exercise in
                                exercise.movement.primaryMuscles.contains(soreMuscle)
                            }
                            
                            if let exerciseToReduce = exercisesForMuscle.first {
                                // Find the corresponding exercise in next week's workout
                                if let exerciseIndex = nextWeekPreviousWorkout.exercises.firstIndex(where: {
                                    $0.movement.name == exerciseToReduce.movement.name
                                }) {
                                    var updatedExercise = nextWeekPreviousWorkout.exercises[exerciseIndex]
                                    
                                    // Only reduce if the exercise has more than one set
                                    if updatedExercise.sets.count > 1 {
                                        updatedExercise.sets.removeLast()
                                        nextWeek[previousWorkoutIndex].exercises[exerciseIndex] = updatedExercise
                                        
                                        // Update progression tracking
                                        if var progression = muscleProgressions[soreMuscle] {
                                            progression.setsRemoved += 1
                                            muscleProgressions[soreMuscle] = progression
                                            processedMuscles.insert(soreMuscle)
                                            
                                            if debug {
                                                log.append("SORENESS: Removed 1 set from \(exerciseToReduce.movement.name) in previous workout '\(previousWorkout.title)' due to soreness in \(soreMuscle.rawValue)")
                                            }
                                        }
                                    } else if debug {
                                        log.append("SORENESS: Cannot reduce sets in \(exerciseToReduce.movement.name) - only 1 set available")
                                    }
                                }
                            }
                        }
                    } else if debug {
                        log.append("SORENESS: No previous workout found that trains \(soreMuscle.rawValue)")
                    }
                } else if debug {
                    log.append("SORENESS: No previous workout found that trains \(soreMuscle.rawValue)")
                }
            }
        }
    }
    
    /// Process joint pain feedback and flag exercises that might aggravate the pain
    private static func processJointPainFeedback(
        forCurrentWeek currentWeek: [WorkoutEntity],
        nextWeek: inout [WorkoutEntity],
        log: inout [String],
        debug: Bool
    ) -> [JointWarning] {
        var jointWarnings = [JointWarning]()
        var reportedJointPain = Set<JointArea>()
        
        // Collect all joint pain reports
        for workout in currentWeek {
            if let preFeedback = workout.preWorkoutFeedback {
                reportedJointPain.formUnion(preFeedback.jointPainAreas)
            }
        }
        
        // If no joint pain reported, return empty
        if reportedJointPain.isEmpty {
            return []
        }
        
        // Create warnings based on reported pain
        for jointArea in reportedJointPain {
            let affectedMuscles: [MuscleGroup]
            
            // Determine affected muscles based on joint area
            switch jointArea {
            case .knee:
                affectedMuscles = [.quads, .hamstrings, .calves]
            case .shoulder:
                affectedMuscles = [.chest, .shoulders, .back, .triceps]
            case .elbow:
                affectedMuscles = [.biceps, .triceps, .forearms]
            }
            
            // Add warning with severity of 2 (moderate)
            jointWarnings.append(JointWarning(
                painArea: jointArea,
                affectedMuscles: affectedMuscles,
                severity: 2
            ))
            
            // Flag all affected movements in next week's workouts
            for i in 0..<nextWeek.count {
                for j in 0..<nextWeek[i].exercises.count {
                    let exercise = nextWeek[i].exercises[j]
                    let targetedMuscles = Set(exercise.movement.primaryMuscles + exercise.movement.secondaryMuscles)
                    
                    // Check if exercise targets any affected muscles
                    if !targetedMuscles.isDisjoint(with: Set(affectedMuscles)) {
                        // Flag the exercise with joint warning
                        var updatedExercise = exercise
                        updatedExercise.shouldShowJointWarning = true
                        nextWeek[i].exercises[j] = updatedExercise
                        
                        if debug {
                            log.append("JOINT PAIN: Flagged \(exercise.movement.name) with warning for \(jointArea.rawValue) pain")
                        }
                    }
                }
            }
        }
        
        return jointWarnings
    }
    
    /// Process fatigue feedback and reduce sets in high-volume exercises for completely drained sessions
    /// - Returns: Set of workout IDs that had sets removed due to fatigue
    private static func processFatigueFeedback(
        forCurrentWeek currentWeek: [WorkoutEntity],
        nextWeek: inout [WorkoutEntity],
        log: inout [String],
        debug: Bool
    ) -> Set<UUID> {
        // Track which workouts had sets reduced due to fatigue
        var fatigueReducedWorkouts = Set<UUID>()
        // Find matching workout pairs (current week → next week)
        for (currentIndex, currentWorkout) in currentWeek.enumerated() {
            // Ensure we don't go out of bounds
            guard currentIndex < nextWeek.count else { continue }
            
            // Get post-workout feedback directly from the workout entity
            let isCompletelyDrained = currentWorkout.postWorkoutFeedback?.sessionFatigue == .completelyDrained
            
            // Skip if not completely drained
            guard isCompletelyDrained else { continue }
            
            // Get the corresponding workout in next week
            var nextWorkout = nextWeek[currentIndex]
            
            if debug {
                log.append("FATIGUE: Workout \(currentWorkout.title) reported completely drained, removing 2 sets")
            }
            
            // Identify exercises with the most sets
            let sortedExercises = nextWorkout.exercises.sorted { $0.sets.count > $1.sets.count }
            
            // We need to remove 2 sets total
            var setsToRemove = 2
            var exercisesToModify = [UUID: Int]() // [exerciseId: setsToRemove]
            
            // First pass: identify which exercises to remove sets from
            for exercise in sortedExercises {
                guard setsToRemove > 0 else { break }
                
                // Only remove sets if exercise has more than 1 set
                if exercise.sets.count > 1 {
                    // Remove 1 set at a time
                    exercisesToModify[exercise.id] = 1
                    setsToRemove -= 1

                    // If we need another set and this exercise still has enough, take another
                    if setsToRemove > 0 && exercise.sets.count > 2 {
                        exercisesToModify[exercise.id] = 2
                        setsToRemove -= 1
                    }
                }
            }
            
            // Second pass: apply the changes
            for i in 0..<nextWorkout.exercises.count {
                if let setsToRemove = exercisesToModify[nextWorkout.exercises[i].id] {
                    var exercise = nextWorkout.exercises[i]
                    
                    // Remove the specified number of sets
                    for _ in 0..<setsToRemove {
                        exercise.sets.removeLast()
                    }
                    
                    // Update the exercise
                    nextWorkout.exercises[i] = exercise
                    
                    // Mark this workout as fatigue-reduced
                    fatigueReducedWorkouts.insert(nextWorkout.id)
                    
                    if debug {
                        log.append("FATIGUE: Removed \(setsToRemove) sets from \(exercise.movement.name)")
                    }
                }
            }
            
            // Update the workout in the next week
            nextWeek[currentIndex] = nextWorkout
        }
        
        return fatigueReducedWorkouts
    }
    
    /// Apply volume progression for muscles under their targets
    private static func applyVolumeProgression(
        fromCurrentWeek currentWeek: [WorkoutEntity],
        toNextWeek nextWeek: inout [WorkoutEntity],
        currentVolume: [MuscleGroup: Int],
        muscleProgressions: inout [MuscleGroup: MuscleProgression],
        jointWarnings: [JointWarning],
        fatigueReducedWorkouts: Set<UUID>,
        log: inout [String],
        debug: Bool
    ) {
        // Get the list of warned muscles (to avoid progression)
        let warnedMuscles = Set(jointWarnings.flatMap { $0.affectedMuscles })
        
        // Track global sets added per muscle across all workouts
        var globalSetsAdded = [MuscleGroup: Int]()
        
        // For each muscle that's progressing, find all exercises that target it
        var exercisesByMuscle = [MuscleGroup: [(workoutIndex: Int, exerciseIndex: Int, exercise: ExerciseInstanceEntity)]]()
        
        // Build a lookup of all exercises by muscle
        for (workoutIndex, workout) in nextWeek.enumerated() {
            for (exerciseIndex, exercise) in workout.exercises.enumerated() {
                // Skip exercises with joint warnings
                if exercise.shouldShowJointWarning {
                    continue
                }
                
                // Add to each primary muscle's exercise list
                for muscle in exercise.movement.primaryMuscles {
                    exercisesByMuscle[muscle, default: []].append((workoutIndex, exerciseIndex, exercise))
                }
            }
        }
        
        // For each muscle that needs progression
        for (muscle, progression) in muscleProgressions {
            // Skip muscles with warnings or that are already at regression (due to soreness)
            if warnedMuscles.contains(muscle) || progression.setsRemoved > 0 {
                if debug && warnedMuscles.contains(muscle) {
                    log.append("PROGRESSION: Skipping \(muscle.rawValue) due to joint pain warning")
                }
                continue
            }
            
            // Check if this muscle is prioritized in any of the workouts' training plan
            // We only want to add volume for prioritized muscles
            let isPrioritized = isPrioritizedMuscle(muscle, in: nextWeek)
            if !isPrioritized {
                if debug {
                    log.append("PROGRESSION: Skipping \(muscle.rawValue) - not prioritized in training plan")
                }
                continue
            }
            
            // Get current volume and hypertrophy target
            let current = currentVolume[muscle] ?? 0
            let target = muscle.trainingGuidelines.hypertrophySetsRange
            
            // Calculate how many sets are needed to reach target
            let setsNeededToTarget = target.upperBound - current
            
            // Strictly enforce the global +2 set limit across all workouts
            // Take into account any sets already added to this muscle in other workouts
            let alreadyAddedSets = globalSetsAdded[muscle] ?? 0
            let remainingAllowedSets = min(2 - alreadyAddedSets, setsNeededToTarget)
            
            if debug {
                log.append("PROGRESSION: \(muscle.rawValue) already has \(alreadyAddedSets) sets added globally")
                log.append("PROGRESSION: \(muscle.rawValue) can receive up to \(remainingAllowedSets) more sets")
            }
            
            // Skip if no more sets can be added
            if remainingAllowedSets <= 0 {
                if debug {
                    log.append("PROGRESSION: \(muscle.rawValue) already received maximum weekly progression (+\(alreadyAddedSets) sets)")
                }
                continue
            }
            
            // Get all exercises that target this muscle
            guard let targetingExercises = exercisesByMuscle[muscle], !targetingExercises.isEmpty else {
                if debug {
                    log.append("PROGRESSION: No exercises found that target \(muscle.rawValue)")
                }
                continue
            }
            
            // Filter out exercises from workouts that were reduced due to fatigue
            let eligibleExercises = targetingExercises.filter { workoutIndex, _, _ in
                let workoutId = nextWeek[workoutIndex].id
                let isEligible = !fatigueReducedWorkouts.contains(workoutId)
                
                if !isEligible && debug {
                    log.append("PROGRESSION: Skipping workout \(nextWeek[workoutIndex].title) for progression - already reduced due to fatigue")
                }
                
                return isEligible
            }
            
            // Skip if no eligible exercises remain after filtering
            if eligibleExercises.isEmpty {
                if debug {
                    log.append("PROGRESSION: No eligible exercises found for \(muscle.rawValue) after filtering fatigue-reduced workouts")
                }
                continue
            }
            
            // Sort exercises by set count (prioritize those with fewer sets first)
            let sortedExercises = eligibleExercises.sorted { $0.exercise.sets.count < $1.exercise.sets.count }
            
            var setsRemainingToAdd = remainingAllowedSets
            var setsAddedThisPass = 0
            
            if debug {
                log.append("PROGRESSION: Trying to add \(setsRemainingToAdd) sets to \(muscle.rawValue) across \(sortedExercises.count) exercises")
            }
            
            // Single-pass distribution of sets across eligible exercises
            for (workoutIndex, exerciseIndex, exercise) in sortedExercises {
                // Stop if we've added all the allowed sets
                if setsRemainingToAdd <= 0 {
                    break
                }
                // Skip if exercise already has 5 sets
                if exercise.sets.count >= 5 {
                    if debug {
                        log.append("PROGRESSION: Skipping \(exercise.movement.name) - already at 5 sets maximum")
                    }
                    continue
                }
                
                // Check for "too much" feedback in current week's matching exercise
                if workoutIndex < currentWeek.count,
                   let currentExercise = currentWeek[workoutIndex].exercises.first(where: { $0.movement.id == exercise.movement.id }),
                   let feedback = currentExercise.feedback,
                   feedback.setVolume == .tooMuch {
                    if let index = nextWeek[workoutIndex].exercises.firstIndex(where: { $0.movement.id == exercise.movement.id }),
                       nextWeek[workoutIndex].exercises[index].sets.count > 1 {
                        
                        nextWeek[workoutIndex].exercises[index].sets.removeLast()
                        
                        if debug {
                            log.append("PROGRESSION: Removed 1 set from \(exercise.movement.name) due to 'too much' feedback")
                        }
                    } else if debug {
                        log.append("PROGRESSION: Skipped reduction for \(exercise.movement.name) - only 1 set")
                    }
                    continue
                }
                
                // Add one set by duplicating the most recent one (if available)
                var updatedExercise = exercise
                
                let newSet: ExerciseSetEntity = exercise.sets.last.map {
                    ExerciseSetEntity(
                        weight: $0.weight,
                        targetReps: $0.targetReps,
                        isComplete: false
                    )
                } ?? ExerciseSetEntity() // fallback to empty if no sets (shouldn't occur)
                
                updatedExercise.sets.append(newSet)
                
                // Update the exercise in the next week
                nextWeek[workoutIndex].exercises[exerciseIndex] = updatedExercise
                
                
                // Update all tracking variables
                setsRemainingToAdd -= 1
                setsAddedThisPass += 1
                
                // Update the global tracking for this muscle
                globalSetsAdded[muscle, default: 0] += 1
                
                if debug {
                    log.append("PROGRESSION: Added set to \(exercise.movement.name) for \(muscle.rawValue)")
                    log.append("PROGRESSION: New set count = \(updatedExercise.sets.count)")
                    log.append("PROGRESSION: \(setsRemainingToAdd) sets remaining to add for \(muscle.rawValue)")
                }
            }

            
            // Update the progression tracking object
            var updatedProgression = progression
            updatedProgression.setsAdded = setsAddedThisPass
            muscleProgressions[muscle] = updatedProgression
            
            if debug {
                log.append("PROGRESSION: \(muscle.rawValue) received +\(setsAddedThisPass) sets in this pass")
                log.append("PROGRESSION: \(muscle.rawValue) total sets added across all workouts: \(globalSetsAdded[muscle, default: 0])")
            }
        }
    }
    
    /// Find exercise feedback for a specific exercise ID
    private static func findExerciseFeedback(for exerciseId: UUID, in workout: WorkoutEntity) -> ExerciseFeedback? {
        // Find the exercise directly in the workout's exercises
        if let exercise = workout.exercises.first(where: { $0.id == exerciseId }),
           let feedback = exercise.feedback {
            return feedback
        }
        
        return nil
    }
    
    /// Check if a muscle is prioritized in any of the workouts' training plans
    private static func isPrioritizedMuscle(_ muscle: MuscleGroup, in workouts: [WorkoutEntity]) -> Bool {
        // Use a Set for a faster lookup
        var prioritizedMuscles = Set<MuscleGroup>()
        
        // Collect all prioritized muscles from any training plans in these workouts
        for workout in workouts {
            if let plan = workout.trainingPlan,
               let preferences = plan.musclePreferences {
                // Add all muscles that are prioritized for growth
                let growMuscles = preferences
                    .filter { $0.goal == .grow }
                    .map { $0.muscleGroup }
                
                prioritizedMuscles.formUnion(growMuscles)
            }
        }
        
        // Check if our target muscle is in the prioritized set, or if there are no preferences at all
        // If there are no muscle preferences, treat all muscles as prioritized
        return prioritizedMuscles.isEmpty || prioritizedMuscles.contains(muscle)
    }
    /// Apply weight progression based on exercise feedback
    private static func applyWeightProgression(
        fromCurrentWeek currentWeek: [WorkoutEntity],
        toNextWeek nextWeek: inout [WorkoutEntity],
        log: inout [String],
        debug: Bool
    ) {
        if debug {
            log.append("WEIGHT: Starting weight progression analysis")
        }
        
        // Process each workout pair (current week → next week)
        for (currentIndex, currentWorkout) in currentWeek.enumerated() {
            // Ensure we don't go out of bounds
            guard currentIndex < nextWeek.count else { continue }
            
            // Get the corresponding workout in next week
            let nextWorkout = nextWeek[currentIndex]
            
            // Process each exercise pair
            for (_, currentExercise) in currentWorkout.exercises.enumerated() {
                // Find matching exercise in next week's workout
                guard let nextExerciseIndex = nextWorkout.exercises.firstIndex(where: { $0.movement.id == currentExercise.movement.id }) else {
                    continue
                }
                
                // Skip bodyweight exercises
                if currentExercise.movement.equipment == .bodyweight {
                    if debug {
                        log.append("WEIGHT: Skipping weight progression for bodyweight exercise \(currentExercise.movement.name)")
                    }
                    continue
                }
                
                // Get feedback for the current exercise
                guard let feedback = currentExercise.feedback else {
                    if debug {
                        log.append("WEIGHT: No feedback available for \(currentExercise.movement.name)")
                    }
                    continue
                }
                
                // Get recent feedback for this movement (for consecutive failed detection)
                // This is simplified - in a real implementation we'd need to look back multiple weeks
                let recentFeedbacks: [ExerciseIntensity] = [feedback.intensity] // Placeholder for now
                
                // Get a reference to the next week's exercise to avoid deep indexing
                let nextExercise = nextWorkout.exercises[nextExerciseIndex]
                
                // Process each set in the exercise
                for setIndex in 0..<nextExercise.sets.count {
                    // Get the current set
                    let set = nextExercise.sets[setIndex]
                    let referenceIndex = min(setIndex, currentExercise.sets.count - 1)
                    let currentWeight = currentExercise.sets[referenceIndex].weight
                    
                    // Calculate the raw weight adjustment based on feedback
                    let newWeight = updatedWeight(
                        currentWeight: currentWeight,
                        feedback: feedback.intensity,
                        recentFeedbacks: recentFeedbacks,
                        equipment: currentExercise.movement.equipment
                    )

                    
                    // Update the weight if it changed
                    if newWeight != currentWeight {
                        set.weight = newWeight
                        nextExercise.sets[setIndex] = set
                        
                        if debug {
                            let changeDirection = newWeight > currentWeight ? "increased" : "decreased"
                            let changePercent = abs(((newWeight / currentWeight) - 1) * 100)
                            log.append("WEIGHT: \(currentExercise.movement.name) weight \(changeDirection) from \(currentWeight) to \(newWeight) (\(String(format: "%.1f", changePercent))% change) based on \(feedback.intensity) feedback")
                        }
                    }
                }
                
                // Update the exercise in the next workout
                nextWorkout.exercises[nextExerciseIndex] = nextExercise
            }
            
            // Update the workout in the next week
            nextWeek[currentIndex] = nextWorkout
        }
    }
    
    /// Calculate updated weight based on feedback and recent feedback history
    private static func updatedWeight(
        currentWeight: Double,
        feedback: ExerciseIntensity,
        recentFeedbacks: [ExerciseIntensity],
        equipment: EquipmentType
    ) -> Double {
        // If weight is very light (under 5 lbs), don't apply percentage changes
        guard currentWeight >= 5 else { return currentWeight }

        let increment: Double = switch (feedback, equipment) {
            case (.tooEasy, .dumbbell), (.tooEasy, .machine), (.tooEasy, .cable): 5
            case (.moderate, .dumbbell), (.moderate, .machine), (.moderate, .cable): 2.5
            case (.tooEasy, .barbell): 10
            case (.moderate, .barbell): 5
            case (.failed, _): equipment == .barbell ? -5 : -2.5
            default: 0
        }
        return currentWeight + increment
    }
}

// MARK: - Input Types & Extensions

// Helper extension for PreWorkoutFeedback
extension PreWorkoutFeedback {
    var hasMuscleOrJointIssues: Bool {
        return !soreMuscles.isEmpty || !jointPainAreas.isEmpty
    }
}

// Extension to check if a set is disjointed
extension Set {
    func isDisjoint(with otherSet: Set<Element>) -> Bool {
        return intersection(otherSet).isEmpty
    }
}
