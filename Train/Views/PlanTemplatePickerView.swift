import SwiftUI

struct PlanTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedTemplate: PlanTemplate?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppStyle.Layout.standardSpacing) {
                        // Custom Plan Option
                        NavigationLink {
                            PlanEditorView(template: nil)
                                .navigationBarBackButtonHidden()
                        } label: {
                            customPlanCard
                        }
                        
                        // Template Options
                        ForEach(PlanTemplate.templates) { template in
                            NavigationLink {
                                PlanEditorView(template: template)
                                    .navigationBarBackButtonHidden()
                            } label: {
                                templateCard(template)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var customPlanCard: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Custom Plan")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Build your own training plan from scratch")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private func templateCard(_ template: PlanTemplate) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text(template.title)
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text(template.suggestedDuration)
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .lineLimit(2)
            
            HStack {
                templateMetric(title: "Goal", value: template.goal.rawValue)
                Spacer()
                templateMetric(title: "Duration", value: (template.suggestedDuration))
            }
        }
        .cardStyle()
    }
    
    private func templateMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            Text(value)
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
        }
    }
}

#Preview {
    PlanTemplatePickerView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
