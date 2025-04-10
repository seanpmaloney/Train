import Foundation

class TrainingPlanEntity: ObservableObject, Identifiable, Codable {
    let id: UUID = UUID()
    @Published var name: String
    @Published var notes: String?
    @Published var startDate: Date
    @Published var workouts: [WorkoutEntity] = []
    
    var endDate: Date {
        workouts.map { $0.scheduledDate ?? startDate }.max() ?? startDate
    }

    init(name: String, notes: String? = nil, startDate: Date) {
        self.name = name
        self.notes = notes
        self.startDate = startDate
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, startDate, workouts
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        startDate = try container.decode(Date.self, forKey: .startDate)
        workouts = try container.decode([WorkoutEntity].self, forKey: .workouts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(workouts, forKey: .workouts)
    }
}
