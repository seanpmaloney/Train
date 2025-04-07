//
//  ActiveWorkoutViewModel.swift
//  Train
//
//  Created by Sean Maloney on 4/6/25.
//

import Foundation
import Combine

@MainActor
class ActiveWorkoutViewModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var workout: Workout
    private let dataStore: TrainingDataStore
    
    // MARK: - Initialization
    init(workout: Workout, dataStore: TrainingDataStore = .shared) {
        self.workout = workout
        self.dataStore = dataStore
    }
    
    // MARK: - Set Management
    
    func addSet(to exercise: Exercise) {
        let set = ExerciseSet(weight: 0, targetReps: 8)
        
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises[index].sets.append(set)
        }
    }

    
    func updateWeight(for set: ExerciseSetEntity, to weight: Double) {
        set.weight = weight
    }
    
    func updateReps(for set: ExerciseSetEntity, to reps: Int) {
        set.completedReps = reps
    }
    
    func toggleSetComplete(_ set: ExerciseSetEntity) {
        // In the new model, we don't need to track completion separately
        // since we're using a single reps value
    }
    
    // MARK: - Workout Management
    
    func endWorkout() {
        UserDefaults.standard.removeObject(forKey: "activeWorkoutId")
    }
    
    // MARK: - Formatting
    
    func formattedWeight(for set: ExerciseSetEntity) -> String {
        String(format: "%.1f", set.weight)
    }
    
    func formattedTargetReps(for set: ExerciseSetEntity) -> String {
        "\(set.targetReps)"
    }
    
    func formattedCompletedReps(for set: ExerciseSetEntity) -> String {
        "\(set.completedReps)"
    }
}
