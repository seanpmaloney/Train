import SwiftUI

/// View for entering first and last name during onboarding
struct NameSetupView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @FocusState private var firstNameFocused: Bool
    
    // Validation check
    private var isValidInput: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("What's Your Name?")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("We'll use this to personalize your experience")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Input fields
            VStack(spacing: 16) {
                // First name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("First Name")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    
                    TextField("", text: $firstName)
                        .font(AppStyle.Typography.body())
                        .padding()
                        .background(AppStyle.Colors.surfaceTop)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                                .strokeBorder(AppStyle.Colors.primary.opacity(firstNameFocused ? 0.5 : 0), lineWidth: 2)
                        )
                        .focused($firstNameFocused)
                        .submitLabel(.next)
                        .animation(.easeInOut(duration: 0.2), value: firstNameFocused)
                }
                
                // Last name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Name (Optional)")
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                    
                    TextField("", text: $lastName)
                        .font(AppStyle.Typography.body())
                        .padding()
                        .background(AppStyle.Colors.surfaceTop)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                        .submitLabel(.done)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Submit button
            Button {
                saveNameAndContinue()
            } label: {
                Text("Continue")
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                    .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                    .padding(.horizontal)
            }
            .disabled(!isValidInput)
            .padding(.bottom, 40)
            .simultaneousGesture(TapGesture().onEnded { _ in
                if isValidInput {
                    HapticService.shared.impact(style: .medium)
                }
            })
        }
        .padding()
        .onAppear {
            // Focus the first name field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                firstNameFocused = true
            }
        }
    }
    
    private func saveNameAndContinue() {
        guard let currentUser = viewModel.user else { return }
        
        // Create a mutable copy of the user
        var updatedUser = currentUser
        
        // Format name (trim whitespace)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set the display name
        if !trimmedLastName.isEmpty {
            updatedUser.displayName = "\(trimmedFirstName) \(trimmedLastName)"
        } else {
            updatedUser.displayName = trimmedFirstName
        }
        
        // Store first and last name separately for future use
        updatedUser.firstName = trimmedFirstName
        updatedUser.lastName = trimmedLastName.isEmpty ? nil : trimmedLastName
        
        // Update the user in the view model
        viewModel.user = updatedUser
        
        // Immediately save to AppState for persistence
        viewModel.appState.updateUser(updatedUser)
        viewModel.appState.savePlans()
        print("Saved user name to AppState during onboarding: \(updatedUser.displayName ?? "None")")
        
        // Also update session manager to maintain consistent state
        viewModel.userSessionManager.signInWithUser(updatedUser, appState: viewModel.appState)
        
        // Provide haptic feedback and advance to next step
        Task {
            HapticService.shared.impact(style: .medium)
            viewModel.advanceToNextStep()
        }
    }
}

#if DEBUG
struct NameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        NameSetupView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
            .preferredColorScheme(.dark)
    }
}
#endif
