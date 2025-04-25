import Foundation
import SwiftUI
import Combine

/// ViewModel for managing an active workout session
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
        
        // Trigger UI updates
        appState.objectWillChange.send()
        objectWillChange.send()
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
