import SwiftUI

/// Root view that displays either the main app or onboarding flow
struct RootView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userSessionManager: UserSessionManager
    
    var body: some View {
        if isOnboardingCompleted {
            ContentView()
                .environmentObject(userSessionManager)
        } else {
            OnboardingContainerView(appState: appState, userSessionManager: userSessionManager)
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        RootView()
            .environmentObject(appState)
            .environmentObject(userSessionManager)
    }
}
#endif
