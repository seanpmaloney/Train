import SwiftUI
import Charts

/// A view displaying weekly sets per muscle group
struct WeeklyMuscleGroupSetsView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: StatsViewModel
    @State private var scrollPosition: CGFloat = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Weekly Sets Per Muscle Group")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            if allMusclesEmpty() {
                emptyStateView
            } else {
                chartListView
            }
        }
        .padding(16)
        .background(AppStyle.Colors.surface)
        .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
    
    // MARK: - Subviews
    
    /// View when no data is available
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            Text("Complete workouts to see your\nweekly sets per muscle group")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    /// List of charts for all muscle groups
    private var chartListView: some View {
        VStack(spacing: 32) {
            // Get non-empty muscle groups and sort by total sets
            let sortedMuscleGroups = sortMuscleGroupsByTotalSets()
            
            ForEach(sortedMuscleGroups) { muscle in
                MuscleGroupWeeklyChart(
                    muscle: muscle,
                    data: viewModel.weeklyMuscleGroupSets[muscle] ?? [],
                    expandedMuscleGroup: $viewModel.expandedMuscleGroup
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if all muscle groups have no data
    private func allMusclesEmpty() -> Bool {
        return MuscleGroup.allCases.allSatisfy { muscle in
            let data = viewModel.weeklyMuscleGroupSets[muscle] ?? []
            return data.allSatisfy { $0.sets == 0 }
        }
    }
    
    /// Sorts muscle groups by total sets (non-zero first, then in descending order)
    private func sortMuscleGroupsByTotalSets() -> [MuscleGroup] {
        return MuscleGroup.allCases.sorted { muscle1, muscle2 in
            let totalSets1 = (viewModel.weeklyMuscleGroupSets[muscle1] ?? []).reduce(0.0) { $0 + $1.sets }
            let totalSets2 = (viewModel.weeklyMuscleGroupSets[muscle2] ?? []).reduce(0.0) { $0 + $1.sets }
            
            // If one is zero and the other isn't, non-zero comes first
            if totalSets1 == 0 && totalSets2 > 0 { return false }
            if totalSets2 == 0 && totalSets1 > 0 { return true }
            
            // Otherwise sort by total sets
            return totalSets1 > totalSets2
        }
    }
}

/// A horizontal bar chart for a single muscle group's weekly sets
struct MuscleGroupWeeklyChart: View {
    // MARK: - Properties
    
    let muscle: MuscleGroup
    let data: [StatsViewModel.WeeklySetDataPoint]
    @Binding var expandedMuscleGroup: MuscleGroup?
    
    // Computed
    private var isExpanded: Bool { expandedMuscleGroup == muscle }
    private var totalSets: Double { data.reduce(0) { $0 + $1.sets } }
    private var weeklyAverage: Double { totalSets / Double(max(1, data.count)) }
    private var maxSets: Double { data.map { $0.sets }.max() ?? 0 }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(muscle.displayName)
                    .font(AppStyle.Typography.body())
                    .fontWeight(.semibold)
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(totalSets)) sets")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            
            // Chart
            chartView
                .frame(height: isExpanded ? 140 : 80)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expandedMuscleGroup = isExpanded ? nil : muscle
                    }
                }
            
            // Optional expanded details
            if isExpanded {
                expandedDetails
            }
        }
    }
    
    // MARK: - Subviews
    
    /// The bar chart
    private var chartView: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Week", point.formattedDate),
                    y: .value("Sets", point.sets)
                )
                .cornerRadius(4)
                .foregroundStyle(
                    muscle.isOptimalSetsPerWeek(Double(point.sets)) ?
                    AppStyle.MuscleColors.color(for: muscle) :
                    AppStyle.MuscleColors.color(for: muscle).opacity(0.5)
                )
            }
        }
        .chartYScale(domain: 0...(maxSets * 1.2))
        .chartYAxis {
            AxisMarks { value in
                if let sets = value.as(Double.self), sets.truncatingRemainder(dividingBy: 5) == 0 {
                    AxisValueLabel {
                        Text("\(Int(sets))")
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                    AxisGridLine()
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel {
                    // Only show labels in expanded view
                    if isExpanded {
                        Text("")
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppStyle.Colors.surfaceTop.opacity(0.3))
        )
    }
    
    /// Expanded details view
    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Weekly average
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Average")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    
                    Text("\(Int(weeklyAverage.rounded())) sets")
                        .font(AppStyle.Typography.body())
                        .fontWeight(.medium)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                }
                
                Spacer()
                
                // Training recommendations
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimal Range")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    
                    Text("\(muscle.trainingGuidelines.minHypertrophySets)–\(muscle.trainingGuidelines.maxHypertrophySets) sets/week")
                        .font(AppStyle.Typography.body())
                        .fontWeight(.medium)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                }
            }
            
            // Fitness gauge
            fitnessGauge
            
            // Date labels for the chart
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(data) { point in
                        Text(point.formattedDate)
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    /// Fitness gauge indicating training effectiveness
    private var fitnessGauge: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { section in
                Rectangle()
                    .fill(
                        section == 0 ? Color.red.opacity(0.6) :
                        section == 1 ? Color.green.opacity(0.7) :
                        Color.red.opacity(0.6)
                    )
                    .frame(height: 6)
            }
            .overlay(
                GeometryReader { geo in
                    // Marker position
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .shadow(radius: 1)
                        .position(
                            x: calculateMarkerPosition(
                                totalWidth: geo.size.width,
                                weeklyAverage: weeklyAverage,
                                minSets: Double(muscle.trainingGuidelines.minMaintenanceSets),
                                optimalMinSets: Double(muscle.trainingGuidelines.minHypertrophySets),
                                optimalMaxSets: Double(muscle.trainingGuidelines.maxHypertrophySets),
                                maxSets: Double(muscle.trainingGuidelines.maxHypertrophySets * 2)
                            ),
                            y: geo.size.height / 2
                        )
                }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .frame(height: 6)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate position for the gauge marker
    private func calculateMarkerPosition(
        totalWidth: CGFloat, 
        weeklyAverage: Double,
        minSets: Double, 
        optimalMinSets: Double, 
        optimalMaxSets: Double, 
        maxSets: Double
    ) -> CGFloat {
        // Define ranges
        let totalRange = maxSets - 0
        let leftSectionEnd = optimalMinSets / totalRange
        let rightSectionStart = optimalMaxSets / totalRange
        
        // Calculate position percentage
        let percentage = min(1.0, max(0.0, weeklyAverage / totalRange))
        
        return totalWidth * CGFloat(percentage)
    }
}

extension MuscleGroup {
    /// Checks if the given set count is within the optimal weekly range
    func isOptimalSetsPerWeek(_ sets: Double) -> Bool {
        return sets >= Double(trainingGuidelines.minHypertrophySets) && 
               sets <= Double(trainingGuidelines.maxHypertrophySets)
    }
}

#Preview {
    let model = StatsViewModel(appState: AppState())
    return WeeklyMuscleGroupSetsView(viewModel: model)
        .preferredColorScheme(.dark)
}
