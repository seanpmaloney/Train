import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingNewPlanSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppStyle.Layout.compactSpacing) {
                    if let plan = appState.currentPlan {
                        currentPlanSection(plan: plan)
                    }
                    
                    createPlanButton
                    
                    if !appState.pastPlans.isEmpty {
                        pastPlansSection
                    }
                }
                .padding()
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("Plans")
//            .sheet(isPresented: $showingNewPlanSheet) {
//                PlanTemplatePickerView()
//            }
        }
    }
    
    
    private var createPlanButton: some View {
        NavigationLink(destination: PlanTemplatePickerView()) {
            HStack {
                Text("Create New Plan")
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
            
    }
    
    private func currentPlanSection(plan: TrainingPlanEntity) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Current Plan")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            NavigationLink(destination: PlanDetailView(plan: plan)) {
                VStack(spacing: AppStyle.Layout.compactSpacing) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(AppStyle.Typography.headline())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            Text("\(plan.daysPerWeek) workouts per week")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
                    }
                    
                    Divider()
                        .background(AppStyle.Colors.textSecondary.opacity(0.2))
                    
                    HStack(spacing: AppStyle.Layout.standardSpacing) {
                        planMetric(title: "Started", value: plan.startDate.formatted(date: .abbreviated, time: .omitted))
                        planMetric(title: "Progress", value: "5 of 20 complete")
                        Spacer()
                    }
                }
                .padding()
                .background(AppStyle.Colors.surface)
                .cornerRadius(12)
            }
        }
    }
    
    private var pastPlansSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Past Plans")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            ForEach(appState.pastPlans, id: \.id) { plan in
                NavigationLink(destination: PlanDetailView(plan: plan)) {
                    PastPlanCard(plan: plan)
                }
            }
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

struct PastPlanCard: View {
    let plan: TrainingPlanEntity
    
    var body: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    Text("Completed \(plan.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
            }
            
            Divider()
                .background(AppStyle.Colors.textSecondary.opacity(0.2))
            
            HStack(spacing: AppStyle.Layout.standardSpacing) {
                planMetric(title: "Duration", value: "\(plan.daysPerWeek) workouts/week")
                planMetric(title: "Completed", value: "18 of 20")
                Spacer()
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
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
    PlansView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
