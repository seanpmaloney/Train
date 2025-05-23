# Train App - User Account Implementation Plan

This document outlines the detailed implementation plan for adding user accounts to the Train app using Firebase Authentication with Sign In with Apple, and StoreKit for subscription management.

## TL;DR — Developer Quickstart

1. **Install Dependencies**
   - Add Firebase SDK via Swift Package Manager
   - Confirm StoreKit 2 support in your deployment target

2. **Configure Firebase**
   - Add `GoogleService-Info.plist` to your project
   - Call `FirebaseApp.configure()` in `TrainApp.swift`

3. **Run the App**
   - Launch `TrainApp.swift`
   - Sign in with Apple using `LoginView`

4. **Check Subscription Integration**
   - `SubscriptionService` loads available StoreKit products and checks tier
   - `FeatureAccessService` gates features by current subscription level

5. **Sync Plans**
   - Plans are stored locally and synced via `FirestoreSyncService`
   - Sync triggers from `BackgroundSyncManager` or manually after sign-in
```

**Key Files to Implement:**
- `UserEntity.swift`: User model with subscription tier
- `AuthService.swift`: Protocol for authentication
- `FirebaseAuthService.swift`: Firebase implementation
- `SubscriptionService.swift`: StoreKit integration
- `PlanSyncService.swift`: Data synchronization

**Implementation Order:**
1. Authentication (2 weeks)
2. StoreKit integration (2-3 weeks)
3. Data synchronization (3 weeks)
4. Account management (2 weeks)
5. Polish and production (2 weeks)

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Implementation Stages](#implementation-stages)
3. [Folder Structure](#folder-structure)
4. [Detailed Implementation Guide](#detailed-implementation-guide)
5. [Testing Strategy](#testing-strategy)
6. [Compliance Requirements](#compliance-requirements)

## Architecture Overview

The user account system follows these key architectural principles:

- **Offline-First**: All data is stored locally first, then synced to the cloud
- **Clean Separation of Concerns**: Authentication, subscription management, and data sync are separate services
- **Type Safety**: Using protocols and strong typing throughout
- **Testability**: All components are designed for easy mocking and testing

### Key Components

![Architecture Diagram](architecture-diagram.png)

1. **UserSessionManager**: Central coordinator for authentication state
2. **AuthService**: Handles Sign In with Apple and Firebase authentication
3. **SubscriptionService**: Manages StoreKit subscriptions and user tiers
4. **PlanSyncService**: Synchronizes local data with Firebase Firestore
5. **FeatureAccessService**: Controls access to premium features

## Implementation Stages

### Stage 1: Authentication Infrastructure (2 weeks)

- Firebase setup with Sign In with Apple
- UserEntity and AuthService implementation
- UserSessionManager for auth state management
- Basic authentication UI

### Stage 2: StoreKit Integration (2-3 weeks)

- SubscriptionService with StoreKit 2
- Subscription tier management
- Feature access control
- Subscription UI

### Stage 3: Data Synchronization (3 weeks)

- Entity model updates for user ownership
- Firestore sync service
- Conflict resolution
- Background sync management

### Stage 4: Account Management (2 weeks)

- Account deletion (Apple requirement)
- Privacy policy and terms of service
- Data export functionality

### Stage 5: Polish and Production (2 weeks)

- Error handling and recovery
- Analytics and monitoring
- TestFlight testing

## Folder Structure

```
Train/
├── Auth/
│   ├── Models/
│   │   ├── UserEntity.swift
│   │   └── AuthError.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── FirebaseAuthService.swift
│   │   └── KeychainService.swift
│   ├── ViewModels/
│   │   └── UserSessionManager.swift
│   └── Views/
│       ├── LoginView.swift
│       ├── AppleSignInButton.swift
│       └── AccountView.swift
├── Subscription/
│   ├── Models/
│   │   ├── SubscriptionTier.swift
│   │   └── Feature.swift
│   ├── Services/
│   │   ├── SubscriptionService.swift
│   │   └── FeatureAccessService.swift
│   └── Views/
│       ├── SubscriptionView.swift
│       └── FeatureLockedView.swift
└── Sync/
    ├── Models/
    │   └── SyncStatus.swift
    ├── Services/
    │   ├── PlanSyncService.swift
    │   ├── FirestoreSyncService.swift
    │   └── BackgroundSyncManager.swift
    └── Views/
        └── SyncStatusView.swift
