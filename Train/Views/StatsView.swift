import SwiftUI
import Charts

/// Main view for displaying workout statistics and training progress
struct StatsView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: StatsViewModel
    @State private var selectedChart: ChartType = .muscleGroup
    
    // Enum for chart selection
    enum ChartType: String, CaseIterable, Identifiable {
        case muscleGroup = "Muscle Groups"
        //case weeklyVolume = "Weekly Volume"
        case oneRepMax = "1RM Estimates"
        case strengthTrends = "Strength Trends"
        case muscleGroupSetsOverTime = "Muscle Group Sets Over Time"
        
        var id: String { rawValue }
    }
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self._viewModel = StateObject(wrappedValue: StatsViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart selector
                    chartSelector
                    
                    // Time range selector (for applicable charts)
                    if selectedChart == .strengthTrends {
                        timeRangeSelector
                    }
                    
                    // Selected chart view
                    selectedChartView
                        .frame(minHeight: 300)
                        .padding(.horizontal, 16)
                    
//                    // Additional stats sections
//                    if selectedChart != .oneRepMax {
//                        topExercisesSection
//                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshAllData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Chart type selector
    private var chartSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases) { chartType in
                    Button(action: {
                        withAnimation {
                            selectedChart = chartType
                        }
                    }) {
                        Text(chartType.rawValue)
                            .font(AppStyle.Typography.body())
                            .foregroundColor(selectedChart == chartType ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedChart == chartType ? AppStyle.Colors.surfaceTop : AppStyle.Colors.background)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppStyle.Colors.surfaceTop, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    /// Time range selector
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(StatsViewModel.TimeRange.allCases) { timeRange in
                Button(action: {
                    withAnimation {
                        viewModel.selectedTimeRange = timeRange
                        viewModel.refreshStrengthTrendData()
                    }
                }) {
                    Text(timeRange.rawValue)
                        .font(AppStyle.Typography.body())
                        .foregroundColor(viewModel.selectedTimeRange == timeRange ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedTimeRange == timeRange ? AppStyle.Colors.surfaceTop : AppStyle.Colors.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppStyle.Colors.surfaceTop, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    /// Shows the appropriate chart view based on the current selection
    @ViewBuilder
    private var selectedChartView: some View {
        switch selectedChart {
        case .muscleGroup:
            MuscleGroupVolumeView(data: viewModel.muscleGroupVolumeData, viewModel: viewModel)
        //case .weeklyVolume:
            //WeeklyVolumeChartView(data: viewModel.weeklyVolumeData)
        case .oneRepMax:
            OneRepMaxListView(data: viewModel.oneRepMaxData)
        case .strengthTrends:
            StrengthTrendsChartView(data: viewModel.strengthTrendData)
        case .muscleGroupSetsOverTime:
            MuscleGroupSetsOverTimeView(data: viewModel.muscleGroupSetsOverTime)
        }
    }
    
    /// Top exercises section
    private var topExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Lifts")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
                .padding(.horizontal, 16)
            
            if viewModel.oneRepMaxData.isEmpty {
                emptyStateCard(message: "No exercise data available yet. Complete some workouts to see your strongest lifts.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.oneRepMaxData.prefix(5)) { item in
                            TopExerciseCard(data: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    /// Empty state view
    private func emptyStateCard(message: String) -> some View {
        Text(message)
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppStyle.Colors.surfaceTop)
            .cornerRadius(AppStyle.Layout.cardCornerRadius)
            .padding(.horizontal, 16)
    }
}

// MARK: - Chart Components

/// Weekly volume chart
struct WeeklyVolumeChartView: View {
    let data: [StatsViewModel.VolumeDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Training Volume")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if data.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Week", item.formattedDate),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(AppStyle.Colors.primary.gradient)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatLargeNumber(doubleValue))
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(height: 220)
    }
    
    private var emptyStateView: some View {
        Text("Complete workouts to see your weekly volume data.")
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", number / 1000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

/// Muscle group volume view
struct MuscleGroupVolumeView: View {
    let data: [StatsViewModel.MuscleGroupVolumeData]
    @ObservedObject var viewModel: StatsViewModel
    @State private var selectedMuscle: MuscleGroup? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Sets by Muscle Group")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if data.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 10) {
                    ForEach(data) { item in
                        MuscleGroupVolumeRow(data: item, timeSeriesData: viewModel.muscleGroupSetsOverTime[item.muscle] ?? [])
                            .onTapGesture {
                                self.selectedMuscle = item.muscle
                            }
                    }
                }
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
        .sheet(item: $selectedMuscle) { muscle in
            MuscleInfoSheet(muscle: muscle)
        }
    }
    
    private var emptyStateView: some View {
        Text("Complete workouts to see your training volume by muscle group.")
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
}

/// Line graph row for a single muscle group
struct MuscleGroupVolumeRow: View {
    let data: StatsViewModel.MuscleGroupVolumeData
    let timeSeriesData: [StatsViewModel.SetOverTimeDataPoint]
    
    var body: some View {
        VStack(spacing: 4) {
            // Muscle name and set count
            HStack {
                Text(data.muscle.displayName)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Set count
                Text("\(data.setCount) sets")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                // Info icon
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 2)
            
            // Line graph
            if timeSeriesData.isEmpty {
                // Show empty state if no time series data
                HStack {
                    Spacer()
                    Text("No history data")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                // Line chart using SwiftUI Chart
                Chart {
                    ForEach(timeSeriesData.sorted(by: { $0.date < $1.date })) { point in
                        LineMark(
                            x: .value("Week", point.date),
                            y: .value("Sets", point.sets)
                        )
                        .foregroundStyle(AppStyle.Colors.textPrimary)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Week", point.date),
                            y: .value("Sets", point.sets)
                        )
                        .foregroundStyle(AppStyle.Colors.textPrimary)
                        .symbolSize(5)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 40)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .background(AppStyle.Colors.surfaceTop)
        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
        .contentShape(Rectangle()) // Make entire row tappable
    }
}

/// One-rep max list view
struct OneRepMaxListView: View {
    let data: [StatsViewModel.OneRepMaxData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1 Rep Max")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if data.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Column headers
                        HStack {
                            Text("Exercise")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .frame(width: 120, alignment: .leading)
                            
                            Spacer()
                            
                            Text("Weight")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .frame(width: 60, alignment: .trailing)
                            
                            Text("Reps")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .frame(width: 40, alignment: .trailing)
                            
                            Text("Est. 1RM")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        
                        // List of 1RM data
                        ForEach(data) { item in
                            OneRepMaxRow(data: item)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
    
    private var emptyStateView: some View {
        Text("Complete workouts to see your estimated one-rep max data.")
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
}

/// One-rep max row
struct OneRepMaxRow: View {
    let data: StatsViewModel.OneRepMaxData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.exercise.movementType.displayName)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(data.formattedDate)
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(String(format: "%.1f", data.weight))
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
                .frame(width: 60, alignment: .trailing)
            
            Text("\(data.reps)")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
                .frame(width: 40, alignment: .trailing)
            
            Text(String(format: "%.1f", data.estimatedOneRM))
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.primary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppStyle.Colors.surfaceTop)
        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
    }
}

/// Strength trends chart view
struct StrengthTrendsChartView: View {
    let data: [StatsViewModel.StrengthTrendCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Trends Over Time")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if data.isEmpty || !data.contains(where: { $0.hasData }) {
                emptyStateView
            } else {
                chartView
                
                // Legend
                HStack(spacing: 16) {
                    ForEach(data.indices, id: \.self) { index in
                        HStack {
                            Rectangle()
                                .fill(lineColor(for: index))
                                .frame(width: 8, height: 8)
                            
                            Text(data[index].name)
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(data.indices, id: \.self) { categoryIndex in
                let category = data[categoryIndex]
                if category.hasData {
                    ForEach(category.dataPoints) { point in
                        LineMark(
                            x: .value("Month", point.formattedDate),
                            y: .value("Strength", point.value)
                        )
                        .foregroundStyle(lineColor(for: categoryIndex))
                        .symbol {
                            Circle()
                                .fill(lineColor(for: categoryIndex))
                                .frame(width: 8, height: 8)
                        }
                        .interpolationMethod(.catmullRom)
                    }
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatLargeNumber(doubleValue))
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(height: 220)
    }
    
    private var emptyStateView: some View {
        Text("Complete workouts over time to see your strength trends.")
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func lineColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink
        ]
        return colors[index % colors.count]
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", number / 1000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

/// Muscle group sets over time chart
struct MuscleGroupSetsOverTimeView: View {
    let data: [MuscleGroup: [StatsViewModel.SetOverTimeDataPoint]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets Over Time")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if data.isEmpty || !data.values.contains(where: { !$0.isEmpty }) {
                emptyStateView
            } else {
                // Show all muscles together in a list
                VStack(spacing: 16) {
                    // Filter to only show muscles with data
                    ForEach(MuscleGroup.allCases.filter { data[$0]?.isEmpty == false }.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { muscle in
                        muscleChartRow(muscle: muscle, muscleData: data[muscle] ?? [])
                    }
                }
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
    
    private var emptyStateView: some View {
        Text("Complete workouts over several weeks to see how your training volume changes over time.")
            .font(AppStyle.Typography.body())
            .foregroundColor(AppStyle.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func muscleChartRow(muscle: MuscleGroup, muscleData: [StatsViewModel.SetOverTimeDataPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Muscle header
            HStack {
                Text(muscle.displayName)
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                // Show current set count if available
                if let latestData = muscleData.sorted(by: { $0.date > $1.date }).first {
                    Text("\(latestData.sets) sets")
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
            
            // Mini chart
            Chart {
                ForEach(muscleData) { dataPoint in
                    LineMark(
                        x: .value("Week", dataPoint.date),
                        y: .value("Sets", dataPoint.sets)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(muscleColor(for: muscle))
                    .symbol {
                        Circle()
                            .fill(muscleColor(for: muscle))
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Add recommended range if available
                RuleMark(y: .value("Maintenance Min", muscle.trainingGuidelines.minMaintenanceSets))
                    .foregroundStyle(Color.yellow.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                RuleMark(y: .value("Maintenance Max", muscle.trainingGuidelines.maxMaintenanceSets))
                    .foregroundStyle(Color.yellow.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                RuleMark(y: .value("Hypertrophy Min", muscle.trainingGuidelines.minHypertrophySets))
                    .foregroundStyle(Color.green.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                RuleMark(y: .value("Hypertrophy Max", muscle.trainingGuidelines.maxHypertrophySets))
                    .foregroundStyle(Color.green.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel {
                        // No labels for compact view
                        EmptyView()
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel {
                        // No labels for compact view
                        EmptyView()
                    }
                }
            }
            .frame(height: 60)
            
            // Range indicator
            HStack {
                Text("\(muscle.trainingGuidelines.minMaintenanceSets) sets")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                Spacer()
                
                Text("\(muscle.trainingGuidelines.maxHypertrophySets) sets")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(AppStyle.Colors.surfaceTop)
        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
    }
    
    private func muscleColor(for muscle: MuscleGroup) -> Color {
        AppStyle.MuscleColors.color(for: muscle)
    }
}

/// Top exercise card
struct TopExerciseCard: View {
    let data: StatsViewModel.OneRepMaxData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.exercise.movementType.displayName)
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
                .lineLimit(1)
            
            HStack {
                Text(String(format: "%.1f", data.estimatedOneRM))
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.primary)
                
                Text("lbs")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            HStack {
                Text("\(data.reps) reps at")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                Text(String(format: "%.1f", data.weight))
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Text("lbs")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            MusclePill(muscle: data.exercise.primaryMuscles.first ?? .chest)
                .padding(.top, 4)
        }
        .padding(12)
        .frame(width: 180, height: 130)
        .background(AppStyle.Colors.surfaceTop)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
}

struct MuscleInfoSheet: View {
    let muscle: MuscleGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Muscle header
                    HStack {
                        Text(muscle.displayName)
                            .font(AppStyle.Typography.headline())
                            .foregroundColor(muscle.color)
                        
                        Spacer()
                        
                        // Pill showing total set range
                        Text("\(muscle.trainingGuidelines.minMaintenanceSets)–\(muscle.trainingGuidelines.maxHypertrophySets) sets/week")
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(muscle.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(muscle.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 8)
                    
                    // Volume Guidelines
                    VStack(alignment: .leading, spacing: 16) {
                        // Maintenance
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Maintenance Volume")
                                    .font(AppStyle.Typography.body())
                                    .foregroundColor(AppStyle.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(muscle.trainingGuidelines.minMaintenanceSets)–\(muscle.trainingGuidelines.maxMaintenanceSets) sets/week")
                                    .font(AppStyle.Typography.body())
                                    .foregroundColor(Color.yellow)
                            }
                            
                            Text("Sets needed to maintain current muscle mass")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Growth
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Growth Volume")
                                    .font(AppStyle.Typography.body())
                                    .foregroundColor(AppStyle.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(muscle.trainingGuidelines.minHypertrophySets)–\(muscle.trainingGuidelines.maxHypertrophySets) sets/week")
                                    .font(AppStyle.Typography.body())
                                    .foregroundColor(Color.green)
                            }
                            
                            Text("Optimal range for muscle hypertrophy")
                                .font(AppStyle.Typography.caption())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Training Guidelines")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            
                            Text(muscle.trainingGuidelines.description)
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(AppStyle.Colors.surfaceTop)
                        .cornerRadius(8)
                        
                        // Source link
                        Link(destination: muscle.trainingGuidelines.source) {
                            HStack {
                                Text("Research Source")
                                    .font(AppStyle.Typography.body())
                                    .foregroundColor(AppStyle.Colors.primary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(AppStyle.Colors.primary)
                            }
                            .padding(12)
                            .background(AppStyle.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    return StatsView(appState: appState)
        .environmentObject(appState)
        .preferredColorScheme(.dark)
}
