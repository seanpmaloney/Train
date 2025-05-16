import Foundation

class ExerciseInstanceEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var movement: MovementEntity
    var exerciseType: String
    var sets: [ExerciseSetEntity]
    var note: String?
    // Flag to indicate if this exercise might aggravate joint pain
    var shouldShowJointWarning: Bool = false
    // Exercise-specific feedback
    var feedback: ExerciseFeedback?
    
    init(movement: MovementEntity, exerciseType : String = "", sets: [ExerciseSetEntity] = [], note: String? = nil, shouldShowJointWarning: Bool = false, feedback: ExerciseFeedback? = nil) {
        self.id = UUID()
        self.movement = movement
        self.sets = sets
        self.note = note
        self.exerciseType = exerciseType
        self.shouldShowJointWarning = shouldShowJointWarning
        self.feedback = feedback
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case movement
        case exerciseType
        case sets
        case feedback
        case note
        case shouldShowJointWarning
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.movement = try container.decode(MovementEntity.self, forKey: .movement)
        self.exerciseType = try container.decode(String.self, forKey: .exerciseType)
        self.sets = try container.decode([ExerciseSetEntity].self, forKey: .sets)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.shouldShowJointWarning = try container.decodeIfPresent(Bool.self, forKey: .shouldShowJointWarning) ?? false
        self.feedback = try container.decodeIfPresent(ExerciseFeedback.self, forKey: .feedback)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(movement, forKey: .movement)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(sets, forKey: .sets)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(shouldShowJointWarning, forKey: .shouldShowJointWarning)
        try container.encodeIfPresent(feedback, forKey: .feedback)
    }
    
    // MARK: - Exercise Status
    
    /// Whether the exercise is complete (all sets are complete)
    var isComplete: Bool {
        // An exercise is complete when all its sets are marked as complete
        guard !sets.isEmpty else { return false }
        return sets.allSatisfy { $0.isComplete }
    }
    
    // MARK: - Movement Replacement
    
    /// Replaces the current movement with a new one
    /// This change is persisted to the workout and will save in state
    /// - Parameter newMovement: The movement to replace the current one with
    func replaceMovement(with newMovement: MovementEntity) {
        self.movement = newMovement
        objectWillChange.send()
    }
} 
