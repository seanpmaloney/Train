import SwiftUI

@MainActor
class CalendarCardViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var displayedMonth: Date
    @Published var sessions: [Date: [TrainingSession]]
    
    private let calendar = Calendar.current
    
    init(sessions: [Date: [TrainingSession]] = TrainingSession.mockData) {
        self.selectedDate = Date()
        self.displayedMonth = Date()
        self.sessions = sessions
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
    
    var selectedDaySessions: [TrainingSession] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return sessions[startOfDay, default: []]
    }
    
    func isDateSelectable(_ date: Date) -> Bool {
        date >= calendar.startOfDay(for: Date())
    }
    
    func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    func getTrainingType(for date: Date) -> TrainingType? {
        let startOfDay = calendar.startOfDay(for: date)
        guard let sessions = sessions[startOfDay], !sessions.isEmpty else { return nil }
        
        let types = Set(sessions.map { session in session.type })
        if types.count > 1 {
            return .hybrid
        }
        return types.first
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
