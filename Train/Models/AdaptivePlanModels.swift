// TODO: Rename this file to PlanModels.swift for consistency with the naming convention

import SwiftUI

// MARK: - Models for Plan Setup

/// Training goal options
enum TrainingGoal: String, CaseIterable, Identifiable, Codable {
    case hypertrophy = "Build Muscle"
    case strength = "Gain Strength"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .hypertrophy:
            return "Focus on adding muscle mass through higher volume training"
        case .strength:
            return "Focus on getting stronger with lower rep, higher intensity training"
        }
    }
}

/// Training frequency options
enum DaysPerWeek: String, CaseIterable, Identifiable, Codable {
    case two = "2 days"
    case three = "3 days"
    case four = "4 days"
    case five = "5 days"
    case six = "6 days"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .two:
            return "Busy schedule (weekend warrior)"
        case .three:
            return "Balanced approach"
        case .four:
            return "Consistent training"
        case .five:
            return "Dedicated training"
        case .six:
            return "All-in"
        }
    }
}

/// Workout duration options
enum WorkoutDuration: String, CaseIterable, Identifiable, Codable {
    case short = "~30 minutes"
    case medium = "~45 minutes"
    case long = "~60+ minutes"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .short:
            return "Quick, focused workouts"
        case .medium:
            return "Balanced duration and intensity"
        case .long:
            return "Complete, thorough sessions"
        }
    }
}

/// Split style options
enum SplitStyle: String, CaseIterable, Identifiable, Codable {
    case fullBody = "Full Body"
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .fullBody:
            return "Train all major muscle groups in each workout"
        case .upperLower:
            return "Alternate between upper and lower body days"
        case .pushPullLegs:
            return "Separate pushing, pulling, and leg exercises"
        }
    }
}

/// Training experience level
enum TrainingExperience: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "New to resistance training with little or no experience"
        case .intermediate:
            return "Familiar with exercises but less than 3 years structured training"
        case .advanced:
            return "3+ years of structured training, comfortable with all movements"
        }
    }
    
    /// Convert to numeric training age for volume calculations
    var trainingAge: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 2
        case .advanced: return 4
        }
    }
}

/// Model to hold all plan preferences
struct PlanPreferences {
    var trainingGoal: TrainingGoal?
    var priorityMuscles: Set<MuscleGroup> = []
    var daysPerWeek: DaysPerWeek?
    var workoutDuration: WorkoutDuration?
    var availableEquipment: Set<EquipmentType> = []
    var splitStyle: SplitStyle?
    var trainingExperience: TrainingExperience?
    
    /// Returns true if all required preferences are set
    var isComplete: Bool {
        return trainingGoal != nil && 
               daysPerWeek != nil && 
               workoutDuration != nil && 
               !availableEquipment.isEmpty &&
               splitStyle != nil &&
               trainingExperience != nil
    }
}
