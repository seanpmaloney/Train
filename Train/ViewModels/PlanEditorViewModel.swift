import Foundation
import SwiftUI

class PlanEditorViewModel: ObservableObject {
    @Published var days: [DayPlan]
    @Published var planLength: Int = 4
    let template: PlanTemplate?
    
    let minWeeks = 3
    let maxWeeks = 8
    let dayNames = Calendar.current.weekdaySymbols
    
    struct MovementConfig: Identifiable {
        let id = UUID()
        let movement: MovementEntity
        var targetSets: Int
        var targetReps: Int
        
        init(movement: MovementEntity, targetSets: Int = 3, targetReps: Int = 10) {
            self.movement = movement
            self.targetSets = targetSets
            self.targetReps = targetReps
        }
    }
    
    struct DayPlan: Identifiable {
        let id = UUID()
        let label: String
        var movements: [MovementConfig]
    }
    
    init(template: PlanTemplate?) {
        self.template = template
        self.days = Calendar.current.weekdaySymbols.map { dayName in
            DayPlan(label: dayName, movements: [])
        }
    }
    
    func addMovement(_ movement: [MovementEntity], to dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        for movement in movement {
            let config = MovementConfig(movement: movement)
            days[dayIndex].movements.append(config)
        }
        objectWillChange.send()
    }
    
    func removeMovement(at indexSet: IndexSet, from dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        days[dayIndex].movements.remove(atOffsets: indexSet)
        objectWillChange.send()
    }
    
    func moveMovement(from source: IndexSet, to destination: Int, in dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        days[dayIndex].movements.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
    }
    
    func updateSets(_ sets: Int, for movementId: UUID, in dayIndex: Int) {
        guard days.indices.contains(dayIndex),
              let movementIndex = days[dayIndex].movements.firstIndex(where: { $0.id == movementId }) else { return }
        days[dayIndex].movements[movementIndex].targetSets = min(sets, 20)
        objectWillChange.send()
    }
    
    func updateReps(_ reps: Int, for movementId: UUID, in dayIndex: Int) {
        guard days.indices.contains(dayIndex),
              let movementIndex = days[dayIndex].movements.firstIndex(where: { $0.id == movementId }) else { return }
        days[dayIndex].movements[movementIndex].targetReps = min(reps, 100)
        objectWillChange.send()
    }
    
    var generatedWeeks: [[DayPlan]] {
        let weeks = Array(repeating: days, count: planLength)
        return weeks
    }
    
    var totalMovementCount: Int {
        days.reduce(0) { count, day in
            count + day.movements.count
        }
    }
}
