import Foundation
import AuthenticationServices
import SwiftUI

/// A reusable provider that conforms to ASAuthorizationControllerPresentationContextProviding
/// to properly present Apple Sign In sheets in SwiftUI
class AppleAuthorizationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding, ObservableObject {
    
    /// Required by ASAuthorizationControllerPresentationContextProviding
    /// Returns the window to present the Apple Sign In dialog
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Find the active window scene for presenting the Apple authentication UI
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            // Fallback to the key window if no scene is available (unlikely)
            return UIApplication.shared.windows.first!
        }
        
        return window
    }
}
