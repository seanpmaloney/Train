import SwiftUI

struct PlanSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: PlanSummaryViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(weeks: [[PlanEditorViewModel.DayPlan]], template: PlanTemplate?) {
        _viewModel = StateObject(wrappedValue: PlanSummaryViewModel(weeks: weeks, template: template))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppStyle.Layout.standardSpacing) {
                    // Plan Name
                    TextField("Plan Name", text: $viewModel.planName)
                        .font(AppStyle.Typography.title())
                        .cardStyle()
                    
                    // Start Date
                    DatePicker(
                        "Start Date",
                        selection: $viewModel.startDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .cardStyle()
                    
                    // Summary Metrics
                    summaryMetrics
                    
                    // Start Button
                    Button {
                        let plan = viewModel.createPlan()
                        appState.setCurrentPlan(plan)
                        // Pop back to root view
                        presentationMode.wrappedValue.dismiss()
                        dismiss()
                    } label: {
                        Text("Start Plan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButton())
                }
                .padding()
            }
            .navigationTitle("Plan Summary")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppStyle.Colors.background)
        }
    }
    
    private var summaryMetrics: some View {
        VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
            Text("Summary")
                .font(AppStyle.Typography.headline())
                .foregroundColor(AppStyle.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppStyle.Layout.standardSpacing) {
                HStack {
                    metricView(title: "Total Weeks", value: "\(viewModel.totalWeeks)")
                    Spacer()
                    metricView(title: "Days/Week", value: "\(viewModel.daysPerWeek)")
                }
                
                if !viewModel.topMuscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: AppStyle.Layout.compactSpacing) {
                        Text("Primary Focus")
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.topMuscleGroups, id: \.self) { muscle in
                                Text(muscle.rawValue)
                                    .font(AppStyle.Typography.caption())
                                    .foregroundColor(AppStyle.Colors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(AppStyle.Colors.primary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding()
            .cardStyle()
        }
    }
    
    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppStyle.Typography.caption())
                .foregroundColor(AppStyle.Colors.textSecondary)
            Text(value)
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textPrimary)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? 0,
            height: rows.last?.maxY ?? 0
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for subviewData in row.subviews {
                subviewData.subview.place(
                    at: CGPoint(
                        x: bounds.minX + row.minX + subviewData.origin.x,
                        y: bounds.minY + row.minY
                    ),
                    proposal: .unspecified
                )
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(minY: 0)
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            maxHeight = max(maxHeight, size.height)
            
            if currentRow.width + size.width + spacing > (proposal.width ?? 0) {
                currentRow.maxY = currentRow.minY + maxHeight
                rows.append(currentRow)
                currentRow = Row(minY: currentRow.maxY + spacing)
                maxHeight = 0
            }
            
            let origin = CGPoint(x: currentRow.width, y: 0)
            currentRow.width += size.width + spacing
            currentRow.subviews.append(SubviewData(subview: subview, size: size, origin: origin))
        }
        
        if !currentRow.subviews.isEmpty {
            currentRow.maxY = currentRow.minY + maxHeight
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var minY: CGFloat
        var maxY: CGFloat = 0
        var width: CGFloat = 0
        var minX: CGFloat = 0
        var subviews: [SubviewData] = []
    }
    
    private struct SubviewData {
        let subview: LayoutSubview
        let size: CGSize
        let origin: CGPoint
    }
}

#Preview {
    NavigationStack {
        PlanSummaryView(
            weeks: [[
                PlanEditorViewModel.DayPlan(label: "Monday", movements: []),
                PlanEditorViewModel.DayPlan(label: "Wednesday", movements: []),
                PlanEditorViewModel.DayPlan(label: "Friday", movements: [])
            ]],
            template: nil
        )
        .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
