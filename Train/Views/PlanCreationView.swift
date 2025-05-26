import SwiftUI

/// A simplified view for creating a new plan from the training screen
struct PlanCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showingTemplatePicker = false
    @State private var initialPlanId: UUID?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Create New Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Text("Your current plan will be archived when you create a new one")
                    .font(.subheadline)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)
            .onAppear {
                // Store the current plan ID when the view appears
                initialPlanId = appState.currentPlan?.id
            }
            
            // Create plan button
            Button {
                showingTemplatePicker = true
            } label: {
                HStack {
                    Text("Select Plan Template")
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
                }
                .padding()
                .background(AppStyle.Colors.surface)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(AppStyle.Colors.textSecondary)
            .padding(.bottom)
        }
        .background(AppStyle.Colors.background.ignoresSafeArea())
        .navigationDestination(isPresented: $showingTemplatePicker) {
            PlanTemplatePickerView()
                .environmentObject(appState)
                .onDisappear {
                    // If the current plan has changed, dismiss the sheet
                    if let initialId = initialPlanId, appState.currentPlan?.id != initialId {
                        dismiss()
                    }
                }
        }
    }
}

#Preview {
    PlanCreationView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
