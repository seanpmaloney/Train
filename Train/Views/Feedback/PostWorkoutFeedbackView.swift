import SwiftUI

struct PostWorkoutFeedbackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFatigue: FatigueLevel?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppStyle.Layout.standardSpacing) {
                // Header card
                workoutCompleteCard
                
                // Fatigue selector
                fatigueSelector
                
                Spacer()
                
                // Finish button
                Button {
                    saveFeedback()
                    // Success haptic for workout completion
                    HapticService.shared.success()
                } label: {
                    Text("Finish Workout")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedFatigue != nil ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
                .disabled(selectedFatigue == nil)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppStyle.Colors.background.ignoresSafeArea())
            .navigationTitle("Workout Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        goBack()
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        skipFeedback()
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
    }
    
    // Header card with completion message
    private var workoutCompleteCard: some View {
        VStack(spacing: AppStyle.Layout.compactSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppStyle.Colors.success)
                .padding(.bottom, 8)
            
            Text("Workout Complete!")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("How was your overall workout fatigue?")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // Fatigue level selector
    private var fatigueSelector: some View {
        VStack(spacing: 8) {
            ForEach(FatigueLevel.allCases, id: \.self) { level in
                FatigueLevelButton(
                    level: level,
                    isSelected: selectedFatigue == level,
                    action: {
                        selectedFatigue = level
                        // Medium haptic for fatigue selection
                        HapticService.shared.impact(style: .medium)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func saveFeedback() {
        guard let fatigue = selectedFatigue, let workout = appState.activeWorkout else { return }
        
        // End the workout with the selected fatigue level
        appState.endWorkout(with: fatigue)
        dismiss()
    }
    
    private func skipFeedback() {
        // End the workout with a default fatigue level
        if appState.activeWorkout != nil {
            appState.endWorkout(with: .normal)
        }
        dismiss()
    }
    
    private func goBack() {
        // Go back to the workout view without completing it
        // The calling view should handle unchecking the last completed set
        dismiss()
    }
}

struct FatigueLevelButton: View {
    let level: FatigueLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(level.description)
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text(fatigueDescription(for: level))
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(fatigueColor(for: level))
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .fill(isSelected ? AppStyle.Colors.surfaceTop : AppStyle.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .stroke(isSelected ? fatigueColor(for: level) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func fatigueColor(for level: FatigueLevel) -> Color {
        switch level {
        case .fresh: return AppStyle.Colors.success
        case .normal: return AppStyle.Colors.primary
        case .wiped: return AppStyle.Colors.secondary
        case .completelyDrained: return AppStyle.Colors.danger
        }
    }
    
    private func fatigueDescription(for level: FatigueLevel) -> String {
        switch level {
        case .fresh:
            return "I could have done more exercises"
        case .normal:
            return "Good workout, appropriately tired"
        case .wiped:
            return "Challenging and thoroughly tired"
        case .completelyDrained:
            return "Too intense, need more recovery time"
        }
    }
}

#Preview {
    PostWorkoutFeedbackView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
