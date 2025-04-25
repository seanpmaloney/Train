import SwiftUI

/// A minimal week selector inspired by Notion/Headspace design
struct WeekSelectorView: View {
    let weekGroups: [EnhancedTrainingViewModel.WeekGroup]
    let currentWeekIndex: Int
    let onWeekSelected: (Int) -> Void
    
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 8) {
            // Week label
            Text("Week \(currentWeekIndex + 1)")
                .font(.headline)
                .foregroundColor(AppStyle.Colors.textPrimary)
                .padding(.bottom, 2)
                .animation(.easeInOut, value: currentWeekIndex)
            
            // Week indicators
            HStack(spacing: 12) {
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
                
                // Week dots
                HStack(spacing: 6) {
                    ForEach(0..<min(weekGroups.count, 7), id: \.self) { index in
                        let isVisible = shouldShowDot(at: index, totalCount: weekGroups.count)
                        if isVisible {
                            Circle()
                                .fill(dotColor(for: index))
                                .frame(width: isCurrentWeek(index) ? 8 : 6, height: isCurrentWeek(index) ? 8 : 6)
                                .overlay(
                                    isCurrentWeek(index) ?
                                    Circle()
                                        .stroke(AppStyle.Colors.primary, lineWidth: 1.5)
                                        .matchedGeometryEffect(id: "currentWeekIndicator", in: animation)
                                    : nil
                                )
                                .animation(.spring(), value: currentWeekIndex)
                        } else if index == 3 && weekGroups.count > 7 {
                            // Show ellipsis for truncated weeks
                            Text("...")
                                .font(.system(size: 10))
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                    }
                }
                
                // Next button
                Button(action: {
                    if currentWeekIndex < weekGroups.count - 1 {
                        onWeekSelected(currentWeekIndex + 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentWeekIndex < weekGroups.count - 1 ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.3))
                }
                .disabled(currentWeekIndex >= weekGroups.count - 1)
            }
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
    // Create sample week groups
    let weekGroups = (0..<8).map { week in
        EnhancedTrainingViewModel.WeekGroup(
            weekNumber: week + 1,
            startDate: Date().addingTimeInterval(Double(week) * 7 * 24 * 60 * 60),
            endDate: Date().addingTimeInterval(Double(week + 1) * 7 * 24 * 60 * 60),
            workouts: []
        )
    }
    
    return VStack {
        WeekSelectorView(
            weekGroups: weekGroups,
            currentWeekIndex: 2,
            onWeekSelected: { _ in }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppStyle.Colors.background)
        
        // Another with fewer weeks
        WeekSelectorView(
            weekGroups: Array(weekGroups.prefix(3)),
            currentWeekIndex: 1,
            onWeekSelected: { _ in }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppStyle.Colors.background)
    }
    .preferredColorScheme(.dark)
}
