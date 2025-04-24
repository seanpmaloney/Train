//import SwiftUI
//
//var pullUps = MovementEntity(
//    name: "Pull-Up",
//    primaryMuscles: [.back],
//    secondaryMuscles: [.biceps],
//    equipment: .bodyweight
//)
//var dbRow = MovementEntity(
//    name: "Dumbell Row",
//    primaryMuscles: [.back],
//    secondaryMuscles: [.biceps],
//    equipment: .dumbbell
//)
//var bicepCurls = MovementEntity(
//    name: "Biceps Curl",
//    primaryMuscles: [.biceps],
//    equipment: .dumbbell
//)
//var squats = MovementEntity(
//    name: "Squat",
//    primaryMuscles: [.quads],
//    secondaryMuscles: [.glutes, .hamstrings],
//    equipment: .barbell
//)
//var rdl = MovementEntity(
//    name: "Romanian Deadlift",
//    primaryMuscles: [.hamstrings],
//    secondaryMuscles: [.glutes, .back],
//    equipment: .barbell
//)
//var legExt = MovementEntity(
//    name: "Leg Extension",
//    primaryMuscles: [.quads],
//    equipment: .machine
//)
//
//func makeDefaultSets(count: Int = 3, weight: Double = 100.0, reps: Int = 8) -> [ExerciseSetEntity] {
//    (0..<count).map { _ in
//        ExerciseSetEntity(weight: weight, completedReps: 0, targetReps: reps, isComplete: false)
//    }
//}
//
//var exercisesToDo = [ExerciseInstanceEntity(movement: pullUps, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: dbRow, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: bicepCurls, exerciseType: "Hypertrophy", sets: makeDefaultSets())]
//
//var sampleWorkout = WorkoutEntity(
//    title: "Back & Biceps",
//    description: "Pull-ups, rows, and bicep work",
//    isComplete: false,
//    exercises: exercisesToDo
//)
//
//var legExercisesToDo = [ExerciseInstanceEntity(movement: squats, exerciseType: "Hypertrophy", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: rdl, exerciseType: "Strength", sets: makeDefaultSets()), ExerciseInstanceEntity(movement: legExt, exerciseType: "Hypertrophy", sets: makeDefaultSets())]
//
//var sampleWorkout2 = WorkoutEntity(
//    title: "Legs",
//    description: "Squats, RDLs, and some leg extensions",
//    isComplete: false,
//    exercises: legExercisesToDo
//)
//
//struct TrainingView: View {
//    @StateObject private var viewModel: TrainingViewModel
//    @State private var activeWorkout: WorkoutEntity?
//    @EnvironmentObject var appState: AppState
//    
//    init(appState: AppState) {
//        _viewModel = StateObject(wrappedValue: TrainingViewModel(appState: appState))
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // Background
//                Color(AppStyle.Colors.background)
//                    .ignoresSafeArea()
//                
//                WorkoutListView(workouts: viewModel.upcomingWorkouts, viewModel: viewModel)
//            }
//        }
//    }
//}
//
//struct WorkoutCard: View {
//    @ObservedObject var workout: WorkoutEntity
//    let isNextWorkout: Bool
//    let onStart: () -> Void
//    let viewModel: TrainingViewModel
//    @EnvironmentObject private var appState: AppState
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationLink(destination: ActiveWorkoutView(
//            workout: workout,
//            viewModel: ActiveWorkoutViewModel(
//                workout: workout,
//                isReadOnly: workout.isComplete
//            )
//        )) {
//            VStack(alignment: .leading, spacing: 12) {
//                // Header with date
//                HStack {
//                    Text(workout.title)
//                        .font(.headline)
//                    
//                    Spacer()
//                    
//                    if let scheduledDate = workout.scheduledDate {
//                        Text(viewModel.formatDate(scheduledDate))
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                // Description
//                if !workout.description.isEmpty {
//                    Text(workout.description)
//                        .font(.subheadline)
//                        .foregroundColor(AppStyle.Colors.textSecondary)
//                }
//                
//                // Muscle groups
//                let allMuscles = workout.exercises.flatMap { exercise in
//                    exercise.movement.primaryMuscles + exercise.movement.secondaryMuscles
//                }
//                if !allMuscles.isEmpty {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            ForEach(Array(Set(allMuscles)), id: \.self) { muscle in
//                                Text(muscle.rawValue.capitalized)
//                                    .font(.caption)
//                                    .foregroundColor(AppStyle.Colors.textPrimary)
//                                    .padding(.horizontal, 8)
//                                    .padding(.vertical, 4)
//                                    .background(AppStyle.MuscleColors.color(for: muscle).opacity(0.2))
//                                    .cornerRadius(8)
//                            }
//                        }
//                    }
//                }
//                
//                // Start button for next incomplete workout
//                if isNextWorkout && !workout.isComplete {
//                    HStack {
//                        Spacer()
//                        Text("Start Workout")
//                            .font(.headline)
//                            .foregroundColor(Color(AppStyle.Colors.primary))
//                        Image(systemName: "chevron.right")
//                            .font(.headline)
//                            .foregroundColor(Color(AppStyle.Colors.primary))
//                    }
//                    .padding(.top, 4)
//                }
//            }
//            .padding()
//            .background(Color(AppStyle.Colors.surface))
//            .cornerRadius(12)
//            .opacity(workout.isComplete ? 0.5 : 1.0)
//            .animation(.easeInOut(duration: 0.2), value: workout.isComplete)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .simultaneousGesture(TapGesture().onEnded {
//            if isNextWorkout && !workout.isComplete {
//                appState.activeWorkoutId = workout.id
//            }
//        })
//    }
//}
//
//struct WorkoutListView: View {
//    let workouts: [WorkoutEntity]
//    let viewModel: TrainingViewModel
//    @EnvironmentObject var appState: AppState
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                if workouts.isEmpty {
//                    emptyState
//                } else {
//                    ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
//                        WorkoutCard(
//                            workout: workout,
//                            isNextWorkout: workout.id == appState.getNextWorkout().id,
//                            onStart: {},
//                            viewModel: viewModel
//                        )
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//    
//    private var emptyState: some View {
//        VStack(spacing: 12) {
//            Text("No upcoming training yet")
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            NavigationLink(destination: PlanTemplatePickerView()) {
//                Text("Create a plan to get started")
//                    .font(.subheadline)
//                    .foregroundColor(Color(hex: "#00B4D8"))
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//    }
//}
//
//#Preview {
//    let appState = AppState()
//    let viewModel = TrainingViewModel(appState: appState)
//    return Group {
//        TrainingView(appState: appState)
//            .environmentObject(appState)
//        
//        // Sample workout card
//        WorkoutCard(
//            workout: WorkoutEntity(
//                title: "Sample Workout",
//                description: "A sample workout for preview",
//                isComplete: false,
//                exercises: []
//            ),
//            isNextWorkout: true,
//            onStart: {},
//            viewModel: viewModel
//        )
//        .padding()
//        .environmentObject(appState)
//    }
//    .preferredColorScheme(.dark)
//}
