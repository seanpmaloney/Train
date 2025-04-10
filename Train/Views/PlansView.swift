import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingNewPlanSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Background
                AppStyle.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppStyle.Layout.standardSpacing) {
                        if let plan = appState.currentPlan {
                            currentPlanSection(plan: plan)
                        }
                        
                        if !appState.pastPlans.isEmpty {
                            pastPlansSection
                        }
                        
                        // Add safe area padding at the bottom to prevent content from being hidden by the tab bar
                        // and floating action button
                        Color.clear
                            .frame(height: 100)
                    }
                    .padding()
                }
                
                // Floating Action Button
                addButton
                    .padding(.bottom, 80) // Clear the tab bar
                    .padding(.trailing, 16)
            }
            .navigationTitle("Plans")
            .sheet(isPresented: $showingNewPlanSheet) {
                PlanTemplatePickerView()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showingNewPlanSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppStyle.Colors.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
    
    private func currentPlanSection(plan: TrainingPlanEntity) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Current Plan")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppStyle.Layout.standardSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(AppStyle.Typography.title())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    if let notes = plan.notes {
                        Text(notes)
                            .font(AppStyle.Typography.body())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
                
                HStack {
                    planMetric(title: "Started", value: plan.startDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                NavigationLink {
                    Text("Plan Detail") // TODO: Create PlanDetailView
                } label: {
                    Text("View Plan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButton())
            }
            .cardStyle()
        }
    }
    
    private var pastPlansSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Past Plans")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            ForEach(appState.pastPlans, id: \.id) { plan in
                PastPlanCard(plan: plan)
            }
        }
    }
    
    private func planMetric(title: String, value: String) -> some View {
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

struct PastPlanCard: View {
    let plan: TrainingPlanEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text(plan.name)
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if let notes = plan.notes {
                Text(notes)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            HStack {
                planMetric(title: "Completed", value: plan.endDate.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .cardStyle()
    }
    
    private func planMetric(title: String, value: String) -> some View {
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
    PlansView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
