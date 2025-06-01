import SwiftUI

/// View for setting up a username during onboarding
struct UsernameSetupView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var username = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCheckingUsername = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Your Username")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("This is how other users will identify you in the app.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                
                HStack {
                    TextField("Choose a username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if isCheckingUsername {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding()
                .background(AppStyle.Colors.surface)
                .cornerRadius(8)
                
                Text("3-20 characters, letters, numbers, underscores only")
                    .font(AppStyle.Typography.caption())
                    .foregroundColor(AppStyle.Colors.textSecondary)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                submitUsername()
            } label: {
                Text("Continue")
                    .font(AppStyle.Typography.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isUsernameValid ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                    .cornerRadius(8)
            }
            .disabled(!isUsernameValid || isCheckingUsername)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isUsernameValid: Bool {
        !username.isEmpty && username.count >= 3 && username.count <= 20
    }
    
    private func submitUsername() {
        // Validate username format
        let usernamePattern = "^[a-zA-Z0-9_]{3,20}$"
        if let regex = try? NSRegularExpression(pattern: usernamePattern),
           regex.firstMatch(in: username, range: NSRange(username.startIndex..., in: username)) == nil {
            errorMessage = "Username must be 3-20 characters and contain only letters, numbers, or underscores"
            showingError = true
            
            Task {
                await HapticService.shared.error()
            }
            return
        }
        
        // Set loading state
        isCheckingUsername = true
        
        // In a real implementation, you'd check if the username is already taken
        Task {
            do {
                // Simulate network delay for username checking
                try await Task.sleep(for: .seconds(0.5))
                
                await MainActor.run {
                    guard var user = viewModel.user else {
                        errorMessage = "User data not found"
                        showingError = true
                        isCheckingUsername = false
                        return
                    }
                    
                    // Update the user with the username
                    user.username = username
                    viewModel.user = user
                    
                    // Clear loading state
                    isCheckingUsername = false
                    
                    // Add haptic feedback
                    Task {
                        await HapticService.shared.impact(style: .medium)
                    }
                    
                    // Move to next step
                    viewModel.advanceToNextStep()
                }
            } catch {
                await MainActor.run {
                    isCheckingUsername = false
                    errorMessage = error.localizedDescription
                    showingError = true
                    
                    Task {
                        await HapticService.shared.error()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct UsernameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        UsernameSetupView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
