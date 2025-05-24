import SwiftUI

/// View for user login
struct LoginView: View {
    @EnvironmentObject var sessionManager: UserSessionManager
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo and app name
            Text("Train")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description
            Text("Sign in to sync your workouts across devices")
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // Sign in button
            if isLoading {
                ProgressView()
                    .frame(height: 50)
            } else {
                AppleSignInButton {
                    await signIn()
                }
                .padding(.horizontal)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 8)
            }
            
            // Privacy and terms links
            HStack {
                Button("Privacy Policy") {
                    showingPrivacyPolicy = true
                }
                
                Text("•")
                
                Button("Terms of Service") {
                    showingTerms = true
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .onChange(of: sessionManager.authState) { newState in
            handleAuthStateChange(newState)
        }
    }
    
    /// Handle sign in process
    private func signIn() async {
        isLoading = true
        errorMessage = nil
        
        await sessionManager.signInWithApple()
    }
    
    /// Handle authentication state changes
    private func handleAuthStateChange(_ state: UserSessionManager.AuthState) {
        isLoading = false
        
        switch state {
        case .authenticated:
            // Successfully authenticated, no need to do anything here
            // The parent view will handle navigation based on auth state
            break
        case .error(let error):
            errorMessage = error.localizedDescription
        default:
            break
        }
    }
}

/// View for privacy policy
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: May 22, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Group {
                        Text("1. Information We Collect")
                            .font(.headline)
                        
                        Text("We collect information you provide directly to us when you create an account, such as your name and email address. We also collect information about your workouts, training plans, and app usage to provide and improve our services.")
                    }
                    
                    Group {
                        Text("2. How We Use Your Information")
                            .font(.headline)
                        
                        Text("We use the information we collect to provide, maintain, and improve our services, including to personalize your workout experience and provide recommendations.")
                    }
                    
                    Group {
                        Text("3. Data Storage and Security")
                            .font(.headline)
                        
                        Text("Your data is stored securely using industry-standard encryption. We use Firebase for authentication and data storage, which maintains high security standards.")
                    }
                }
                .padding()
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

/// View for terms of service
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: May 22, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                        
                        Text("By accessing or using the Train app, you agree to be bound by these Terms of Service.")
                    }
                    
                    Group {
                        Text("2. User Accounts")
                            .font(.headline)
                        
                        Text("You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")
                    }
                    
                    Group {
                        Text("3. Subscription Terms")
                            .font(.headline)
                        
                        Text("Subscriptions are billed in advance on a monthly basis. You can cancel your subscription at any time through your App Store account settings.")
                    }
                }
                .padding()
            }
            .navigationBarTitle("Terms of Service", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserSessionManager())
}