```

## Detailed Implementation Guide

### Stage 1: Authentication Infrastructure

#### 1.1 Firebase Setup

1. Add Firebase SDK via Swift Package Manager:
   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
   ],
   targets: [
       .target(
           name: "Train",
           dependencies: [
               .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
               .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
               .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk")
           ]
       )
   ]
   ```

2. Configure Firebase in your app:
   ```swift
   // TrainApp.swift
   import Firebase
   
   @main
   struct TrainApp: App {
       @StateObject private var userSessionManager = UserSessionManager()
       
       init() {
           FirebaseApp.configure()
       }
       
       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environmentObject(userSessionManager)
           }
       }
   }
   ```

3. Set up Firebase Authentication in the Firebase console:
   - Enable Apple as a sign-in provider
   - Configure Sign In with Apple in your Apple Developer account
   - Add the Firebase configuration file to your project

#### 1.2 User Entity and Authentication Service

```swift
// Models/UserEntity.swift
struct UserEntity: Codable, Identifiable, Equatable {
    let id: String           // Firebase UID
    var email: String
    var displayName: String?
    var tier: SubscriptionTier
    var createdAt: Date
    var lastLoginAt: Date
}

// Services/AuthService.swift
protocol AuthService {
    func signInWithApple() async throws -> UserEntity
    func signOut() async throws
    func getCurrentUser() -> UserEntity?
    func deleteAccount() async throws
}

// Services/FirebaseAuthService.swift
class FirebaseAuthService: AuthService {
    private let appleAuthProvider = ASAuthorizationAppleIDProvider()
    
    func signInWithApple() async throws -> UserEntity {
        // Implementation details in code file
    }
    
    func signOut() async throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUser() -> UserEntity? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        return UserEntity(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            tier: .free,  // Default to free, will be updated by SubscriptionService
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            lastLoginAt: firebaseUser.metadata.lastSignInDate ?? Date()
        )
    }
    
    func deleteAccount() async throws {
        try await Auth.auth().currentUser?.delete()
    }
}
```

#### 1.3 User Session Manager

```swift
// ViewModels/UserSessionManager.swift
@MainActor
class UserSessionManager: ObservableObject {
    @Published var currentUser: UserEntity?
    @Published var authState: AuthState = .unknown
    
    enum AuthState {
        case unknown, authenticated, unauthenticated, error(Error)
    }
    
    private let authService: AuthService
    private let subscriptionService: SubscriptionService
    
    init(authService: AuthService = FirebaseAuthService(),
         subscriptionService: SubscriptionService = SubscriptionService()) {
        self.authService = authService
        self.subscriptionService = subscriptionService
        
        // Check for existing user on init
        Task {
            await checkAuthState()
        }
    }
    
    func signInWithApple() async {
        do {
            let user = try await authService.signInWithApple()
            self.currentUser = user
            self.authState = .authenticated
            
            // Check subscription status
            await subscriptionService.refreshSubscriptionStatus()
        } catch {
            self.authState = .error(error)
        }
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            self.currentUser = nil
            self.authState = .unauthenticated
        } catch {
            self.authState = .error(error)
        }
    }
    
    func checkAuthState() async {
        if let user = authService.getCurrentUser() {
            self.currentUser = user
            self.authState = .authenticated
            
            // Check subscription status
            await subscriptionService.refreshSubscriptionStatus()
        } else {
            self.authState = .unauthenticated
        }
    }
}
```

#### 1.4 Authentication UI

