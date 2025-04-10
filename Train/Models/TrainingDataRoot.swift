import Foundation

class TrainingDataRoot: ObservableObject, Codable {
    @Published var trainingPlans: [TrainingPlanEntity]
    @Published var workouts: [WorkoutEntity]
    @Published var exercises: [MovementEntity]
    @Published var exerciseInstances: [ExerciseInstanceEntity]
    @Published var exerciseSets: [ExerciseSetEntity]
    @Published var muscleGroups: [MuscleGroup]
    
    init(
        trainingPlans: [TrainingPlanEntity] = [],
        workouts: [WorkoutEntity] = [],
        exercises: [MovementEntity] = [],
        exerciseInstances: [ExerciseInstanceEntity] = [],
        exerciseSets: [ExerciseSetEntity] = [],
        muscleGroups: [MuscleGroup] = []
    ) {
        self.trainingPlans = trainingPlans
        self.workouts = workouts
        self.exercises = exercises
        self.exerciseInstances = exerciseInstances
        self.exerciseSets = exerciseSets
        self.muscleGroups = muscleGroups
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case trainingPlans
        case workouts
        case movements
        case exerciseInstances
        case exerciseSets
        case muscleGroups
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.trainingPlans = try container.decode([TrainingPlanEntity].self, forKey: .trainingPlans)
        self.workouts = try container.decode([WorkoutEntity].self, forKey: .workouts)
        self.exercises = try container.decode([MovementEntity].self, forKey: .movements)
        self.exerciseInstances = try container.decode([ExerciseInstanceEntity].self, forKey: .exerciseInstances)
        self.exerciseSets = try container.decode([ExerciseSetEntity].self, forKey: .exerciseSets)
        self.muscleGroups = try container.decode([MuscleGroup].self, forKey: .muscleGroups)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trainingPlans, forKey: .trainingPlans)
        try container.encode(workouts, forKey: .workouts)
        try container.encode(exercises, forKey: .movements)
        try container.encode(exerciseInstances, forKey: .exerciseInstances)
        try container.encode(exerciseSets, forKey: .exerciseSets)
        try container.encode(muscleGroups, forKey: .muscleGroups)
    }
} 
