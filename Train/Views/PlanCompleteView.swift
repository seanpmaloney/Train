import SwiftUI

struct PlanCompleteView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let stats: PlanCompletionStats
    
    @State private var showingDatePicker = false
    @State private var selectedStartDate = Date()
    @State private var pendingAction: PlanCompleteAction?
    @State private var showingDeloadChoice = false
    @State private var currentStatIndex = 0
    @State private var showButtons = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppStyle.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header section
                        headerSection
                        
                        // Stats section (includes buttons as final page)
                        statsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDeloadChoice) {
            deloadChoiceSheet
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Celebration icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundColor(AppStyle.Colors.secondary)
                .padding(.bottom, 4)
            
            // Main header
            Text("Congrats on finishing your plan!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppStyle.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Subheader
            Text("We tallied up a few stats for you to brag to your friends.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 20) {
            // Stats carousel with buttons as final page
            TabView(selection: $currentStatIndex) {
                // Workouts completed
                AnimatedStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Workouts Completed",
                    value: "\(stats.workoutsCompleted)",
                    subtitle: stats.workoutsCompleted == 1 ? "workout crushed" : "workouts crushed",
                    color: AppStyle.Colors.primary
                )
                .tag(0)
                
                // Total pounds lifted
                AnimatedStatCard(
                    icon: "scalemass.fill",
                    title: "Total Pounds Lifted",
                    value: formatWeight(stats.totalPoundsLifted),
                    subtitle: "pounds moved",
                    color: AppStyle.Colors.danger
                )
                .tag(1)
                
                // Biggest improvement (if any)
                if let improvement = stats.biggestImprovement {
                    let percentIncrease = ((improvement.endingWeight - improvement.startingWeight) / improvement.startingWeight) * 100
                    AnimatedStatCard(
                        icon: "arrow.up.circle.fill",
                        title: "Biggest PR",
                        value: improvement.movement.name,
                        subtitle: "+\(Int(percentIncrease))% (\(improvement.formattedRange))",
                        color: .green
                    )
                    .tag(2)
                    
                    // Action buttons as final page
                    actionButtonsCard
                        .tag(3)
                } else {
                    // If no improvement, buttons come after pounds lifted
                    actionButtonsCard
                        .tag(2)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            .onChange(of: currentStatIndex) { newIndex in
                let totalStats = stats.biggestImprovement != nil ? 3 : 2
                showButtons = newIndex >= totalStats
            }
            
            // Custom page indicator
            HStack(spacing: 8) {
                let totalPages = stats.biggestImprovement != nil ? 4 : 3
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentStatIndex ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentStatIndex)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Action Buttons Card
    
    private var actionButtonsCard: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppStyle.Colors.primary.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(AppStyle.Colors.primary)
                }
                
                Text("What's next?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Primary button - Continue this plan
                Button {
                    HapticService.shared.impact(style: .medium)
                    showingDeloadChoice = true
                } label: {
                    Text("Continue this plan")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(16)
                }
                
                // Secondary button - Choose new plan
                NavigationLink(destination: PlanTemplatePickerView()) {
                    Text("Choose a new plan")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppStyle.Colors.surface.opacity(0.5))
                        .cornerRadius(16)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    appState.dismissPlanComplete(action: .chooseNewPlan)
                    dismiss()
                })
                
                // Ghost button - Maybe later
                Button {
                    appState.dismissPlanComplete(action: .maybeLater)
                    dismiss()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppStyle.Colors.background)
        )
    }
    
    // MARK: - Legacy Action Buttons Section (unused)
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary button - Continue this plan
            Button {
                HapticService.shared.impact(style: .medium)
                showingDeloadChoice = true
            } label: {
                Text("Continue this plan")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppStyle.Colors.primary)
                    .cornerRadius(16)
            }
            
            // Secondary button - Choose new plan
            NavigationLink(destination: PlanTemplatePickerView()) {
                Text("Choose a new plan")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppStyle.Colors.surface)
                    .cornerRadius(16)
            }
            .simultaneousGesture(TapGesture().onEnded {
                appState.dismissPlanComplete(action: .chooseNewPlan)
                dismiss()
            })
            
            // Ghost button - Maybe later
            Button {
                appState.dismissPlanComplete(action: .maybeLater)
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Deload Choice Sheet
    
    private var deloadChoiceSheet: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Start with a deload week?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Text("A deload week uses lighter weights to help you recover before starting the new cycle.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    // Yes, start with deload
                    Button {
                        pendingAction = .continueWithDeload(startDate: Date())
                        selectedStartDate = Date()
                        showingDeloadChoice = false
                        showingDatePicker = true
                    } label: {
                        Text("Yes, start with deload")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppStyle.Colors.primary)
                            .cornerRadius(16)
                    }
                    
                    // No, jump right in
                    Button {
                        pendingAction = .continuePlan(startDate: Date())
                        selectedStartDate = Date()
                        showingDeloadChoice = false
                        showingDatePicker = true
                    } label: {
                        Text("No, jump right in")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppStyle.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppStyle.Colors.surface)
                            .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(AppStyle.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDeloadChoice = false
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Date Picker Sheet
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("When do you want to start?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .padding(.top, 32)
                
                DatePicker(
                    "Start Date",
                    selection: $selectedStartDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
                
                Button {
                    if let action = pendingAction {
                        let finalAction: PlanCompleteAction
                        switch action {
                        case .continuePlan:
                            finalAction = .continuePlan(startDate: selectedStartDate)
                        case .continueWithDeload:
                            finalAction = .continueWithDeload(startDate: selectedStartDate)
                        default:
                            finalAction = action
                        }
                        
                        // Add haptic feedback for success
                        HapticService.shared.success()
                        
                        appState.dismissPlanComplete(action: finalAction)
                        showingDatePicker = false
                        dismiss()
                    }
                } label: {
                    Text("Start Plan")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(AppStyle.Colors.background.ignoresSafeArea())
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDatePicker = false
                        pendingAction = nil
                    }
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Helper Methods
    
    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.1fK", weight / 1000)
        } else {
            return String(format: "%.0f", weight)
        }
    }
}

// MARK: - Animated Stat Card Component

struct AnimatedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    @State private var isAnimated = false
    @State private var numberValue: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Icon with animated background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimated)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(color)
                    .scaleEffect(isAnimated ? 1.0 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: isAnimated)
            }
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.6), value: isAnimated)
                
                // Animated value
                Text(value)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: isAnimated)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(1.0), value: isAnimated)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppStyle.Colors.background)
        )
        .onAppear {
            withAnimation {
                isAnimated = true
            }
        }
        .onDisappear {
            isAnimated = false
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleStats = PlanCompletionStats(
        workoutsCompleted: 12,
        totalPoundsLifted: 15420.0,
        biggestImprovement: PlanCompletionStats.MovementImprovement(
            movement: MovementEntity(
                type: .barbellBackSquat,
                primaryMuscles: [.quads],
                equipment: .barbell
            ),
            startingWeight: 185.0,
            endingWeight: 225.0,
            improvement: 40.0
        )
    )
    
    return PlanCompleteView(stats: sampleStats)
        .environmentObject(AppState())
}
