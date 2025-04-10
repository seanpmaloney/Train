import Foundation

class MockDataProvider {
    static let shared = MockDataProvider()
    
    // MARK: - Sample Data
    
    let benchPress = MovementEntity(
        name: "Bench Press",
        notes: "Standard barbell bench press",
        videoURL: "https://example.com/bench-press"
    )
    
    let overheadPress = MovementEntity(
        name: "Overhead Press",
        notes: "Standing overhead press with barbell",
        videoURL: "https://example.com/ohp"
    )
    
    let squat = MovementEntity(
        name: "Back Squat",
        notes: "High bar back squat",
        videoURL: "https://example.com/squat"
    )
    
    let deadlift = MovementEntity(
        name: "Deadlift",
        notes: "Conventional deadlift",
        videoURL: "https://example.com/deadlift"
    )
    
    let hypertophySet = ExerciseSetEntity(weight: 135.0, completedReps: 0, targetReps: 12, isComplete: false)
    let strengthSet = ExerciseSetEntity(weight: 135.0, completedReps: 0, targetReps: 12, isComplete: false)
    
    // MARK: - Mock Data Creation
    
    func createMockData() -> TrainingDataRoot {
        let root = TrainingDataRoot()
        
        // Create muscle groups
        let chest = MuscleGroup.chest
        let shoulders = MuscleGroup.shoulders
        let legs = [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.glutes]
        let back = MuscleGroup.back
        
        // Add muscle groups to exercises
        benchPress.muscleGroups = [chest, shoulders]
        overheadPress.muscleGroups = [shoulders]
        squat.muscleGroups = legs
        deadlift.muscleGroups = [back] + legs
        
        // Create exercise instances
        let benchInstance = ExerciseInstanceEntity(
            movement: benchPress,
            exerciseType: "strength",
            sets: [strengthSet, strengthSet, strengthSet],
            note: "Focus on form"
        )
        
        let ohpInstance = ExerciseInstanceEntity(
            movement: overheadPress,
            exerciseType: "hypertrophy",
            sets: [hypertophySet, hypertophySet, hypertophySet],
            note: "Keep core tight"
        )
        
        let squatInstance = ExerciseInstanceEntity(
            movement: squat,
            exerciseType: "hypertrophy",
            sets: [hypertophySet, hypertophySet, hypertophySet],
            note: "Keep core tight"
        )
        
        let deadliftInstance = ExerciseInstanceEntity(
            movement: deadlift,
            exerciseType: "strength",
            sets: [strengthSet, strengthSet, strengthSet],
            note: "Keep core tight"
        )
        
        // Create workout
        let workout = WorkoutEntity(
            title: "Upper Body Strength",
            description: "Focus on compound movements",
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
        root.exerciseSets = benchInstance.sets + ohpInstance.sets
        root.muscleGroups = [chest, shoulders, back] + legs
        
        return root
    }
} 
