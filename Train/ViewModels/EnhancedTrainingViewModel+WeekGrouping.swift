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
        guard let firstWeekStart = calendar.startOfWeek(for: firstWorkoutDate) else { return [] }
        
        // Find the last workout date to determine end week
        guard let lastWorkoutDate = sortedWorkouts.last?.scheduledDate else { return [] }
        
        // Calculate number of weeks between first and last workout
        let lastWorkoutWeekStart = calendar.startOfWeekWithFallback(for: lastWorkoutDate)
        let numberOfWeeks = calendar.dateComponents([.weekOfYear], from: firstWeekStart, to: lastWorkoutWeekStart).weekOfYear ?? 0
        
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
            let weekStart = calendar.startOfWeekWithFallback(for: workoutDate)
            
            if let weekIndex = weekGroups.firstIndex(where: { group in 
                // Both dates must be non-optional for isDate comparison
                return calendar.isDate(group.startDate, inSameDayAs: weekStart) 
            }) {
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

// MARK: - Calendar Extensions

extension Calendar {
    /// Returns the start date of the week containing the specified date
    /// - Parameter date: The date for which to find the start of the week
    /// - Returns: The start date of the week, or nil if calculation fails
    func startOfWeek(for date: Date) -> Date? {
        // Get the year and week components
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        
        // Create date from these components (this will be the start of the week)
        return self.date(from: components)
    }
    
    /// Returns the start date of the week containing the specified date, with a fallback value
    /// - Parameters:
    ///   - date: The date for which to find the start of the week
    ///   - fallback: The fallback date to use if calculation fails (defaults to original date)
    /// - Returns: The start date of the week, or the fallback date if calculation fails
    func startOfWeekWithFallback(for date: Date, fallback: Date? = nil) -> Date {
        return startOfWeek(for: date) ?? (fallback ?? date)
    }
}
