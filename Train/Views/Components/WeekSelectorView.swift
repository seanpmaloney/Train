import SwiftUI

/// A minimal week selector inspired by Notion/Headspace design
struct WeekSelectorView: View {
    let weeklyWorkouts: [[WorkoutEntity]]
    let currentWeekIndex: Int
    let onWeekSelected: (Int) -> Void
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            // Week selector controls in a horizontal layout
            HStack(spacing: 8) {
                // Previous button
                Button(action: {
                    if currentWeekIndex > 0 {
                        onWeekSelected(currentWeekIndex - 1)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentWeekIndex > 0 ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.3))
                }
                .disabled(currentWeekIndex <= 0)
                
                // Week label
                Text("Week \(currentWeekIndex + 1)")
                    .font(.headline)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .animation(.easeInOut, value: currentWeekIndex)
                    .frame(minWidth: 80)
                
                // Next button
                Button(action: {
                    if currentWeekIndex < weeklyWorkouts.count - 1 {
                        onWeekSelected(currentWeekIndex + 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentWeekIndex < weeklyWorkouts.count - 1 ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.3))
                }
                .disabled(currentWeekIndex >= weeklyWorkouts.count - 1)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(AppStyle.Colors.surface.opacity(0.5))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    // Helper to determine if we should show this dot based on total count
    private func shouldShowDot(at index: Int, totalCount: Int) -> Bool {
        if totalCount <= 7 {
            // Show all dots if 7 or fewer weeks
            return true
        } else {
            // For many weeks, show first 3, last 3, and current week
            if index < 3 || index >= totalCount - 3 || index == currentWeekIndex {
                return true
            }
            return false
        }
    }
    
    // Helper to determine dot color
    private func dotColor(for index: Int) -> Color {
        if isCurrentWeek(index) {
            return AppStyle.Colors.primary.opacity(0.7)
        } else if index < currentWeekIndex {
            // Past weeks
            return AppStyle.Colors.textSecondary.opacity(0.7)
        } else {
            // Future weeks
            return AppStyle.Colors.textSecondary.opacity(0.3)
        }
    }
    
    // Helper to check if this is the current week
    private func isCurrentWeek(_ index: Int) -> Bool {
        return index == currentWeekIndex
    }
}

#Preview {
    // Create sample weekly workouts
    let weeklyWorkouts: [[WorkoutEntity]] = (0..<8).map { week in
        // Create a few sample workouts for each week
        let startDate = Date().addingTimeInterval(Double(week) * 7 * 24 * 60 * 60)
        return (0..<3).map { day in
            let workout = WorkoutEntity(
                title: "Workout \(day+1)",
                description: "Sample workout",
                isComplete: false,
                scheduledDate: startDate.addingTimeInterval(Double(day) * 24 * 60 * 60),
                exercises: []
            )
            return workout
        }
    }
    
    return VStack {
        WeekSelectorView(
            weeklyWorkouts: weeklyWorkouts,
            currentWeekIndex: 2,
            onWeekSelected: { _ in }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppStyle.Colors.background)
        
        // Another with fewer weeks
        WeekSelectorView(
            weeklyWorkouts: Array(weeklyWorkouts.prefix(3)),
            currentWeekIndex: 1,
            onWeekSelected: { _ in }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppStyle.Colors.background)
    }
    .preferredColorScheme(.dark)
}
