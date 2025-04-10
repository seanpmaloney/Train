import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest, back, quads, hamstrings, glutes, calves, biceps, triceps, shoulders, abs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .shoulders: return "Shoulders"
        case .abs: return "Abs"
        }
    }
}
