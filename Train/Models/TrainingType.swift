import Foundation

enum TrainingType: String {
    case strength
    case endurance
    case mobility
    case hybrid
    case external
    case none
    
    var color: String {
        switch self {
        case .strength: return "#00B4D8"
        case .endurance: return "#FF9F1C"
        case .mobility: return "#4CAF50"
        case .hybrid: return "#9C27B0"
        case .external: return "#6B7280"
        case .none: return "#000000"
        }
    }
}
