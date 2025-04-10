import Foundation
import Combine

class TrainingDataStore: ObservableObject {
    // MARK: - Singleton
    static let shared = TrainingDataStore()
    
    // MARK: - Properties
    @Published private(set) var data: TrainingDataRoot
    private let fileURL: URL
    private var saveCancellable: AnyCancellable?
    private let mockProvider = MockDataProvider.shared
    
    // MARK: - Initialization
    private init() {
        // Get the documents directory URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentsDirectory.appendingPathComponent("training_data.json")
        
        // Initialize with empty data
        self.data = TrainingDataRoot()
        
        // Load data from disk
        load()
        
        // Set up automatic saving
        setupAutomaticSaving()
    }
    
    // MARK: - Public Methods
    
    /// Load data from disk
    func load() {
        Task {
            await loadAsync()
        }
    }
    
    /// Save data to disk
    func save() {
        Task {
            await saveAsync()
        }
    }
    
    /// Reset all data
    func reset() {
        Task {
            await resetAsync()
        }
    }
    
    /// Load mock data for development
    func loadMockData() {
        Task {
            await MainActor.run {
                self.data = mockProvider.createMockData()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAutomaticSaving() {
        // Observe changes to the data and save automatically
        saveCancellable = $data
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }
    
    private func loadAsync() async {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let root = try decoder.decode(TrainingDataRoot.self, from: data)
            
            await MainActor.run {
                self.data = root
            }
        } catch {
            print("Error loading data: \(error)")
            // If loading fails, load mock data for development
            await MainActor.run {
                self.data = mockProvider.createMockData()
            }
        }
    }
    
    private func saveAsync() async {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.data)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    private func resetAsync() async {
        await MainActor.run {
            self.data = TrainingDataRoot()
        }
        await saveAsync()
    }
    
    // MARK: - Data Access Methods
    
    func addTrainingPlan(_ plan: TrainingPlanEntity) {
        data.trainingPlans.append(plan)
    }
    
    func addWorkout(_ workout: WorkoutEntity) {
        data.workouts.append(workout)
    }
    
    func addMovement(_ movement: MovementEntity) {
        data.exercises.append(movement)
    }
    
    func addExerciseInstance(_ instance: ExerciseInstanceEntity) {
        data.exerciseInstances.append(instance)
    }
    
    func addExerciseSet(_ set: ExerciseSetEntity) {
        data.exerciseSets.append(set)
    }
    
    // MARK: - Data Query Methods
    
    func getTrainingPlan(withId id: UUID) -> TrainingPlanEntity? {
        data.trainingPlans.first { $0.id == id }
    }
    
    func getWorkout(withId id: UUID) -> WorkoutEntity? {
        data.workouts.first { $0.id == id }
    }
    
    func getMovement(withId id: UUID) -> MovementEntity? {
        data.exercises.first { $0.id == id }
    }
    
    func getExerciseInstance(withId id: UUID) -> ExerciseInstanceEntity? {
        data.exerciseInstances.first { $0.id == id }
    }
    
    func getExerciseSet(withId id: UUID) -> ExerciseSetEntity? {
        data.exerciseSets.first { $0.id == id }
    }
    
    // MARK: - Convenience Methods
    
    func getTodaysWorkouts() -> [WorkoutEntity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return data.workouts.filter { workout in
            guard let date = workout.scheduledDate else { return false }
            return date >= today && date < tomorrow
        }
    }
} 
