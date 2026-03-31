# PlaySync - Setup Guide

## Overview
PlaySync is a Flutter mobile application for AI-based player matchmaking and team formation. This guide will help you set up the project.

## Prerequisites
- Flutter SDK (3.11.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication (Email/Password)
4. Create a Cloud Firestore database

### 2. Add Firebase to Android
1. In Firebase Console, go to Project Settings
2. Add Android app with package name: `com.example.playsync` (or your package name)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 3. Add Firebase to iOS
1. In Firebase Console, add iOS app with bundle ID
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

### 4. Enable Firestore
1. Go to Firestore Database in Firebase Console
2. Create database in production mode (or test mode for development)
3. Set up security rules (see below)

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Player profiles
    match /playerProfiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Turfs
    match /turfs/{turfId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    
    // Matches
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (resource.data.createdBy == request.auth.uid ||
         (
           request.resource.data.diff(resource.data).affectedKeys().hasOnly(['players']) &&
           (
             (
               request.resource.data.players.hasAll(resource.data.players) &&
               request.resource.data.players.hasAny([request.auth.uid]) &&
               request.resource.data.players.size() == resource.data.players.size() + 1 &&
               request.resource.data.players.size() <= resource.data.maxPlayers
             ) ||
             (
               resource.data.players.hasAny([request.auth.uid]) &&
               resource.data.players.hasAll(request.resource.data.players) &&
               request.resource.data.players.size() + 1 == resource.data.players.size()
             )
           )
         ));
    }
    
    // Feedback
    match /feedback/{feedbackId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    
    // Achievements
    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Installation Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

## Project Structure

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── player_profile_model.dart
│   ├── turf_model.dart
│   ├── match_model.dart
│   ├── feedback_model.dart
│   └── achievement_model.dart
├── services/           # Business logic and Firebase services
│   ├── firebase_service.dart
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── matchmaking_service.dart
├── screens/            # UI screens
│   ├── role_selection_screen.dart
│   ├── player_auth_screen.dart
│   ├── player_home_screen.dart
│   ├── find_players_screen.dart
│   ├── create_match_screen.dart
│   ├── match_detail_screen.dart
│   └── ... (other screens)
├── theme/              # App theme
│   └── app_theme.dart
└── main.dart           # App entry point
```

## Features Implemented

### Player Features
- ✅ User registration and login
- ✅ Player profile management
- ✅ Sport selection
- ✅ AI-based player matchmaking
- ✅ Create and join matches
- ✅ Automatic balanced team formation
- ✅ Digital toss feature
- ✅ Match statistics and predictions
- ✅ Feedback and rating system
- ✅ Achievements and badges system

### Turf Owner Features
- ✅ Turf owner registration
- ✅ Turf profile setup
- ✅ Turf management

## Database Collections

The app uses the following Firestore collections:
- `users` - User accounts
- `playerProfiles` - Player profiles with skills and preferences
- `turfs` - Turf information
- `matches` - Match data
- `feedback` - Player feedback and ratings
- `achievements` - Player achievements and badges

## AI Matchmaking Algorithm

The matchmaking service matches players based on:
1. **Skill Level** (40% weight) - Similar skill levels
2. **Location Proximity** (30% weight) - Nearby players
3. **Rating Compatibility** (20% weight) - Similar ratings
4. **Experience Level** (10% weight) - Similar game experience

## Team Formation

Teams are automatically balanced using an algorithm that:
- Sorts players by skill level
- Distributes players alternately to balance teams
- Adjusts if teams are significantly unbalanced

## Next Steps

1. Configure Firebase with your project credentials
2. Add location permissions in AndroidManifest.xml and Info.plist
3. Test the authentication flow
4. Customize the UI theme if needed
5. Add more sports or features as needed

## Troubleshooting

### Firebase Not Initialized
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
- Check that Firebase is properly configured in your project

### Location Services Not Working
- Add location permissions to AndroidManifest.xml:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
- Add location permissions to Info.plist for iOS

### Build Errors
- Run `flutter clean` and then `flutter pub get`
- Ensure all dependencies are compatible with your Flutter version

## Support

For issues or questions, please check the Flutter and Firebase documentation.
