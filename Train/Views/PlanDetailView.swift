import SwiftUI

struct PlanDetailView: View {
    let plan: TrainingPlanEntity
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppStyle.Layout.standardSpacing) {
                // Header
                VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
                    Text(plan.name)
                        .font(AppStyle.Typography.title())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    HStack(spacing: AppStyle.Layout.standardSpacing) {
                        planMetric(title: "Progress", value: "5 of 20 complete")
                    }
                }
                .padding()
                .background(AppStyle.Colors.surface)
                .cornerRadius(12)
                
                // Weekly Schedule
                VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
                    Text("Weekly Schedule")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    
                    VStack(spacing: AppStyle.Layout.compactSpacing) {
                        ForEach(0..<7) { day in
                            dayScheduleRow(for: day)
                        }
                    }
                    .padding()
                    .background(AppStyle.Colors.surface)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !plan.isCompleted {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditor = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            PlanEditorView(template: nil, appState: appState)
        }
    }
    
    private func dayScheduleRow(for day: Int) -> some View {
        HStack {
            Text(Calendar.current.weekdaySymbols[day])
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Spacer()
            
            Text("3 movements")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
    }
    
    private func planMetric(title: String, value: String) -> some View {
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
    NavigationStack {
        PlanDetailView(plan: TrainingPlanEntity(
            name: "Sample Plan",
            notes: "Sample",
            startDate: Date(),
            daysPerWeek: 5,
            isCompleted: false
        ))
    }
    .preferredColorScheme(.dark)
}
