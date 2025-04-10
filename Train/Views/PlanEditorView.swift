import SwiftUI

struct PlanEditorView: View {
    @StateObject private var viewModel: PlanEditorViewModel
    @State private var showingMovementPicker = false
    @State private var showingSummary = false
    @State private var selectedDayIndex: Int?
    @State private var selectedWeekIndex: Int?
    
    init(template: PlanTemplate?) {
        _viewModel = StateObject(wrappedValue: PlanEditorViewModel(template: template))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppStyle.Layout.standardSpacing) {
                ForEach(viewModel.weeks.indices, id: \.self) { weekIndex in
                    weekView(for: weekIndex)
                }
                
                addWeekButton
                
                nextButton
            }
            .padding()
        }
        .navigationTitle("Edit Plan")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppStyle.Colors.background)
        .sheet(isPresented: $showingMovementPicker) {
            MovementPickerView { movement in
                if let dayIndex = selectedDayIndex,
                   let weekIndex = selectedWeekIndex {
                    viewModel.addMovement(movement, to: dayIndex, weekIndex: weekIndex)
                }
            }
        }
        .navigationDestination(isPresented: $showingSummary) {
            PlanSummaryView(weeks: viewModel.weeks, template: viewModel.template)
        }
    }
    
    private func weekView(for weekIndex: Int) -> some View {
        VStack(spacing: AppStyle.Layout.standardSpacing) {
            Text("Week \(weekIndex + 1)")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(viewModel.weeks[weekIndex].indices, id: \.self) { dayIndex in
                dayCard(for: dayIndex, weekIndex: weekIndex)
            }
        }
    }
    
    private func dayCard(for dayIndex: Int, weekIndex: Int) -> some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            HStack {
                Picker("Day", selection: Binding(
                    get: { viewModel.weeks[weekIndex][dayIndex].label },
                    set: { viewModel.updateDayLabel($0, for: dayIndex, weekIndex: weekIndex) }
                )) {
                    ForEach(Calendar.current.weekdaySymbols, id: \.self) { day in
                        Text(day).tag(day)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(AppStyle.Colors.primary)
                
                Spacer()
                
                Text("\(viewModel.weeks[weekIndex][dayIndex].movements.count) movements")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if !viewModel.weeks[weekIndex][dayIndex].movements.isEmpty {
                movementsList(for: dayIndex, weekIndex: weekIndex)
            }
            
            addMovementButton(for: dayIndex, weekIndex: weekIndex)
                .padding()
        }
        .cardStyle()
    }
    
    private func movementsList(for dayIndex: Int, weekIndex: Int) -> some View {
        VStack(spacing: 1) {
            ForEach(viewModel.weeks[weekIndex][dayIndex].movements) { movement in
                MovementRow(movement: movement) {
                    if let index = viewModel.weeks[weekIndex][dayIndex].movements.firstIndex(where: { $0.id == movement.id }) {
                        viewModel.removeMovement(at: IndexSet([index]), from: dayIndex, weekIndex: weekIndex)
                    }
                }
            }
            .onMove { source, destination in
                viewModel.moveMovement(from: source, to: destination, in: dayIndex, weekIndex: weekIndex)
            }
        }
        .background(AppStyle.Colors.background)
    }
    
    private func addMovementButton(for dayIndex: Int, weekIndex: Int) -> some View {
        Button {
            selectedDayIndex = dayIndex
            selectedWeekIndex = weekIndex
            showingMovementPicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Movement")
            }
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.primary)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var addWeekButton: some View {
        Button {
            viewModel.addNewWeek()
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus")
                Text("Add New Week")
            }
            .font(AppStyle.Typography.body())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppStyle.Colors.primary)
            .cornerRadius(12)
        }
        .padding(.top)
    }
    
    private var nextButton: some View {
        Button {
            showingSummary = true
        } label: {
            Text("Review & Start Plan")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButton())
        .padding(.top, AppStyle.Layout.standardSpacing)
    }
}

struct MovementRow: View {
    let movement: MovementEntity
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppStyle.Layout.compactSpacing) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(AppStyle.Colors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.name)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                HStack {
                    ForEach(movement.primaryMuscles, id: \.self) { muscle in
                        muscleBadge(muscle.rawValue, isPrimary: true)
                    }
                    ForEach(movement.secondaryMuscles, id: \.self) { muscle in
                        muscleBadge(muscle.rawValue, isPrimary: false)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(AppStyle.Colors.surface)
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
