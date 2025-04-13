import Foundation

struct MovementLibrary {
    static let allMovements: [MovementEntity] = [
        // Chest
        MovementEntity(
            name: "Barbell Bench Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Dumbbell Incline Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Push-Ups",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Cable Flyes",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable
        ),
        MovementEntity(
            name: "Machine Pec Deck",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .machine
        ),
        MovementEntity(
            name: "Dumbbell Bench Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Cable Chest Fly",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable
        ),
        
        // Back
        MovementEntity(
            name: "Barbell Deadlift",
            primaryMuscles: [.back],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Pull-Ups",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Bent Over Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Lat Pulldown",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .machine
        ),
        MovementEntity(
            name: "Seated Cable Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .cable
        ),
        MovementEntity(
            name: "Dumbbell Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Cable Pullover",
            primaryMuscles: [.back],
            secondaryMuscles: [.abs],
            equipment: .cable
        ),
        MovementEntity(
            name: "Chin-Ups",
            primaryMuscles: [.back, .biceps],
            secondaryMuscles: [],
            equipment: .bodyweight
        ),
        
        // Legs
        MovementEntity(
            name: "Barbell Back Squat",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Romanian Deadlift",
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [.glutes, .back],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Leg Press",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .machine
        ),
        MovementEntity(
            name: "Bulgarian Split Squat",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Standing Calf Raise",
            primaryMuscles: [.calves],
            equipment: .machine
        ),
        MovementEntity(
            name: "Leg Extension",
            primaryMuscles: [.quads],
            equipment: .machine
        ),
        MovementEntity(
            name: "Lying Leg Curl",
            primaryMuscles: [.hamstrings],
            equipment: .machine
        ),
        MovementEntity(
            name: "Goblet Squat",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Sled Push",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .calves],
            equipment: .machine
        ),
        MovementEntity(
            name: "Barbell Front Squat",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        ),
        
        // Shoulders
        MovementEntity(
            name: "Overhead Press",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Lateral Raise",
            primaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Face Pull",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.back],
            equipment: .cable
        ),
        MovementEntity(
            name: "Front Raise",
            primaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Arnold Press",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Machine Lateral Raise",
            primaryMuscles: [.shoulders],
            equipment: .machine
        ),
        
        // Arms
        MovementEntity(
            name: "Barbell Curl",
            primaryMuscles: [.biceps],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Tricep Pushdown",
            primaryMuscles: [.triceps],
            equipment: .cable
        ),
        MovementEntity(
            name: "Hammer Curl",
            primaryMuscles: [.biceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Skull Crushers",
            primaryMuscles: [.triceps],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Preacher Curl",
            primaryMuscles: [.biceps],
            equipment: .machine
        ),
        MovementEntity(
            name: "Concentration Curl",
            primaryMuscles: [.biceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Overhead Tricep Extension",
            primaryMuscles: [.triceps],
            secondaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Cable Curl",
            primaryMuscles: [.biceps],
            equipment: .cable
        ),
        
        // Core
        MovementEntity(
            name: "Cable Crunch",
            primaryMuscles: [.abs],
            equipment: .cable
        ),
        MovementEntity(
            name: "Plank",
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Russian Twist",
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Hanging Leg Raise",
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Decline Sit-Up",
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Ab Wheel Rollout",
            primaryMuscles: [.abs],
            secondaryMuscles: [.shoulders],
            equipment: .bodyweight
        ),
        
        // Compound Movements
        MovementEntity(
            name: "Dips",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .bodyweight
        ),
        MovementEntity(
            name: "Clean and Press",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.back, .quads, .glutes],
            equipment: .barbell
        ),
        MovementEntity(
            name: "T-Bar Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .machine
        ),
        MovementEntity(
            name: "Hip Thrust",
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings],
            equipment: .barbell
        ),
        MovementEntity(
            name: "Incline Dumbbell Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            name: "Machine Chest Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .machine
        )
    ]
}
