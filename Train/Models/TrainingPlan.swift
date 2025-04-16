import Foundation

class TrainingPlanEntity: ObservableObject, Identifiable, Codable {
    var id: UUID = UUID()
    @Published var name: String
    @Published var notes: String?
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var daysPerWeek: Int
    @Published var isCompleted: Bool
    @Published var workouts: [WorkoutEntity] = []
    
    var calculatedEndDate: Date {
        workouts.map { $0.scheduledDate ?? startDate }.max() ?? startDate
    }

    init(name: String, notes: String? = nil, startDate: Date, daysPerWeek: Int = 3, isCompleted: Bool = false) {
        self.name = name
        self.notes = notes
        self.startDate = startDate
        self.endDate = startDate
        self.daysPerWeek = daysPerWeek
        self.isCompleted = isCompleted
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, startDate, endDate, daysPerWeek, isCompleted, workouts
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        daysPerWeek = try container.decode(Int.self, forKey: .daysPerWeek)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        workouts = try container.decode([WorkoutEntity].self, forKey: .workouts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(daysPerWeek, forKey: .daysPerWeek)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(workouts, forKey: .workouts)
    }
    
    func percentageCompleted() -> Double {
        let totalWorkouts = workouts.count
        let completedWorkouts = workouts.filter { $0.isComplete }.count
        return totalWorkouts > 0 ? Double(completedWorkouts) / Double(totalWorkouts) : 0.0
    }
}
