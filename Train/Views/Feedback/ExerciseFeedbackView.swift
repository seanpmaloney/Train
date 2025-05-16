import SwiftUI

struct ExerciseFeedbackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let exercise: ExerciseInstanceEntity
    let workout: WorkoutEntity
    @Binding var isCollectingFeedback: Bool
    
    @State private var selectedIntensity: ExerciseIntensity? = nil
    @State private var selectedVolume: SetVolumeRating? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Layout.standardSpacing) {
                // Header
                exerciseHeader
                
                // Feedback sections
                ScrollView {
                    VStack(spacing: AppStyle.Layout.standardSpacing) {
                        intensitySection
                        volumeSection
                    }
                }
                
                // Submit button
                Button {
                    saveFeedback()
                } label: {
                    Text("Submit Feedback")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(submitButtonEnabled ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
                .disabled(!submitButtonEnabled)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppStyle.Colors.background.ignoresSafeArea())
            .navigationTitle("Exercise Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        isCollectingFeedback = false
                        dismiss()
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
    }
    
    private var submitButtonEnabled: Bool {
        selectedIntensity != nil && selectedVolume != nil
    }
    
    // Exercise header card
    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            HStack(alignment: .center, spacing: 8) {
                Text(exercise.movement.name)
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                if let primaryMuscle = exercise.movement.primaryMuscles.first {
                    MusclePill(muscle: primaryMuscle)
                }
                
                Spacer()
            }
            
            Text("How did this exercise feel?")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    // Intensity feedback section
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Exercise Intensity")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("How challenging was the weight/resistance?")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            intensityPicker
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    // Volume feedback section
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Set Volume")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("How did the number of sets feel?")
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            volumePicker
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
    }
    
    // Intensity picker with grid of cards
    private var intensityPicker: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ExerciseIntensity.allCases, id: \.self) { intensity in
                FeedbackOptionCard(
                    text: intensity.description,
                    isSelected: selectedIntensity == intensity,
                    color: intensityColor(for: intensity),
                    action: {
                        selectedIntensity = intensity
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // Volume picker with grid layout
    private var volumePicker: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(SetVolumeRating.allCases, id: \.self) { volume in
                FeedbackOptionCard(
                    text: volume.description,
                    isSelected: selectedVolume == volume,
                    color: volumeColor(for: volume),
                    action: {
                        selectedVolume = volume
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func intensityColor(for intensity: ExerciseIntensity) -> Color {
        switch intensity {
        case .tooEasy: return AppStyle.Colors.textSecondary
        case .moderate: return AppStyle.Colors.primary
        case .challenging: return AppStyle.Colors.success
        case .failed: return AppStyle.Colors.danger
        }
    }
    
    private func volumeColor(for volume: SetVolumeRating) -> Color {
        switch volume {
        case .tooEasy: return AppStyle.Colors.textSecondary
        case .moderate: return AppStyle.Colors.primary
        case .challenging: return AppStyle.Colors.success
        case .tooMuch: return AppStyle.Colors.danger
        }
    }
    
    private func saveFeedback() {
        guard let intensity = selectedIntensity, let volume = selectedVolume else { return }
        
        appState.recordExerciseFeedback(
            for: exercise,
            in: workout,
            intensity: intensity,
            setVolume: volume
        )
        
        isCollectingFeedback = false
        dismiss()
    }
}

// Card-based selection component for feedback options
struct FeedbackOptionCard: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Spacer(minLength: 0)
                
                // Indicator icon shows when selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .padding(.bottom, 4)
                }
                
                Text(text)
                    .font(AppStyle.Typography.caption())
                    .fontWeight(isSelected ? .semibold : .regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? color : AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 4)
                
                Spacer(minLength: 0)
            }
            .frame(minHeight: 64)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .fill(isSelected ? color.opacity(0.15) : AppStyle.Colors.surfaceTop)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 2)
            )
            // Add subtle animation for selection
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var isCollecting = true
    
    let movement = MovementEntity(
        type: .barbellBenchPress,
        primaryMuscles: [.chest],
        secondaryMuscles: [.triceps, .shoulders], equipment: .barbell
    )
    
    ExerciseFeedbackView(
        exercise: ExerciseInstanceEntity(movement: movement),
        workout: WorkoutEntity(title: "Sample Workout", description: "Test", isComplete: false),
        isCollectingFeedback: $isCollecting
    )
    .environmentObject(AppState())
    .preferredColorScheme(.dark)
}
