import SwiftUI

/// View for tracking body soreness by allowing users to tap on different muscle groups
struct SorenessCheckView: View {
    // MARK: - Properties
    
    @State private var showingFrontView = true
    @State private var soreness: [MuscleGroup: SorenessLevel] = [:]
    
    enum SorenessLevel: Int {
        case none = 0
        case mild = 1
        case severe = 2
        
        var color: Color {
            switch self {
            case .none: return Color.gray.opacity(0.3)
            case .mild: return AppStyle.Colors.secondary // Yellow
            case .severe: return AppStyle.Colors.danger  // Red
            }
        }
        
        mutating func cycle() {
            let nextRawValue = (self.rawValue + 1) % 3
            self = SorenessLevel(rawValue: nextRawValue)!
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Instructions
                    VStack(spacing: 8) {
                        Text("How sore are you today? Tap where you're feeling sore")
                            .font(AppStyle.Typography.body())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Front/Back selector
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                showingFrontView = true
                            }
                        }) {
                            Text("Front")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(showingFrontView ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(showingFrontView ? AppStyle.Colors.surfaceTop : AppStyle.Colors.surface)
                                )
                        }
                        
                        Button(action: {
                            withAnimation {
                                showingFrontView = false
                            }
                        }) {
                            Text("Back")
                                .font(AppStyle.Typography.body())
                                .foregroundColor(!showingFrontView ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(!showingFrontView ? AppStyle.Colors.surfaceTop : AppStyle.Colors.surface)
                                )
                        }
                    }
                    .background(AppStyle.Colors.surface)
                    .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                    .padding(.horizontal)
                    

                        RoundedRectangle(cornerRadius: AppStyle.Layout.cardCornerRadius)
                            .fill(AppStyle.Colors.surface)
                            .padding(.horizontal)
                    
                    // Legend
                    HStack(spacing: 16) {
                        LegendItem(color: SorenessLevel.none.color, text: "Not Sore")
                        LegendItem(color: SorenessLevel.mild.color, text: "Mild Soreness")
                        LegendItem(color: SorenessLevel.severe.color, text: "Severe Soreness")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                            .fill(AppStyle.Colors.surface)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    struct LegendItem: View {
        let color: Color
        let text: String
        
        var body: some View {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                
                Text(text)
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Front Body View

struct BodyFrontView: View {
    @Binding var soreness: [MuscleGroup: SorenessCheckView.SorenessLevel]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Color.black.opacity(0.2)
                    .frame(width: width * 0.8, height: height * 0.9)
                    .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                    .position(x: width/2, y: height/2)
                
                // Muscle group labels - front view
                // Upper body
                Group {
                    // Shoulders
                    MuscleLabel(
                        name: "Shoulders",
                        muscleGroup: .shoulders,
                        sorenessLevel: getSorenessLevel(for: .shoulders),
                        action: { toggleSoreness(for: .shoulders) }
                    )
                    .position(x: width * 0.5, y: height * 0.18)
                    
                    // Chest
                    MuscleLabel(
                        name: "Chest",
                        muscleGroup: .chest,
                        sorenessLevel: getSorenessLevel(for: .chest),
                        action: { toggleSoreness(for: .chest) }
                    )
                    .position(x: width * 0.5, y: height * 0.25)
                    
                    // Biceps
                    MuscleLabel(
                        name: "Biceps",
                        muscleGroup: .biceps,
                        sorenessLevel: getSorenessLevel(for: .biceps),
                        action: { toggleSoreness(for: .biceps) }
                    )
                    .position(x: width * 0.5, y: height * 0.32)
                    
                    // Forearms
                    MuscleLabel(
                        name: "Forearms",
                        muscleGroup: .forearms,
                        sorenessLevel: getSorenessLevel(for: .forearms),
                        action: { toggleSoreness(for: .forearms) }
                    )
                    .position(x: width * 0.5, y: height * 0.39)
                }
                
                // Mid body
                Group {
                    // Abs
                    MuscleLabel(
                        name: "Abs",
                        muscleGroup: .abs,
                        sorenessLevel: getSorenessLevel(for: .abs),
                        action: { toggleSoreness(for: .abs) }
                    )
                    .position(x: width * 0.5, y: height * 0.48)
                    
                    // Obliques
                    MuscleLabel(
                        name: "Obliques",
                        muscleGroup: .obliques,
                        sorenessLevel: getSorenessLevel(for: .obliques),
                        action: { toggleSoreness(for: .obliques) }
                    )
                    .position(x: width * 0.5, y: height * 0.55)
                }
                
                // Lower body
                Group {
                    // Quads
                    MuscleLabel(
                        name: "Quads",
                        muscleGroup: .quads,
                        sorenessLevel: getSorenessLevel(for: .quads),
                        action: { toggleSoreness(for: .quads) }
                    )
                    .position(x: width * 0.5, y: height * 0.65)
                    
                    // Calves
                    MuscleLabel(
                        name: "Calves",
                        muscleGroup: .calves,
                        sorenessLevel: getSorenessLevel(for: .calves),
                        action: { toggleSoreness(for: .calves) }
                    )
                    .position(x: width * 0.5, y: height * 0.75)
                }
            }
        }
    }
    
    // Helper function to get soreness level for muscle group
    private func getSorenessLevel(for muscleGroup: MuscleGroup) -> SorenessCheckView.SorenessLevel {
        return soreness[muscleGroup] ?? .none
    }
    
    // Helper function to toggle soreness for muscle group
    private func toggleSoreness(for muscleGroup: MuscleGroup) {
        var currentLevel = getSorenessLevel(for: muscleGroup)
        currentLevel.cycle()
        soreness[muscleGroup] = currentLevel
    }
}