```swift
// Views/AppleSignInButton.swift
struct AppleSignInButton: View {
    var action: () async -> Void
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success:
                    Task {
                        await action()
                    }
                case .failure(let error):
                    print("Apple sign in failed: \(error.localizedDescription)")
                }
            }
        )
        .frame(height: 50)
        .cornerRadius(8)
    }
}

// Views/LoginView.swift
struct LoginView: View {
    @EnvironmentObject var sessionManager: UserSessionManager
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Train")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sign in to sync your workouts across devices")
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            AppleSignInButton {
                await sessionManager.signInWithApple()
            }
            .padding(.horizontal)
            
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
    }
}
```

### Stage 2: StoreKit Integration

#### 2.1 Subscription Service

```swift
// Models/SubscriptionTier.swift
enum SubscriptionTier: String, Codable {
    case free
    case pro
    case premium
    
    var features: [Feature] {
        switch self {
        case .free: return [.basicPlans, .workoutTracking]
        case .pro: return [.basicPlans, .workoutTracking, .customPlans, .analytics]
        case .premium: return [.basicPlans, .workoutTracking, .customPlans, .analytics, .advancedProgression]
        }
    }
}

enum Feature: String {
    case basicPlans, workoutTracking, customPlans, analytics, advancedProgression
}

// Services/SubscriptionService.swift
@MainActor
class SubscriptionService: ObservableObject {
    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactionUpdates()
        
        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // Load available products
    func loadProducts() async {
        do {
            let productIDs = ["com.train.pro.monthly", "com.train.premium.monthly"]
            availableProducts = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // Purchase subscription
    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshSubscriptionStatus()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // Refresh subscription status
    func refreshSubscriptionStatus() async {
        // Get latest transaction for each subscription
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Process the transaction and update the tier
                if transaction.revocationDate == nil && !transaction.isUpgraded {
                    switch transaction.productID {
                    case "com.train.premium.monthly":
                        currentTier = .premium
                        return
                    case "com.train.pro.monthly":
                        currentTier = .pro
                        return
                    default:
                        break
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        // If no active subscriptions found, set to free
        currentTier = .free
    }
    
    // Listen for transaction updates
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                await self.refreshSubscriptionStatus()
            }
        }
    }
    
    // Helper to verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
    
    enum StoreError: Error {
        case failedVerification
        case expiredSubscription
    }
}
```

#### 2.2 Feature Access Control

```swift
// Services/FeatureAccessService.swift
class FeatureAccessService {
    private let subscriptionService: SubscriptionService
    
    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }
    
    func canAccess(_ feature: Feature) -> Bool {
        return subscriptionService.currentTier.features.contains(feature)
    }
    
    func requiresUpgrade(for feature: Feature) -> SubscriptionTier? {
        if canAccess(feature) {
            return nil
        }
        
        // Determine the minimum tier needed for this feature
        if SubscriptionTier.pro.features.contains(feature) {
            return .pro
        } else if SubscriptionTier.premium.features.contains(feature) {
            return .premium
        }
        
        return nil
    }
}
```

#### 2.3 Subscription UI

```swift
// Views/SubscriptionView.swift
struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var selectedProduct: Product?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Train Subscription")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Unlock premium features to take your training to the next level")
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                SubscriptionOptionView(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    currentTier: subscriptionService.currentTier
                ) {
                    selectedProduct = product
                }
            }
            
            Button {
                if let product = selectedProduct {
                    Task {
                        try? await subscriptionService.purchase(product)
                    }
                }
            } label: {
                Text("Subscribe")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(selectedProduct == nil || subscriptionService.purchaseInProgress)
            .padding(.top)
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionService.refreshSubscriptionStatus()
                }
            }
            .font(.footnote)
            .padding(.top, 8)
        }
        .padding()
    }
}
```

### Stage 3: Data Synchronization

#### 3.1 Update Entity Models

