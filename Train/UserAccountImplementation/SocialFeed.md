# Social Feed Implementation Guide

This document outlines the implementation details for the social feed feature in the Train app.

## Overview

The social feed feature allows users to share their workout completions and connect with other users. Key aspects include:

- Feed unlocks only after completing a workout or logging a rest day
- Posts expire after 24 hours
- Two feed tabs: Discover and Friends
- Friend feed shows posts from followed users
- Discover feed shows posts from users who completed similar workouts

## MVP Scope

For the initial implementation, we will focus on these core features:

- **Feed Unlocking**: Users can unlock the feed by completing a workout or logging a rest day
- **Post Creation**: Users can create text posts with optional media
- **Feed Viewing**: Users can view posts from friends and discover new users
- **Follow/Unfollow**: Users can follow and unfollow other users
- **User Search**: Users can search for other users by name or username

### Explicitly Out of Scope for MVP

- Likes and comments functionality
- Notifications for new posts or follows
- Server-side post expiration (will use client-side filtering)
- Analytics and engagement metrics
- Advanced content moderation
- Advanced search filters (e.g., by workout type, location)

## Models

### WorkoutType

```swift
enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case strength
    case cardio
    case run
    case swim
    case cycle
    case yoga
    case hiit
    case rest
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .run: return "Run"
        case .swim: return "Swim"
        case .cycle: return "Cycle"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .rest: return "Rest Day"
        }
    }
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell"
        case .cardio: return "heart.circle"
        case .run: return "figure.run"
        case .swim: return "figure.pool.swim"
        case .cycle: return "bicycle"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "timer"
        case .rest: return "bed.double"
        }
    }
}
```

### FeedUnlock

```swift
struct FeedUnlock: Codable, Identifiable {
    let id: UUID
    let userId: String
    let workoutType: WorkoutType
    let unlockDate: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        workoutType: WorkoutType,
        unlockDate: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.workoutType = workoutType
        self.unlockDate = unlockDate
    }
}
```

### PostEntity

```swift
struct PostEntity: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: String
    let userName: String
    let workoutType: WorkoutType
    let content: String
    let createdAt: Date
    let expiresAt: Date
    
    // Optional media URL
    var mediaURL: URL?
    
    init(
        id: UUID = UUID(),
        userId: String,
        userName: String,
        workoutType: WorkoutType,
        content: String,
        createdAt: Date = Date(),
        mediaURL: URL? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.workoutType = workoutType
        self.content = content
        self.createdAt = createdAt
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: createdAt)!
        self.mediaURL = mediaURL
    }
}
```

## Services

### SocialFeedService

```swift
protocol SocialFeedService {
    /// Get posts for the Friends feed (users the current user follows)
    func getFriendsFeed(limit: Int, lastPostId: UUID?) async throws -> [PostEntity]
    
    /// Get posts for the Discover feed (users with similar workout types)
    func getDiscoverFeed(limit: Int, lastPostId: UUID?) async throws -> [PostEntity]
    
    /// Check if the user has unlocked the feed today
    func hasFeedUnlocked() -> Bool
    
    /// Unlock the feed by completing a workout or logging a rest day
    func unlockFeed(workoutType: WorkoutType) async throws
    
    /// Create a new post
    func createPost(content: String, workoutType: WorkoutType, mediaURL: URL?) async throws -> PostEntity
    
    /// Follow a user
    func followUser(userId: String) async throws
    
    /// Unfollow a user
    func unfollowUser(userId: String) async throws
    
    /// Get users the current user is following
    func getFollowing() async throws -> [UserEntity]
    
    /// Search for users by name or username
    func searchUsers(query: String, limit: Int) async throws -> [UserEntity]
}
```

### FirebaseSocialFeedService

The Firebase implementation of the SocialFeedService will handle:

1. Storing and retrieving posts in Firestore
2. Managing follow relationships
3. Tracking workout completions
4. Implementing feed unlock logic

## Firestore Data Structure

```
/users/{userId}
  - id: String
  - email: String
  - displayName: String
  - tier: String
  - createdAt: Timestamp
  - lastLoginAt: Timestamp
  - lastPostDate: Timestamp
  - feedUnlockDate: Timestamp
  - following: [String]
  - followerCount: Number

/posts/{postId}
  - id: String
  - userId: String
  - userName: String
  - workoutType: String
  - content: String
  - createdAt: Timestamp
  - expiresAt: Timestamp
  - mediaURL: String (optional)

/follows/{followId}
  - followerId: String
  - followeeId: String
  - createdAt: Timestamp
```

## Feed Unlock Logic

The feed unlock logic is implemented as follows:

1. When a user completes a workout or logs a rest day, the app calls `unlockFeed(workoutType:)`
2. The `SocialFeedService` checks if the user has already unlocked the feed today
3. If not, the feed is unlocked and the user can create a post
4. The `feedUnlockDate` property on the user is updated
5. The feed remains unlocked for the rest of the day

### Client-Side Enforcement
- The UI will only show the post creation button if `hasFeedUnlocked()` returns true
- The view model will check this status before allowing navigation to the post creation screen

### Server-Side Enforcement
- Firestore rules will verify that a user can only create a post if their `feedUnlockDate` is today
- This prevents API manipulation and ensures the unlock-to-post flow is maintained

## Post Expiration

For the MVP, we'll implement client-side filtering for post expiration:

1. When fetching posts, the client will filter out any posts where `expiresAt < Date()`
2. The UI will display a countdown for posts nearing expiration
3. Server-side deletion via Cloud Functions will be implemented in a future version

## Feed Tabs

The feed is split into two tabs:

1. **Friends**: Shows posts from users the current user follows
2. **Discover**: Shows posts from users who completed similar workouts

The implementation uses a TabView with separate views for each feed type.

