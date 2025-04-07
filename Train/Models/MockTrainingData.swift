import Foundation

class MockDataProvider {
    static let shared = MockDataProvider()
    
    // MARK: - Sample Data
    
    let benchPress = ExerciseEntity(
        name: "Bench Press",
        notes: "Standard barbell bench press",
        videoURL: "https://example.com/bench-press"
    )
    
    let overheadPress = ExerciseEntity(
        name: "Overhead Press",
        notes: "Standing overhead press with barbell",
        videoURL: "https://example.com/ohp"
    )
    
    let squat = ExerciseEntity(
        name: "Back Squat",
        notes: "High bar back squat",
        videoURL: "https://example.com/squat"
    )
    
    let deadlift = ExerciseEntity(
        name: "Deadlift",
        notes: "Conventional deadlift",
        videoURL: "https://example.com/deadlift"
    )
    
    // MARK: - Mock Data Creation
    
    func createMockData() -> TrainingDataRoot {
        let root = TrainingDataRoot()
        
        // Create muscle groups
        let chest = MuscleGroupEntity(name: "Chest")
        let shoulders = MuscleGroupEntity(name: "Shoulders")
        let legs = MuscleGroupEntity(name: "Legs")
        let back = MuscleGroupEntity(name: "Back")
        
        // Add muscle groups to exercises
        benchPress.muscleGroups = [chest, shoulders]
        overheadPress.muscleGroups = [shoulders]
        squat.muscleGroups = [legs]
        deadlift.muscleGroups = [back, legs]
        
        // Create exercise instances
        let benchInstance = ExerciseInstanceEntity(
            exercise: benchPress,
            exerciseType: "strength",
            note: "Focus on form"
        )
        
        let ohpInstance = ExerciseInstanceEntity(
            exercise: overheadPress,
            exerciseType: "hypertrophy",
            note: "Keep core tight"
        )
        
        // Create sets for exercises
        let benchSets = [
            ExerciseSetEntity(weight: 135, reps: 8),
            ExerciseSetEntity(weight: 155, reps: 6),
            ExerciseSetEntity(weight: 175, reps: 4)
        ]
        
        let ohpSets = [
            ExerciseSetEntity(weight: 95, reps: 10),
            ExerciseSetEntity(weight: 105, reps: 8),
            ExerciseSetEntity(weight: 115, reps: 6)
        ]
        
        // Add sets to instances
        benchInstance.sets = benchSets
        ohpInstance.sets = ohpSets
        
        // Create workout
        let workout = WorkoutEntity(
            title: "Upper Body Strength",
            notes: "Focus on compound movements",
            scheduledDate: Date()
        )
        
        // Add exercise instances to workout
        workout.exercises = [benchInstance, ohpInstance]
        
        // Create training plan
        let plan = TrainingPlanEntity(
            name: "Strength Builder",
            notes: "12-week strength program",
            startDate: Date()
        )
        
        // Add workout to plan
        plan.workouts = [workout]
        
        // Add everything to root
        root.trainingPlans = [plan]
        root.workouts = [workout]
        root.exercises = [benchPress, overheadPress, squat, deadlift]
        root.exerciseInstances = [benchInstance, ohpInstance]
        root.exerciseSets = benchSets + ohpSets
        root.muscleGroups = [chest, shoulders, legs, back]
        
        return root
    }
} 
