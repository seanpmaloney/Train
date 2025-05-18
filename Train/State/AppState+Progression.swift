import Foundation

// MARK: - Workout Progression System
extension AppState {
    
    /// Apply the feedback-driven progression algorithm to update next week's workout using the ProgressionEngine
    /// - Parameters:
    ///   - workout: The workout to apply progression to
    ///   - feedback: Bundle containing workout feedback (pre, exercises, post)
    func applyProgressionAlgorithm(to workout: WorkoutEntity, using feedback: WorkoutFeedbackBundle) {
        print("DEBUG: Applying progression algorithm to: \(workout.title)")
        
        // Make sure we have a training plan and this workout belongs to it
        guard let plan = currentPlan, 
              let workoutPlan = workout.trainingPlan,
              workoutPlan.id == plan.id else {
            print("ERROR: Cannot apply progression - workout doesn't belong to current plan")
            return
        }
        
        // Find which week this workout is in
        var weekIndex = -1
        var workoutInWeekIndex = -1
        
        for (weekIdx, weekWorkouts) in plan.weeklyWorkouts.enumerated() {
            if let workoutIdx = weekWorkouts.firstIndex(where: { $0.id == workout.id }) {
                weekIndex = weekIdx
                workoutInWeekIndex = workoutIdx
                break
            }
        }
        
        // We need to find this workout in a week and there must be a next week
        guard weekIndex >= 0, workoutInWeekIndex >= 0, weekIndex + 1 < plan.weeklyWorkouts.count else {
            print("ERROR: Cannot apply progression - workout not found in plan or no next week available")
            return
        }
        
        // Create a mini 2D array with just this workout and its next week counterpart
        let currentWorkout = plan.weeklyWorkouts[weekIndex][workoutInWeekIndex]
        
        // Ensure the next week has the same workout position
        guard workoutInWeekIndex < plan.weeklyWorkouts[weekIndex + 1].count else {
            print("ERROR: Cannot apply progression - no matching workout in next week")
            return
        }
        
        // Get the next week's workout that corresponds to this one
        var nextWorkout = plan.weeklyWorkouts[weekIndex + 1][workoutInWeekIndex]
        
        // MARK: 1. Default Weight Increase (not handled by ProgressionEngine)
        
        // Apply weight increases directly (this is separate from set count progression)
        applyWeightProgression(to: nextWorkout, using: feedback)
        
        // MARK: 2. Set Count Progression via ProgressionEngine
        
        // Create a mini 2D array with just this workout and its next week counterpart
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [currentWorkout],
            [nextWorkout]
        ]
        
        // Run the progression engine on our mini workout array
        // The engine will now get feedback directly from the workout entities
        let logs = ProgressionEngine.applyProgression(
            to: &weeklyWorkouts,
            debug: true
        )
        
        // Log the progression results
        for log in logs {
            print("PROGRESSION: \(log)")
        }
        
        // Get the updated next workout from the progression engine results
        let updatedNextWorkout = weeklyWorkouts[1][0]
        
        // MARK: 3. Update the actual workout in the plan
        
        // Update the workout in the plan with the progression results
        plan.weeklyWorkouts[weekIndex + 1][workoutInWeekIndex] = updatedNextWorkout
        
