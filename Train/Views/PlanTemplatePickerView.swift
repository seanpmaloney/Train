import SwiftUI

struct PlanTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var navigation: NavigationCoordinator
    
    var body: some View {
            ScrollView {
                VStack(spacing: AppStyle.Layout.compactSpacing) {
                    // Adaptive Plan Option (Special)
                    Button {
                        // Navigate to the adaptive plan setup
                        navigation.navigateToAdaptivePlanSetup()
                    } label: {
                        adaptivePlanCard
                    }
                    
                    // Custom Plan Option
                    Button {
                        // Navigate to the custom plan editor
                        navigation.navigateToPlanEditor(templateId: nil)
                    } label: {
                        customPlanCard
                    }
                }
                .padding()
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private var customPlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Plan")
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Text("Build your own training plan from scratch")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private var adaptivePlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("Adaptive Plan")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    // Add a special symbol/badge to make it look enticing
                    Image(systemName: "sparkles")
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text("A personalized program built from your goals, with built-in progression and performance monitoring.")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AppStyle.Colors.surface,
                    AppStyle.Colors.surface.opacity(0.95),
                    AppStyle.Colors.textSecondary.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

#Preview {
    PlanTemplatePickerView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
