import Foundation

enum EquipmentType: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case cable = "Cable"
}

enum MovementPattern: String, Codable {
    // Big compound patterns
    case horizontalPush
    case verticalPush
    case horizontalPull
    case verticalPull
    case squat
    case hinge
    case lunge
    case carry
    
    // Core/control
    case core
    case rotation
    case antiRotation
    case antiExtension
    
    // Isolation/supportive
    case abduction       // e.g. lateral raise
    case adduction       // e.g. chest fly
    case elbowFlexion    // e.g. curls
    case elbowExtension  // e.g. triceps
    case kneeExtension   // e.g. leg extension
    case kneeFlexion     // e.g. leg curl
    
    case unknown
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
    let movementPattern: MovementPattern
    let isCompound: Bool
    
    var muscleGroups: [MuscleGroup] {
        primaryMuscles + secondaryMuscles
    }

    init(
        type: MovementType,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentType,
        notes: String? = nil,
        videoURL: String? = nil,
        movementPattern: MovementPattern = .unknown,
        isCompound: Bool = false
    ) {
        self.id = UUID()
        self.movementType = type
        self.name = type.displayName
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.notes = notes
        self.videoURL = videoURL
        self.movementPattern = movementPattern
        self.isCompound = isCompound
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, videoURL, primaryMuscles, secondaryMuscles, equipment, movementType, movementPattern, isCompound
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
        movementPattern = try container.decode(MovementPattern.self, forKey: .movementPattern)
        isCompound = try container.decode(Bool.self, forKey: .isCompound)
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
        try container.encode(movementPattern, forKey: .movementPattern)
        try container.encode(isCompound, forKey: .isCompound)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovementEntity, rhs: MovementEntity) -> Bool {
        return lhs.id == rhs.id
    }
}
