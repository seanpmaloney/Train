import SwiftUI

struct ActiveWorkoutView: View {
    let workout: Workout
    @AppStorage("activeWorkoutId") private var activeWorkoutId: String?
    @State private var exercises: [Exercise]
    @State private var isTimerExpanded = false
    
    // Initialize with workout and create exercise state
    init(workout: Workout) {
        self.workout = workout
        // Initialize exercise state with sample data
        let sampleExercises = [
            Exercise(
                name: "Pull-ups",
                sets: [
                    ExerciseSet(weight: 0, targetReps: 8),
                    ExerciseSet(weight: 0, targetReps: 8),
                    ExerciseSet(weight: 0, targetReps: 8)
                ]
            ),
            Exercise(
                name: "Barbell Rows",
                sets: [
                    ExerciseSet(weight: 135, targetReps: 12),
                    ExerciseSet(weight: 135, targetReps: 12),
                    ExerciseSet(weight: 135, targetReps: 12)
                ]
            ),
            Exercise(
                name: "Bicep Curls",
                sets: [
                    ExerciseSet(weight: 30, targetReps: 12),
                    ExerciseSet(weight: 30, targetReps: 12),
                    ExerciseSet(weight: 25, targetReps: 12)
                ]
            )
        ]
        _exercises = State(initialValue: sampleExercises)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main scrolling content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with clock button
                    HStack {
                        Text(workout.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Clock button
                        TimerButton(isExpanded: $isTimerExpanded)
                    }
                    .padding(.bottom)
                    
                    // Rest of workout content
                    LazyVStack(spacing: 16) {
                        ForEach($exercises) { $exercise in
                            ExerciseCard(exercise: $exercise)
                        }
                    }
                    
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
                                    .fill(Color.red)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            // Floating timer overlay
            if isTimerExpanded {
                GeometryReader { geometry in
                    VStack {
                        // Add spacing to position below button
                        HStack {
                            Spacer()
                            RestTimer(isExpanded: $isTimerExpanded)
                                .padding(.top, 60) // Adjust based on your header height
                                .padding(.trailing)
                        }
                        Spacer()
                    }
                }
                .background(Color.clear) // Make sure background is clear
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

struct ExerciseCard: View {
    @Binding var exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(exercise.name)
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach($exercise.sets) { $set in
                    SetRow(set: $set)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.17))
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct SetRow: View {
    @Binding var set: ExerciseSet
    
    var body: some View {
        HStack(spacing: 16) {
            // Weight Input
            HStack {
                TextField("Weight", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                    .disabled(set.isComplete)
                Text("lbs")
                    .foregroundColor(.gray)
            }
            
            // Reps Input
            HStack {
                TextField("Reps", value: Binding(
                    get: { set.completedReps ?? set.targetReps },
                    set: { set.completedReps = $0 }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .disabled(set.isComplete)
                Text("reps")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Complete Checkbox
            Button(action: {
                withAnimation {
                    set.isComplete.toggle()
                    if set.isComplete {
                        set.completedReps = set.targetReps
                    } else {
                        set.completedReps = nil
                    }
                }
            }) {
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(set.isComplete ? .green : .gray)
            }
        }
        .opacity(set.isComplete ? 0.6 : 1)
    }
}

// Simplified timer button
struct TimerButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
                isExpanded.toggle()
            }
        ) {
            Image(systemName: "clock.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(Color(white: 0.17))
                        .shadow(color: .black.opacity(0.2), radius: 10)
                )
                .contentShape(Circle())
        }
    }
}

// Data Models
struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    var sets: [ExerciseSet]
}

struct ExerciseSet: Identifiable {
    let id = UUID()
    var weight: Double
    var targetReps: Int
    var completedReps: Int?
    var isComplete: Bool = false
}

#Preview {
    ZStack {
        Color(white: 0.12).ignoresSafeArea()
        ActiveWorkoutView(
            workout: Workout(
                id: "back-biceps-01",
                title: "Back & Biceps",
                type: "Strength",
                description: "Pull-ups, rows, and bicep work"
            )
        )
    }
    .preferredColorScheme(.dark)
} 
