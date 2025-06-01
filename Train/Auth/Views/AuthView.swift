import SwiftUI
import AuthenticationServices

/// Consolidated authentication view that handles both login and account management
struct AuthView: View {
    @EnvironmentObject var sessionManager: UserSessionManager
    @EnvironmentObject var appState: AppState
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authProvider = AppleAuthorizationProvider()
    
    var body: some View {
        // If user is authenticated, show account view
        if sessionManager.isAuthenticated {
            accountView
        } else {
            // Otherwise show login view
            loginView
        }
    }
    
    // MARK: - Login View
    
    private var loginView: some View {
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
                SignInWithAppleButton(
                    .signUp,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            switch result {
                            case .success(let authorization):
                                // Process the authorization directly instead of triggering another sign-in
                                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    await processAppleSignIn(with: appleIDCredential)
                                }
                            case .failure(let error):
                                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                            }
                        }
                    }
                )
                .frame(height: 50)
                .cornerRadius(8)
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
    
    // MARK: - Account View
    
    private var accountView: some View {
        NavigationView {
            List {
                // User information section
                Section(header: Text("Account")) {
                    if let user = sessionManager.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Text("Subscription")
                            Spacer()
                            Text(user.tier.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Member Since")
                            Spacer()
                            Text(formattedDate(user.createdAt))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Subscription section
                Section(header: Text("Subscription")) {
                    NavigationLink(destination: Text("Subscription Management")) {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                    
                    NavigationLink(destination: Text("Feature Access")) {
                        Label("Available Features", systemImage: "list.star")
                    }
                }
                
                // Account management section
                Section(header: Text("Account Management")) {
                    Button(action: {
                        Task {
                            await signOut()
                        }
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(isLoading)
                }
                
                // Support section
                Section(header: Text("Support")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                }
                
                // App information section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Account")
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(width: 80, height: 80)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            )
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            await deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: Binding(
                get: { errorMessage.map { ErrorWrapper(message: $0) } },
                set: { errorMessage = $0?.message }
            )) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Process Apple Sign In with received credentials
    private func processAppleSignIn(with appleIDCredential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        // Create user from the credential
        let userId = appleIDCredential.user
        
        // Keep the email if we got one or preserve existing email if already signed in before
        let email = appleIDCredential.email ?? 
                    (sessionManager.currentUser?.email ?? "")
        
        // Extract name if provided by Apple
        // If Apple doesn't provide names but we had them from a previous sign-in, keep those
        let firstName = appleIDCredential.fullName?.givenName ?? 
                        sessionManager.currentUser?.firstName
        let lastName = appleIDCredential.fullName?.familyName ?? 
                       sessionManager.currentUser?.lastName
        
        // Generate display name from first and last name
        var displayName: String? = nil
        if let firstName = firstName, let lastName = lastName {
            displayName = "\(firstName) \(lastName)"
        } else if let existingName = sessionManager.currentUser?.displayName {
            // Preserve existing display name if available
            displayName = existingName
        }
        
        // Preserve username if already set
        let username = sessionManager.currentUser?.username
        
        // Create user entity
        let user = UserEntity(
            id: userId,
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username
        )
        
        print("Created user from Apple Sign In: ID=\(userId), Name=\(displayName ?? "None"), Email=\(email)")
        
        // Sign in the user directly without triggering another Apple dialog
        sessionManager.signInWithUser(user, appState: appState)
        
        // Force an immediate save to ensure persistence
        appState.updateUser(user)
        appState.savePlans()
        
        print("User signed in and saved to AppState")
        isLoading = false
    }
    
    /// Legacy sign in method - only kept for compatibility, should not be used directly
    private func signIn() async {
        isLoading = true
        errorMessage = nil
        
        // Use our authorization provider for sign in
        // Pass appState to ensure user data is properly persisted
        await sessionManager.signInWithApple(presentationContextProvider: authProvider, appState: appState)
    }
    
    /// Handle authentication state changes
    private func handleAuthStateChange(_ state: UserSessionManager.AuthState) {
        isLoading = false
        
        switch state {
        case .authenticated:
            // Successfully authenticated, no need to do anything here
            // The view will automatically switch to account view due to @Published state
            break
        case .error(let error):
            errorMessage = error.localizedDescription
        default:
            break
        }
    }
    
    /// Sign out the current user
    private func signOut() async {
        isLoading = true
        errorMessage = nil
        
        // Pass appState to ensure user data is properly cleared
        await sessionManager.signOut(appState: appState)
        
        isLoading = false
    }
    
    /// Delete the current user's account
    private func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        // Pass appState to ensure user data is properly cleared
        await sessionManager.deleteAccount(appState: appState)
        
        isLoading = false
    }
    
    /// Format a date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Support Views

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

/// Wrapper for error messages to make them identifiable for alerts
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    AuthView()
        .environmentObject(UserSessionManager())
}
