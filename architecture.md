# Swipzee - Campus Viral Social App Architecture

## Overview
Swipzee is a college-only social app that combines rate/swipe functionality, secret crushes, leaderboards, and gamification features to create a viral campus social experience.

## Core Features (MVP)
1. **Simple Authentication**: Student ID + PIN (4-digit) system
2. **RateMe Swipe Cards**: Swipe left (❌) or right (🔥) on classmate photos
3. **Secret Crush System**: Add up to 10 people, mutual matches unlock chat
4. **Leaderboards**: Daily/Weekly top 100 based on 🔥 received
5. **Weekly Challenges**: Photo submissions with hashtags and leaderboards
6. **Daily Streaks**: Gamified engagement tracking
7. **Chat System**: Only available after mutual matches

## App Structure

### Navigation
- Bottom Navigation: Chat, Home, Profile
- Nested navigation within each tab

### Screen Flow
1. **Onboarding**: Registration/Login with Student ID + PIN
2. **Home**: Main swipe interface + challenge submissions
3. **Chat**: Mutual matches list + add people functionality
4. **Profile**: User stats, posts, streaks, badges
5. **Leaderboard**: Daily/Weekly rankings

## Data Models

### User
- id, studentId, name, profileImageUrl, pin (hashed)
- dailyStreak, postsCount, totalFiresReceived
- createdAt, updatedAt

### Post
- id, userId, imageUrl, caption, challengeTag
- firesCount, createdAt, updatedAt

### Match
- id, user1Id, user2Id, isMatual, createdAt

### Crush
- id, fromUserId, toUserId, createdAt, expiresAt

### Message
- id, matchId, senderId, content, createdAt

### Challenge
- id, title, hashtag, startDate, endDate, isActive

## Services Architecture

### Data Layer
- **UserService**: User CRUD, authentication, streak management
- **PostService**: Post creation, rating system, challenge submissions
- **MatchService**: Crush system, mutual matching logic
- **MessageService**: Chat functionality
- **ChallengeService**: Weekly challenge management
- **LeaderboardService**: Ranking calculations

### Storage
- Local storage using SharedPreferences
- Sample data for development and demo

## Key Components

### Widgets
- **SwipeCard**: Animated card for rating posts
- **LeaderboardTile**: User ranking display
- **ChallengeCard**: Weekly challenge submission display
- **MatchTile**: Chat list item
- **ProfileStats**: User statistics display

### Screens
- **OnboardingScreen**: Registration/Login flow
- **MainScreen**: Bottom navigation wrapper
- **HomeScreen**: Swipe cards + challenges
- **ChatScreen**: Matches list + add people
- **ProfileScreen**: User profile and posts
- **LeaderboardScreen**: Rankings display

## Technical Implementation

### State Management
- Provider pattern for app-wide state
- Local state for UI interactions

### UI/UX Design
- Modern, sleek interface with vibrant colors
- Card-based design with smooth animations
- Generous spacing and elegant typography
- Non-Material Design approach

### Security Considerations
- PIN-based authentication (4-digit)
- Local data encryption for sensitive information
- Input validation and sanitization

## Development Priority
1. Data models and services setup
2. Authentication system
3. Basic navigation structure
4. Home screen with swipe functionality
5. Profile screen with user stats
6. Chat system with matching logic
7. Leaderboard implementation
8. Challenge system
9. UI polish and animations
10. Testing and debugging

## Files Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── user.dart
│   ├── post.dart
│   ├── match.dart
│   ├── crush.dart
│   ├── message.dart
│   └── challenge.dart
├── services/
│   ├── user_service.dart
│   ├── post_service.dart
│   ├── match_service.dart
│   ├── message_service.dart
│   ├── challenge_service.dart
│   └── leaderboard_service.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── profile_screen.dart
│   └── leaderboard_screen.dart
└── widgets/
    ├── swipe_card.dart
    ├── leaderboard_tile.dart
    ├── challenge_card.dart
    ├── match_tile.dart
    └── profile_stats.dart
```

## Success Metrics
- Daily active users and retention
- Swipe engagement rates
- Mutual match conversion
- Challenge participation
- Streak maintenance rates