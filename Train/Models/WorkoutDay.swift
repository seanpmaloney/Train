import Foundation
import SwiftUI

/// Enum representing days of the week for workout scheduling
enum WorkoutDay: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    /// Returns the display name of the day
    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    /// Returns the short display name of the day
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    /// Get the Calendar.Component.weekday value for this day
    var calendarWeekday: Int {
        rawValue
    }
    
    /// Parse a string representation of workout days (e.g., "Mon/Wed/Fri")
    static func parseScheduleString(_ scheduleString: String) -> [WorkoutDay] {
        let components = scheduleString.components(separatedBy: CharacterSet(charactersIn: "/,-"))
        
        return components.compactMap { component in
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            switch trimmed {
            case "sun", "sunday": return .sunday
            case "mon", "monday": return .monday
            case "tue", "tues", "tuesday": return .tuesday
            case "wed", "weds", "wednesday": return .wednesday
            case "thu", "thur", "thurs", "thursday": return .thursday
            case "fri", "friday": return .friday
            case "sat", "saturday": return .saturday
            default: return nil
            }
        }
    }
    
    /// Get a formatted string representation of workout days (e.g., "Mon/Wed/Fri")
    static func formatSchedule(_ days: [WorkoutDay]) -> String {
        days.map { $0.shortName }.joined(separator: "/")
    }
}
