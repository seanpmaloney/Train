import Foundation

class WorkoutEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var description: String
    @Published var isComplete: Bool
    @Published var scheduledDate: Date?
    @Published var exercises: [ExerciseInstanceEntity]
    weak var trainingPlan: TrainingPlanEntity?
    
    // Feedback properties
    var preWorkoutFeedback: PreWorkoutFeedback?
    var postWorkoutFeedback: PostWorkoutFeedback?
    
    init(title: String, description: String, isComplete: Bool, scheduledDate: Date? = nil, exercises: [ExerciseInstanceEntity] = [], preWorkoutFeedback: PreWorkoutFeedback? = nil, postWorkoutFeedback: PostWorkoutFeedback? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isComplete = isComplete
        self.scheduledDate = scheduledDate
        self.exercises = exercises
        self.preWorkoutFeedback = preWorkoutFeedback
        self.postWorkoutFeedback = postWorkoutFeedback
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isComplete
        case scheduledDate
        case exercises
        case preWorkoutFeedback
        case postWorkoutFeedback
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        self.exercises = try container.decode([ExerciseInstanceEntity].self, forKey: .exercises)
        self.preWorkoutFeedback = try container.decodeIfPresent(PreWorkoutFeedback.self, forKey: .preWorkoutFeedback)
        self.postWorkoutFeedback = try container.decodeIfPresent(PostWorkoutFeedback.self, forKey: .postWorkoutFeedback)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encode(exercises, forKey: .exercises)
        try container.encodeIfPresent(preWorkoutFeedback, forKey: .preWorkoutFeedback)
        try container.encodeIfPresent(postWorkoutFeedback, forKey: .postWorkoutFeedback)
    }
    
    func copy() -> WorkoutEntity {
        let copiedExercises = exercises.map { exercise -> ExerciseInstanceEntity in
            let copiedSets = exercise.sets.map { $0.copy() as! ExerciseSetEntity }
            return ExerciseInstanceEntity(
                movement: exercise.movement,
                exerciseType: exercise.exerciseType,
                sets: copiedSets,
                feedback: exercise.feedback
            )
        }
        
        return WorkoutEntity(
            title: self.title,
            description: self.description,
            isComplete: self.isComplete,
            scheduledDate: self.scheduledDate,
            exercises: copiedExercises,
            preWorkoutFeedback: self.preWorkoutFeedback,
            postWorkoutFeedback: self.postWorkoutFeedback
        )
    }
} 
