import Foundation

enum TrainingType: String {
    case strength
    case endurance
    case hybrid
    
    var color: String {
        switch self {
        case .strength: return "#EF476F"  // Red
        case .endurance: return "#00B4D8" // Blue
        case .hybrid: return "#FFD166"    // Yellow
        }
    }
}

struct TrainingSession: Identifiable {
    let id = UUID()
    let title: String
    let type: TrainingType
    let startTime: Date?
    let summary: String?
    
    static var mockData: [Date: [TrainingSession]] {
        let calendar = Calendar.current
        var data: [Date: [TrainingSession]] = [:]
        
        // Today's session
        let today = calendar.startOfDay(for: Date())
        data[today] = [
            TrainingSession(
                title: "Lower Strength",
                type: .strength,
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today),
                summary: "Squats 5x5, RDLs 3x8"
            )
        ]
        
        // Tomorrow's sessions
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            data[tomorrow] = [
                TrainingSession(
                    title: "Morning Run",
                    type: .endurance,
                    startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow),
                    summary: "45min Zone 2"
                ),
                TrainingSession(
                    title: "Upper Strength",
                    type: .strength,
                    startTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: tomorrow),
                    summary: "Bench 5x5, OHP 3x8"
                )
            ]
        }
        
        return data
    }
}
