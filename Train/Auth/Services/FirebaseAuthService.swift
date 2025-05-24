import Foundation
import AuthenticationServices
import CryptoKit
// Firebase will need to be added via Swift Package Manager in Xcode
// import FirebaseAuth

/// Implementation of AuthService using Firebase
@MainActor
class FirebaseAuthService: NSObject, AuthService {
    // For Apple Sign In
    private var currentNonce: String?
    
    /// Sign in with Apple and then with Firebase
    func signInWithApple() async throws -> UserEntity {
        // Generate a nonce for Firebase auth
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Request Apple Sign In
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // Perform the request
        do {
            let result = try await performAppleSignIn(request: request)
            
            // Convert to Firebase credential and sign in
            // This would use Firebase in a real implementation
            // For now, we'll simulate a successful sign in
            
            // In a real implementation:
            // let credential = OAuthProvider.credential(withProviderID: "apple.com",
            //                                          idToken: result.identityToken,
            //                                          rawNonce: nonce)
            // let authResult = try await Auth.auth().signIn(with: credential)
            
            // Simulate a successful sign in
            let simulatedUser = UserEntity(
                id: UUID().uuidString,
                email: result.email ?? "user@example.com",
                displayName: formatFullName(result.fullName),
                tier: .free,
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            return simulatedUser
        } catch {
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    throw AuthError.signInCanceled
                default:
                    throw AuthError.authenticationFailed(message: error.localizedDescription)
                }
            }
            throw AuthError.unknown(message: error.localizedDescription)
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        // In a real implementation:
        // try Auth.auth().signOut()
        
        // For now, we'll just simulate a successful sign out
        print("User signed out")
    }
    
    /// Get the current authenticated user
    nonisolated func getCurrentUser() -> UserEntity? {
        // In a real implementation:
        // guard let firebaseUser = Auth.auth().currentUser else {
        //     return nil
        // }
        // 
        // return UserEntity(
        //     id: firebaseUser.uid,
        //     email: firebaseUser.email ?? "",
        //     displayName: firebaseUser.displayName,
        //     tier: .free,  // This would be fetched from Firestore
        //     createdAt: firebaseUser.metadata.creationDate ?? Date(),
        //     lastLoginAt: firebaseUser.metadata.lastSignInDate ?? Date()
        // )
        
        // For now, return nil to simulate no user is signed in
        return nil
    }
    
    /// Delete the current user's account
    func deleteAccount() async throws {
        // In a real implementation:
        // try await Auth.auth().currentUser?.delete()
        
        // For now, we'll just simulate a successful account deletion
        print("User account deleted")
    }
    
    // MARK: - Helper Methods
    
    /// Perform Apple Sign In and return the result
    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            
            // Create the delegate on the main actor to avoid isolation warnings
            Task { @MainActor in
                let delegate = AppleSignInDelegate(continuation: continuation)
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                
                // Store the delegate to prevent it from being deallocated
                objc_setAssociatedObject(self, "appleSignInDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    /// Format the full name from Apple Sign In components
    private func formatFullName(_ nameComponents: PersonNameComponents?) -> String? {
        guard let nameComponents = nameComponents else { return nil }
        
        var formattedName = ""
        if let givenName = nameComponents.givenName {
            formattedName += givenName
        }
        
        if let familyName = nameComponents.familyName {
            if !formattedName.isEmpty {
                formattedName += " "
            }
            formattedName += familyName
        }
        
        return formattedName.isEmpty ? nil : formattedName
    }
    
    /// Generate a random nonce for authentication
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Generate SHA256 hash of the input string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

/// Delegate for handling Apple Sign In callbacks
@MainActor
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
    
    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AuthError.authenticationFailed(message: "Invalid credentials"))
            return
        }
        
        continuation.resume(returning: credential)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This would normally return the window, but for our implementation we'll use a workaround
        // In a real app, you'd inject the window or use UIApplication.shared.windows.first
        return ASPresentationAnchor()
    }
}
