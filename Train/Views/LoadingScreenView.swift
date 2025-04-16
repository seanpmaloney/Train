import SwiftUI

struct LoadingView: View {
    @State private var glowRadius: CGFloat = 50
    @State private var glowOpacity: CGFloat = 0.5
    @State private var rotationAngle: CGFloat = 0
    
    private let glowColor = AppStyle.Colors.primary
    private let animationDuration: Double = 2.0
    
    var body: some View {
        ZStack {
            // Background
            AppStyle.Colors.background
                .ignoresSafeArea()
            
            // Main loading circle
            Circle()
                .stroke(lineWidth: 0)
                .frame(width: 60, height: 60)
                .foregroundColor(AppStyle.Colors.primary)
                .overlay(
                    // Glow effect
                    Circle()
                        .stroke(glowColor, lineWidth: 24)
                        .blur(radius: glowRadius)
                        .opacity(glowOpacity)
                )
                .overlay(
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(AppStyle.Colors.primary, lineWidth: 12)
                        .rotationEffect(.degrees(Double(rotationAngle)))
                )

            
            // Loading text
            VStack {
                Spacer()
                Text("Loading")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            withAnimation(Animation.easeInOut(duration: animationDuration/2).repeatForever(autoreverses: true)) {
                glowRadius = 30
                glowOpacity = 0.8
            }
        }
    }
}

#Preview {
    LoadingView()
        .preferredColorScheme(.dark)
}

