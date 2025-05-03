import Foundation

/// Represents the training goal for a specific muscle group
enum MuscleGoal: String, Codable, CaseIterable, Identifiable {
    case grow = "Grow"
    case maintain = "Maintain"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .grow:
            return "Focus on muscle growth with higher volume"
        case .maintain:
            return "Maintain current muscle mass with sufficient volume"
        }
    }
}

/// Stores a user's training preference for a specific muscle group
struct MuscleTrainingPreference: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let muscleGroup: MuscleGroup
    var goal: MuscleGoal
    
    static func == (lhs: MuscleTrainingPreference, rhs: MuscleTrainingPreference) -> Bool {
        return lhs.muscleGroup == rhs.muscleGroup && lhs.goal == rhs.goal
    }
    
    /// Calculate the recommended weekly sets based on the selected goal
    var recommendedWeeklySets: Int {
        switch goal {
        case .grow:
            return muscleGroup.trainingGuidelines.minHypertrophySets
        case .maintain:
            return muscleGroup.trainingGuidelines.minMaintenanceSets
        }
    }
}
