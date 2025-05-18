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
    @Published private(set) var workout: WorkoutEntity
    private let dataStore: TrainingDataStore
    @Published var isReadOnly: Bool = false
    
    // MARK: - Initialization
    init(workout: WorkoutEntity, dataStore: TrainingDataStore = .shared, isReadOnly: Bool = false) {
        self.workout = workout
        self.dataStore = dataStore
        self.isReadOnly = isReadOnly
    }
    
    // MARK: - Set Management
    
    func addSet(to exercise: ExerciseSetEntity) {
        guard !isReadOnly else { return }
        let set = ExerciseSetEntity(weight: 100.0, targetReps: 8, isComplete: false)
        
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises[index].sets.append(set)
        }
    }
    
    func updateWeight(for set: ExerciseSetEntity, to weight: Double) {
        guard !isReadOnly else { return }
        set.weight = weight
    }
    
    func updateReps(for set: ExerciseSetEntity, to reps: Int) {
        guard !isReadOnly else { return }
        set.completedReps = reps
    }
    
    func toggleSetComplete(_ set: ExerciseSetEntity, to isComplete: Bool) {
        guard !isReadOnly else { return }
        set.isComplete = isComplete
    }
    
    // MARK: - Workout Management
    
    func completeWorkout() {
        workout.isComplete = true
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
