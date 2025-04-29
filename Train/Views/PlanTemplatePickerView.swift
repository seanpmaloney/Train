import SwiftUI

struct PlanTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedTemplate: PlanTemplate?
    @State private var planCreated = false // State to track if a plan was created
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppStyle.Layout.compactSpacing) {
                    // Custom Plan Option
                    NavigationLink {
                        PlanEditorView(template: nil, appState: appState, planCreated: $planCreated)
                    } label: {
                        customPlanCard
                    }
                    
                    // Template Options
                    ForEach(PlanTemplate.templates) { template in
                        NavigationLink {
                            PlanEditorView(template: template, appState: appState, planCreated: $planCreated)
                        } label: {
                            templateCard(template)
                        }
                    }
                }
                .padding()
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            // When planCreated changes to true, dismiss this view
            .onChange(of: planCreated) { created in
                if created {
                    dismiss()
                }
            }
        }
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
    
    private func templateCard(_ template: PlanTemplate) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
            //add divider
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text(template.scheduleString)
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
        }
        
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            Text(value)
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppStyle.Colors.background.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    PlanTemplatePickerView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
