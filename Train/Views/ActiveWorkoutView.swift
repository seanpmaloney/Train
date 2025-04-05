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
                                    .fill(AppStyle.Colors.danger)
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
                .fill(AppStyle.Colors.surface)
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}

struct SetRow: View {
    @Binding var set: ExerciseSet
    @State private var showingWeightPad = false
    @State private var showingRepsPad = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Weight Input
            HStack {
                Button(action: {
                    showingWeightPad = true
                }) {
                    Text(String(format: "%.1f", set.weight))
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 70, alignment: .trailing)
                }
                .disabled(set.isComplete)
                .sheet(isPresented: $showingWeightPad) {
                    CustomNumberPadView(
                        title: "Weight",
                        initialValue: set.weight,
                        mode: .weight
                    ) { newValue in
                        set.weight = newValue
                    }
                    .presentationDetents([.height(400)])
                }
                
                Text("lbs")
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            // Reps Input
            HStack {
                Button(action: {
                    showingRepsPad = true
                }) {
                    Text("\(set.completedReps ?? set.targetReps)")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 50, alignment: .trailing)
                }
                .disabled(set.isComplete)
                .sheet(isPresented: $showingRepsPad) {
                    CustomNumberPadView(
                        title: "Reps",
                        initialValue: Double(set.completedReps ?? set.targetReps),
                        mode: .reps
                    ) { newValue in
                        set.completedReps = Int(newValue)
                    }
                    .presentationDetents([.height(350)])
                }
                
                Text("reps")
                    .foregroundColor(AppStyle.Colors.textSecondary)
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
                    .foregroundColor(set.isComplete ? AppStyle.Colors.success : AppStyle.Colors.textSecondary)
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
                        .fill(AppStyle.Colors.surface)
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
        Color(AppStyle.Colors.background).ignoresSafeArea()
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
