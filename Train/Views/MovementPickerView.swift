import SwiftUI

struct MovementPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MovementPickerViewModel()
    let onMovementSelected: (MovementEntity) -> Void
    
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
                    filterButton(muscle, title: muscle.rawValue)
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
                    MovementCard(movement: movement) {
                        selectMovement(movement)
                    }
                }
                
                Divider()
                    .padding(.vertical)
            }
            
            Text("All Movements")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
    }
    
    private var movementsList: some View {
        ScrollView {
            LazyVStack(spacing: AppStyle.Layout.compactSpacing) {
                ForEach(viewModel.filteredMovements) { movement in
                    MovementCard(movement: movement) {
                        selectMovement(movement)
                    }
                }
            }
        }
    }
    
    private func selectMovement(_ movement: MovementEntity) {
        viewModel.addToRecentlyUsed(movement)
        onMovementSelected(movement)
        dismiss()
    }
}

struct MovementCard: View {
    let movement: MovementEntity
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: AppStyle.Layout.standardSpacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(movement.name)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                HStack(spacing: 8) {
                    equipmentTag
                    muscleGroups
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppStyle.Colors.primary)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var equipmentTag: some View {
        Text(movement.equipment.rawValue)
            .font(AppStyle.Typography.caption())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(AppStyle.Colors.secondary.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var muscleGroups: some View {
        HStack(spacing: 4) {
            ForEach(movement.primaryMuscles, id: \.self) { muscle in
                Text(muscle.rawValue)
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppStyle.Colors.primary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    MovementPickerView { _ in }
        .preferredColorScheme(.dark)
}
