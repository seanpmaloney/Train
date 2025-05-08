//import Foundation
//
///**
// Default implementation of ExerciseSelector that uses MovementLibrary
// to select appropriate exercises for workouts.
// */
//class DefaultExerciseSelector: ExerciseSelector {
//    // Cache of movements to avoid actor isolation issues
//    private let movements: [MovementEntity]
//    
//    init(movements: [MovementEntity] = []) {
//        self.movements = movements
//    }
//    
//    /// Factory method to create a DefaultExerciseSelector with movements from the library
//    @MainActor
//    static func create() -> DefaultExerciseSelector {
//        return DefaultExerciseSelector(movements: MovementLibrary.allMovements)
//    }
//    
//    /// Selects exercises that target specified muscles with available equipment
//    func selectExercises(
//        targeting: [MuscleGroup],
//        withPriority: [MuscleGroup],
//        availableEquipment: [EquipmentType],
//        exerciseCount: Int
//    ) -> [MovementEntity] {
//        // Filter movements by available equipment
//        let equipmentFiltered = movements.filter { movement in
//            availableEquipment.contains(movement.equipment)
//        }
//        
//        // Score each exercise based on muscle targeting and priority
//        let scoredMovements = equipmentFiltered.map { movement -> (movement: MovementEntity, score: Int) in
//            var score = 0
//            
//            // Check primary muscles
//            for muscle in movement.primaryMuscles {
//                if targeting.contains(muscle) {
//                    score += 10
//                    
//                    // Bonus for prioritized muscles
//                    if withPriority.contains(muscle) {
//                        score += 5
//                    }
//                }
//            }
//            
//            // Check secondary muscles
//            for muscle in movement.secondaryMuscles {
//                if targeting.contains(muscle) {
//                    score += 5
//                    
//                    // Smaller bonus for prioritized muscles in secondary position
//                    if withPriority.contains(muscle) {
//                        score += 2
//                    }
//                }
//            }
//            
//            return (movement, score)
//        }
//        
//        // Filter out irrelevant exercises (score of 0)
//        let relevantMovements = scoredMovements.filter { $0.score > 0 }
//        
//        // Sort by score (highest first) and return requested amount
//        let sortedMovements = relevantMovements.sorted { $0.score > $1.score }
//        return sortedMovements.prefix(exerciseCount).map { $0.movement }
//    }
//}
