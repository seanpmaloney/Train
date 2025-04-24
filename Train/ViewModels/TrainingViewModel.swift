import Foundation
import SwiftUI
import Combine

class TrainingViewModel: ObservableObject {
    @Published private(set) var upcomingWorkouts: [WorkoutEntity] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        updateUpcomingWorkouts()
        
        // Subscribe to changes in scheduledWorkouts
        appState.$scheduledWorkouts
            .sink { [weak self] _ in
                self?.updateUpcomingWorkouts()
            }
            .store(in: &cancellables)
            
        // Subscribe to changes in currentPlan
        appState.$currentPlan
            .sink { [weak self] _ in
                self?.updateUpcomingWorkouts()
            }
            .store(in: &cancellables)
    }
    
    func updateUpcomingWorkouts() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all future workouts from current plan
        if let currentPlan = appState.currentPlan {
            upcomingWorkouts = currentPlan.workouts
                .filter { workout in
                    guard let scheduledDate = workout.scheduledDate else { return false }
                    return !calendar.isDate(scheduledDate, inSameDayAs: today) && scheduledDate >= today
                }
                .sorted { workout1, workout2 in
                    guard let date1 = workout1.scheduledDate, let date2 = workout2.scheduledDate else { return false }
                    return date1 < date2
                }
        } else {
            upcomingWorkouts = []
        }
    }
    
    func getMuscleGroups(from workout: WorkoutEntity) -> [MuscleGroup] {
        var muscles = Set<MuscleGroup>()
        
        for exercise in workout.exercises {
            muscles.formUnion(exercise.movement.primaryMuscles)
            muscles.formUnion(exercise.movement.secondaryMuscles)
        }
        
        return Array(muscles).sorted { $0.displayName < $1.displayName }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
