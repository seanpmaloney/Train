import Foundation

/// Implements volume progression over a training plan period
class StandardVolumeRampStrategy: VolumeRampStrategy {
    
    // MARK: - Constants
    
    /// Percentage of target sets to use in each phase (week range)
    private enum ProgressionPhase: Double {
        case initial = 0.6    // First quarter: 60% of target
        case buildup = 0.75   // Second quarter: 75% of target
        case preMaximal = 0.9  // Third quarter: 90% of target
        case maximal = 1.0    // Final quarter: 100% of target
        case shortPlan = 0.85  // Fixed percentage for very short plans (2-3 weeks)
    }
    
    /// Experience level volume adjustment factors
    private enum ExperienceAdjustment: Double {
        case beginner = 0.7     // Beginners start with lower volume
        case intermediate = 0.9  // Intermediates use near-optimal volume
        case advanced = 1.0     // Advanced trainees use full recommended volume
    }
    
    // MARK: - VolumeRampStrategy Implementation
    
    func calculateVolume(
        for muscleGroup: MuscleGroup,
        goal: TrainingGoal,
        trainingAge: Int,
        isEmphasized: Bool
    ) -> VolumeRecommendation {
        // Get baseline volume based on muscle and goal
        let baselineSets = getBaselineVolume(for: muscleGroup, goal: goal)
        
        // Adjust for experience level
        let experienceAdjusted = adjustForExperience(baselineSets, trainingAge: trainingAge)
        
        // Adjust for emphasis if needed
        let finalSets = isEmphasized ? adjustForEmphasis(experienceAdjusted) : experienceAdjusted
        
        // Get rep ranges based on goal and experience
        let (minReps, maxReps) = getRepRange(for: goal, trainingAge: trainingAge)
        
        // Calculate intensity based on goal and experience
        let intensity = getIntensity(for: goal, trainingAge: trainingAge)
        
        return VolumeRecommendation(
            setsPerWeek: finalSets,
            repRangeLower: minReps,
            repRangeUpper: maxReps,
            intensity: intensity
        )
    }
    
    /// Calculate volume for a specific week in the plan
    /// - Parameters:
    ///   - targetSets: Target number of sets per week
    ///   - currentWeek: Current week number (1-based)
    ///   - totalWeeks: Total weeks in the plan
    ///   - isMaintenance: Whether this is a maintenance goal
    /// - Returns: Adjusted number of sets for the current week
    func calculateVolumeForWeek(
        targetSets: Int,
        currentWeek: Int,
        totalWeeks: Int,
        isMaintenance: Bool
    ) -> Int {
        // For maintenance goals, always use 100% of target
        if isMaintenance {
            return targetSets
        }
        
        // For very short plans (2-3 weeks), use fixed 85% volume
        if totalWeeks < 4 {
            return Int(Double(targetSets) * ProgressionPhase.shortPlan.rawValue)
        }
        
        // For growth goals with longer plans, ramp up progressively
        let phase = getProgressionPhase(for: currentWeek, totalWeeks: totalWeeks)
        return Int(Double(targetSets) * phase.rawValue)
    }
    
    // MARK: - Helper Methods
    
    /// Determines which progression phase applies based on the week number and total plan length
    /// - Parameters:
    ///   - week: Current week number (1-based)
    ///   - totalWeeks: Total weeks in the plan
    /// - Returns: The appropriate progression phase
    private func getProgressionPhase(for week: Int, totalWeeks: Int) -> ProgressionPhase {
        // Calculate which quarter of the plan we're in (1-4)
        let quarterSize = max(1, totalWeeks / 4)
        let completedQuarters = (week - 1) / quarterSize
        
        switch completedQuarters {
        case 0:
            return .initial     // First quarter
        case 1:
            return .buildup     // Second quarter
        case 2:
            return .preMaximal  // Third quarter
        default:
            return .maximal     // Fourth quarter or beyond
        }
    }
    
    /// Get baseline weekly sets based on muscle group and training goal
    /// - Parameters:
    ///   - muscleGroup: The muscle group
    ///   - goal: The training goal
    /// - Returns: Baseline sets per week
    private func getBaselineVolume(for muscleGroup: MuscleGroup, goal: TrainingGoal) -> Int {
        let guidelines = muscleGroup.trainingGuidelines
        
        switch goal {
        case .hypertrophy:
            return guidelines.minHypertrophySets
        case .strength:
            // For strength, use slightly lower volume but higher intensity
            return guidelines.minMaintenanceSets + 2
        }
    }
    
    /// Adjust volume based on training experience
    /// - Parameters:
    ///   - baseSets: Base number of sets
    ///   - trainingAge: User's training experience (years)
    /// - Returns: Adjusted number of sets based on experience
    private func adjustForExperience(_ baseSets: Int, trainingAge: Int) -> Int {
        let adjustment: ExperienceAdjustment
        
        // Convert trainingAge to the appropriate enum
        if trainingAge < 1 {
            adjustment = .beginner
        } else if trainingAge < 3 {
            adjustment = .intermediate
        } else {
            adjustment = .advanced
        }
        
        return Int(Double(baseSets) * adjustment.rawValue)
    }
    
    /// Adjust volume for emphasized muscle groups
    /// - Parameter baseSets: Base number of sets
    /// - Returns: Adjusted number of sets for emphasized muscles
    private func adjustForEmphasis(_ baseSets: Int) -> Int {
        // Add 30% more volume for emphasized muscles
        return Int(Double(baseSets) * 1.3)
    }
    
    /// Get appropriate rep range suggestions based on goal and experience
    /// - Parameters:
    ///   - goal: Training goal
    ///   - trainingAge: User's training experience (years)
    /// - Returns: Tuple with (minimum reps, maximum reps)
    private func getRepRange(for goal: TrainingGoal, trainingAge: Int) -> (Int, Int) {
        // For beginners (less than 1 year of experience), prioritize safety and technique
        if trainingAge < 1 {
            switch goal {
            case .hypertrophy:
                return (8, 15) // Moderate rep range for beginners focusing on hypertrophy
            case .strength:
                return (5, 12) // Higher reps for beginners focusing on strength (safer)
            }
        } 
        // For intermediate and advanced lifters, provide wider guidelines based on goal
        else {
            switch goal {
            case .hypertrophy:
                return (5, 30) // Full spectrum of hypertrophy rep ranges (more flexibility)
            case .strength:
                return (2, 5)  // Traditional strength training rep range
            }
        }
    }
    
    /// Get appropriate intensity (% of 1RM) based on goal and experience
    /// - Parameters:
    ///   - goal: Training goal
    ///   - trainingAge: User's training experience (years)
    /// - Returns: Relative intensity as a percentage of 1RM
    private func getIntensity(for goal: TrainingGoal, trainingAge: Int) -> Double {
        switch goal {
        case .hypertrophy:
            if trainingAge < 1 {
                return 0.65 // 65% of 1RM for beginners (technique focus)
            } else if trainingAge < 3 {
                return 0.7 // 70% of 1RM for intermediates
            } else {
                return 0.75 // 75% of 1RM for advanced
            }
            
        case .strength:
            if trainingAge < 1 {
                return 0.75 // 75% of 1RM for beginners (safety)
            } else if trainingAge < 3 {
                return 0.8 // 80% of 1RM for intermediates
            } else {
                return 0.85 // 85% of 1RM for advanced
            }
        }
    }
}
