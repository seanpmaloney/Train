import Foundation
import SwiftUI

class MovementPickerViewModel: ObservableObject {
    @Published var selectedMuscleGroup: MuscleGroup?
    @Published var searchText = ""
    @Published var recentlyUsed: [MovementEntity] = []
    private let allMovements = MovementLibrary.allMovements
    
    var filteredMovements: [MovementEntity] {
        var movements = allMovements
        
        // Apply muscle group filter
        if let muscleGroup = selectedMuscleGroup {
            movements = movements.filter { movement in
                movement.primaryMuscles.contains(muscleGroup) ||
                movement.secondaryMuscles.contains(muscleGroup)
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            movements = movements.filter { movement in
                movement.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return movements
    }
    
    var suggestedMovements: [MovementEntity] {
        // For now, return recently used. Could be enhanced with ML/analytics
        return recentlyUsed
    }
    
    func addToRecentlyUsed(_ movement: MovementEntity) {
        // Add to front, remove duplicates, keep max 10 items
        recentlyUsed.removeAll { $0.id == movement.id }
        recentlyUsed.insert(movement, at: 0)
        if recentlyUsed.count > 10 {
            recentlyUsed.removeLast()
        }
    }
}
