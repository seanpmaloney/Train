import SwiftUI

struct LoadingView: View {
    @State private var glowRadius: CGFloat = 20
    @State private var glowOpacity: CGFloat = 0.5
    @State private var rotationAngle: CGFloat = 0
    
    private let glowColor = Color.blue.opacity(0.6)
    private let animationDuration: Double = 2.0
    
    var body: some View {
        ZStack {
            // Background
            AppStyle.Colors.background
                .ignoresSafeArea()
            
            // Main loading circle
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 60, height: 60)
                .foregroundColor(AppStyle.Colors.primary)
                .overlay(
                    // Glow effect
                    Circle()
                        .stroke(glowColor, lineWidth: 2)
                        .blur(radius: glowRadius)
                        .opacity(glowOpacity)
                )
                .overlay(
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(AppStyle.Colors.primary, lineWidth: 2)
                        .rotationEffect(.degrees(Double(rotationAngle)))
                )
                .overlay(
                    // Inner dot
                    Circle()
                        .fill(AppStyle.Colors.primary)
                        .frame(width: 6, height: 6)
                        .offset(y: -30)
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
