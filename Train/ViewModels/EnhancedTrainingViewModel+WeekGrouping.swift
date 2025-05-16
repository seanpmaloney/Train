import Foundation

@MainActor
// Extension to add week grouping functionality to EnhancedTrainingViewModel
extension EnhancedTrainingViewModel {
    
    // MARK: - Week Grouping
    
    /// Structure representing a week in a training plan
    struct WeekGroup: Identifiable {
        let id = UUID()
        let weekNumber: Int
        let startDate: Date
        let endDate: Date
        var workouts: [WorkoutEntity]
    }
    
    /// Get all weeks in the current plan
    func getWeekGroups() -> [WeekGroup] {
        guard let currentPlan = appState.currentPlan, 
              !currentPlan.weeklyWorkouts.isEmpty else {
            return []
        }

        let calendar = Calendar.current
        var weekGroups: [WeekGroup] = []
        let sortedWorkouts = currentPlan.weeklyWorkouts.flatMap{$0}.sorted { $0.scheduledDate ?? Date() < $1.scheduledDate ?? Date() }
        
        guard let firstWorkoutDate = sortedWorkouts.first?.scheduledDate else { return [] }
        let firstWeekStart = calendar.startOfWeek(for: firstWorkoutDate)
        
        // Find the last workout date to determine end week
        guard let lastWorkoutDate = sortedWorkouts.last?.scheduledDate else { return [] }
        
        // Calculate number of weeks between first and last workout
        let numberOfWeeks = calendar.dateComponents([.weekOfYear], from: firstWeekStart, to: lastWorkoutDate).weekOfYear ?? 0
        
        // Create empty week groups
        for weekIndex in 0...numberOfWeeks {
            guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: firstWeekStart) else { continue }
            guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else { continue }
            
            let weekGroup = WeekGroup(
                weekNumber: weekIndex + 1,
                startDate: weekStartDate,
                endDate: weekEndDate,
                workouts: []
            )
            weekGroups.append(weekGroup)
        }
        
        // Assign workouts to appropriate week groups
        for workout in sortedWorkouts {
            guard let workoutDate = workout.scheduledDate else { continue }
            let weekStart = calendar.startOfWeek(for: workoutDate)
            
            if let weekIndex = weekGroups.firstIndex(where: { calendar.isDate($0.startDate, inSameDayAs: weekStart) }) {
                weekGroups[weekIndex].workouts.append(workout)
            }
        }
        
        return weekGroups
    }
    
    /// Get the current week group (containing the next workout)
    func getCurrentWeekGroup() -> WeekGroup? {
        let weekGroups = getWeekGroups()
        
        // Find week containing the next workout
        let nextWorkout = appState.getNextWorkout()
        if let nextWorkoutDate = nextWorkout.scheduledDate {
            return weekGroups.first { group in
                return nextWorkoutDate >= group.startDate && nextWorkoutDate <= group.endDate
            }
        }
        
        // Fallback to first week with incomplete workouts
        return weekGroups.first { group in
            return group.workouts.contains { !$0.isComplete }
        } ?? weekGroups.first
    }
}

// Helper extension for Calendar
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
