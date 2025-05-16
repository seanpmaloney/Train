import Foundation

@MainActor
// Extension to add exercise history functionality to EnhancedActiveWorkoutViewModel
extension EnhancedActiveWorkoutViewModel {
    
    // MARK: - Exercise History
    
    /// Get historical instances of an exercise from past completed workouts
    func getExerciseHistory(for currentExercise: ExerciseInstanceEntity) -> [ExerciseInstanceEntity] {
        // Make sure we have an appState and the current plan contains our workout
        guard let appState = appState,
              let currentPlan = appState.currentPlan,
              currentPlan.weeklyWorkouts.flatMap({$0}).contains(where: { $0.id == workout.id }) else {
            // Return just the current exercise if no history is available
            return [currentExercise]
        }
        
        // Get the current workout (needed to exclude it from history)
        let currentWorkoutId = workout.id
        
        // Find all similar exercises in past completed workouts
        var historyExercises: [ExerciseInstanceEntity] = []
        
        // Include the current exercise as the last item
        historyExercises.append(currentExercise)
        
        // Add past exercises that match the movement type
        for historicalWorkout in currentPlan.weeklyWorkouts.flatMap({$0}) {
            // Skip if not complete, future date, or current workout
            guard historicalWorkout.isComplete,
                  historicalWorkout.id != currentWorkoutId
            else {
                continue
            }
            
            // Find matching exercise in this workout
            for exercise in historicalWorkout.exercises {
                if exercise.movement.movementType == currentExercise.movement.movementType {
                    historyExercises.append(exercise)
                    break // Only take one matching exercise per workout
                }
            }
        }
        
        // Sort by date (newest to oldest, with current exercise first)
        historyExercises.sort { (a, b) in
            // Put current exercise at the end (most recent)
            if a.id == currentExercise.id { return false }
            if b.id == currentExercise.id { return true }
            
            // Otherwise sort by date
            let aWorkout = currentPlan.weeklyWorkouts.flatMap({$0}).first { $0.exercises.contains { $0.id == a.id } }
            let bWorkout = currentPlan.weeklyWorkouts.flatMap({$0}).first { $0.exercises.contains { $0.id == b.id } }
            
            let aDate = aWorkout?.scheduledDate ?? Date.distantPast
            let bDate = bWorkout?.scheduledDate ?? Date.distantPast
            
            return aDate < bDate
        }
        
        return historyExercises
    }
    
    /// Get the workout date for a specific exercise instance
    func getDateForExercise(_ exercise: ExerciseInstanceEntity) -> Date? {
        guard let appState = appState,
              let currentPlan = appState.currentPlan else {
            return nil
        }
        
        // Find the workout containing this exercise
        let containingWorkout = currentPlan.weeklyWorkouts.flatMap({$0}).first { workout in
            workout.exercises.contains { $0.id == exercise.id }
        }
        
        return containingWorkout?.scheduledDate
    }
    
    /// Check if this exercise is the current one (not historical)
    func isCurrentExercise(_ exercise: ExerciseInstanceEntity) -> Bool {
        return exercise.id == workout.exercises.first { 
            $0.movement.movementType == exercise.movement.movementType 
        }?.id
    }
}
