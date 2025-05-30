import SwiftUI

struct PreWorkoutFeedbackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let workout: WorkoutEntity
    
    @State private var selectedSoreMuscles: Set<MuscleGroup> = []
    @State private var selectedJointAreas: Set<JointArea> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Layout.standardSpacing) {
                // Header
                workoutHeaderSection
                
                // Content - Feedback Sections
                ScrollView {
                    VStack(spacing: AppStyle.Layout.standardSpacing) {
                        soreMusclesSection
                        jointPainSection
                    }
                    .padding(.bottom)
                }
                
                // Start button
                Button {
                    saveFeedback()
                    // Success haptic for starting the workout
                    HapticService.shared.success()
                } label: {
                    Text("Start Workout")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppStyle.Colors.background.ignoresSafeArea())
            .navigationTitle("Pre-Workout Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
    }
    
    // Header section with workout info
    private var workoutHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text(workout.title)
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Get ready for your workout")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    // Sore muscles selection section
    private var soreMusclesSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Any sore muscles today?")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Select any muscles that feel sore")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            VStack(spacing: 4) {
                // Split the muscles into 4 groups of 4 for a grid layout
                let filteredMuscles = MuscleGroup.allCases.filter { $0 != .unknown }
                let rows = stride(from: 0, to: filteredMuscles.count, by: 4).map {
                    Array(filteredMuscles[$0..<min($0 + 4, filteredMuscles.count)])
                }
                
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 2) {
                        ForEach(rows[rowIndex], id: \.self) { muscle in
                            MusclePillSelectable(
                                muscle: muscle,
                                isSelected: selectedSoreMuscles.contains(muscle)
                            ) {
                                toggleMuscle(muscle)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
//            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    // Joint pain selection section
    private var jointPainSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Joint Pain?")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Select areas experiencing discomfort or pain")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(JointArea.allCases, id: \.self) { joint in
                    JointPill(
                        joint: joint,
                        isSelected: selectedJointAreas.contains(joint),
                        action: {
                            toggleJoint(joint)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    private func toggleMuscle(_ muscle: MuscleGroup) {
        if selectedSoreMuscles.contains(muscle) {
            selectedSoreMuscles.remove(muscle)
        } else {
            selectedSoreMuscles.insert(muscle)
        }
        
        // Medium haptic for sore muscle selection/deselection
        HapticService.shared.impact(style: .medium)
    }
    
    private func toggleJoint(_ joint: JointArea) {
        if selectedJointAreas.contains(joint) {
            selectedJointAreas.remove(joint)
        } else {
            selectedJointAreas.insert(joint)
        }
        
        // Error haptic for joint pain selection/deselection
        HapticService.shared.error()
    }
    
    private func saveFeedback() {
        appState.recordPreWorkoutFeedback(
            for: workout,
            soreMuscles: Array(selectedSoreMuscles),
            jointPainAreas: Array(selectedJointAreas)
        )
        
        // Begin the workout
        appState.setActiveWorkout(workout)
        dismiss()
    }
}

// Selectable muscle pill component (similar to existing MusclePill but toggleable)
struct MusclePillSelectable: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(muscle.displayName)
                .font(AppStyle.Typography.caption())
                .foregroundColor(isSelected ? .white : AppStyle.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected 
                            ? AppStyle.MuscleColors.color(for: muscle) 
                            : AppStyle.MuscleColors.color(for: muscle).opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



struct JointPill: View {
    let joint: JointArea
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(joint.description)
                .font(AppStyle.Typography.caption())
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppStyle.Colors.danger.opacity(0.2) : AppStyle.Colors.surfaceTop)
                )
                .foregroundColor(isSelected ? AppStyle.Colors.danger : AppStyle.Colors.textSecondary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? AppStyle.Colors.danger : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let workout = WorkoutEntity(
        title: "Sample Workout", 
        description: "Test", 
        isComplete: false
    )
    
    PreWorkoutFeedbackView(workout: workout)
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
