import Foundation

/// Utility functions for weight calculations and rounding
struct WeightUtilities {
    
    /// Rounds weight to the nearest 2.5 lb increment
    /// - Parameter weight: The weight to round
    /// - Returns: Weight rounded to nearest 2.5 lb increment
    static func closestWeightIn2pt5Increment(_ weight: Double) -> Double {
        let increment = 2.5
        return round(weight / increment) * increment
    }
    
    /// Constants for plan continuation logic
    struct PlanContinuation {
        /// Back-off multiplier for plans <= 4 weeks (targets ~2 RIR)
        static let shortPlanBackoffMultiplier = 0.93
        
        /// Back-off multiplier for plans > 4 weeks (targets ~3 RIR)
        static let longPlanBackoffMultiplier = 0.90
        
        /// Deload multiplier (50% of last week loads)
        static let deloadMultiplier = 0.5
    }
}
