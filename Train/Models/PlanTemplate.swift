import Foundation

struct PlanTemplate: Identifiable {
    let id = UUID()
    let title: String
    let goal: TrainingGoal
    let schedule: String
    let daysPerWeek: Int
    let suggestedDuration: String
    let type: TrainingPlanBuilder.SplitStyle
    
    static let templates: [PlanTemplate] = [
        PlanTemplate(
            title: "Full Body",
            goal: .strength,
            schedule: "Mon/Wed/Fri",
            daysPerWeek: 3,
            suggestedDuration: "4-12 weeks",
            type: .fullBody
        ),
        PlanTemplate(
            title: "Upper/Lower",
            goal: .hypertrophy,
            schedule: "Mon/Tue/Thu/Fri",
            daysPerWeek: 4,
            suggestedDuration: "8-16 weeks",
            type: .upperLower
        ),
        PlanTemplate(
            title: "Push/Pull/Legs",
            goal: .hypertrophy,
            schedule: "Mon-Fri",
            daysPerWeek: 3,
            suggestedDuration: "12-16 weeks",
            type: .pushPullLegs
        ),
        PlanTemplate(
            title: "5-Day Split",
            goal: .hypertrophy,
            schedule: "Mon-Fri",
            daysPerWeek: 5,
            suggestedDuration: "12-16 weeks",
            type: .fiveDaySplit
        )
    ]
}

enum TrainingGoal: String {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy"
    case endurance = "Endurance"
    case powerbuilding = "Powerbuilding"
}
