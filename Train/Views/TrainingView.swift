import SwiftUI

struct TrainingView: View {
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    // Sample workout data
    private let workouts = [
        Workout(
            id: "back-biceps-01",
            title: "Back & Biceps",
            type: "Strength",
            description: "Pull-ups, rows, and bicep work focusing on time under tension"
        ),
        Workout(
            id: "legs-core-01",
            title: "Legs & Core",
            type: "Hypertrophy",
            description: "High-volume leg training with core stability work"
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(AppStyle.Colors.background)
                    .ignoresSafeArea()
                
                if let activeId = activeWorkoutId,
                   let workout = workouts.first(where: { $0.id == activeId }) {
                    ActiveWorkoutView(workout: workout)
                } else {
                    WorkoutListView(workouts: workouts)
                }
            }
            .navigationTitle("Training")
        }
    }
}

struct WorkoutListView: View {
    let workouts: [Workout]
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(workouts) { workout in
                    WorkoutCard(workout: workout)
                }
            }
            .padding()
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(workout.type)
                    .font(.subheadline)
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            // Description
            Text(workout.description)
                .font(.body)
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            // Buttons
            HStack {
                Button(action: {
                    activeWorkoutId = workout.id
                }) {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppStyle.Colors.primary)
                        )
                }
                
                Button(action: {
                    // Info action (to be implemented)
                }) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppStyle.Colors.surface)
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct ActiveWorkoutView_Preview: View {
    let workout: Workout
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Active Workout")
                .font(.headline)
                .foregroundColor(AppStyle.Colors.background)
            
            Text(workout.title)
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: {
                activeWorkoutId = nil
            }) {
                Text("End Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppStyle.Colors.danger)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct Workout: Identifiable {
    let id: String
    let title: String
    let type: String
    let description: String
    var exercises: [Exercise] = [] // Optional default empty array
}

#Preview {
    TrainingView()
        .preferredColorScheme(.dark)
} 
