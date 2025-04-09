import SwiftUI

var pullUps = MovementEntity(name: "Pull-Up")
var dbRow = MovementEntity(name: "Dumbell Row")
var bicepCurls = MovementEntity(name: "Biceps Curl")
var squats = MovementEntity(name: "Squat")
var rdl = MovementEntity(name: "Romanian Deadlift")
var legExt = MovementEntity(name: "Leg Extension")

func makeDefaultSets(count: Int = 3, weight: Double = 100.0, reps: Int = 8) -> [ExerciseSetEntity] {
    (0..<count).map { _ in
        ExerciseSetEntity(weight: weight, completedReps: 0, targetReps: reps, isComplete: false)
    }
}

var exercisesToDo = [ExerciseInstanceEntity(movement: pullUps, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: dbRow, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: bicepCurls, exerciseType: "Hypertrophy", sets: makeDefaultSets())]

var sampleWorkout = WorkoutEntity(
    title: "Back & Biceps",
    description: "Pull-ups, rows, and bicep work",
    exercises: exercisesToDo
)

var legExercisesToDo = [ExerciseInstanceEntity(movement: squats, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: rdl, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: legExt, exerciseType: "Hypertrophy", sets: makeDefaultSets())]

var sampleWorkout2 = WorkoutEntity(
    title: "Legs",
    description: "Squats, RDLs, and some leg extensions",
    exercises: legExercisesToDo
)

struct TrainingView: View {
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    // Sample workout data
    private let workouts = [sampleWorkout, sampleWorkout2]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(AppStyle.Colors.background)
                    .ignoresSafeArea()
                
                if let activeId = activeWorkoutId,
                   let workout = workouts.first(where: { $0.title == activeId }) {
                    ActiveWorkoutView(workout: workout, viewModel: ActiveWorkoutViewModel(workout: workout))
                } else {
                    WorkoutListView(workouts: workouts)
                }
            }
            .navigationTitle("Training")
        }
    }
}

struct WorkoutListView: View {
    let workouts: [WorkoutEntity]
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
    let workout: WorkoutEntity
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    @State private var exercises: [ExerciseInstanceEntity]
    
    init(workout: WorkoutEntity) {
            self.workout = workout
            _exercises = State(initialValue: workout.exercises)
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(workout.exercises.first?.exerciseType ?? "Strength")
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
                    activeWorkoutId = workout.title
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
    let workout: WorkoutEntity
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

#Preview {
    TrainingView()
        .preferredColorScheme(.dark)
} 
