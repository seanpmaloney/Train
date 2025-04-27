import Testing
import Foundation
@testable import Train

/// TestHelpers.swift - Shared utilities and mock data for unit and UI tests.
/// This file provides common test data, mock objects, and helper functions.

// MARK: - Mock Data

struct MockData {
    // Mock workout data
    static func createMockWorkout(title: String = "Test Workout", 
                                 isComplete: Bool = false) -> WorkoutEntity {
        return WorkoutEntity(
            title: title,
            description: "Test workout description",
            isComplete: isComplete
        )
    }
    
    // Mock exercise data
    static func createMockExercise(movementType: MovementType = .benchPress) -> ExerciseInstanceEntity {
        let movement = MovementEntity(
            type: movementType,
            primaryMuscles: [MuscleGroup.chest],
            secondaryMuscles: [MuscleGroup.triceps],
            equipment: .barbell
        )
        
        return ExerciseInstanceEntity(
            movement: movement,
            exerciseType: "Strength",
            sets: [createMockSet()]
        )
    }
    
    // Mock set data
    static func createMockSet(weight: Double = 100, 
                             completedReps: Int = 10, 
                             targetReps: Int = 10, 
                             isComplete: Bool = false) -> ExerciseSetEntity {
        return ExerciseSetEntity(
            weight: weight,
            completedReps: completedReps,
            targetReps: targetReps,
            isComplete: isComplete
        )
    }
}

// MARK: - Test Helpers

/// Wait for a specified time (in seconds)
func wait(for duration: TimeInterval) async {
    try? await Task.sleep(for: .seconds(duration))
}

// MARK: - Mock Classes

/// Mock file manager for testing persistence operations
class MockFileManager {
    var fileExists = false
    var fileData: Data?
    var lastSavedData: Data?
    var lastSavedPath: String?
    var error: Error?
    
    func fileExists(atPath path: String) -> Bool {
        return fileExists
    }
    
    func contents(atPath path: String) -> Data? {
        return fileData
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        if let error = error {
            throw error
        }
    }
    
    func createFile(atPath path: String, contents data: Data?, attributes: [FileAttributeKey: Any]?) -> Bool {
        lastSavedPath = path
        lastSavedData = data
        return error == nil
    }
}

/// Testable AppState subclass with injectable dependencies for testing
class TestableAppState: AppState {
    var mockFileManager: MockFileManager?
    
    override func getDocumentsDirectory() -> URL {
        return URL(fileURLWithPath: "/test/documents")
    }
    
    override func loadPlans() {
        // Override to avoid actual file system access during tests
        if let mockFileManager = mockFileManager {
            // Custom loading logic using mock file manager
        } else {
            super.loadPlans()
        }
    }
    
    override func savePlans() {
        // Override to avoid actual file system access during tests
        if let mockFileManager = mockFileManager {
            // Custom saving logic using mock file manager
        } else {
            super.savePlans()
        }
    }
}
