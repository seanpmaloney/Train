import Foundation

/// Template for creating a training plan
struct PlanTemplate: Identifiable {
    let id = UUID()
    let title: String
    let goal: TrainingGoal
    let scheduleDays: [WorkoutDay]
    let daysPerWeek: Int
    let suggestedDuration: String
    let type: TrainingPlanBuilder.SplitStyle
    let workoutDays: [WorkoutDayTemplate]
    
    // Format workout days for display
    var scheduleString: String {
        WorkoutDay.formatSchedule(scheduleDays)
    }
    
    static let templates: [PlanTemplate] = [
        PlanTemplate(
            title: "Full Body",
            goal: .strength,
            scheduleDays: [.monday, .wednesday, .friday],
            daysPerWeek: 3,
            suggestedDuration: "4-12 weeks",
            type: .fullBody,
            workoutDays: [
                WorkoutDayTemplate(
                    label: "Day 1",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBackSquat), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBenchPress), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .latPulldown), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .romanianDeadlift), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .standingCalfRaise), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Day 2",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellFrontSquat), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadPress), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .seatedCableRow), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lyingLegCurl), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellCurl), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Day 3",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellDeadlift), sets: 3, reps: 6),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dumbbellInclinePress), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .pullUps), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legExtension), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .tricepPushdown), sets: 3, reps: 12)
                    ]
                )
            ]
        ),
        PlanTemplate(
            title: "Upper/Lower",
            goal: .hypertrophy,
            scheduleDays: [.monday, .tuesday, .thursday, .friday],
            daysPerWeek: 4,
            suggestedDuration: "8-16 weeks",
            type: .upperLower,
            workoutDays: [
                WorkoutDayTemplate(
                    label: "Upper 1",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBenchPress), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .bentOverRow), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dips), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .chinUps), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lateralRaise), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .seatedCableRow), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Lower 1",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBackSquat), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .romanianDeadlift), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legExtension), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .standingCalfRaise), sets: 4, reps: 15)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Upper 2",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadPress), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dumbbellInclinePress), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .latPulldown), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellCurl), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dumbbellRow), sets: 3, reps: 10)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Lower 2",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBackSquat), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .bulgarianSplitSquat), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legExtension), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lyingLegCurl), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .standingCalfRaise), sets: 3, reps: 15)
                    ]
                )
            ]
        ),
        PlanTemplate(
            title: "Push/Pull/Legs",
            goal: .hypertrophy,
            scheduleDays: [.monday, .wednesday, .friday],
            daysPerWeek: 3,
            suggestedDuration: "12-16 weeks",
            type: .pushPullLegs,
            workoutDays: [
                WorkoutDayTemplate(
                    label: "Push",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBenchPress), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadPress), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dumbbellInclinePress), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lateralRaise), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .tricepPushdown), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadTricepExtension), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Pull",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellDeadlift), sets: 3, reps: 6),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .pullUps), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .bentOverRow), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .facePull), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellCurl), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .hammerCurl), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Legs",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBackSquat), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .romanianDeadlift), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legPress), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legExtension), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lyingLegCurl), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .standingCalfRaise), sets: 4, reps: 15)
                    ]
                )
            ]
        ),
        PlanTemplate(
            title: "5-Day Split",
            goal: .hypertrophy,
            scheduleDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            daysPerWeek: 5,
            suggestedDuration: "12-16 weeks",
            type: .fiveDaySplit,
            workoutDays: [
                WorkoutDayTemplate(
                    label: "Chest",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBenchPress), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dumbbellInclinePress), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .dips), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .cableChestFly), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .pushUps), sets: 3, reps: 15)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Back",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellDeadlift), sets: 3, reps: 6),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .pullUps), sets: 3, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .bentOverRow), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .latPulldown), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .seatedCableRow), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Legs",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellBackSquat), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legPress), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .romanianDeadlift), sets: 3, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .legExtension), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lyingLegCurl), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .standingCalfRaise), sets: 3, reps: 20)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Shoulders",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadPress), sets: 4, reps: 8),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .lateralRaise), sets: 4, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .frontRaise), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .facePull), sets: 3, reps: 15),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .uprightRow), sets: 3, reps: 12)
                    ]
                ),
                WorkoutDayTemplate(
                    label: "Arms",
                    exercises: [
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .barbellCurl), sets: 4, reps: 10),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .hammerCurl), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .tricepPushdown), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .overheadTricepExtension), sets: 3, reps: 12),
                        createExerciseInstance(movement: MovementLibrary.getMovement(type: .skullCrushers), sets: 3, reps: 10)
                    ]
                )
            ]
        )
    ]
    
    /// Helper function to create an exercise instance with sets and reps
    private static func createExerciseInstance(movement: MovementEntity, sets: Int, reps: Int) -> ExerciseInstanceEntity {
        let exerciseSets = (0..<sets).map { _ in
            ExerciseSetEntity(weight: 0, completedReps: 0, targetReps: reps, isComplete: false)
        }
        return ExerciseInstanceEntity(movement: movement, exerciseType: "strength", sets: exerciseSets)
    }
}

/// Structure defining a day in a workout template
struct WorkoutDayTemplate {
    let label: String
    let exercises: [ExerciseInstanceEntity]
}

enum TrainingGoal: String, Codable {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy"
    case endurance = "Endurance"
    case powerbuilding = "Powerbuilding"
}
