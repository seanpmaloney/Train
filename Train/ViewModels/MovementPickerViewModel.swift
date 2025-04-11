import Foundation
import SwiftUI

class MovementPickerViewModel: ObservableObject {
    @Published var selectedMuscleGroup: MuscleGroup?
    @Published var searchText = ""
    @Published var recentlyUsed: [MovementEntity] = []
    @Published var selectedMovements: Set<UUID> = []
    private let allMovements = MovementLibrary.allMovements
    private let maxSelections = 10
    
    var canSelectMore: Bool {
        selectedMovements.count < maxSelections
    }
    
    var hasSelections: Bool {
        !selectedMovements.isEmpty
    }
    
    var filteredMovements: [MovementEntity] {
        var movements = allMovements
        
        // Apply search filter first
        if !searchText.isEmpty {
            movements = movements.filter { movement in
                movement.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply muscle group filter and sorting
        if let muscleGroup = selectedMuscleGroup {
            // Split into primary and secondary matches
            let primaryMatches = movements.filter { movement in
                movement.primaryMuscles.contains(muscleGroup)
            }
            let secondaryMatches = movements.filter { movement in
                !movement.primaryMuscles.contains(muscleGroup) &&
                movement.secondaryMuscles.contains(muscleGroup)
            }
            
            // Combine with primary matches first
            movements = primaryMatches + secondaryMatches
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
    
    func toggleSelection(_ movement: MovementEntity) {
        if selectedMovements.contains(movement.id) {
            selectedMovements.remove(movement.id)
        } else if canSelectMore {
            selectedMovements.insert(movement.id)
        }
    }
    
    func isSelected(_ movement: MovementEntity) -> Bool {
        selectedMovements.contains(movement.id)
    }
    
    func getSelectedMovements() -> [MovementEntity] {
        allMovements.filter { selectedMovements.contains($0.id) }
    }
}
