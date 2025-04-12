import SwiftUI

struct PlanEditorView: View {
    @StateObject private var viewModel: PlanEditorViewModel
    @State private var scrollTarget: ScrollTarget?
    @State private var requiredPadding: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    private let numberPadHeight: CGFloat = 390
    private let desiredSpaceAboveKeyboard: CGFloat = 40
    
    enum ActiveSheet: Identifiable {
        case movementPicker(dayIndex: Int)
        case datePicker

        var id: String {
            switch self {
            case .movementPicker(let dayIndex):
                return "movementPicker_\(dayIndex)"
            case .datePicker:
                return "datePicker"
            }
        }
    }
    @State private var activeSheet: ActiveSheet?
    
    struct ScrollTarget: Equatable {
        let id: UUID
        let buttonFrame: CGRect
        
        static func == (lhs: ScrollTarget, rhs: ScrollTarget) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    init(template: PlanTemplate?, appState: AppState) {
        _viewModel = StateObject(wrappedValue: PlanEditorViewModel(template: template, appState: appState))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppStyle.Layout.compactSpacing) {
                        planDetailsSection
                        planLengthPicker
                        daysSection
                        
                        // Dynamic padding based on button position
                        Color.clear
                            .frame(height: requiredPadding)
                            .animation(.easeInOut(duration: 0.25), value: requiredPadding)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, AppStyle.Layout.standardSpacing)
                    .onChange(of: scrollTarget) { target in
                        if let target = target {
                            // Calculate if and how much padding we need
                            let screenHeight = UIScreen.main.bounds.height
                            let buttonBottomY = target.buttonFrame.maxY + 20
                            let keyboardTopY = screenHeight - numberPadHeight
                            
                            // If button would be hidden by keyboard
                            if buttonBottomY > keyboardTopY {
                                // Calculate padding needed to show button above keyboard
                                let overlap = buttonBottomY - keyboardTopY
                                let padding = overlap + desiredSpaceAboveKeyboard
                                
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    requiredPadding = padding
                                    proxy.scrollTo(target.id, anchor: .center)
                                }
                            } else {
                                // Button is already visible above keyboard
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    requiredPadding = 0
                                }
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                requiredPadding = 0
                            }
                        }
                    }
                }
                .background(AppStyle.Colors.background)
                .navigationTitle("Create Plan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            viewModel.finalizePlan()
                            dismiss()
                        }
                        .disabled(viewModel.planName.isEmpty || viewModel.totalMovementCount == 0)
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .movementPicker(let dayIndex):
                        MovementPickerView { movement in
                            viewModel.addMovement(movement, to: dayIndex)
                            activeSheet = nil
                        }
                    case .datePicker:
                        DatePicker(
                            "Start Date",
                            selection: $viewModel.planStartDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .presentationDetents([.medium])
                    }
                }
            }
        }
    }
    
    private var planDetailsSection: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            TextField("Plan Name", text: $viewModel.planName)
                .textFieldStyle(.roundedBorder)
                .font(AppStyle.Typography.body())
            
            Button(action: {
                activeSheet = .datePicker
            }) {
                HStack {
                    Text("Start Date")
                        .font(AppStyle.Typography.body())
                    Spacer()
                    Text(viewModel.planStartDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
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
                    dayIndex: dayIndex,
                    viewModel: viewModel,
                    scrollTarget: $scrollTarget,
                    numberPadShowing: (false),
                    onAddMovement: {
                        activeSheet = .movementPicker(dayIndex: dayIndex)
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
    let dayIndex: Int
    let viewModel: PlanEditorViewModel
    @Binding var scrollTarget: PlanEditorView.ScrollTarget?
    let numberPadShowing: Bool
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
                MovementRow(
                    movement: movement,
                    dayIndex: dayIndex,
                    viewModel: viewModel,
                    scrollTarget: $scrollTarget
                )
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
    let movement: PlanEditorViewModel.MovementConfig
    let dayIndex: Int
    @ObservedObject var viewModel: PlanEditorViewModel
    @Binding var scrollTarget: PlanEditorView.ScrollTarget?
    @State private var showingSetsEditor = false
    @State private var showingRepsEditor = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.movement.name)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    equipmentTag
                    muscleGroupTags
                }
                
                Divider()
                    .background(AppStyle.Colors.textSecondary.opacity(0.2))
                    .padding(.vertical, 4)
                
                HStack(spacing: AppStyle.Layout.standardSpacing) {
                    Button(action: {
                        let frame = geometry.frame(in: .global)
                        scrollTarget = PlanEditorView.ScrollTarget(id: movement.id, buttonFrame: frame)
                        showingSetsEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sets")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                            Text("\(movement.targetSets)")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        let frame = geometry.frame(in: .global)
                        scrollTarget = PlanEditorView.ScrollTarget(id: movement.id, buttonFrame: frame)
                        showingRepsEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reps")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                            Text("\(movement.targetReps)")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .id(movement.id)
            .padding()
            .background(AppStyle.Colors.background.opacity(0.5))
            .cornerRadius(8)
            .sheet(isPresented: $showingSetsEditor) {
                CustomNumberPadView(
                    title: "Sets",
                    initialValue: Double(movement.targetSets),
                    mode: .reps
                ) { newValue in
                    viewModel.updateSets(Int(newValue), for: movement.id, in: dayIndex)
                    scrollTarget = nil
                }
                .presentationDetents([.height(350)])
                .onDisappear {
                    scrollTarget = nil
                }
            }
            .sheet(isPresented: $showingRepsEditor) {
                CustomNumberPadView(
                    title: "Reps",
                    initialValue: Double(movement.targetReps),
                    mode: .reps
                ) { newValue in
                    viewModel.updateReps(Int(newValue), for: movement.id, in: dayIndex)
                    scrollTarget = nil
                }
                .presentationDetents([.height(350)])
                .onDisappear {
                    scrollTarget = nil
                }
            }
        }
        .frame(height: 140)
    }
    
    private var equipmentTag: some View {
        Text(movement.movement.equipment.rawValue)
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
                ForEach(movement.movement.primaryMuscles, id: \.self) { muscle in
                    muscleBadge(muscle.rawValue, isPrimary: true)
                }
                ForEach(movement.movement.secondaryMuscles, id: \.self) { muscle in
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
        PlanEditorView(template: PlanTemplate.templates.first, appState: AppState())
            .preferredColorScheme(.dark)
    }
}
