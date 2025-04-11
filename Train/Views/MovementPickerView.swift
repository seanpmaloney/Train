import SwiftUI

struct MovementPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MovementPickerViewModel()
    let onMovementSelected: ([MovementEntity]) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                muscleGroupFilter
                    .padding(.vertical)
                
                if viewModel.searchText.isEmpty && viewModel.selectedMuscleGroup == nil {
                    suggestedSection
                }
                
                movementsList
            }
            .padding(.horizontal)
            .navigationTitle("Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppStyle.Colors.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            TextField("Search movements", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .foregroundColor(AppStyle.Colors.textPrimary)
        }
        .padding()
        .background(AppStyle.Colors.background.opacity(0.5))
        .cornerRadius(10)
    }
    
    private var muscleGroupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppStyle.Layout.compactSpacing) {
                filterButton(nil, title: "All")
                
                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    filterButton(muscle, title: muscle.displayName)
                }
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
                .font(AppStyle.Typography.body())
                .foregroundColor(viewModel.selectedMuscleGroup == muscle ? .white : AppStyle.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    viewModel.selectedMuscleGroup == muscle ?
                    AppStyle.Colors.primary :
                    AppStyle.Colors.background.opacity(0.5)
                )
                .cornerRadius(20)
        }
    }
    
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.standardSpacing) {
            if !viewModel.suggestedMovements.isEmpty {
                Text("Recently Used")
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                ForEach(viewModel.suggestedMovements) { movement in
                    MovementCard(movement: movement, isSelected: viewModel.isSelected(movement)) {
                        viewModel.toggleSelection(movement)
                    }
                }
                
                Divider()
                    .padding(.vertical)
            }
        }
    }
    
    private var movementsList: some View {
        ScrollView {
            LazyVStack(spacing: AppStyle.Layout.compactSpacing) {
                ForEach(viewModel.filteredMovements) { movement in
                    MovementCard(movement: movement, isSelected: viewModel.isSelected(movement)) {
                        viewModel.toggleSelection(movement)
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
        HStack(spacing: AppStyle.Layout.standardSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(movement.name)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        equipmentTag
                        // Primary muscles first line
                        ForEach(movement.primaryMuscles.prefix(2), id: \.self) { muscle in
                            musclePill(muscle, isPrimary: true)
                        }
                    }
                    
                    if movement.primaryMuscles.count > 2 || !movement.secondaryMuscles.isEmpty {
                        FlowLayout(spacing: 8) {
                            // Remaining primary muscles
                            ForEach(Array(movement.primaryMuscles.dropFirst(2)), id: \.self) { muscle in
                                musclePill(muscle, isPrimary: true)
                            }
                            // Secondary muscles
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
                    .font(.title2)
                    .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
            }
        }
        .padding()
        .cardStyle()
        .opacity(isSelected ? 1 : 0.8)
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
    
    private func musclePill(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        Text(muscle.displayName)
            .font(AppStyle.Typography.caption())
            .foregroundColor(isPrimary ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background((isPrimary ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary).opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    MovementPickerView { _ in }
        .preferredColorScheme(.dark)
}
