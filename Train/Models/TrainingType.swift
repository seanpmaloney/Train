import Foundation

enum TrainingType: String {
    case strength
    case endurance
    case mobility
    case hybrid
    case none
    
    var color: String {
        switch self {
        case .strength: return "#00B4D8"
        case .endurance: return "#FF9F1C"
        case .mobility: return "#4CAF50"
        case .hybrid: return "#9C27B0"
        case .none: return "#000000"
        }
    }
}
