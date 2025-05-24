import SwiftUI

/// View for displaying and managing user account
struct AccountView: View {
    @EnvironmentObject var sessionManager: UserSessionManager
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
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
    
    /// Sign out the current user
    private func signOut() async {
        isLoading = true
        errorMessage = nil
        
        await sessionManager.signOut()
        
        isLoading = false
    }
    
    /// Delete the current user's account
    private func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        await sessionManager.deleteAccount()
        
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

/// Wrapper for error messages to make them identifiable for alerts
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    AccountView()
        .environmentObject(UserSessionManager())
}
