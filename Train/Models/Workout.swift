import Foundation

class WorkoutEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var description: String
    @Published var scheduledDate: Date?
    @Published var exercises: [ExerciseInstanceEntity]
    
    init(title: String, description: String, scheduledDate: Date? = nil, exercises: [ExerciseInstanceEntity] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.scheduledDate = scheduledDate
        self.exercises = exercises
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case scheduledDate
        case exercises
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        self.exercises = try container.decode([ExerciseInstanceEntity].self, forKey: .exercises)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encode(exercises, forKey: .exercises)
    }
} 
