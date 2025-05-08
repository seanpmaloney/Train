//
//  PlanGenUtilities.swift
//  Train
//
//  Created by Sean Maloney on 5/7/25.
//

/// Get the workout day type for a specific day in the week
/// - Parameters:
///   - day: The day number (1-based)
///   - split: User's preferred split style
///   - totalDays: Total days per week
/// - Returns: The appropriate workout day type
func getDayType(day: Int, split: SplitStyle, totalDays: Int) -> WorkoutDayType {
    switch split {
    case .fullBody:
        return .fullBody
        
    case .upperLower:
        // Alternate upper/lower
        return day % 2 == 1 ? .upper : .lower
        
    case .pushPullLegs:
        // Cycle through push/pull/legs
        let modDay = day % 3
        if modDay == 1 { return .push }
        if modDay == 2 { return .pull }
        return .legs
    }
}

/// Get the muscles targeted on a specific workout day type
/// - Parameter dayType: The workout day type
/// - Returns: Array of muscles that should be trained on this day
func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
    switch dayType {
    case .fullBody:
        // All muscles except unknown
        return MuscleGroup.allCases.filter { $0 != .unknown }
        
    case .upper:
        // Upper body muscles
        return [
            .chest, .back, .shoulders,
                .biceps, .triceps, .forearms, .traps
        ]
        
    case .lower:
        // Lower body muscles
        return [
            .quads, .hamstrings, .glutes,
                .calves, .abs, .obliques, .lowerBack
        ]
        
    case .push:
        // Push-focused muscles
        return [.chest, .shoulders, .triceps]
        
    case .pull:
        // Pull-focused muscles
        return [.back, .biceps, .forearms, .traps]
        
    case .legs:
        // Leg-focused muscles
        return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
    }
}

// Utility: map duration to number of exercises
func getExerciseCount(for duration: WorkoutDuration) -> Int {
    switch duration {
    case .short: return 4
    case .medium: return 6
    case .long: return 8
    }
}

/// Get appropriate rep range based on muscle, goal and experience
/// - Parameters:
///   - muscle: Target muscle group
///   - goal: Training goal (strength, hypertrophy, etc.)
///   - experienceLevel: User's training experience
/// - Returns: Tuple with lower and upper bounds for rep range
func getRepRange(
    for muscle: MuscleGroup,
    goal: TrainingGoal,
    experienceLevel: TrainingExperience
) -> (lower: Int, upper: Int) {
    // Base rep ranges by goal
    switch goal {
    case .strength:
        // Strength focus: lower reps, higher intensity
        return muscle.muscleSize == .large ? (3, 6) : (5, 8)
        
    case .hypertrophy:
        // Hypertrophy focus: moderate reps
        return muscle.muscleSize == .large ? (6, 12) : (8, 15)
    }
}


