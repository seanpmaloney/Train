import Foundation
import SwiftUI

@MainActor
class TodaysTrainingViewModel: ObservableObject {
    @Published private(set) var todaysWorkout: WorkoutEntity?
    @Published private(set) var completionPercentage: Double = 0.0
    
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        updateTodaysWorkout()
    }
    
    func updateTodaysWorkout() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find today's workout from current plan
        if let currentPlan = appState.currentPlan {
            todaysWorkout = currentPlan.workouts.first { workout in
                if let scheduledDate = workout.scheduledDate {
                    return calendar.isDate(scheduledDate, inSameDayAs: today)
                }
                return false
            }
            
            // Calculate completion percentage
            if let workout = todaysWorkout {
                let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
                let completedSets = workout.exercises.reduce(0) { $0 + $1.sets.filter { $0.isComplete }.count }
                completionPercentage = totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0.0
            }
        } else {
            todaysWorkout = nil
            completionPercentage = 0.0
        }
    }
    
    func getMuscleGroups() -> (primary: Set<MuscleGroup>, secondary: Set<MuscleGroup>) {
        guard let workout = todaysWorkout else { return (Set(), Set()) }
        
        var primary = Set<MuscleGroup>()
        var secondary = Set<MuscleGroup>()
        
        for exercise in workout.exercises {
            primary.formUnion(exercise.movement.primaryMuscles)
            secondary.formUnion(exercise.movement.secondaryMuscles)
        }
        
        // Remove any muscles that are in both sets (keep them only in primary)
        secondary.subtract(primary)
        
        return (primary, secondary)
    }
}