```swift
// Models/SyncStatus.swift
enum SyncStatus: String, Codable {
    case notSynced
    case synced
    case pendingUpload
    case pendingDownload
    case conflict
}

// Models/TrainingPlan.swift (extension)
extension TrainingPlanEntity {
    // Add these properties to the existing class
    var userId: String?
    var lastModified: Date = Date()
    var syncStatus: SyncStatus = .notSynced
    
    // Update the Codable implementation to include new properties
    enum CodingKeys: String, CodingKey {
        // Existing keys
        case id, name, notes, startDate, endDate, daysPerWeek, isCompleted, weeklyWorkouts
        // New keys
        case userId, lastModified, syncStatus
    }
    
    // Update init(from:) and encode(to:) methods
}
```

#### 3.2 Firestore Sync Service

```swift
// Services/PlanSyncService.swift
protocol PlanSyncService {
    func syncPlans() async throws
    func uploadPlan(_ plan: TrainingPlanEntity) async throws
    func downloadPlans() async throws
    func resolveConflict(localPlan: TrainingPlanEntity, remotePlan: TrainingPlanEntity) async throws -> TrainingPlanEntity
}

// Services/FirestoreSyncService.swift
class FirestoreSyncService: PlanSyncService {
    private let db = Firestore.firestore()
    private let appState: AppState
    private let userSessionManager: UserSessionManager
    
    init(appState: AppState, userSessionManager: UserSessionManager) {
        self.appState = appState
        self.userSessionManager = userSessionManager
    }
    
    func syncPlans() async throws {
        guard let userId = userSessionManager.currentUser?.id else {
            throw SyncError.notAuthenticated
        }
        
        // Upload pending plans
        let plansToUpload = appState.getAllPlans().filter { 
            $0.syncStatus == .pendingUpload && $0.userId == userId 
        }
        
        for plan in plansToUpload {
            try await uploadPlan(plan)
        }
        
        // Download new plans
        try await downloadPlans()
    }
    
    func uploadPlan(_ plan: TrainingPlanEntity) async throws {
        guard let userId = userSessionManager.currentUser?.id else {
            throw SyncError.notAuthenticated
        }
        
        // Ensure plan belongs to current user
        if plan.userId != userId {
            plan.userId = userId
        }
        
        // Convert plan to dictionary
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(plan)
        let planDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Upload to Firestore
        try await db.collection("plans").document(plan.id.uuidString).setData(planDict)
        
        // Update sync status
        plan.syncStatus = .synced
        appState.savePlans()
    }
    
    func downloadPlans() async throws {
        guard let userId = userSessionManager.currentUser?.id else {
            throw SyncError.notAuthenticated
        }
        
        // Get all plans for this user
        let snapshot = try await db.collection("plans")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for document in snapshot.documents {
            let data = document.data()
            
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            
            // Decode to plan entity
            let remotePlan = try decoder.decode(TrainingPlanEntity.self, from: jsonData)
            
            // Check if plan exists locally
            if let localPlan = appState.findPlan(with: remotePlan.id) {
                // Check for conflicts
                if localPlan.lastModified > remotePlan.lastModified {
                    // Local is newer, mark for upload
                    localPlan.syncStatus = .pendingUpload
                } else if localPlan.lastModified < remotePlan.lastModified {
                    // Remote is newer, update local
                    appState.updatePlan(remotePlan)
                }
            } else {
                // New plan, add to app state
                appState.addPlan(remotePlan)
            }
        }
        
        appState.savePlans()
    }
    
    func resolveConflict(localPlan: TrainingPlanEntity, remotePlan: TrainingPlanEntity) async throws -> TrainingPlanEntity {
        // Default to timestamp-based resolution
        if localPlan.lastModified > remotePlan.lastModified {
            return localPlan
        } else {
            return remotePlan
        }
    }
    
    enum SyncError: Error {
        case notAuthenticated
        case uploadFailed
        case downloadFailed
    }
}
```

#### 3.3 Background Sync Manager

