import SwiftUI

struct CalendarCardView: View {
    @StateObject private var viewModel = CalendarCardViewModel()
    
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
                    if let date = viewModel.weeks.flatMap { $0 }[index] {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isSelectable: viewModel.isDateSelectable(date),
                            trainingType: viewModel.getTrainingType(for: date)
                        )
                        .onTapGesture {
                            if viewModel.isDateSelectable(date) {
                                withAnimation {
                                    viewModel.selectedDate = date
                                }
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
            }
            
            // Training preview section
            if !viewModel.selectedDaySessions.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.selectedDaySessions) { session in
                        TrainingSessionPreview(session: session)
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
    let trainingType: TrainingType?
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelectable ? .primary : .secondary)
            
            if let type = trainingType {
                Circle()
                    .fill(Color(hex: type.color))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 32)
        .background(
            isSelected ?
            Circle()
                .fill(Color(hex: "#00B4D8").opacity(0.2))
                .frame(width: 32, height: 32)
            : nil
        )
    }
}

struct TrainingSessionPreview: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title)
                    .font(.headline)
                
                Spacer()
                
                if let startTime = session.startTime {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }
            
            if let summary = session.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(session.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: session.type.color).opacity(0.2))
                    .foregroundColor(Color(hex: session.type.color))
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(hex: "#0F1115"))
        .cornerRadius(12)
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
