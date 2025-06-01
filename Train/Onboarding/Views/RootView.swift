import SwiftUI

/// Root view that displays either the main app or onboarding flow
struct RootView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if isOnboardingCompleted {
            ContentView()
        } else {
            OnboardingContainerView()
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState.shared)
    }
}
#endif
