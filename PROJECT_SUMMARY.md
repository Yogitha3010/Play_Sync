# PlaySync - Project Summary

## Overview
PlaySync is a comprehensive Flutter mobile application for AI-based player matchmaking and team formation. The application helps players find other players with similar skill levels and nearby locations, create balanced teams, and improve gameplay experience through feedback and performance tracking.

## Technology Stack
- **Flutter** (Dart 3.11.0+)
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Database
- **Geolocator & Geocoding** - Location services
- **Provider** - State management (ready for implementation)

## Architecture

### Models (`lib/models/`)
- `user_model.dart` - User account data
- `player_profile_model.dart` - Player profile with skills, ratings, and preferences
- `turf_model.dart` - Turf/venue information
- `match_model.dart` - Match data with teams, status, and scores
- `feedback_model.dart` - Player feedback and ratings
- `achievement_model.dart` - Player achievements and badges

### Services (`lib/services/`)
- `firebase_service.dart` - Firebase initialization and collection references
- `auth_service.dart` - Authentication (register, login, logout)
- `firestore_service.dart` - All Firestore database operations
- `matchmaking_service.dart` - AI-based player matching algorithm
- `achievement_service.dart` - Automatic achievement awarding and rating updates

### Screens (`lib/screens/`)
**Authentication & Setup:**
- `role_selection_screen.dart` - Initial role selection (Player/Turf Owner)
- `player_auth_screen.dart` - Player registration and login
- `turf_auth_screen.dart` - Turf owner registration and login
- `player_profile_setup_screen.dart` - Complete player profile
- `turf_profile_setup_screen.dart` - Complete turf profile

**Player Screens:**
- `player_home_screen.dart` - Main player dashboard with navigation
- `find_players_screen.dart` - AI matchmaking to find players
- `create_match_screen.dart` - Create new matches
- `my_matches_screen.dart` - View all player matches
- `match_detail_screen.dart` - Match details, team formation, toss
- `player_profile_screen.dart` - View player profile
- `player_detail_screen.dart` - View other players' profiles
- `edit_player_profile_screen.dart` - Edit player profile
- `achievements_screen.dart` - View earned achievements
- `feedback_screen.dart` - Provide feedback after matches

**Turf Owner Screens:**
- `turf_home_screen.dart` - Turf owner dashboard
- `my_turfs_screen.dart` - View all registered turfs

## Key Features

### Player Features
1. **Registration & Authentication**
   - Email/password authentication
   - Profile setup with location, sports, and skill level

2. **AI Matchmaking**
   - Finds players based on:
     - Skill level compatibility (40% weight)
     - Location proximity (30% weight)
     - Rating compatibility (20% weight)
     - Experience level (10% weight)

3. **Match Management**
   - Create matches with location and scheduling
   - Join existing matches
   - Automatic balanced team formation
   - Digital toss feature
   - Match status tracking (pending, active, completed)

4. **Team Formation**
   - Automatic balanced team splitting
   - Skill-based distribution
   - Team A and Team B assignment

5. **Match Predictions**
   - Win probability calculation based on team composition
   - Skill and rating analysis

6. **Feedback System**
   - Rate all players after match completion
   - Comments and ratings (1-5 stars)
   - Automatic rating updates
   - Games played counter

7. **Achievements & Badges**
   - Automatic achievement awarding:
     - First Game
     - Rookie Player (10 games)
     - Veteran Player (50 games)
     - Champion (100 games)
     - Highly Rated (4.5+ rating)
     - Perfect Player (5.0 rating)
     - Skill Master (9.0+ skill)
     - Multi-Sport Player (3+ sports)

### Turf Owner Features
1. **Registration & Profile**
   - Basic registration (name, email, password, contact)
   - Turf profile setup:
     - Location
     - Games available
     - Number of courts per game
     - Price per hour
     - Facilities (AC, changing room, etc.)

2. **Turf Management**
   - View all registered turfs
   - Turf status (active/inactive)

## Database Structure

### Collections

**users**
- userId, role, email, name, phone, createdAt, profileCompleted

**playerProfiles**
- userId, name, skillLevel, gamesPlayed, rating, preferredSports, location, locationAddress, achievements, matchHistory, lastUpdated

**turfs**
- turfId, ownerId, name, location, coordinates, gamesAvailable, courts, pricePerHour, facilities, contact, createdAt, isActive

**matches**
- matchId, gameType, location, coordinates, turfId, createdBy, players, teamA, teamB, playerPositions, matchStatus, tossResult, score, createdAt, scheduledTime, maxPlayers, matchGroupId

**feedback**
- feedbackId, matchId, fromPlayerId, toPlayerId, rating, comments, createdAt

**achievements**
- achievementId, playerId, badgeName, description, icon, unlockedAt, category

## AI Matchmaking Algorithm

The matchmaking service uses a weighted scoring system:

1. **Skill Level Compatibility (40%)**
   - Compares skill levels between players
   - Prefers players with similar skill levels (within tolerance)

2. **Location Proximity (30%)**
   - Uses Haversine formula to calculate distance
   - Filters players within max distance
   - Closer players get higher scores

3. **Rating Compatibility (20%)**
   - Compares average ratings
   - Prefers players with similar ratings

4. **Experience Compatibility (10%)**
   - Compares games played
   - Prefers players with similar experience

## Team Formation Algorithm

1. Sorts all players by skill level (descending)
2. Distributes players alternately to Team A and Team B
3. Calculates total team skill
4. If teams are unbalanced (>2.0 skill difference), swaps players
5. Ensures balanced teams

## UI/UX Features

- Modern Material Design 3
- Clean and professional interface
- Smooth navigation
- Reusable widgets
- Responsive layouts
- Loading states
- Error handling
- Form validation

## Setup Requirements

1. **Firebase Configuration**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Enable Authentication (Email/Password)
   - Create Firestore database

2. **Location Permissions**
   - Android: Add permissions to `AndroidManifest.xml`
   - iOS: Add permissions to `Info.plist`

3. **Dependencies**
   - Run `flutter pub get`

## Next Steps for Production

1. **Security**
   - Implement proper Firestore security rules
   - Add input validation and sanitization
   - Implement rate limiting

2. **Features to Add**
   - Push notifications for match updates
   - In-app chat/messaging
   - Payment integration for turf booking
   - Match history and statistics
   - Social features (friends, follow)
   - Tournament mode
   - Live score updates

3. **Performance**
   - Implement caching
   - Optimize Firestore queries
   - Add pagination for large lists
   - Image upload and storage

4. **Testing**
   - Unit tests for services
   - Widget tests for UI
   - Integration tests

5. **Deployment**
   - Configure app signing
   - Set up CI/CD
   - App store deployment

## File Structure

```
lib/
├── models/              # Data models
├── services/            # Business logic
├── screens/             # UI screens
├── theme/               # App theme
└── main.dart            # Entry point
```

## Notes

- The app is ready for Firebase integration
- All core features are implemented
- UI is modern and user-friendly
- Code is modular and scalable
- Follows Flutter best practices

For detailed setup instructions, see `SETUP_GUIDE.md`.
