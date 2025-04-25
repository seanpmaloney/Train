import SwiftUI

/// A view for selecting a day of the week for a workout
struct DayPickerView: View {
    let selectedDay: WorkoutDay?
    let selectedDays: [WorkoutDay]
    let onSelect: (WorkoutDay?) -> Void
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Day")
                .font(AppStyle.Typography.headline())
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(WorkoutDay.allCases) { day in
                    DayButton(
                        day: day,
                        isSelected: selectedDay == day,
                        isUnavailable: isUnavailable(day),
                        onSelect: { onSelect(day) }
                    )
                }
                
                // "Clear" button to remove selection
                Button(action: {
                    onSelect(nil)
                }) {
                    Text("Clear")
                        .font(AppStyle.Typography.body())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppStyle.Colors.surface)
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppStyle.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .gridCellColumns(2)
            }
            .padding()
        }
        .frame(width: 300)
        .background(AppStyle.Colors.background)
    }
    
    private func isUnavailable(_ day: WorkoutDay) -> Bool {
        // Day is unavailable if it's already selected by another workout
        return selectedDay != day && selectedDays.contains(day)
    }
}

/// Button representing a single day in the day picker
struct DayButton: View {
    let day: WorkoutDay
    let isSelected: Bool
    let isUnavailable: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            if !isUnavailable {
                onSelect()
            }
        }) {
            Text(day.displayName)
                .font(AppStyle.Typography.body())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? AppStyle.Colors.primary : Color.clear, lineWidth: isSelected ? 2 : 0)
                )
        }
        .disabled(isUnavailable)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppStyle.Colors.primary.opacity(0.15)
        } else if isUnavailable {
            return AppStyle.Colors.surface.opacity(0.3)
        } else {
            return AppStyle.Colors.surface
        }
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return AppStyle.Colors.primary
        } else if isUnavailable {
            return AppStyle.Colors.textSecondary.opacity(0.5)
        } else {
            return AppStyle.Colors.textPrimary
        }
    }
}

#Preview {
    DayPickerView(
        selectedDay: .monday,
        selectedDays: [.monday, .wednesday, .friday],
        onSelect: { _ in }
    )
    .preferredColorScheme(.dark)
}
