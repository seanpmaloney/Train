import SwiftUI

@MainActor
class CalendarCardViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var displayedMonth: Date
    
    private let calendar = Calendar.current
    private let appState: AppState
    
    init(appState: AppState = AppState()) {
        self.selectedDate = Date()
        self.displayedMonth = Date()
        self.appState = appState
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
    
    func isDateSelectable(_ date: Date) -> Bool {
        date >= calendar.startOfDay(for: Date())
    }
    
    func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    func getWorkoutType(for date: Date) -> TrainingType {
        let workouts = appState.getWorkouts(for: date)
        guard !workouts.isEmpty else { return .none }
        
        if workouts.count > 1 {
            return .hybrid
        }
        
        // For now just return strength for single workouts
        // TODO: Add workout type to WorkoutEntity and use that
        return .strength
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
