import SwiftUI

struct CalendarCardView: View {
    @StateObject private var viewModel: CalendarCardViewModel
    @EnvironmentObject private var appState: AppState
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: CalendarCardViewModel(appState: appState))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button(action: { viewModel.moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(viewModel.monthTitle)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            WeekdayHeaderView()
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(viewModel.weeks.flatMap { $0 }.indices, id: \.self) { index in
                    if let date = viewModel.weeks.flatMap({ $0 })[index] {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isSelectable: viewModel.isDateSelectable(date),
                            workoutType: viewModel.getWorkoutType(for: date)
                        )
                        .onTapGesture {
                            if viewModel.isDateSelectable(date) {
                                    viewModel.selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
            }
            
            // Workouts preview section
            if !viewModel.selectedDayWorkouts.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.selectedDayWorkouts) { workout in
                        WorkoutPreview(workout: workout)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(hex: "#1A1C20"))
        .cornerRadius(16)
    }
}

struct WeekdayHeaderView: View {
    private let weekdays = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isSelectable: Bool
    let workoutType: TrainingType
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelectable ? .primary : .secondary)
            
        }
        .frame(height: 32)
        .background(
            isSelected ?
            Circle()
                .fill(Color(hex: "#00B4D8").opacity(0.2))
                .frame(width: 40, height: 40)
            : nil
        )
        .background(
            workoutType != .none ?
                Circle()
                    .stroke(Color(hex: workoutType.color), lineWidth: 1)
                    .frame(width: 34, height: 34)
            : nil)
            }
}

struct WorkoutPreview: View {
    let workout: WorkoutEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title)
                    .font(.headline)
                
                Spacer()
                
                if let scheduledDate = workout.scheduledDate {
                    Text(scheduledDate.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(workout.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#00B4D8").opacity(0.2))
                        .foregroundColor(Color(hex: "#00B4D8"))
                        .cornerRadius(8)
                    
                    let muscles = getMuscleGroups(from: workout)
                    ForEach(Array(muscles.primary), id: \.self) { muscle in
                        musclePill(muscle, isPrimary: true)
                    }
                    ForEach(Array(muscles.secondary), id: \.self) { muscle in
                        musclePill(muscle, isPrimary: false)
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "#0F1115"))
        .cornerRadius(12)
    }
    
    private func musclePill(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        Text(muscle.displayName)
            .font(.caption)
            .foregroundColor(isPrimary ? Color(hex: "#00B4D8") : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isPrimary ? Color(hex: "#00B4D8") : .secondary).opacity(0.2))
            .cornerRadius(8)
    }
    
    private func getMuscleGroups(from workout: WorkoutEntity) -> (primary: Set<MuscleGroup>, secondary: Set<MuscleGroup>) {
        var primary = Set<MuscleGroup>()
        var secondary = Set<MuscleGroup>()
        
        for exercise in workout.exercises {
            primary.formUnion(exercise.movement.primaryMuscles)
            secondary.formUnion(exercise.movement.secondaryMuscles)
        }
        
        // Remove any muscles that are in both sets (keep them only in primary)
        secondary.subtract(primary)
        
        return (primary, secondary)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CalendarCardView(appState: AppState()).preferredColorScheme(.dark)
}
