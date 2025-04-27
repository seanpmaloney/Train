import Foundation

enum EquipmentType: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case cable = "Cable"
}

struct MovementEntity: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let notes: String?
    let videoURL: String?
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: EquipmentType
    let movementType: MovementType
    
    var muscleGroups: [MuscleGroup] {
        primaryMuscles + secondaryMuscles
    }

    init(
        type: MovementType,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentType,
        notes: String? = nil,
        videoURL: String? = nil
    ) {
        self.id = UUID()
        self.movementType = type
        self.name = type.displayName
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.notes = notes
        self.videoURL = videoURL
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, videoURL, primaryMuscles, secondaryMuscles, equipment, movementType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL)
        primaryMuscles = try container.decode([MuscleGroup].self, forKey: .primaryMuscles)
        secondaryMuscles = try container.decode([MuscleGroup].self, forKey: .secondaryMuscles)
        equipment = try container.decode(EquipmentType.self, forKey: .equipment)
        movementType = try container.decode(MovementType.self, forKey: .movementType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(videoURL, forKey: .videoURL)
        try container.encode(primaryMuscles, forKey: .primaryMuscles)
        try container.encode(secondaryMuscles, forKey: .secondaryMuscles)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(movementType, forKey: .movementType)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovementEntity, rhs: MovementEntity) -> Bool {
        return lhs.id == rhs.id
    }
}
