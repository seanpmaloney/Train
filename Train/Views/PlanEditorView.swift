import SwiftUI

struct PlanEditorView: View {
    @StateObject private var viewModel: PlanEditorViewModel
    @State private var showingMovementPicker = false
    @State private var selectedDayIndex: Int? = 0
    
    init(template: PlanTemplate?) {
        _viewModel = StateObject(wrappedValue: PlanEditorViewModel(template: template))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppStyle.Layout.compactSpacing) {
                planLengthPicker
                daysSection
            }
            .padding(.horizontal)
            .padding(.vertical, AppStyle.Layout.standardSpacing)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Create Plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMovementPicker) {
            if let dayIndex = selectedDayIndex {
                MovementPickerView { movement in
                    viewModel.addMovement(movement, to: dayIndex)
                }
            }
        }
    }
    
    private var planLengthPicker: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            HStack {
                Text("Plan Length")
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                Picker("", selection: $viewModel.planLength) {
                    ForEach(viewModel.minWeeks...viewModel.maxWeeks, id: \.self) { weeks in
                        Text("\(weeks) weeks").tag(weeks)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppStyle.Colors.primary)
            }
            
            Divider()
                .background(AppStyle.Colors.textSecondary.opacity(0.2))
            
            NavigationLink {
                PlanSummaryView(weeks: viewModel.generatedWeeks, template: viewModel.template)
            } label: {
                HStack {
                    Text("Review & Start Plan")
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.5))
                }
            }
            .disabled(viewModel.totalMovementCount == 0)
            .opacity(viewModel.totalMovementCount == 0 ? 0.5 : 1)
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private var daysSection: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            ForEach(viewModel.days.indices, id: \.self) { dayIndex in
                DayView(
                    day: viewModel.days[dayIndex],
                    onAddMovement: {
                        selectedDayIndex = dayIndex
                        showingMovementPicker = true
                    },
                    onRemoveMovement: { indexSet in
                        viewModel.removeMovement(at: indexSet, from: dayIndex)
                    },
                    onMoveMovement: { source, destination in
                        viewModel.moveMovement(from: source, to: destination, in: dayIndex)
                    }
                )
            }
        }
    }
}

private struct DayView: View {
    let day: PlanEditorViewModel.DayPlan
    let onAddMovement: () -> Void
    let onRemoveMovement: (IndexSet) -> Void
    let onMoveMovement: (IndexSet, Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text(day.label)
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if day.movements.isEmpty {
                emptyState
            } else {
                movementsList
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private var emptyState: some View {
        Button(action: onAddMovement) {
            HStack {
                Text("Add Movement")
                    .font(AppStyle.Typography.body())
                Spacer()
                Image(systemName: "plus.circle")
            }
            .foregroundColor(AppStyle.Colors.textSecondary)
        }
    }
    
    private var movementsList: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            ForEach(day.movements) { movement in
                MovementRow(movement: movement)
            }
            .onMove(perform: onMoveMovement)
            .onDelete(perform: onRemoveMovement)

            Button(action: onAddMovement) {
                HStack {
                    Text("Add Movement")
                        .font(AppStyle.Typography.body())
                    Spacer()
                    Image(systemName: "plus.circle")
                }
                .foregroundColor(AppStyle.Colors.primary)
            }
        }
    }
}

private struct MovementRow: View {
    let movement: MovementEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(movement.name)
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            HStack(spacing: 4) {
                equipmentTag
                muscleGroupTags
            }
        }
        .padding()
        .background(AppStyle.Colors.background.opacity(0.5))
        .cornerRadius(8)
    }
    
    private var equipmentTag: some View {
        Text(movement.equipment.rawValue)
            .font(AppStyle.Typography.caption())
            .foregroundColor(AppStyle.Colors.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(AppStyle.Colors.secondary.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var muscleGroupTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(movement.primaryMuscles, id: \.self) { muscle in
                    muscleBadge(muscle.rawValue, isPrimary: true)
                }
                ForEach(movement.secondaryMuscles, id: \.self) { muscle in
                    muscleBadge(muscle.rawValue, isPrimary: false)
                }
            }
        }
    }
    
    private func muscleBadge(_ text: String, isPrimary: Bool) -> some View {
        Text(text)
            .font(AppStyle.Typography.caption())
            .foregroundColor(isPrimary ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                (isPrimary ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
                    .opacity(0.2)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        PlanEditorView(template: PlanTemplate.templates.first)
            .preferredColorScheme(.dark)
    }
}
