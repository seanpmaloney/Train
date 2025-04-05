import SwiftUI

struct RestTimer: View {
    @Binding var isExpanded: Bool
    @AppStorage("timerIsRunning") private var isRunning = false
    @AppStorage("timerStartTime") private var startTimeInterval: TimeInterval = 0
    @AppStorage("timerElapsedTime") private var elapsedTime: TimeInterval = 0
    
    @State private var currentTime: TimeInterval = 0
    
    // Timer publisher
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer display
            Text(timeString(from: currentTime))
                .font(.system(size: 48, weight: .medium, design: .monospaced))
                .foregroundColor(AppStyle.Colors.textPrimary)
                .padding(.top, 16)
            
            // Controls
            HStack(spacing: 24) {
                // Start/Pause button
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(isRunning ? AppStyle.Colors.secondary : AppStyle.Colors.success)
                        .frame(width: 60, height: 60)
                }
                
                // Stop button
                Button(action: stopTimer) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppStyle.Colors.danger)
                        .frame(width: 60, height: 60)
                }
            }
            .padding(.bottom, 16)
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppStyle.Colors.surface)
                .shadow(color: AppStyle.Colors.background.opacity(0.2), radius: 10)
        )
        .onAppear {
            if isRunning {
                currentTime = elapsedTime + Date().timeIntervalSince1970 - startTimeInterval
            } else {
                currentTime = elapsedTime
            }
        }
        .onReceive(timer) { _ in
            if isRunning {
                currentTime = elapsedTime + Date().timeIntervalSince1970 - startTimeInterval
            }
        }
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            startTimeInterval = Date().timeIntervalSince1970
        } else {
            elapsedTime = currentTime
        }
    }
    
    private func stopTimer() {
        isRunning = false
        currentTime = 0
        elapsedTime = 0
        startTimeInterval = 0
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
} 
