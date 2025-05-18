import Foundation
import Combine

/// Service class to manage workout-related operations
/// Centralizes the logic for modifying workouts and exercises
@MainActor
class WorkoutManager {
    // Singleton instance for app-wide access
    static let shared = WorkoutManager()
    
    // Publisher for changes to workouts
    private let workoutChangesSubject = PassthroughSubject<Void, Never>()
    var workoutChanges: AnyPublisher<Void, Never> {
        workoutChangesSubject.eraseToAnyPublisher()
    }
    
    // Private initializer for singleton
    private init() {}
    
    // MARK: - Set Management
    
    /// Completely removes a set from an exercise
    /// - Parameters:
    ///   - exercise: The exercise containing the set
    ///   - set: The set to remove
    func deleteSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity) {
        // Find the index of the set to remove
        if let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) {
            // Remove the set
            exercise.sets.remove(at: setIndex)
            
            // Notify observers of the change
            workoutChangesSubject.send()
        }
    }
    
    /// Marks a set as skipped (grayed out) without deleting it
    /// Sets weight and reps to 0 and marks it as complete
    /// - Parameters:
    ///   - exercise: The exercise containing the set
    ///   - set: The set to skip
    func skipSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity) {
        // Mark as skipped by setting weight and reps to 0 and marking as complete
        set.weight = 0
        set.completedReps = 0
        set.isComplete = true
        
        // Notify observers of the change
        workoutChangesSubject.send()
    }
    
    /// Unskips a previously skipped set by resetting its values
    /// - Parameters:
    ///   - exercise: The exercise containing the set
    ///   - set: The set to unskip
    ///   - defaultWeight: Optional default weight to reset to (if nil, keeps current value)
    ///   - defaultReps: Optional default target reps (if nil, keeps current value)
    func unskipSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity, defaultWeight: Double? = nil, defaultReps: Int? = nil) {
        // Only unskip if it appears to be a skipped set
        if set.isComplete && set.completedReps == 0 && set.weight == 0 {
            // If default values are provided, use them, otherwise keep the target reps
            if let defaultWeight = defaultWeight {
                set.weight = defaultWeight
            }
            
            // Reset completed reps to -1 (untouched) but keep target reps unless specified
            set.completedReps = -1
            if let defaultReps = defaultReps {
                set.targetReps = defaultReps
            }
            
            // Mark as not complete
            set.isComplete = false
            
            // Notify observers of the change
            workoutChangesSubject.send()
        }
    }
    
    /// Checks if a set is skipped (weight=0, reps=0, complete=true)
    /// - Parameter set: The set to check
    /// - Returns: True if the set is skipped, false otherwise
    func isSetSkipped(_ set: ExerciseSetEntity) -> Bool {
        return set.isComplete && set.completedReps == 0 && set.weight == 0
    }
    
    /// Adds a new set to an exercise, copying the last set's values
    /// - Parameter exercise: The exercise to add a set to
    func addSet(to exercise: ExerciseInstanceEntity) {
        // Get values from the last set to use as defaults
        if let lastSet = exercise.sets.last {
            // Create a new set with the same values as the last set, but not completed
            let newSet = ExerciseSetEntity(
                weight: lastSet.weight,
                targetReps: lastSet.targetReps,
                isComplete: false
            )
            
            // Add the new set to the exercise
            exercise.sets.append(newSet)
            
            // Notify observers of the change
            workoutChangesSubject.send()
        } else {
            // If there are no existing sets (unlikely), create a default one
            let newSet = ExerciseSetEntity(
                weight: 0,
                targetReps: 8,
                isComplete: false
            )
            
            // Add the new set to the exercise
            exercise.sets.append(newSet)
            
            // Notify observers of the change
            workoutChangesSubject.send()
        }
    }
    
    /// Updates the weight for all sets in a given exercise
    /// - Parameters:
    ///   - exercise: The exercise to update
    ///   - weight: The new weight value
    func updateAllSetsWeight(in exercise: ExerciseInstanceEntity, to weight: Double) {
        for set in exercise.sets {
            set.weight = weight
        }
        workoutChangesSubject.send()
    }
    
    /// Updates the target reps for all sets in a given exercise
    /// - Parameters:
    ///   - exercise: The exercise to update
    ///   - reps: The new target reps value
    func updateAllSetsTargetReps(in exercise: ExerciseInstanceEntity, to reps: Int) {
        for set in exercise.sets {
            set.targetReps = reps
        }
        workoutChangesSubject.send()
    }
    
    // MARK: - Exercise Management
    
    /// Adds a new exercise to a workout
    /// - Parameters:
    ///   - workout: The workout to add an exercise to
    ///   - movement: The movement for the new exercise
    ///   - sets: The number of sets to create (default 3)
    func addExercise(to workout: WorkoutEntity, movement: MovementEntity, sets: Int = 3) {
        let exercise = ExerciseInstanceEntity(
            movement: movement,
            exerciseType: "Strength",  // Default type
            sets: []
        )
        
        // Add default sets
        for _ in 0..<sets {
            let set = ExerciseSetEntity(
                weight: 0,
                targetReps: 8,
                isComplete: false
            )
            exercise.sets.append(set)
        }
        
        // Add exercise to workout
        workout.exercises.append(exercise)
        workoutChangesSubject.send()
    }
    
    /// Removes an exercise from a workout
    /// - Parameters:
    ///   - workout: The workout containing the exercise
    ///   - exercise: The exercise to remove
    func removeExercise(from workout: WorkoutEntity, exercise: ExerciseInstanceEntity) {
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises.remove(at: index)
            workoutChangesSubject.send()
        }
    }
    
    // MARK: - Analytics and Automation
    
    /// Analyzes performance and adjusts future workouts (placeholder for future implementation)
    /// - Parameters:
    ///   - completedWorkout: The workout that was just completed
    ///   - appState: The app state for accessing other workouts
    func analyzeAndAdjustFutureWorkouts(completedWorkout: WorkoutEntity, appState: AppState) {
        // This is a placeholder for future implementation
        // In the future, this would analyze the completed workout's performance
        // and make adjustments to future workouts accordingly
        
        // For example, if user consistently fails to complete certain sets,
        // we might reduce weight or reps in future workouts
        
        // Or if user consistently completes all sets easily,
        // we might increase weight or reps in future workouts
    }
}
