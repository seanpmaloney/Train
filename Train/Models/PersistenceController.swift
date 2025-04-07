import CoreData

struct PersistenceController {
    // MARK: - Static Properties
    
    /// The shared instance for use across the app
    static let shared = PersistenceController()
    
    /// Preview instance with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        let viewContext = controller.container.viewContext
        
        // Create sample workout
        let workout = WorkoutEntity(context: viewContext)
        workout.id = UUID()
        workout.title = "Upper Body Strength"
        workout.scheduledDate = Calendar.current.startOfDay(for: Date())
        
        // Create exercises
        let exercises = [
            ("Bench Press", "strength"),
            ("Overhead Press", "hypertrophy")
        ]
        
        for (name, type) in exercises {
            let exercise = ExerciseEntity(context: viewContext)
            exercise.id = UUID()
            exercise.name = name
            workout.addToExercises(exercise)
            
            let instance = ExerciseInstanceEntity(context: viewContext)
            instance.id = UUID()
            instance.exercise = exercise
            instance.exerciseType = type
        }
        
        try? viewContext.save()
        return controller
    }()
    
    // MARK: - Properties
    
    /// The Core Data container
    let container: NSPersistentContainer
    
    // MARK: - Initialization
    
    /// Initialize the Core Data stack
    /// - Parameter inMemory: If true, uses an in-memory store instead of persisting to disk
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Train")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In development, we want to catch store loading failures early
                fatalError("Failed to load Core Data stack: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure view context to roll back rather than fail on conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Create sample data if needed
        createSampleDataIfNeeded()
    }
    
    private func createSampleDataIfNeeded() {
        let fetchRequest: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        do {
            let count = try container.viewContext.count(for: fetchRequest)
            if count == 0 {
                // Create sample workout
                let workout = WorkoutEntity(context: container.viewContext)
                workout.id = UUID()
                workout.title = "Upper Body Strength"
                workout.scheduledDate = Calendar.current.startOfDay(for: Date())
                
                // Create exercises
                let exercises = [
                    ("Bench Press", "strength"),
                    ("Overhead Press", "hypertrophy")
                ]
                
                for (name, type) in exercises {
                    let exercise = ExerciseEntity(context: container.viewContext)
                    exercise.id = UUID()
                    exercise.name = name
                    workout.addToExercises(exercise)
                    
                    let instance = ExerciseInstanceEntity(context: container.viewContext)
                    instance.id = UUID()
                    instance.exercise = exercise
                    instance.exerciseType = type
                }
                
                try container.viewContext.save()
            }
        } catch {
            print("Error creating sample data: \(error)")
        }
    }
}
