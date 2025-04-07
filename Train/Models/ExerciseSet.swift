import Foundation

class ExerciseSetEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var weight: Double
    @Published var targetReps: Int
    @Published var completedReps: Int
    @Published var timestamp: Date

    init(weight: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.weight = weight
        self.targetReps = reps
        self.completedReps = reps
        self.timestamp = Date()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case weight
        case targetReps
        case completedReps
        case timestamp
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.weight = try container.decode(Double.self, forKey: .weight)
        self.targetReps = try container.decode(Int.self, forKey: .targetReps)
        self.completedReps = try container.decode(Int.self, forKey: .completedReps)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(weight, forKey: .weight)
        try container.encode(targetReps, forKey: .targetReps)
        try container.encode(completedReps, forKey: .completedReps)
    }
} 
