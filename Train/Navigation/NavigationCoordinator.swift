import SwiftUI
import Combine

/// Coordinates navigation throughout the app
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    // MARK: - Navigation Actions
    
    /// Navigate to the template picker
    func navigateToTemplatePicker() {
        path.append(NavigationDestination.templatePicker)
    }
    
    /// Navigate to the adaptive plan setup
    func navigateToAdaptivePlanSetup() {
        path.append(NavigationDestination.adaptivePlanSetup)
    }
    
    /// Navigate to the generated plan editor
    func navigateToGeneratedPlanEditor(planId: UUID) {
        path.append(NavigationDestination.generatedPlanEditor(planId: planId))
    }
    
    /// Navigate to the plan editor
    func navigateToPlanEditor(templateId: String?) {
        path.append(NavigationDestination.planEditor(templateId: templateId))
    }
    
    /// Navigate to plan details
    func navigateToPlanDetail(planId: UUID) {
        path.append(NavigationDestination.planDetail(planId: planId))
    }
    
    /// Return to the root view
    func returnToRoot() {
        path = NavigationPath()
    }
}
