import Foundation

typealias WorkoutFeedbackBundle = (pre: PreWorkoutFeedback?, exercises: [ExerciseFeedback], post: PostWorkoutFeedback?)

class TrainingPlanEntity: ObservableObject, Identifiable, Codable {
    var id: UUID = UUID()
    @Published var name: String
    @Published var notes: String?
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var daysPerWeek: Int
    @Published var isCompleted: Bool
    @Published var musclePreferences: [MuscleTrainingPreference]?
    @Published var trainingGoal: TrainingGoal?
    @Published var weeklyWorkouts: [[WorkoutEntity]] = []
    @Published var workoutFeedbacks: [WorkoutFeedback] = []
    
    var calculatedEndDate: Date {
        weeklyWorkouts
            .flatMap { $0 }
            .compactMap { $0.scheduledDate }
            .max() ?? startDate
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
        case id, name, notes, startDate, endDate, daysPerWeek, isCompleted, weeklyWorkouts, musclePreferences, trainingGoal, workoutFeedbacks
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
        weeklyWorkouts = try container.decode([[WorkoutEntity]].self, forKey: .weeklyWorkouts)
        
        // Handle optional new properties for backward compatibility
        musclePreferences = try container.decodeIfPresent([MuscleTrainingPreference].self, forKey: .musclePreferences)
        trainingGoal = try container.decodeIfPresent(TrainingGoal.self, forKey: .trainingGoal)
        workoutFeedbacks = try container.decode([WorkoutFeedback].self, forKey: .workoutFeedbacks)
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
        try container.encode(weeklyWorkouts, forKey: .weeklyWorkouts)
        try container.encode(workoutFeedbacks, forKey: .workoutFeedbacks)
        
        // Encode new properties only if they exist
        try container.encodeIfPresent(musclePreferences, forKey: .musclePreferences)
        try container.encodeIfPresent(trainingGoal, forKey: .trainingGoal)
    }
    
    func percentageCompleted() -> Double {
        let allWorkouts = weeklyWorkouts.flatMap { $0 }
        let completed = allWorkouts.filter { $0.isComplete }.count
        return allWorkouts.isEmpty ? 0.0 : Double(completed) / Double(allWorkouts.count)
    }
    
    // MARK: - Feedback Management
    
    /// Adds feedback to this plan
    func addFeedback(_ feedback: WorkoutFeedback) {
        // Ensure the workout belongs to this plan
        let allWorkoutIds = Set(weeklyWorkouts.flatMap { $0 }.map(\.id))
        guard allWorkoutIds.contains(feedback.workoutId) else { return }

        // Remove existing feedback for same target and type
        workoutFeedbacks.removeAll {
            switch (feedback, $0) {
            case let (new as ExerciseFeedback, existing as ExerciseFeedback):
                return new.workoutId == existing.workoutId && new.exerciseId == existing.exerciseId
            case (_ as PreWorkoutFeedback, _ as PreWorkoutFeedback),
                 (_ as PostWorkoutFeedback, _ as PostWorkoutFeedback):
                return feedback.workoutId == $0.workoutId
            default:
                return false
            }
        }

        workoutFeedbacks.append(feedback)
    }
    
    /// Get all feedback for a specific workout
    func getFeedback(for workoutId: UUID) -> WorkoutFeedbackBundle {
        let allFeedback = workoutFeedbacks.filter { $0.workoutId == workoutId }
        
        let preFeedback = allFeedback.first { $0 is PreWorkoutFeedback } as? PreWorkoutFeedback
        let exerciseFeedbacks = allFeedback.compactMap { $0 as? ExerciseFeedback }
        let postFeedback = allFeedback.first { $0 is PostWorkoutFeedback } as? PostWorkoutFeedback
        
        return (pre: preFeedback, exercises: exerciseFeedbacks, post: postFeedback)
    }
    
    /// Get the most recent feedback for a specific muscle
    func getMostRecentFeedbackForMuscle(_ muscle: MuscleGroup) -> PreWorkoutFeedback? {
        return workoutFeedbacks
            .compactMap { $0 as? PreWorkoutFeedback }
            .filter { $0.soreMuscles.contains(muscle) }
            .sorted { $0.date > $1.date }
            .first
    }
}
