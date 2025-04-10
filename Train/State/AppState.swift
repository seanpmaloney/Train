import Foundation

class AppState: ObservableObject {
    @Published var currentPlan: TrainingPlanEntity?
    @Published var pastPlans: [TrainingPlanEntity] = []
    
    // In a real app, this would load from persistent storage
    init() {
        // Load saved plans
    }
    
    func setCurrentPlan(_ plan: TrainingPlanEntity) {
        // Move current plan to past plans if it exists
        if let current = currentPlan {
            pastPlans.insert(current, at: 0)
        }
        
        // Set new current plan
        currentPlan = plan
        
        // Save to persistent storage
        savePlans()
    }
    
    private func savePlans() {
        // TODO: Implement persistence
        // This would save both currentPlan and pastPlans to disk
    }
}
