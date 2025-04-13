import SwiftUI

var pullUps = MovementEntity(
    name: "Pull-Up",
    primaryMuscles: [.back],
    secondaryMuscles: [.biceps],
    equipment: .bodyweight
)
var dbRow = MovementEntity(
    name: "Dumbell Row",
    primaryMuscles: [.back],
    secondaryMuscles: [.biceps],
    equipment: .dumbbell
)
var bicepCurls = MovementEntity(
    name: "Biceps Curl",
    primaryMuscles: [.biceps],
    equipment: .dumbbell
)
var squats = MovementEntity(
    name: "Squat",
    primaryMuscles: [.quads],
    secondaryMuscles: [.glutes, .hamstrings],
    equipment: .barbell
)
var rdl = MovementEntity(
    name: "Romanian Deadlift",
    primaryMuscles: [.hamstrings],
    secondaryMuscles: [.glutes, .back],
    equipment: .barbell
)
var legExt = MovementEntity(
    name: "Leg Extension",
    primaryMuscles: [.quads],
    equipment: .machine
)

func makeDefaultSets(count: Int = 3, weight: Double = 100.0, reps: Int = 8) -> [ExerciseSetEntity] {
    (0..<count).map { _ in
        ExerciseSetEntity(weight: weight, completedReps: 0, targetReps: reps, isComplete: false)
    }
}

var exercisesToDo = [ExerciseInstanceEntity(movement: pullUps, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: dbRow, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: bicepCurls, exerciseType: "Hypertrophy", sets: makeDefaultSets())]

var sampleWorkout = WorkoutEntity(
    title: "Back & Biceps",
    description: "Pull-ups, rows, and bicep work",
    isComplete: false,
    exercises: exercisesToDo
)

var legExercisesToDo = [ExerciseInstanceEntity(movement: squats, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: rdl, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: legExt, exerciseType: "Hypertrophy", sets: makeDefaultSets())]

var sampleWorkout2 = WorkoutEntity(
    title: "Legs",
    description: "Squats, RDLs, and some leg extensions",
    isComplete: false,
    exercises: legExercisesToDo
)

struct TrainingView: View {
    @StateObject private var viewModel: TrainingViewModel
    @State private var activeWorkout: WorkoutEntity?
    @EnvironmentObject var appState: AppState
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: TrainingViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(AppStyle.Colors.background)
                    .ignoresSafeArea()
                
                if let activeId = activeWorkoutId,
                   let workout = viewModel.upcomingWorkouts.first(where: { $0.title == activeId }) {
                    ActiveWorkoutView(workout: workout, viewModel: ActiveWorkoutViewModel(workout: workout))
                } else {
                    WorkoutListView(workouts: viewModel.upcomingWorkouts, viewModel: viewModel)
                }
            }
            .navigationTitle("Training")
        }
    }
}

struct WorkoutCard: View {
    let workout: WorkoutEntity
    let isNextWorkout: Bool
    let onStart: () -> Void
    let viewModel: TrainingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date
            HStack {
                Text(workout.title)
                    .font(.headline)
                
                Spacer()
                
                if let scheduledDate = workout.scheduledDate {
                    Text(viewModel.formatDate(scheduledDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
                Text(workout.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            
            // Muscle tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.getMuscleGroups(from: workout), id: \.self) { muscle in
                        Text(muscle.displayName)
                            .font(.caption)
                            .foregroundColor(AppStyle.MuscleColors.color(for: muscle))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppStyle.MuscleColors.color(for: muscle).opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Start button for next workout
            if isNextWorkout {
                Button(action: onStart) {
                    HStack {
                        Spacer()
                        Text("Start Workout")
                            .font(.headline)
                            .foregroundColor(Color(AppStyle.Colors.primary))
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundColor(Color(AppStyle.Colors.primary))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(AppStyle.Colors.surface))
        .cornerRadius(12)
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

struct WorkoutListView: View {
    let workouts: [WorkoutEntity]
    let viewModel: TrainingViewModel
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if workouts.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                        WorkoutCard(
                            workout: workout,
                            isNextWorkout: index == 0,
                            onStart: { activeWorkoutId = workout.title },
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No upcoming training yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            NavigationLink(destination: PlanEditorView(template: nil, appState: appState)) {
                Text("Create a plan to get started")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#00B4D8"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}


#Preview {
    let appState = AppState()
    let viewModel = TrainingViewModel(appState: appState)
    return Group {
        TrainingView(appState: appState)
            .environmentObject(appState)
        
        // Sample workout card
        WorkoutCard(
            workout: WorkoutEntity(
                title: "Sample Workout",
                description: "A sample workout for preview",
                isComplete: false,
                exercises: []
            ),
            isNextWorkout: true,
            onStart: {},
            viewModel: viewModel
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
