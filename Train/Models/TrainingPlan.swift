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
    @Published var musclePreferences: [MuscleTrainingPreference]?
    @Published var trainingGoal: TrainingGoal?
    
    var calculatedEndDate: Date {
        workouts.map { $0.scheduledDate ?? startDate }.max() ?? startDate
    }
    
    /// Returns muscle groups that are prioritized for growth, or empty array if no preferences
    var prioritizedMuscles: [MuscleGroup] {
        musclePreferences?.filter { $0.goal == .grow }.map { $0.muscleGroup } ?? []
    }
    
    /// Returns true if this is an adaptive plan with muscle preferences
    var isAdaptivePlan: Bool {
        return musclePreferences != nil && trainingGoal != nil
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
        case id, name, notes, startDate, endDate, daysPerWeek, isCompleted, workouts, musclePreferences, trainingGoal
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
        
        // Handle optional new properties for backward compatibility
        musclePreferences = try container.decodeIfPresent([MuscleTrainingPreference].self, forKey: .musclePreferences)
        trainingGoal = try container.decodeIfPresent(TrainingGoal.self, forKey: .trainingGoal)
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
        
        // Encode new properties only if they exist
        try container.encodeIfPresent(musclePreferences, forKey: .musclePreferences)
        try container.encodeIfPresent(trainingGoal, forKey: .trainingGoal)
    }
    
    func percentageCompleted() -> Double {
        let totalWorkouts = workouts.count
        let completedWorkouts = workouts.filter { $0.isComplete }.count
        return totalWorkouts > 0 ? Double(completedWorkouts) / Double(totalWorkouts) : 0.0
    }
}
