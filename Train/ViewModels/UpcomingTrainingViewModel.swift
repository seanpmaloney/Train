import Foundation

@MainActor
class UpcomingTrainingViewModel: ObservableObject {
    @Published var nextWorkout: WorkoutEntity?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        updateNextWorkout()
    }
    
    func updateNextWorkout() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // First check today's workouts
        let todaysWorkouts = appState.getWorkouts(for: today)
        if !todaysWorkouts.isEmpty {
            nextWorkout = todaysWorkouts.first
            return
        }
        
        // If no workouts today, find the next workout
        var nextDate = today
        for _ in 1...30 { // Look up to 30 days ahead
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            let workouts = appState.getWorkouts(for: nextDate)
            if let workout = workouts.first {
                nextWorkout = workout
                return
            }
        }
        
        nextWorkout = nil
    }
    
    var hasCurrentPlan: Bool {
        appState.currentPlan != nil
    }
    
    var nextWorkoutDateString: String? {
        guard let date = nextWorkout?.scheduledDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        }
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        if calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Day name (e.g., "Monday")
        return formatter.string(from: date)
    }
}
