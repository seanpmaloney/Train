import SwiftUI
import AuthenticationServices

/// A helper class to provide the presentation anchor for ASAuthorizationController
@MainActor
class AppleAuthorizationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    /// The window scene to use for presentation
    var window: UIWindow?
    
    /// Initialize with the current window
    override init() {
        super.init()
        // Window will be set when needed in presentationAnchor
    }
    
    /// Provide the presentation anchor for authorization
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window on the main actor
        if self.window == nil {
            if #available(iOS 15.0, *) {
                self.window = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first(where: { $0.isKeyWindow })
            } else {
                self.window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            }
        }
        
        // Return the window or a fallback if somehow still nil
        return self.window ?? ASPresentationAnchor()
    }
}
