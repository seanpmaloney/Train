import SwiftUI

/// A view for editing exercises during a workout
struct ExerciseEditView: View {
    @ObservedObject var exercise: ExerciseInstanceEntity
    @ObservedObject var viewModel: EnhancedActiveWorkoutViewModel
    
    @State private var exerciseHistory: [ExerciseInstanceEntity] = []
    @State private var selectedHistoryIndex: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.movement.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isViewingHistory ? AppStyle.Colors.textSecondary : AppStyle.Colors.textPrimary)
                    
                    // Muscle group pills
                    if let displayExercise = currentDisplayExercise, !displayExercise.movement.primaryMuscles.isEmpty {
                        // Only show the first muscle group to keep the display static
                        if let primaryMuscle = displayExercise.movement.primaryMuscles.first {
                            MusclePill(muscle: primaryMuscle)
                                .padding(.bottom, 4)
                        }
                    }
                }
                
                Spacer()
                
                // Exercise history indicator
                if hasHistory {
                    ExerciseHistoryIndicator(
                        currentIndex: selectedHistoryIndex,
                        totalCount: exerciseHistory.count,
                        onNavigate: { index in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHistoryIndex = index
                            }
                        }
                    )
                }
            }
            
            // Sets list
            VStack(spacing: 12) {
                if let displayExercise = currentDisplayExercise {
                    ForEach(displayExercise.sets) { set in
                        SetEditRow(
                            set: set,
                            isEditable: !isViewingHistory,
                            viewModel: viewModel
                        )
                        .id("\(displayExercise.id)-\(set.id)")
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedHistoryIndex)
            .opacity(isViewingHistory ? 0.6 : 1.0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppStyle.Colors.surface)
        )
        .padding(.horizontal, 4)
        .onAppear {
            // Load exercise history when view appears
            exerciseHistory = viewModel.getExerciseHistory(for: exercise)
            
            // Default to current week
            selectedHistoryIndex = exerciseHistory.count - 1
        }
    }
    
    private var currentDisplayExercise: ExerciseInstanceEntity? {
        guard !exerciseHistory.isEmpty else { return exercise }
        return exerciseHistory[selectedHistoryIndex]
    }
    
    private var isViewingHistory: Bool {
        guard !exerciseHistory.isEmpty else { return false }
        // If we're not at the last index (current exercise), we're viewing history
        return selectedHistoryIndex != exerciseHistory.count - 1 && exerciseHistory.count > 1
    }
    
    private var hasHistory: Bool {
        // Need at least 2 exercises to have history
        return exerciseHistory.count > 1
    }
}

/// A version of SetRow that can be toggled between editable and readonly states
struct SetEditRow: View {
    @ObservedObject var set: ExerciseSetEntity
    let isEditable: Bool
    let viewModel: EnhancedActiveWorkoutViewModel
    
    @State private var showingWeightPad = false
    @State private var showingRepsPad = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Weight Input
            HStack {
                if isEditable {
                    Button(action: {
                        showingWeightPad = true
                    }) {
                        Text(String(format: "%.1f", set.weight))
                            .font(.body)
                            .foregroundColor(AppStyle.Colors.textPrimary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .disabled(set.isComplete)
                    .sheet(isPresented: $showingWeightPad) {
                        CustomNumberPadView(
                            title: "Weight",
                            initialValue: set.weight,
                            mode: .weight
                        ) { newValue in
                            set.weight = newValue
                        }
                        .presentationDetents([.height(405)])
                    }
                } else {
                    Text(String(format: "%.1f", set.weight))
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(width: 70, alignment: .trailing)
                }
                
                Text("lbs")
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            // Reps Input
            HStack {
                if isEditable {
                    Button(action: {
                        showingRepsPad = true
                    }) {
                        Text("\(set.completedReps)")
                            .font(.body)
                            .foregroundColor(AppStyle.Colors.textPrimary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .disabled(set.isComplete)
                    .sheet(isPresented: $showingRepsPad) {
                        CustomNumberPadView(
                            title: "Reps",
                            initialValue: Double(set.completedReps),
                            mode: .reps
                        ) { newValue in
                            set.completedReps = Int(newValue)
                        }
                        .presentationDetents([.height(350)])
                    }
                } else {
                    Text("\(set.completedReps)")
                        .font(.body)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(width: 40, alignment: .trailing)
                }
                
                Text("/ \(set.targetReps) reps")
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            Spacer()
            
            // Complete Checkbox (only for editable mode)
            if isEditable {
                Button(action: {
                    withAnimation {
                        set.toggleComplete()
                    }
                }) {
                    Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(set.isComplete ? AppStyle.Colors.success : AppStyle.Colors.textSecondary)
                }
            } else {
                // Show static complete indicator for history
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(set.isComplete ? AppStyle.Colors.success.opacity(0.6) : AppStyle.Colors.textSecondary.opacity(0.6))
            }
        }
        .opacity(set.isComplete && isEditable ? 0.6 : 1.0)
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
