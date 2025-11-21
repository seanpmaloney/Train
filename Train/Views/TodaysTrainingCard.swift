import SwiftUI

struct TodaysTrainingCard: View {
    @StateObject private var viewModel: TodaysTrainingViewModel
    @EnvironmentObject private var appState: AppState
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: TodaysTrainingViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationLink(
            destination: viewModel.todaysWorkout.map { workout in
                EnhancedActiveWorkoutView(workout: workout)
            }
        ) {
            cardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Today")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                CircularProgressView(
                    progress: viewModel.completionPercentage,
                    size: 24,
                    lineWidth: 2
                )
            }
            
            if let workout = viewModel.todaysWorkout {
                // Workout info
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(workout.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Muscle group tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let muscles = viewModel.getMuscleGroups()
                            ForEach(Array(muscles.primary), id: \.self) { muscle in
                                musclePill(muscle, isPrimary: true)
                            }
                            ForEach(Array(muscles.secondary), id: \.self) { muscle in
                                musclePill(muscle, isPrimary: false)
                            }
                        }
                    }
                    
                    // Start workout button
                    HStack {
                        Spacer()
                        Text("Start Workout")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#00B4D8"))
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#00B4D8"))
                    }
                }
            } else {
                // No workout message
                HStack {
                    Spacer()
                    Text("No training scheduled for today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(AppStyle.Colors.surface)
        .cornerRadius(12)
    }
    
    private func musclePill(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        Text(muscle.displayName)
            .font(.caption)
            .foregroundColor(isPrimary ? AppStyle.MuscleColors.color(for: muscle) : AppStyle.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isPrimary ? AppStyle.MuscleColors.color(for: muscle) : AppStyle.Colors.textSecondary).opacity(0.2))
            .cornerRadius(8)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: "#00B4D8"), style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