        // Save changes to persist the progression
        savePlans()
    }
    
    /// Apply weight progression to a workout based on feedback
    /// This is handled separately from set count progression
    private func applyWeightProgression(to workout: WorkoutEntity, using feedback: WorkoutFeedbackBundle) {
        for exercise in workout.exercises {
            // Default weight increase percentage
            let increasePercentage = 0.025 // 2.5%
            
            // Find corresponding exercise feedback by matching movement name
            let exerciseFeedback = feedback.exercises.first { feedback in
                if let sourceExercise = getExerciseById(feedback.exerciseId) {
                    return sourceExercise.movement.name == exercise.movement.name
                }
                return false
            }
            
            // Unless explicitly blocked, apply default weight progression
            let shouldBlockWeightIncrease = exerciseFeedback?.intensity == .failed || 
                                           exerciseFeedback?.setVolume == .tooMuch
            
            // Don't increase weight if there's joint pain affecting this movement
            let hasJointPain = hasJointPainForExercise(exercise, preFeedback: feedback.pre)
            
            if !shouldBlockWeightIncrease && !hasJointPain {
                for set in exercise.sets {
                    set.weight *= (1 + increasePercentage)
                }
            }
        }
    }
    
    /// Check if an exercise might be affected by joint pain
    private func hasJointPainForExercise(_ exercise: ExerciseInstanceEntity, preFeedback: PreWorkoutFeedback?) -> Bool {
        guard let preFeedback = preFeedback else { return false }
        
        let hasKneePain = preFeedback.jointPainAreas.contains(.knee) && 
                        exercise.movement.primaryMuscles.contains(where: { muscle in
                            // Check if muscle is in lower body
                            [.quads, .hamstrings, .glutes, .calves].contains(muscle)
                        })
                        
        let hasArmPain = (preFeedback.jointPainAreas.contains(.elbow) || 
                        preFeedback.jointPainAreas.contains(.shoulder)) && 
                        exercise.movement.primaryMuscles.contains(where: { muscle in
                            // Check if muscle is in upper body
                            [.chest, .back, .shoulders, .biceps, .triceps, .forearms].contains(muscle)
                        })
        
        return hasKneePain || hasArmPain
    }
    
    /// Convert feedback bundle to the format expected by ProgressionEngine
    /// - Note: This method is deprecated and will be removed in a future update.
    ///         Feedback is now stored directly on workout and exercise entities.
    @available(*, deprecated, message: "Feedback is now stored directly on workout and exercise entities")
    private func createFeedbackMap(from feedback: WorkoutFeedbackBundle, for workoutId: UUID) -> [UUID: [WorkoutFeedback]] {
        var feedbacks: [WorkoutFeedback] = []
        
        // Add pre-workout feedback if available
        if let preFeedback = feedback.pre {
            feedbacks.append(preFeedback)
        }
        
        // Add all exercise feedbacks
        feedbacks.append(contentsOf: feedback.exercises)
        
        // Add post-workout feedback if available
        if let postFeedback = feedback.post {
            feedbacks.append(postFeedback)
        }
        
        // Create the map with the workout ID as the key
        return [workoutId: feedbacks]
    }
    
    /// Find which week a workout belongs to in the training plan
    private func findWeekIndex(for workout: WorkoutEntity, in plan: TrainingPlanEntity) -> Int? {
        for (weekIndex, weekWorkouts) in plan.weeklyWorkouts.enumerated() {
            if weekWorkouts.contains(where: { $0.id == workout.id }) {
                return weekIndex
            }
        }
        return nil
    }
    
    /// Find next week's workout of the same type (uses the 2D array structure)
    func findNextWeekWorkout(for workout: WorkoutEntity) -> WorkoutEntity? {
        guard let plan = workout.trainingPlan else { return nil }
        
        // Find which week and position this workout is in
        for (weekIndex, weekWorkouts) in plan.weeklyWorkouts.enumerated() {
            // Find position of workout in this week
            if let workoutIndex = weekWorkouts.firstIndex(where: { $0.id == workout.id }) {
                // Check if there's a next week
                let nextWeekIndex = weekIndex + 1
                if nextWeekIndex < plan.weeklyWorkouts.count {
                    // Check if the next week has enough workouts
                    let nextWeek = plan.weeklyWorkouts[nextWeekIndex]
                    if workoutIndex < nextWeek.count {
                        // Return the workout at the same position in the next week
                        return nextWeek[workoutIndex]
                    }
                }
                break // We found our workout, but no next week workout exists
            }
        }
        return nil
    }
    
    /// Determines if a workout is the first of its type in the training plan
    /// Uses the 2D array structure of weeklyWorkouts to find which week this workout is in
    private func isFirstWorkoutOfType(_ workout: WorkoutEntity) -> Bool {
        guard let plan = workout.trainingPlan else { return true }
        
        // Find which week this workout belongs to
        for (weekIndex, weekWorkouts) in plan.weeklyWorkouts.enumerated() {
            if weekWorkouts.contains(where: { $0.id == workout.id }) {
                // It's the first workout of its type if it's in week 0
                return weekIndex == 0
            }
        }
        
        // If not found in any week, consider it the first (shouldn't happen)
        return true
    }
    
    /// Find previous week's workout of the same type
    private func findPreviousWeekWorkout(for workout: WorkoutEntity) -> WorkoutEntity? {
        guard let plan = workout.trainingPlan else { return nil }
        
        // Find which week and position this workout is in
        for (weekIndex, weekWorkouts) in plan.weeklyWorkouts.enumerated() {
            // Find position of workout in this week
            if let workoutIndex = weekWorkouts.firstIndex(where: { $0.id == workout.id }) {
                // Check if there's a previous week
                let previousWeekIndex = weekIndex - 1
                if previousWeekIndex >= 0 {
                    // Check if the previous week has enough workouts
                    let previousWeek = plan.weeklyWorkouts[previousWeekIndex]
                    if workoutIndex < previousWeek.count {
                        // Return the workout at the same position in the previous week
                        return previousWeek[workoutIndex]
                    }
                }
                break // We found our workout, but no previous week workout exists
            }
        }
        return nil
    }
    
    /// Group exercises by their muscle groups (both primary and secondary)
    private func groupExercisesByMuscle(in workout: WorkoutEntity) -> [MuscleGroup: [ExerciseInstanceEntity]] {
        var exercisesByMuscle: [MuscleGroup: [ExerciseInstanceEntity]] = [:]
        
        for exercise in workout.exercises {
            // Add exercise to its primary muscles groups
            for muscle in exercise.movement.primaryMuscles {
                exercisesByMuscle[muscle, default: []].append(exercise)
            }
            
            // Also add exercise to its secondary muscle groups
            // This ensures we can add sets to exercises that target a muscle as secondary
            // when that's the best option available
            for muscle in exercise.movement.secondaryMuscles {
                // Only add if not already added via primary muscles
                if !exercise.movement.primaryMuscles.contains(muscle) && 
                   !exercisesByMuscle[muscle, default: []].contains(where: { $0.id == exercise.id }) {
                    exercisesByMuscle[muscle, default: []].append(exercise)
                }
            }
        }
        
        return exercisesByMuscle
    }

    
    /// Sort muscles by priority based on plan preferences
    private func sortMusclesByPriority(_ muscles: [MuscleGroup], plan: TrainingPlanEntity?) -> [MuscleGroup] {
        guard let plan = plan, plan.musclePreferences != nil else {
            return muscles
        }
        
        // Extract prioritized muscles from plan if available
        let prioritizedMuscles = plan.musclePreferences!
            .filter { $0.goal == .grow }
            .map { $0.muscleGroup }
        
        // Sort by priority: prioritized muscles first, then others
        return muscles.sorted { muscle1, muscle2 in
            // If muscle1 is prioritized and muscle2 is not, muscle1 comes first
            if prioritizedMuscles.contains(muscle1) && !prioritizedMuscles.contains(muscle2) {
                return true
            }
            // If muscle2 is prioritized and muscle1 is not, muscle2 comes first
            if !prioritizedMuscles.contains(muscle1) && prioritizedMuscles.contains(muscle2) {
                return false
            }
            // If both or neither are prioritized, sort by name for consistency
            return muscle1.rawValue < muscle2.rawValue
        }
    }
}
