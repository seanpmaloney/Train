import Foundation

class ExerciseInstanceEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    let movement: MovementEntity
    var exerciseType: String
    var sets: [ExerciseSetEntity]
    var note: String?
    
    init(movement: MovementEntity, exerciseType : String = "", sets: [ExerciseSetEntity] = [], note: String? = nil) {
        self.id = UUID()
        self.movement = movement
        self.sets = sets
        self.note = note
        self.exerciseType = exerciseType
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case movement
        case exerciseType
        case sets
        case note
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.movement = try container.decode(MovementEntity.self, forKey: .movement)
        self.exerciseType = try container.decode(String.self, forKey: .exerciseType)
        self.sets = try container.decode([ExerciseSetEntity].self, forKey: .sets)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(movement, forKey: .movement)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(sets, forKey: .sets)
        try container.encodeIfPresent(note, forKey: .note)
    }
} 
