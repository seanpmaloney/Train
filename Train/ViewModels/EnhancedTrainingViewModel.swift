import Foundation
import SwiftUI
import Combine

@MainActor
/// ViewModel for managing training workouts, providing both upcoming and past workouts
class EnhancedTrainingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var upcomingWorkouts: [WorkoutEntity] = []
    @Published private(set) var pastWorkouts: [WorkoutEntity] = []
    @Published private(set) var expandedWorkoutIds: Set<UUID> = []
    
    // MARK: - Private Properties
    
    let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self.appState = appState
        
        // Initial data load
        updateWorkouts()
        
        // Subscribe to app state changes
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Starts a workout and navigates to the workout view
    func startWorkout(_ workout: WorkoutEntity) {
        // We don't need to set activeWorkoutId here - the view will handle this when it appears
        // Just notify any observers that something happened
        objectWillChange.send()
    }
    
    /// Returns whether the given workout is currently active
    func isWorkoutActive(_ workout: WorkoutEntity) -> Bool {
        return appState.activeWorkoutId == workout.id
    }
    
    /// Toggles the expanded state of a past workout
    func toggleWorkoutExpanded(_ workout: WorkoutEntity) {
        if expandedWorkoutIds.contains(workout.id) {
            expandedWorkoutIds.remove(workout.id)
        } else {
            expandedWorkoutIds.insert(workout.id)
        }
    }
    
    /// Checks if a workout is expanded
    func isWorkoutExpanded(_ workout: WorkoutEntity) -> Bool {
        return expandedWorkoutIds.contains(workout.id)
    }
    
    /// Formats a date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Extracts unique muscle groups from a workout
    func getMuscleGroups(from workout: WorkoutEntity) -> [MuscleGroup] {
        var muscles = Set<MuscleGroup>()
        
        for exercise in workout.exercises {
            muscles.formUnion(exercise.movement.primaryMuscles)
            muscles.formUnion(exercise.movement.secondaryMuscles)
        }
        
        return Array(muscles).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to scheduledWorkouts changes
        appState.$scheduledWorkouts
            .sink { [weak self] _ in
                self?.updateWorkouts()
            }
            .store(in: &cancellables)
        
        // Subscribe to currentPlan changes
        appState.$currentPlan
            .sink { [weak self] _ in
                self?.updateWorkouts()
            }
            .store(in: &cancellables)
        
        // Subscribe to activeWorkoutId changes
        appState.$activeWorkoutId
            .sink { [weak self] _ in
                self?.updateWorkouts()
            }
            .store(in: &cancellables)
    }
    
    private func updateWorkouts() {
        guard let currentPlan = appState.currentPlan else {
            upcomingWorkouts = []
            pastWorkouts = []
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Separate workouts into past and upcoming
        let (past, upcoming) = currentPlan.weeklyWorkouts.flatMap{$0}.reduce(into: ([WorkoutEntity](), [WorkoutEntity]())) { result, workout in
            // Sort completed workouts into past
            if workout.isComplete {
                result.0.append(workout)
                return
            }
            
            // Sort based on date (past or upcoming)
            if let date = workout.scheduledDate {
                if date < today {
                    result.0.append(workout)
                } else {
                    result.1.append(workout)
                }
            } else {
                // No date defaults to upcoming
                result.1.append(workout)
            }
        }
        
        // Sort past workouts by date (most recent first)
        pastWorkouts = past.sorted { workout1, workout2 in
            let date1 = workout1.scheduledDate ?? Date.distantPast
            let date2 = workout2.scheduledDate ?? Date.distantPast
            return date1 > date2
        }
        
        // Sort upcoming workouts by date (earliest first)
        upcomingWorkouts = upcoming.sorted { workout1, workout2 in
            let date1 = workout1.scheduledDate ?? Date.distantFuture
            let date2 = workout2.scheduledDate ?? Date.distantFuture
            return date1 < date2
        }
    }
}
