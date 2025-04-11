import Foundation
import SwiftUI

class PlanEditorViewModel: ObservableObject {
    @Published var weeks: [[DayPlan]] = []
    let template: PlanTemplate?
    
    struct DayPlan: Identifiable {
        let id = UUID()
        var label: String
        var movements: [MovementEntity]
    }
    
    init(template: PlanTemplate?) {
        self.template = template
        setupInitialWeek()
    }
    
    private func setupInitialWeek() {
        // Initialize with empty week
        let emptyWeek = (0..<7).map { day in
            DayPlan(
                label: Calendar.current.weekdaySymbols[day],
                movements: []
            )
        }
        weeks.append(emptyWeek)
    }
    
    func addMovement(_ movement: [MovementEntity], to dayIndex: Int, weekIndex: Int) {
        guard weeks.indices.contains(weekIndex),
              weeks[weekIndex].indices.contains(dayIndex) else { return }
        for movement in movement {
            weeks[weekIndex][dayIndex].movements.append(movement)
        }
        objectWillChange.send()
    }
    
    func removeMovement(at indexSet: IndexSet, from dayIndex: Int, weekIndex: Int) {
        guard weeks.indices.contains(weekIndex),
              weeks[weekIndex].indices.contains(dayIndex) else { return }
        
        weeks[weekIndex][dayIndex].movements.remove(atOffsets: indexSet)
        objectWillChange.send()
    }
    
    func moveMovement(from source: IndexSet, to destination: Int, in dayIndex: Int, weekIndex: Int) {
        guard weeks.indices.contains(weekIndex),
              weeks[weekIndex].indices.contains(dayIndex) else { return }
        
        weeks[weekIndex][dayIndex].movements.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
    }
    
    func addNewWeek() {
        let newWeek = weeks[0].map { day in
            DayPlan(label: day.label, movements: [])
        }
        weeks.append(newWeek)
        objectWillChange.send()
    }
    
    func updateDayLabel(_ newLabel: String, for dayIndex: Int, weekIndex: Int) {
        guard weeks.indices.contains(weekIndex),
              weeks[weekIndex].indices.contains(dayIndex) else { return }
        
        weeks[weekIndex][dayIndex].label = newLabel
        objectWillChange.send()
    }
}
