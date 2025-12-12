import Foundation

/// Statistics calculated when a training plan is completed
struct PlanCompletionStats {
    /// Number of workouts completed in the plan
    let workoutsCompleted: Int
    
    /// Total pounds lifted across all completed sets in the plan
    let totalPoundsLifted: Double
    
    /// The movement with the biggest improvement, if any
    let biggestImprovement: MovementImprovement?
    
    /// Represents an improvement in a specific movement
    struct MovementImprovement {
        let movement: MovementEntity
        let startingWeight: Double
        let endingWeight: Double
        let improvement: Double
        
        var formattedImprovement: String {
            return "+\(Int(improvement)) lb"
        }
        
        var formattedRange: String {
            return "\(Int(startingWeight)) → \(Int(endingWeight)) lb"
        }
    }
}

/// Service for calculating plan completion statistics
struct PlanStatsCalculator {
    
    /// Calculates comprehensive stats for a completed training plan
    /// - Parameter plan: The completed training plan
    /// - Returns: Statistics about the completed plan
    static func calculateStats(for plan: TrainingPlanEntity) -> PlanCompletionStats {
        let workoutsCompleted = countCompletedWorkouts(in: plan)
        let totalPoundsLifted = calculateTotalPoundsLifted(in: plan)
        let biggestImprovement = findBiggestImprovement(in: plan)
        
        return PlanCompletionStats(
            workoutsCompleted: workoutsCompleted,
            totalPoundsLifted: totalPoundsLifted,
            biggestImprovement: biggestImprovement
        )
    }
    
    // MARK: - Private Calculation Methods
    
    private static func countCompletedWorkouts(in plan: TrainingPlanEntity) -> Int {
        return plan.weeklyWorkouts
            .flatMap { $0 }
            .filter { $0.isComplete }
            .count
    }
    
    private static func calculateTotalPoundsLifted(in plan: TrainingPlanEntity) -> Double {
        let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
        let completedWorkouts = allWorkouts.filter { $0.isComplete }
        let allExercises = completedWorkouts.flatMap { $0.exercises }
        let allSets = allExercises.flatMap { $0.sets }
        let completedSets = allSets.filter { $0.isComplete }
        
        var totalPounds: Double = 0.0
        for set in completedSets {
            totalPounds += set.weight * Double(set.completedReps)
        }
        return totalPounds
    }
    
    private static func findBiggestImprovement(in plan: TrainingPlanEntity) -> PlanCompletionStats.MovementImprovement? {
        let completedWorkouts = plan.weeklyWorkouts
            .flatMap { $0 }
            .filter { $0.isComplete }
            .sorted { $0.scheduledDate ?? Date.distantPast < $1.scheduledDate ?? Date.distantPast }
        
        guard !completedWorkouts.isEmpty else { return nil }
        
        // Group exercises by movement
        var movementData: [UUID: (first: Double, last: Double, movement: MovementEntity)] = [:]
        
        for workout in completedWorkouts {
            for exercise in workout.exercises {
                let movementId = exercise.movement.id
                
                // Find the heaviest completed set in this exercise
                let heaviestWeight = exercise.sets
                    .filter { $0.isComplete }
                    .map { $0.weight }
                    .max() ?? 0.0
                
                if heaviestWeight > 0 {
                    if movementData[movementId] == nil {
                        // First occurrence of this movement
                        movementData[movementId] = (first: heaviestWeight, last: heaviestWeight, movement: exercise.movement)
                    } else {
                        // Update the last weight for this movement
                        movementData[movementId]?.last = heaviestWeight
                    }
                }
            }
        }
        
        // Find the movement with the biggest positive improvement
        var bestImprovement: PlanCompletionStats.MovementImprovement?
        var maxDelta: Double = 0
        
        for (_, data) in movementData {
            let delta = data.last - data.first
            if delta > maxDelta {
                maxDelta = delta
                bestImprovement = PlanCompletionStats.MovementImprovement(
                    movement: data.movement,
                    startingWeight: data.first,
                    endingWeight: data.last,
                    improvement: delta
                )
            }
        }
        
        return bestImprovement
    }
}
