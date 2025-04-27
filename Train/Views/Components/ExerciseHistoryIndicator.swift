import SwiftUI

/// A minimal exercise history indicator inspired by Notion/Headspace design
struct ExerciseHistoryIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let onNavigate: (Int) -> Void
    
    @State private var showControls = false
    @State private var controlsTimer: Timer?
    
    var body: some View {
        HStack(spacing: 4) {
            if showControls && currentIndex > 0 {
                Button(action: {
                    onNavigate(currentIndex - 1)
                    resetControlsTimer()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                .transition(.opacity)
            }
            
            Text("• \(currentIndex + 1)/\(totalCount) •")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(AppStyle.Colors.textSecondary)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                    resetControlsTimer()
                }
            
            if showControls && currentIndex < totalCount - 1 {
                Button(action: {
                    onNavigate(currentIndex + 1)
                    resetControlsTimer()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppStyle.Colors.textSecondary)
                }
                .transition(.opacity)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppStyle.Colors.surface.opacity(showControls ? 0.5 : 0.0))
        )
        .animation(.easeInOut(duration: 0.2), value: showControls)
    }
    
    private func resetControlsTimer() {
        // Cancel existing timer
        controlsTimer?.invalidate()
        
        // Create new timer to hide controls after delay
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            // Dispatch UI updates to the main actor
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showControls = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExerciseHistoryIndicator(
            currentIndex: 0,
            totalCount: 4,
            onNavigate: { _ in }
        )
        
        ExerciseHistoryIndicator(
            currentIndex: 2,
            totalCount: 4,
            onNavigate: { _ in }
        )
    }
    .padding()
    .background(AppStyle.Colors.background)
    .preferredColorScheme(.dark)
}
