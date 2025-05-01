import Foundation
import SwiftUI
import Combine

/// ViewModel for managing an active workout session
@MainActor
class EnhancedActiveWorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var workout: WorkoutEntity
    @Published private(set) var exercises: [ExerciseInstanceEntity]
    @Published var isComplete: Bool = false
    
    // MARK: - Private Properties
    
    var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(workout: WorkoutEntity) {
        self.workout = workout
        self.exercises = workout.exercises
        self.isComplete = workout.isComplete
        
        // Subscribe to workout changes from WorkoutManager
        WorkoutManager.shared.workoutChanges
            .sink { [weak self] _ in
                // Notify SwiftUI that our view model has changed
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Connects the view model to the app state
    func connectAppState(_ appState: AppState) {
        self.appState = appState
    }
    
    /// Updates the weight for a specific exercise set
    func updateWeight(for set: ExerciseSetEntity, to weight: Double) {
        set.weight = weight
        objectWillChange.send()
    }
    
    /// Updates the completed reps for a specific exercise set
    func updateReps(for set: ExerciseSetEntity, to reps: Int) {
        set.completedReps = reps
        objectWillChange.send()
    }
    
    /// Toggles the completion status of a set
    func toggleSetComplete(_ set: ExerciseSetEntity) {
        set.isComplete.toggle()
        objectWillChange.send()
    }
    
    /// Calculates the total completion percentage of the workout
    func getCompletionPercentage() -> Double {
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0 }
        
        let completedSets = exercises.reduce(0) { $0 + $1.sets.filter(\.isComplete).count }
        return Double(completedSets) / Double(totalSets)
    }
    
    /// Completes the workout and updates app state
    func completeWorkout(appState: AppState) {
        // Mark workout as complete
        workout.isComplete = true
        isComplete = true
        
        // Update app state
        appState.markWorkoutComplete(workout, isComplete: true)
        appState.activeWorkoutId = nil
        appState.savePlans()
        
        // Analyze performance and adjust future workouts if needed
        WorkoutManager.shared.analyzeAndAdjustFutureWorkouts(completedWorkout: workout, appState: appState)
        
        // Trigger UI updates
        appState.objectWillChange.send()
        objectWillChange.send()
    }
    
    /// Updates the weight for a specific exercise set and all subsequent sets in the same exercise
    func updateWeightAndSubsequentSets(in exercise: ExerciseInstanceEntity, for set: ExerciseSetEntity, to weight: Double) {
        guard let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) else { return }
        
        // Update current set and all subsequent sets
        for i in setIndex..<exercise.sets.count {
            exercise.sets[i].weight = weight
        }
        
        objectWillChange.send()
    }
    
    /// Updates the completed reps for a specific exercise set and all subsequent sets in the same exercise
    func updateRepsAndSubsequentSets(in exercise: ExerciseInstanceEntity, for set: ExerciseSetEntity, to reps: Int) {
        guard let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) else { return }
        
        // Update current set and all subsequent sets
        for i in setIndex..<exercise.sets.count {
            exercise.sets[i].completedReps = reps
        }
        
        objectWillChange.send()
    }
    
    // MARK: - Set Management Proxy Methods
    
    /// Proxy method to skip a set using WorkoutManager (marks as skipped without deleting)
    func skipSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity) {
        WorkoutManager.shared.skipSet(in: exercise, set: set)
    }
    
    /// Proxy method to delete a set using WorkoutManager (completely removes it)
    func deleteSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity) {
        WorkoutManager.shared.deleteSet(in: exercise, set: set)
    }
    
    /// Proxy method to unskip a set using WorkoutManager
    func unskipSet(in exercise: ExerciseInstanceEntity, set: ExerciseSetEntity) {
        // Find a previous set to get default weight if needed
        var defaultWeight: Double? = nil
        if let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }), setIndex > 0 {
            // Use previous set's weight as default
            defaultWeight = exercise.sets[setIndex - 1].weight
        }
        
        WorkoutManager.shared.unskipSet(in: exercise, set: set, defaultWeight: defaultWeight)
    }
    
    /// Check if a set is skipped
    func isSetSkipped(_ set: ExerciseSetEntity) -> Bool {
        return WorkoutManager.shared.isSetSkipped(set)
    }
    
    /// Proxy method to add a set using WorkoutManager
    func addSet(to exercise: ExerciseInstanceEntity) {
        WorkoutManager.shared.addSet(to: exercise)
    }
    
    // MARK: - Private Methods
    
    /// Formats weight for display
    func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f", weight)
    }
    
    /// Formats reps for display
    func formatReps(_ reps: Int) -> String {
        return "\(reps)"
    }
}
