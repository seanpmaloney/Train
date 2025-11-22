import SwiftUI

@MainActor
class CalendarCardViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var displayedMonth: Date
    private var appState: AppState
    private var healthKitManager = HealthKitManager.shared
    private let calendar = Calendar.current
    
    init(appState: AppState) {
        self.appState = appState
        self.selectedDate = Date()
        self.displayedMonth = Date()
    }
    
    var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }
    
    var weeks: [[Date?]] {
        let interval = calendar.dateInterval(of: .month, for: displayedMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        
        return dates.chunked(into: 7)
    }
    
    var selectedDayWorkouts: [WorkoutEntity] {
        appState.getWorkouts(for: selectedDate)
    }
    
    var selectedDayExternalWorkouts: [ExternalWorkout] {
        healthKitManager.getExternalWorkouts(for: selectedDate)
    }
    
    func isDateSelectable(_ date: Date) -> Bool {
        // Allow selecting any date to view past workouts and external workouts
        return true
    }
    
    func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    func getWorkoutType(for date: Date) -> TrainingType {
        let internalWorkouts = appState.getWorkouts(for: date)
        let externalWorkouts = healthKitManager.getExternalWorkouts(for: date)
        
        // If we have both internal and external workouts, show hybrid
        if !internalWorkouts.isEmpty && !externalWorkouts.isEmpty {
            return .hybrid
        }
        
        // If we only have external workouts, show external type
        if !externalWorkouts.isEmpty && internalWorkouts.isEmpty {
            return .external
        }
        
        // If we only have internal workouts
        if !internalWorkouts.isEmpty {
            if internalWorkouts.count > 1 {
                return .hybrid
            }
            // For now just return strength for single workouts
            // TODO: Add workout type to WorkoutEntity and use that
            return .strength
        }
        
        return .none
    }
}

// Helper extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