```swift
// Services/BackgroundSyncManager.swift
class BackgroundSyncManager {
    private let syncService: PlanSyncService
    private var syncTask: Task<Void, Error>?
    private var timer: Timer?
    
    init(syncService: PlanSyncService) {
        self.syncService = syncService
    }
    
    func startPeriodicSync(interval: TimeInterval = 300) { // 5 minutes
        stopSync()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.scheduleSync()
        }
        
        // Initial sync
        scheduleSync(immediate: true)
    }
    
    func stopSync() {
        timer?.invalidate()
        timer = nil
        syncTask?.cancel()
        syncTask = nil
    }
    
    func scheduleSync(immediate: Bool = false) {
        // Cancel any existing task
        syncTask?.cancel()
        
        // Create a new task
        syncTask = Task {
            if !immediate {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            }
            
            do {
                try await syncService.syncPlans()
            } catch {
                print("Background sync failed: \(error)")
                // Implement exponential backoff for retries
            }
        }
    }
}
```

### Stage 4: Account Management

#### 4.1 Account Deletion

```swift
// ViewModels/UserSessionManager.swift (extension)
extension UserSessionManager {
    func deleteAccount() async throws {
        // 1. Delete user data from Firestore
        try await deleteUserData()
        
        // 2. Delete Firebase account
        try await authService.deleteAccount()
        
        // 3. Clear local state
        self.currentUser = nil
        self.authState = .unauthenticated
        
        // 4. Clear local data
        appState.clearAllData()
    }
    
    private func deleteUserData() async throws {
        guard let userId = currentUser?.id else {
            throw AccountError.notAuthenticated
        }
        
        // Delete user document and all associated data
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete user document
        batch.deleteDocument(db.collection("users").document(userId))
        
        // Delete user plans
        let plans = try await db.collection("plans")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for doc in plans.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Commit batch delete
        try await batch.commit()
    }
    
    enum AccountError: Error {
        case notAuthenticated
        case deletionFailed
    }
}
```

#### 4.2 Privacy and Terms Views

```swift
// Views/PrivacyPolicyView.swift
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Privacy policy content
                    Group {
                        Text("Last Updated: May 22, 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("1. Information We Collect")
                            .font(.headline)
                        
                        Text("We collect information you provide directly to us when you create an account, such as your name and email address. We also collect information about your workouts, training plans, and app usage to provide and improve our services.")
                        
                        // Add more sections as needed
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}
```

## Testing Strategy

### Unit Tests

1. **AuthService Tests**
   - Mock Firebase Auth for testing sign-in/sign-out
   - Test error handling for auth failures

2. **SubscriptionService Tests**
   - Use StoreKit testing configuration
   - Test tier determination logic
   - Verify feature access control

3. **SyncService Tests**
   - Mock Firestore for testing upload/download
   - Test conflict resolution logic
   - Verify error handling

### Integration Tests

1. **Auth Flow Tests**
   - Test complete sign-in flow
   - Verify persistence of auth state

2. **Subscription Flow Tests**
   - Test purchase flow
   - Verify tier changes affect feature access

3. **Sync Flow Tests**
   - Test bidirectional sync
   - Verify data integrity after sync

### UI Tests

1. **Authentication UI Tests**
   - Test login screen
   - Verify error messages

2. **Subscription UI Tests**
   - Test subscription screen
   - Verify tier display

3. **Feature Access Tests**
   - Test premium feature access
   - Verify upgrade prompts

## Compliance Requirements

### Apple Requirements

1. **Sign In with Apple**
   - Must offer as primary sign-in option
   - Must handle credential revocation

2. **Account Deletion**
   - Must provide account deletion option
   - Must delete all user data

3. **Privacy Policy**
   - Must disclose data collection practices
   - Must explain data usage

### Firebase Requirements

1. **Security Rules**
   - Implement proper security rules for Firestore
   - Ensure data is only accessible to authorized users

2. **Data Retention**
   - Implement data retention policies
   - Handle data deletion requests

### GDPR Compliance

1. **Data Export**
   - Provide functionality to export user data
   - Include all personal data

2. **Consent Management**
   - Get explicit consent for data collection
   - Allow users to withdraw consent

---

This implementation plan provides a comprehensive roadmap for adding user accounts to the Train app. Follow each stage sequentially, and refer to the detailed implementation guide for specific code examples and best practices.
