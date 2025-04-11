import Foundation
import SwiftUI

class PlanEditorViewModel: ObservableObject {
    @Published var days: [DayPlan]
    @Published var planLength: Int = 4
    let template: PlanTemplate?
    
    let minWeeks = 3
    let maxWeeks = 8
    let dayNames = Calendar.current.weekdaySymbols
    
    struct DayPlan: Identifiable {
        let id = UUID()
        let label: String
        var movements: [MovementEntity]
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
            days[dayIndex].movements.append(movement)
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
