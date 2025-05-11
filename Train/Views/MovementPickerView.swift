import SwiftUI

struct MovementPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MovementPickerViewModel
    let onMovementSelected: ([MovementEntity]) -> Void
    var filteredView : Bool
    
    init(filterByMuscles: [MuscleGroup]? = nil, onMovementSelected: @escaping ([MovementEntity]) -> Void) {
        filteredView = (filterByMuscles != nil)
        self.onMovementSelected = onMovementSelected
        _viewModel = StateObject(wrappedValue: MovementPickerViewModel(filterByMuscles: filterByMuscles))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Layout.compactSpacing) {
                searchAndFilterSection
                
                if viewModel.searchText.isEmpty && viewModel.selectedMuscleGroup == nil {
                    suggestedSection
                }
                
                movementsList
            }
            .padding(.horizontal)
            .navigationTitle(filteredView ? "Replace Movement" : "Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppStyle.Colors.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Only show Done button when not in filtered/replacement mode
                if !filteredView {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onMovementSelected(viewModel.getSelectedMovements())
                            dismiss()
                        }
                        .disabled(!viewModel.hasSelections)
                    }
                }
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                TextField("Search movements", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
            .padding()
            .background(AppStyle.Colors.surface)
            .cornerRadius(12)
            
            // Muscle group filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppStyle.Layout.compactSpacing) {
                    filterButton(nil, title: "All")
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        filterButton(muscle, title: muscle.displayName)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func filterButton(_ muscle: MuscleGroup?, title: String) -> some View {
        Button {
            withAnimation {
                viewModel.selectedMuscleGroup = muscle
            }
        } label: {
            Text(title)
                .font(AppStyle.Typography.caption())
                .foregroundColor(viewModel.selectedMuscleGroup == muscle ? .white : AppStyle.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    viewModel.selectedMuscleGroup == muscle ?
                    AppStyle.Colors.primary :
                    AppStyle.Colors.surface
                )
                .cornerRadius(8)
        }
    }
    
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            if !viewModel.suggestedMovements.isEmpty {
                Text("Recently Used")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .padding(.top, 4)
                
                ForEach(viewModel.suggestedMovements) { movement in
                    MovementCard(movement: movement, isSelected: viewModel.isSelected(movement)) {
                        viewModel.toggleSelection(movement)
                    }
                }
                
                Divider()
                    .background(AppStyle.Colors.textSecondary.opacity(0.2))
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var movementsList: some View {
        ScrollView {
            LazyVStack(spacing: AppStyle.Layout.compactSpacing) {
                ForEach(viewModel.filteredMovements) { movement in
                    MovementCard(movement: movement, isSelected: viewModel.isSelected(movement)) {
                        if filteredView {
                            // In replacement mode: select single movement and immediately apply
                            viewModel.selectSingleMovement(movement)
                            onMovementSelected([movement])
                            dismiss()
                        } else {
                            // Normal mode: toggle selection for multi-select
                            viewModel.toggleSelection(movement)
                        }
                    }
                }
            }
        }
    }
}

struct MovementCard: View {
    let movement: MovementEntity
    let isSelected: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: AppStyle.Layout.compactSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(movement.name)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    equipmentTag
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(movement.primaryMuscles, id: \.self) { muscle in
                                musclePill(muscle, isPrimary: true)
                            }
                            ForEach(movement.secondaryMuscles, id: \.self) { muscle in
                                musclePill(muscle, isPrimary: false)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private var equipmentTag: some View {
        Text(movement.equipment.rawValue)
            .font(AppStyle.Typography.caption())
            .foregroundColor(AppStyle.Colors.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppStyle.Colors.secondary.opacity(0.2))
            .cornerRadius(4)
    }
    
    private func musclePill(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        Text(muscle.displayName)
            .font(AppStyle.Typography.caption())
            .foregroundColor(isPrimary ? muscle.color: AppStyle.Colors.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isPrimary ? muscle.color : AppStyle.Colors.textSecondary).opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    MovementPickerView { _ in }
        .preferredColorScheme(.dark)
}
