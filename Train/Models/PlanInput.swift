//
//  PlanInput.swift
//  Train
//
//  Created by Sean Maloney on 5/7/25.
//
struct PlanInput {
    /// The primary training goal (e.g., hypertrophy, strength)
    let goal: TrainingGoal

    /// Muscle groups the user wants to prioritize for growth
    let prioritizedMuscles: [MuscleGroup]

    /// Number of days per week the user wants to train
    let trainingDaysPerWeek: Int

    /// Preferred workout duration
    let workoutDuration: WorkoutDuration

    /// Equipment types available to the user
    let equipment: [EquipmentType]

    /// Preferred training split style
    let preferredSplit: SplitStyle

    /// User's training experience level
    let trainingExperience: TrainingExperience

    /// Create plan input from preferences
    static func fromPreferences(_ preferences: PlanPreferences) -> PlanInput? {
        guard let goal = preferences.trainingGoal,
              let daysPerWeek = preferences.daysPerWeek,
              let workoutDuration = preferences.workoutDuration,
              let splitStyle = preferences.splitStyle,
              let trainingExperience = preferences.trainingExperience,
              !preferences.availableEquipment.isEmpty else {
            return nil
        }

        return PlanInput(
            goal: goal,
            prioritizedMuscles: Array(preferences.priorityMuscles),
            trainingDaysPerWeek: Self.daysToInt(daysPerWeek),
            workoutDuration: workoutDuration,
            equipment: Array(preferences.availableEquipment),
            preferredSplit: splitStyle,
            trainingExperience: trainingExperience
        )
    }

    /// Convert DaysPerWeek enum to Int
    private static func daysToInt(_ days: DaysPerWeek) -> Int {
        switch days {
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        }
    }
}

enum WorkoutDayType {
    case fullBody
    case upper
    case lower
    case push
    case pull
    case legs
}