// MARK: - Back Body View

struct BodyBackView: View {
    @Binding var soreness: [MuscleGroup: SorenessCheckView.SorenessLevel]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Color.black.opacity(0.2)
                    .frame(width: width * 0.8, height: height * 0.9)
                    .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                    .position(x: width/2, y: height/2)
                
                // Muscle group labels - back view
                // Upper body
                Group {
                    // Traps
                    MuscleLabel(
                        name: "Traps",
                        muscleGroup: .traps,
                        sorenessLevel: getSorenessLevel(for: .traps),
                        action: { toggleSoreness(for: .traps) }
                    )
                    .position(x: width * 0.5, y: height * 0.15)
                    
                    // Shoulders
                    MuscleLabel(
                        name: "Shoulders",
                        muscleGroup: .shoulders,
                        sorenessLevel: getSorenessLevel(for: .shoulders),
                        action: { toggleSoreness(for: .shoulders) }
                    )
                    .position(x: width * 0.5, y: height * 0.22)
                    
                    // Back
                    MuscleLabel(
                        name: "Back",
                        muscleGroup: .back,
                        sorenessLevel: getSorenessLevel(for: .back),
                        action: { toggleSoreness(for: .back) }
                    )
                    .position(x: width * 0.5, y: height * 0.3)
                    
                    // Triceps
                    MuscleLabel(
                        name: "Triceps",
                        muscleGroup: .triceps,
                        sorenessLevel: getSorenessLevel(for: .triceps),
                        action: { toggleSoreness(for: .triceps) }
                    )
                    .position(x: width * 0.5, y: height * 0.38)
                }
                
                // Mid body
                Group {
                    // Lower Back
                    MuscleLabel(
                        name: "Lower Back",
                        muscleGroup: .lowerBack,
                        sorenessLevel: getSorenessLevel(for: .lowerBack),
                        action: { toggleSoreness(for: .lowerBack) }
                    )
                    .position(x: width * 0.5, y: height * 0.46)
                    
                    // Glutes
                    MuscleLabel(
                        name: "Glutes",
                        muscleGroup: .glutes,
                        sorenessLevel: getSorenessLevel(for: .glutes),
                        action: { toggleSoreness(for: .glutes) }
                    )
                    .position(x: width * 0.5, y: height * 0.54)
                }
                
                // Lower body
                Group {
                    // Hamstrings
                    MuscleLabel(
                        name: "Hamstrings",
                        muscleGroup: .hamstrings,
                        sorenessLevel: getSorenessLevel(for: .hamstrings),
                        action: { toggleSoreness(for: .hamstrings) }
                    )
                    .position(x: width * 0.5, y: height * 0.65)
                    
                    // Calves
                    MuscleLabel(
                        name: "Calves",
                        muscleGroup: .calves,
                        sorenessLevel: getSorenessLevel(for: .calves),
                        action: { toggleSoreness(for: .calves) }
                    )
                    .position(x: width * 0.5, y: height * 0.75)
                }
            }
        }
    }
    
    // Helper function to get soreness level for muscle group
    private func getSorenessLevel(for muscleGroup: MuscleGroup) -> SorenessCheckView.SorenessLevel {
        return soreness[muscleGroup] ?? .none
    }
    
    // Helper function to toggle soreness for muscle group
    private func toggleSoreness(for muscleGroup: MuscleGroup) {
        var currentLevel = getSorenessLevel(for: muscleGroup)
        currentLevel.cycle()
        soreness[muscleGroup] = currentLevel
    }
}

// MARK: - Helper Views

struct MuscleLabel: View {
    let name: String
    let muscleGroup: MuscleGroup
    let sorenessLevel: SorenessCheckView.SorenessLevel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(AppStyle.Typography.body())
                .foregroundColor(
                    sorenessLevel == .none ?
                        Color.white.opacity(0.7) :
                        Color.white
                )
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(sorenessLevel.color)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    SorenessCheckView()
        .preferredColorScheme(.dark)
}
