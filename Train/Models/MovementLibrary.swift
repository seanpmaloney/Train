import Foundation

struct MovementLibrary {
    static let allMovements: [MovementEntity] = [
        // Chest
        MovementEntity(
            type: .barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .barbell
        ),
        MovementEntity(
            type: .dumbbellInclinePress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .pushUps,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .cableFlyes,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable
        ),
        MovementEntity(
            type: .machinePecDeck,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .machine
        ),
        MovementEntity(
            type: .dumbbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .cableChestFly,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable
        ),
        MovementEntity(
            type: .dips,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .bodyweight
        ),
        
        // Back
        MovementEntity(
            type: .barbellDeadlift,
            primaryMuscles: [.back, .lowerBack],
            secondaryMuscles: [.glutes, .hamstrings, .forearms, .traps, .lowerBack],
            equipment: .barbell
        ),
        MovementEntity(
            type: .pullUps,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .bentOverRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .barbell
        ),
        MovementEntity(
            type: .latPulldown,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms],
            equipment: .machine
        ),
        MovementEntity(
            type: .seatedCableRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .cable
        ),
        MovementEntity(
            type: .dumbbellRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .cablePullover,
            primaryMuscles: [.back],
            secondaryMuscles: [.abs, .traps],
            equipment: .cable
        ),
        MovementEntity(
            type: .chinUps,
            primaryMuscles: [.back, .biceps],
            secondaryMuscles: [.traps, .forearms],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .uprightRow,
            primaryMuscles: [.traps, .shoulders],
            secondaryMuscles: [.back, .biceps],
            equipment: .barbell
        ),
        
        // Legs
        MovementEntity(
            type: .barbellBackSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        ),
        MovementEntity(
            type: .romanianDeadlift,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [.glutes, .back, .lowerBack],
            equipment: .barbell
        ),
        MovementEntity(
            type: .legPress,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .machine
        ),
        MovementEntity(
            type: .bulgarianSplitSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .standingCalfRaise,
            primaryMuscles: [.calves],
            equipment: .machine
        ),
        MovementEntity(
            type: .legExtension,
            primaryMuscles: [.quads],
            equipment: .machine
        ),
        MovementEntity(
            type: .lyingLegCurl,
            primaryMuscles: [.hamstrings],
            equipment: .machine
        ),
        MovementEntity(
            type: .gobletSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .sledPush,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .calves],
            equipment: .machine
        ),
        MovementEntity(
            type: .barbellFrontSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell
        ),
        
        // Shoulders
        MovementEntity(
            type: .overheadPress,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .barbell
        ),
        MovementEntity(
            type: .lateralRaise,
            primaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .facePull,
            primaryMuscles: [.shoulders, .traps],
            secondaryMuscles: [.back],
            equipment: .cable
        ),
        MovementEntity(
            type: .frontRaise,
            primaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .arnoldPress,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .machineLateralRaise,
            primaryMuscles: [.shoulders],
            equipment: .machine
        ),
        
        // Arms
        MovementEntity(
            type: .barbellCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .barbell
        ),
        MovementEntity(
            type: .tricepPushdown,
            primaryMuscles: [.triceps],
            equipment: .cable
        ),
        MovementEntity(
            type: .hammerCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .skullCrushers,
            primaryMuscles: [.triceps],
            equipment: .barbell
        ),
        MovementEntity(
            type: .preacherCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .machine
        ),
        MovementEntity(
            type: .concentrationCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .overheadTricepExtension,
            primaryMuscles: [.triceps],
            secondaryMuscles: [.shoulders],
            equipment: .dumbbell
        ),
        MovementEntity(
            type: .cableCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .cable
        ),
        
        // Core
        MovementEntity(
            type: .cableCrunch,
            primaryMuscles: [.abs],
            equipment: .cable
        ),
        MovementEntity(
            type: .plank,
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .russianTwist,
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .legRaise,
            primaryMuscles: [.abs],
            equipment: .bodyweight
        ),
        MovementEntity(
            type: .abRollout,
            primaryMuscles: [.abs],
            equipment: .machine
        )
    ]
    
    /// Returns a movement entity by type
    static func getMovement(type: MovementType) -> MovementEntity {
        if let movement = allMovements.first(where: { $0.movementType == type }) {
            return movement
        }
        
        // Create a fallback movement if we can't find one
        return MovementEntity(
            type: type,
            primaryMuscles: [.unknown],
            equipment: .bodyweight
        )
    }
    
}
