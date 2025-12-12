import SwiftUI

/// Content view for the plan creation sheet
struct PlanCreationSheetView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var coordinator = NavigationCoordinator()
    @Binding var showingSheet: Bool
    var initialPlanId: UUID?
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlanTemplatePickerView()
                .environmentObject(appState)
                .environmentObject(coordinator)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CustomCloseButton {
                            showingSheet = false
                        }
                    }
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .templatePicker:
                        PlanTemplatePickerView()
                            .environmentObject(appState)
                            .environmentObject(coordinator)
                    case .adaptivePlanSetup:
                        AdaptivePlanSetupView()
                            .environmentObject(appState)
                            .environmentObject(coordinator)
                    case .generatedPlanEditor(let planId):
                        if let plan = appState.findPlan(with: planId) {
                            GeneratedPlanEditorView(generatedPlan: plan, appState: appState, planCreated: .constant(false))
                                .environmentObject(coordinator)
                        } else {
                            Text("Plan not found")
                        }
                    case .planEditor(let templateId):
                        let template = templateId != nil ? PlanTemplate.templates.first(where: { $0.id.uuidString == templateId }) : nil
                        PlanEditorView(template: template, appState: appState)
                            .environmentObject(appState)
                            .environmentObject(coordinator)
                    case .planDetail(let planId):
                        if let plan = appState.findPlan(with: planId) {
                            PlanDetailView(plan: plan)
                                .environmentObject(appState)
                                .environmentObject(coordinator)
                        }
                    }
                }
        }
        .onChange(of: appState.currentPlan?.id) { newId in
            if let newId = newId, newId != initialPlanId {
                showingSheet = false
            }
        }
    }
}
