import Foundation

struct MovementLibrary {
    @MainActor static let allMovements: [MovementEntity] = [
        // Chest
        MovementEntity(
            type: .barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .barbell,
            movementPattern: .horizontalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .dumbbellInclinePress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell,
            movementPattern: .horizontalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .pushUps,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .bodyweight,
            movementPattern: .horizontalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .cableFlyes,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable,
            movementPattern: .adduction,
            isCompound: false
        ),
        MovementEntity(
            type: .machinePecDeck,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .machine,
            movementPattern: .adduction,
            isCompound: false
        ),
        MovementEntity(
            type: .dumbbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell,
            movementPattern: .horizontalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .cableChestFly,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable,
            movementPattern: .adduction,
            isCompound: false
        ),
        MovementEntity(
            type: .dips,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .bodyweight,
            movementPattern: .horizontalPush,
            isCompound: true
        ),
        
        // Back
        MovementEntity(
            type: .barbellDeadlift,
            primaryMuscles: [.back, .lowerBack],
            secondaryMuscles: [.glutes, .hamstrings, .forearms, .traps, .lowerBack],
            equipment: .barbell,
            movementPattern: .hinge,
            isCompound: true
        ),
        MovementEntity(
            type: .pullUps,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .bodyweight,
            movementPattern: .verticalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .bentOverRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .barbell,
            movementPattern: .horizontalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .latPulldown,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms],
            equipment: .machine,
            movementPattern: .verticalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .seatedCableRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .cable,
            movementPattern: .horizontalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .dumbbellRow,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .traps, .forearms, .lowerBack],
            equipment: .dumbbell,
            movementPattern: .horizontalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .cablePullover,
            primaryMuscles: [.back],
            secondaryMuscles: [.abs, .traps],
            equipment: .cable,
            movementPattern: .verticalPull,
            isCompound: false
        ),
        MovementEntity(
            type: .chinUps,
            primaryMuscles: [.back, .biceps],
            secondaryMuscles: [.traps, .forearms],
            equipment: .bodyweight,
            movementPattern: .verticalPull,
            isCompound: true
        ),
        MovementEntity(
            type: .uprightRow,
            primaryMuscles: [.traps, .shoulders],
            secondaryMuscles: [.back, .biceps],
            equipment: .barbell,
            movementPattern: .verticalPull,
            isCompound: false
        ),
        MovementEntity(
            type: .superman,
            primaryMuscles: [.back, .lowerBack],
            secondaryMuscles: [],
            equipment: .bodyweight,
            movementPattern: .core,
            isCompound: false
        ),
        
        // Legs
        MovementEntity(
            type: .barbellBackSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .romanianDeadlift,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [.glutes, .back, .lowerBack],
            equipment: .barbell,
            movementPattern: .hinge,
            isCompound: true
        ),
        MovementEntity(
            type: .legPress,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .machine,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .bulgarianSplitSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell,
            movementPattern: .lunge,
            isCompound: true
        ),
        MovementEntity(
            type: .standingCalfRaise,
            primaryMuscles: [.calves],
            equipment: .machine,
            movementPattern: .unknown,
            isCompound: false
        ),
        MovementEntity(
            type: .legExtension,
            primaryMuscles: [.quads],
            equipment: .machine,
            movementPattern: .kneeExtension,
            isCompound: false
        ),
        MovementEntity(
            type: .lyingLegCurl,
            primaryMuscles: [.hamstrings],
            equipment: .machine,
            movementPattern: .kneeFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .gobletSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .dumbbell,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .sledPush,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .calves],
            equipment: .machine,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .barbellFrontSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .barbell,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .bodyweightSquat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipment: .bodyweight,
            movementPattern: .squat,
            isCompound: true
        ),
        MovementEntity(
            type: .quadFocusedLunge,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipment: .bodyweight,
            movementPattern: .lunge,
            isCompound: true
        ),
        MovementEntity(
            type: .gluteFocusedLunge,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.quads, .hamstrings],
            equipment: .bodyweight,
            movementPattern: .lunge,
            isCompound: true
        ),
        MovementEntity(
            type: .pistolSquat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipment: .bodyweight,
            movementPattern: .squat,
            isCompound: true
        ),
        
        // Shoulders
        MovementEntity(
            type: .overheadPress,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .barbell,
            movementPattern: .verticalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .lateralRaise,
            primaryMuscles: [.shoulders],
            equipment: .dumbbell,
            movementPattern: .abduction,
            isCompound: false
        ),
        MovementEntity(
            type: .facePull,
            primaryMuscles: [.shoulders, .traps],
            secondaryMuscles: [.back],
            equipment: .cable,
            movementPattern: .horizontalPull,
            isCompound: false
        ),
        MovementEntity(
            type: .frontRaise,
            primaryMuscles: [.shoulders],
            equipment: .dumbbell,
            movementPattern: .verticalPush,
            isCompound: false
        ),
        MovementEntity(
            type: .arnoldPress,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .dumbbell,
            movementPattern: .verticalPush,
            isCompound: true
        ),
        MovementEntity(
            type: .machineLateralRaise,
            primaryMuscles: [.shoulders],
            equipment: .machine,
            movementPattern: .abduction,
            isCompound: false
        ),
        
        // Arms
        MovementEntity(
            type: .barbellCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .barbell,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .dumbbellCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .tricepPushdown,
            primaryMuscles: [.triceps],
            equipment: .cable,
            movementPattern: .elbowExtension,
            isCompound: false
        ),
        MovementEntity(
            type: .hammerCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .skullCrushers,
            primaryMuscles: [.triceps],
            equipment: .barbell,
            movementPattern: .elbowExtension,
            isCompound: false
        ),
        MovementEntity(
            type: .preacherCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .machine,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .concentrationCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .overheadTricepExtension,
            primaryMuscles: [.triceps],
            secondaryMuscles: [.shoulders],
            equipment: .dumbbell,
            movementPattern: .elbowExtension,
            isCompound: false
        ),
        MovementEntity(
            type: .cableCurl,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .cable,
            movementPattern: .elbowFlexion,
            isCompound: false
        ),
        MovementEntity(
            type: .chairDips,
            primaryMuscles: [.triceps],
            secondaryMuscles: [.chest],
            equipment: .bodyweight,
            movementPattern: .verticalPush,
            isCompound: true
        ),
        
        // Core
        MovementEntity(
            type: .cableCrunch,
            primaryMuscles: [.abs],
            equipment: .cable,
            movementPattern: .core,
            isCompound: false
        ),
        MovementEntity(
            type: .plank,
            primaryMuscles: [.abs],
            equipment: .bodyweight,
            movementPattern: .core,
            isCompound: false
        ),
        MovementEntity(
            type: .russianTwist,
            primaryMuscles: [.abs],
            equipment: .bodyweight,
            movementPattern: .rotation,
            isCompound: false
        ),
        MovementEntity(
            type: .legRaise,
            primaryMuscles: [.abs],
            equipment: .bodyweight,
            movementPattern: .core,
            isCompound: false
        ),
        MovementEntity(
            type: .abRollout,
            primaryMuscles: [.abs],
            equipment: .machine,
            movementPattern: .core,
            isCompound: false
        )
    ]
    
    /// Returns a movement entity by type
    @MainActor static func getMovement(type: MovementType) -> MovementEntity {
        if let movement = allMovements.first(where: { $0.movementType == type }) {
            return movement
        }
        
        // Create a fallback movement if we can't find one
        return MovementEntity(
            type: type,
            primaryMuscles: [.unknown],
            equipment: .bodyweight,
            movementPattern: .unknown,
            isCompound: false
        )
    }
}
