import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/player_profile_model.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register Player
  Future<UserCredential?> registerPlayer({
    required String email,
    required String password,
    required String name,
    required String username,
    String? phone,
  }) async {
    try {
      final trimmedUsername = username.trim();
      final normalizedUsername = _firestoreService.normalizeUsername(
        trimmedUsername,
      );
      final isAvailable = await _firestoreService.isUsernameAvailable(
        trimmedUsername,
      );
      if (!isAvailable) {
        throw Exception('That username is already taken.');
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();

        // Create user document
        final userModel = UserModel(
          userId: userCredential.user!.uid,
          role: 'player',
          email: email,
          name: name,
          phone: phone,
          username: trimmedUsername,
          usernameLowercase: normalizedUsername,
          createdAt: DateTime.now(),
          profileCompleted: false,
        );

        await FirebaseService.usersCollection
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        // Create initial player profile
        final playerProfile = PlayerProfileModel(
          userId: userCredential.user!.uid,
          name: name,
          username: trimmedUsername,
          usernameLowercase: normalizedUsername,
          skillLevel: 5.0,
          gamesPlayed: 0,
          avgRating: 0.0,
          totalRatings: 0,
          playedGames: const [],
          preferredSports: [],
          lastUpdated: DateTime.now(),
        );

        await FirebaseService.playerProfilesCollection
            .doc(userCredential.user!.uid)
            .set(playerProfile.toMap());

        return userCredential;
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Register Turf Owner
  Future<UserCredential?> registerTurfOwner({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();

        final userModel = UserModel(
          userId: userCredential.user!.uid,
          role: 'turfOwner',
          email: email,
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
          profileCompleted: false,
        );

        await FirebaseService.usersCollection
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        return userCredential;
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await FirebaseService.usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user profile completion status
  Future<void> updateProfileCompletion(String userId, bool completed) async {
    await FirebaseService.usersCollection.doc(userId).update({
      'profileCompleted': completed,
    });
  }

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await FirebaseService.usersCollection.doc(userId).update(updates);
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    return _signInWithGoogleForRole(role: 'player');
  }

  Future<UserCredential?> signInWithGoogleAsTurfOwner() async {
    return _signInWithGoogleForRole(role: 'turfOwner');
  }

  Future<UserCredential?> _signInWithGoogleForRole({
    required String role,
  }) async {
    try {
      String? fallbackUsernameFromEmail(String? email) {
        if (email == null || !email.contains('@')) {
          return null;
        }
        return email.split('@').first;
      }

      // For web, use the Firebase JS SDK popup flow for better compatibility.
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);

        if (userCredential.user != null) {
          await _ensureGoogleUserRecord(
            user: userCredential.user!,
            role: role,
            fallbackUsernameFromEmail: fallbackUsernameFromEmail,
          );
        }

        return userCredential;
      }

      // Native platforms: use google_sign_in plugin.
      // The v7+ API requires a serverClientId (Web Client ID from Google Cloud Console)
      // to produce an idToken on native Android. Find it in:
      // Google Cloud Console → APIs & Services → Credentials → "Web client (auto created by Google Service)"
      // Then paste it below.
      const String webClientId =
          '1031724299384-kf55tdt6cfknno4vnp24johqn1o58gle.apps.googleusercontent.com';

      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate(scopeHint: ['email']);

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _ensureGoogleUserRecord(
          user: userCredential.user!,
          role: role,
          fallbackUsernameFromEmail: fallbackUsernameFromEmail,
        );
      }
      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> _ensureGoogleUserRecord({
    required User user,
    required String role,
    required String? Function(String? email) fallbackUsernameFromEmail,
  }) async {
    final doc = await FirebaseService.usersCollection.doc(user.uid).get();

    if (doc.exists) {
      final existingUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      if (existingUser.role != role) {
        await logout();
        throw Exception(
          'This Google account is already registered as ${existingUser.role}. Please use the correct login.',
        );
      }
      return;
    }

    final fallbackUsername = fallbackUsernameFromEmail(user.email);
    final userModel = UserModel(
      userId: user.uid,
      role: role,
      email: user.email ?? '',
      name: user.displayName ?? 'Google User',
      phone: user.phoneNumber,
      username: role == 'player' ? fallbackUsername : null,
      usernameLowercase: role == 'player' ? fallbackUsername?.toLowerCase() : null,
      createdAt: DateTime.now(),
      profileCompleted: false,
    );

    await FirebaseService.usersCollection.doc(user.uid).set(userModel.toMap());

    if (role == 'player') {
      final playerProfile = PlayerProfileModel(
        userId: user.uid,
        name: user.displayName ?? 'Google User',
        username: fallbackUsername,
        usernameLowercase: fallbackUsername?.toLowerCase(),
        skillLevel: 5.0,
        gamesPlayed: 0,
        avgRating: 0.0,
        totalRatings: 0,
        playedGames: const [],
        preferredSports: [],
        lastUpdated: DateTime.now(),
      );

      await FirebaseService.playerProfilesCollection
          .doc(user.uid)
          .set(playerProfile.toMap());
    }
  }
}
