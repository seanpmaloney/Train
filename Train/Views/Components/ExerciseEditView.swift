import SwiftUI

/// A view for editing exercises during a workout
struct ExerciseEditView: View {
    // MARK: - Properties
    
    @ObservedObject var exercise: ExerciseInstanceEntity
    @ObservedObject var viewModel: EnhancedActiveWorkoutViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header
            HStack {
                Text(exercise.movement.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                Text(exercise.exerciseType)
                    .font(.caption)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppStyle.Colors.background)
                    )
            }
            
            // Exercise sets
            VStack(spacing: 12) {
                // Header row
                HStack(spacing: 12) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                .padding(.horizontal, 8)
                
                // Sets
                ForEach(exercise.sets) { set in
                    SetEditView(set: set, viewModel: viewModel)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyle.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// A view for editing a set during a workout
struct SetEditView: View {
    // MARK: - Properties
    
    @ObservedObject var set: ExerciseSetEntity
    @ObservedObject var viewModel: EnhancedActiveWorkoutViewModel
    @State private var showingWeightPicker = false
    @State private var showingRepsPicker = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Weight input
            Button(action: {
                showingWeightPicker = true
            }) {
                HStack(spacing: 4) {
                    Text(viewModel.formatWeight(set.weight))
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text("lbs")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                }
                .frame(width: 80, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(set.isComplete || viewModel.isComplete)
            .sheet(isPresented: $showingWeightPicker) {
                CustomNumberPadView(
                    title: "Weight",
                    initialValue: set.weight,
                    mode: .weight
                ) { newWeight in
                    viewModel.updateWeight(for: set, to: newWeight)
                }
                .presentationDetents([.height(400)])
            }
            
            // Reps input
            Button(action: {
                showingRepsPicker = true
            }) {
                HStack(spacing: 4) {
                    Text("\(set.completedReps)")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text("/")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text("\(set.targetReps)")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text("reps")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                }
                .frame(width: 100, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(set.isComplete || viewModel.isComplete)
            .sheet(isPresented: $showingRepsPicker) {
                CustomNumberPadView(
                    title: "Reps",
                    initialValue: Double(set.targetReps),
                    mode: .reps
                ) { newReps in
                    viewModel.updateReps(for: set, to: Int(newReps))
                }
                .presentationDetents([.height(400)])
            }
            
            Spacer()
            
            // Completion toggle
            Button(action: {
                viewModel.toggleSetComplete(set)
            }) {
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isComplete ? AppStyle.Colors.success : AppStyle.Colors.textSecondary)
                    .font(.system(size: 24))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isComplete)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.isComplete ? AppStyle.Colors.background : AppStyle.Colors.surface)
        )
        .animation(.easeInOut(duration: 0.2), value: set.isComplete)
    }
}

/// A view for picking weight
struct WeightPickerView: View {
    @State private var selectedWeight: Double
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double) -> Void
    
    init(currentWeight: Double, onSave: @escaping (Double) -> Void) {
        self._selectedWeight = State(initialValue: currentWeight)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Weight", selection: $selectedWeight) {
                    ForEach(Array(stride(from: 5.0, through: 400.0, by: 2.5)), id: \.self) { weight in
                        Text("\(weight, specifier: "%.1f") lbs").tag(weight)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Select Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedWeight)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(250)])
    }
}

/// A view for picking reps
struct RepsPickerView: View {
    @State private var selectedReps: Int
    @Environment(\.dismiss) private var dismiss
    let targetReps: Int
    let onSave: (Int) -> Void
    
    init(currentReps: Int, targetReps: Int, onSave: @escaping (Int) -> Void) {
        self._selectedReps = State(initialValue: currentReps)
        self.targetReps = targetReps
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Reps", selection: $selectedReps) {
                    ForEach(0...30, id: \.self) { reps in
                        Text("\(reps) reps").tag(reps)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Completed Reps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedReps)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(250)])
    }
}

#Preview {
    ExerciseEditView(exercise: ExerciseInstanceEntity(movement: MovementEntity(type: .pullUps, primaryMuscles: [MuscleGroup.back], secondaryMuscles: [MuscleGroup.biceps], equipment: EquipmentType.machine), exerciseType: "Strength", sets: [ExerciseSetEntity(weight: 300, completedReps: 5, targetReps: 5, isComplete: true)]), viewModel: EnhancedActiveWorkoutViewModel(workout: WorkoutEntity(title: "Workout", description: "Yeet", isComplete: false)))
}