## User Search

The user search functionality allows users to find and follow other users:

1. **Search Interface**: A search bar at the top of a dedicated search view
2. **Search Results**: Displays matching users with their profile information
3. **Follow Action**: Each result includes a follow/unfollow button

### Implementation Details

```swift
// In SocialFeedService implementation
func searchUsers(query: String, limit: Int = 20) async throws -> [UserEntity] {
    guard !query.isEmpty else { return [] }
    
    // Normalize query for case-insensitive search
    let normalizedQuery = query.lowercased()
    
    // Create Firestore query
    let usersRef = db.collection("users")
    
    // Query by displayName
    let nameQuery = usersRef
        .whereField("displayNameLowercase", isGreaterThanOrEqualTo: normalizedQuery)
        .whereField("displayNameLowercase", isLessThanOrEqualTo: normalizedQuery + "\uf8ff")
        .limit(to: limit)
    
    // Execute query
    let snapshot = try await nameQuery.getDocuments()
    
    // Parse results
    return snapshot.documents.compactMap { document in
        try? document.data(as: UserEntity.self)
    }
}
```

### Firestore Indexing

To support efficient user search, we'll need to add:

1. A `displayNameLowercase` field to the user document (lowercase version of displayName)
2. An index on this field to support range queries

### Search View

```swift
struct UserSearchView: View {
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search for users")
                .onChange(of: searchText) { newValue in
                    viewModel.searchUsers(query: newValue)
                }
            
            // Results list
            List(viewModel.searchResults) { user in
                UserSearchResultRow(user: user, isFollowing: viewModel.isFollowing(user))
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Find Friends")
    }
}
```

## Implementation Steps

1. Create the models (WorkoutType, FeedUnlock, PostEntity)
2. Implement the SocialFeedService protocol
3. Create the Firebase implementation
4. Build the UI components (FeedView, PostView, CreatePostView)
5. Integrate with the existing workout completion flow
6. Add follow/unfollow functionality
7. Implement feed unlocking logic

## Testing Strategy

### Manual Testing

1. **Feed Unlock Flow**
   - Complete a workout and verify feed unlocks
   - Verify feed remains unlocked for the rest of the day
   - Verify feed locks again the next day

2. **Post Creation**
   - Create a post after unlocking the feed
   - Verify post appears in the appropriate feeds
   - Verify post expires after 24 hours

3. **Follow/Unfollow**
   - Follow a user and verify their posts appear in Friends feed
   - Unfollow a user and verify their posts no longer appear
   
4. **User Search**
   - Search for users with partial name matches
   - Verify search results update as you type
   - Verify follow/unfollow actions from search results

### Unit Tests

1. **SocialFeedService Tests**
   - Test feed unlock logic
   - Test post creation and retrieval
   - Test follow/unfollow functionality
   - Test post expiration filtering
   - Test user search functionality

2. **UserEntity Tests**
   - Test `hasFeedUnlockedToday` computed property
   - Test following/follower management

### Integration Tests

1. **Authentication Integration**
   - Verify only authenticated users can view/create posts
   - Verify authentication state is properly maintained

2. **Firestore Rules**
   - Test rules enforce feed unlock before post creation
   - Test rules enforce user permissions for follows

## Security Rules

Firestore security rules should ensure:

1. Users can only read/write their own user data
2. Posts are publicly readable but only writable by the author
3. Follows can be created by the follower and read by both parties
4. Feed unlock is enforced before post creation

Example security rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if feed is unlocked today
    function isFeedUnlockedToday(userId) {
      let user = get(/databases/$(database)/documents/users/$(userId));
      let unlockDate = user.data.feedUnlockDate;
      return unlockDate != null && 
             unlockDate.toMillis() > timestamp.date(timestamp.now().toDate().setHours(0,0,0,0)).toMillis();
    }
    
    // User profiles
    match /users/{userId} {
      allow read;
      allow write: if request.auth.uid == userId;
    }
    
    // Posts
    match /posts/{postId} {
      allow read;
      allow create: if request.auth.uid == request.resource.data.userId && 
                     isFeedUnlockedToday(request.auth.uid);
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Follows
    match /follows/{followId} {
      allow read: if request.auth.uid == resource.data.followerId || 
                    request.auth.uid == resource.data.followeeId;
      allow create: if request.auth.uid == request.resource.data.followerId;
      allow delete: if request.auth.uid == resource.data.followerId;
    }
  }
}
```

## Offline Support

The social feed feature follows the app's offline-first approach:

1. Posts are cached locally for offline viewing
2. New posts are queued for upload when the device is online
3. Follow/unfollow actions are queued for sync
4. The feed unlock status is tracked locally

## Performance Considerations

1. **Pagination and Query Limits**
   - All feed queries include pagination parameters (limit, lastPostId)
   - Default limit of 20 posts per page to reduce data transfer
   - Compound indexes on (workoutType, createdAt) for Discover feed efficiency

2. **Caching Strategy**
   - Cache feed data locally for offline viewing
   - Use Firebase SDK's built-in caching for Firestore queries
   - Implement custom caching for media URLs with expiration matching post expiration

3. **Authentication Coupling**
   - All social feed operations require authentication
   - SocialFeedService depends on UserSessionManager for current user ID
   - Feed views check authentication state before rendering

4. **Query Optimization**
   - Discover feed uses compound query on workoutType and timestamp
   - Friends feed uses array-contains query on following array
   - Both are limited and paginated to ensure performance

## Future Enhancements (Post-MVP)

1. Likes and comments functionality
2. Notifications for new posts and follows
3. Server-side post expiration via Cloud Functions
4. Analytics and engagement metrics
5. Content moderation and reporting
6. Advanced search filters (by workout type, activity level, location)
7. Suggested friends based on similar workout patterns
