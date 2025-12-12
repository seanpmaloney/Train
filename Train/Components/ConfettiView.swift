import SwiftUI

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size.width, height: piece.size.height)
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
                    .opacity(piece.opacity)
                    .animation(.easeOut(duration: piece.duration), value: piece.position)
                    .animation(.linear(duration: piece.duration), value: piece.opacity)
            }
        }
        .onAppear {
            startConfetti()
        }
        .task {
            await runConfettiAnimation()
        }
        .task {
            // Stop confetti after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await fadeOutConfetti()
        }
    }
    
    private func startConfetti() {
        // Create initial burst
        createConfettiBurst()
        isAnimating = true
    }
    
    private func runConfettiAnimation() async {
        while isAnimating {
            // Add new confetti pieces
            if confettiPieces.count < 150 {
                createConfettiPieces(count: 3)
            }
            
            // Remove old pieces
            confettiPieces.removeAll { piece in
                piece.position.y > UIScreen.main.bounds.height + 50
            }
            
            // Wait before next iteration
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func stopConfetti() {
        isAnimating = false
        confettiPieces.removeAll()
    }
    
    private func createConfettiBurst() {
        createConfettiPieces(count: 50)
    }
    
    private func createConfettiPieces(count: Int) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<count {
            let piece = ConfettiPiece(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: -20
                ),
                color: colors.randomElement() ?? .blue,
                size: CGSize(
                    width: CGFloat.random(in: 4...12),
                    height: CGFloat.random(in: 4...12)
                ),
                rotation: Double.random(in: 0...360),
                duration: Double.random(in: 2.0...4.0),
                opacity: 1.0
            )
            
            confettiPieces.append(piece)
            
            // Animate the piece falling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position = CGPoint(
                        x: piece.position.x + CGFloat.random(in: -100...100),
                        y: screenHeight + 50
                    )
                    confettiPieces[index].rotation += Double.random(in: 180...720)
                }
            }
        }
    }
    
    private func fadeOutConfetti() async {
        isAnimating = false
        
        withAnimation(.easeOut(duration: 1.0)) {
            for index in confettiPieces.indices {
                confettiPieces[index].opacity = 0.0
            }
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        confettiPieces.removeAll()
    }
}

struct ConfettiPiece {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGSize
    var rotation: Double
    let duration: Double
    var opacity: Double
}

// MARK: - Confetti Modifier

extension View {
    func confetti(isActive: Bool) -> some View {
        self.overlay(
            Group {
                if isActive {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
        }
    }
    .confetti(isActive: true)
}
