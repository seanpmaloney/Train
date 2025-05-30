import SwiftUI

/// A view for editing exercises during a workout
struct ExerciseEditView: View {
    @ObservedObject var exercise: ExerciseInstanceEntity
    @ObservedObject var viewModel: EnhancedActiveWorkoutViewModel
    
    @State private var exerciseHistory: [ExerciseInstanceEntity] = []
    @State private var selectedHistoryIndex: Int = 0
    @State private var showingMovementInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(alignment: .top) {
                HStack(alignment: .center, spacing: 8) {
                    Text(exercise.movement.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isViewingHistory ? AppStyle.Colors.textSecondary : AppStyle.Colors.textPrimary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    if let displayExercise = currentDisplayExercise, !displayExercise.movement.primaryMuscles.isEmpty {
                        if let primaryMuscle = displayExercise.movement.primaryMuscles.first {
                            MusclePill(muscle: primaryMuscle)
                        }
                    }

                    Spacer(minLength: 4)

                    Button(action: {
                        showingMovementInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .font(.system(size: 16))
                    }
                    .sheet(isPresented: $showingMovementInfo) {
                        MovementInfoSheet(movement: exercise.movement)
                    }
                }

                Spacer()
            }
            
            // Sets list
            VStack(spacing: 12) {
                if let displayExercise = currentDisplayExercise {
                    ForEach(displayExercise.sets) { set in
                        SetEditRow(
                            set: set,
                            exercise: displayExercise,
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
    let exercise: ExerciseInstanceEntity
    let isEditable: Bool
    let viewModel: EnhancedActiveWorkoutViewModel
    var onSetCompleted: ((ExerciseInstanceEntity) -> Void)? = nil
    
    @State private var showingWeightPad = false
    @State private var showingRepsPad = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main row content
        
            HStack {
                // Weight section - fixed width to ensure alignment
                HStack(spacing: 4) {
                    if isEditable {
                        Button(action: {
                            // If set is skipped, unskip it first
                            if viewModel.isSetSkipped(set) {
                                viewModel.unskipSet(in: exercise, set: set)
                            } else {
                                showingWeightPad = true
                            }
                        }) {
                            Text(String(format: "%.1f", set.weight))
                                .font(.body)
                                .foregroundColor(viewModel.isSetSkipped(set) ? AppStyle.Colors.textSecondary.opacity(0.6) : AppStyle.Colors.textPrimary)
                                .frame(width: 55, alignment: .trailing)
                        }
                        .disabled(set.isComplete && !viewModel.isSetSkipped(set))
                        .sheet(isPresented: $showingWeightPad) {
                            CustomNumberPadView(
                                title: "Weight",
                                initialValue: set.weight,
                                mode: .weight
                            ) { newValue in
                                viewModel.updateWeightAndSubsequentSets(
                                    in: exercise,
                                    for: set,
                                    to: newValue
                                )
                            }
                            .presentationDetents([.height(405)])
                        }
                    } else {
                        Text(String(format: "%.1f", set.weight))
                            .font(.body)
                            .foregroundColor(viewModel.isSetSkipped(set) ? AppStyle.Colors.textSecondary.opacity(0.6) : AppStyle.Colors.textPrimary)
                            .frame(width: 55, alignment: .trailing)
                    }
                    
                    Text("lbs")
                        .foregroundColor(viewModel.isSetSkipped(set) ? AppStyle.Colors.textSecondary.opacity(0.6) : AppStyle.Colors.textSecondary)
                }
                .frame(width: 100)
                .padding(.trailing, 12)
                
                // Reps section - fixed width to ensure alignment
                HStack(spacing: 4) {
                    if isEditable {
                        Button(action: {
                            // If set is skipped, unskip it first
                            if viewModel.isSetSkipped(set) {
                                viewModel.unskipSet(in: exercise, set: set)
                            } else {
                                showingRepsPad = true
                            }
                        }) {
                            // Display based on skip status
                            if viewModel.isSetSkipped(set) {
                                Text("Skipped")
                                    .font(.body)
                                    .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.6))
                                    .frame(width: 90, alignment: .trailing)
                            } else {
                                // Single value that shows target when not entered, actual when entered
                                if set.completedReps >= 0 {
                                    Text("\(set.completedReps)")
                                        .font(.body)
                                        .foregroundColor(AppStyle.Colors.textPrimary)
                                        .frame(width: 30, alignment: .trailing)
                                } else {
                                    Text("\(set.targetReps)")
                                        .font(.body)
                                        .foregroundColor(AppStyle.Colors.textSecondary)
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                        }
                        .disabled(set.isComplete && !viewModel.isSetSkipped(set))
                        .sheet(isPresented: $showingRepsPad) {
                            CustomNumberPadView(
                                title: "Reps",
                                initialValue: Double(set.completedReps >= 0 ? set.completedReps : set.targetReps),
                                mode: .reps
                            ) { newValue in
                                viewModel.updateReps(
                                    for: set,
                                    to: Int(newValue)
                                )
                            }
                            .presentationDetents([.height(350)])
                        }
                    } else {
                        // Display based on skip status
                        if viewModel.isSetSkipped(set) {
                            Text("Skipped")
                                .font(.body)
                                .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.6))
                                .frame(width: 90, alignment: .trailing)
                        } else {
                            // Show either completed or target reps based on what was recorded
                            if set.completedReps >= 0 {
                                Text("\(set.completedReps)")
                                    .font(.body)
                                    .foregroundColor(AppStyle.Colors.textPrimary)
                                    .frame(width: 30, alignment: .trailing)
                            } else {
                                Text("\(set.targetReps)")
                                    .font(.body)
                                    .foregroundColor(AppStyle.Colors.textSecondary)
                                    .frame(width: 30, alignment: .trailing)
                            }
                            
                            Text("reps")
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Only show "reps" text if not skipped
                    if !viewModel.isSetSkipped(set) && isEditable {
                        Text("reps")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .padding(.leading, 4)
                    }
                }
                .frame(width: 90)
                
                Spacer()
                
                // Complete Checkbox (only for editable mode)
                if isEditable {
                    // Show different button based on whether set is skipped
                    if viewModel.isSetSkipped(set) {
                        Button(action: {
                            viewModel.unskipSet(in: exercise, set: set)
                        }) {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .font(.title2)
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        .padding(.horizontal, 4)
                    } else {
                        Button(action: {
                            withAnimation {
                                // if user hasn't updated the reps,
                                // use target reps as the completed reps
                                if set.completedReps == -1 {
                                    set.completedReps = set.targetReps
                                }
                                set.toggleComplete()
                                // Only trigger if this was the last set to complete
                                // and ALL sets in the exercise are now complete
                                if set.isComplete && exercise.isComplete, let callback = onSetCompleted {
                                    callback(exercise)
                                }
                            }
                        }) {
                            Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(set.isComplete ? AppStyle.Colors.success : AppStyle.Colors.textSecondary)
                        }
                        .padding(.horizontal, 4)
                        .hapticFeedback(style: .rigid)
                    }
                    
                    // 3-dot menu for set actions
                    Menu {
                        Button(action: {
                            viewModel.skipSet(in: exercise, set: set)
                        }) {
                            Label("Skip Set", systemImage: "arrow.uturn.backward.circle")
                        }
                        Button(action: {
                            viewModel.addSet(to: exercise)
                        }) {
                            Label("Add Set", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(viewModel.isComplete)
                    .padding(.horizontal, 4)
                    
                } else {
                    // Show static complete indicator for history
                    if viewModel.isSetSkipped(set) {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                            .foregroundColor(AppStyle.Colors.textSecondary.opacity(0.6))
                            .padding(.horizontal, 8)
                    } else {
                        Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(set.isComplete ? AppStyle.Colors.success.opacity(0.6) : AppStyle.Colors.textSecondary.opacity(0.6))
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                .fill(viewModel.isSetSkipped(set) ? AppStyle.Colors.surfaceTop.opacity(0.5) : AppStyle.Colors.surfaceTop)
        )
        .opacity(set.isComplete && isEditable && !viewModel.isSetSkipped(set) ? 0.6 : 1.0)
    }
}

#Preview {
    ExerciseEditView(exercise: ExerciseInstanceEntity(movement: MovementEntity(type: .pullUps, primaryMuscles: [MuscleGroup.back], secondaryMuscles: [MuscleGroup.biceps], equipment: EquipmentType.machine), exerciseType: "Strength", sets: [ExerciseSetEntity(weight: 300, completedReps: 5, targetReps: 5, isComplete: true), ExerciseSetEntity(weight: 300, completedReps: 5, targetReps: 5, isComplete: true)]), viewModel: EnhancedActiveWorkoutViewModel(workout: WorkoutEntity(title: "Workout", description: "Yeet", isComplete: false)))
}
