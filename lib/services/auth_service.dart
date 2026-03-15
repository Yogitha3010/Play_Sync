import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/player_profile_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register Player
  Future<UserCredential?> registerPlayer({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
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
          skillLevel: 5.0,
          gamesPlayed: 0,
          rating: 0.0,
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

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // For web, use the Firebase JS SDK popup flow for better compatibility.
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);

        if (userCredential.user != null) {
          // Create user document if not exists
          final doc = await FirebaseService.usersCollection
              .doc(userCredential.user!.uid)
              .get();

          if (!doc.exists) {
            final userModel = UserModel(
              userId: userCredential.user!.uid,
              role: 'player',
              email: userCredential.user!.email ?? '',
              name: userCredential.user!.displayName ?? 'Google User',
              phone: userCredential.user!.phoneNumber,
              createdAt: DateTime.now(),
              profileCompleted: false,
            );

            await FirebaseService.usersCollection
                .doc(userCredential.user!.uid)
                .set(userModel.toMap());

            final playerProfile = PlayerProfileModel(
              userId: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Google User',
              skillLevel: 5.0,
              gamesPlayed: 0,
              rating: 0.0,
              preferredSports: [],
              lastUpdated: DateTime.now(),
            );

            await FirebaseService.playerProfilesCollection
                .doc(userCredential.user!.uid)
                .set(playerProfile.toMap());
          }
        }

        return userCredential;
      }

      // Native platforms: use google_sign_in plugin.
      // The v7+ api exposes a singleton and uses authenticate() instead of a constructor.
      await GoogleSignIn.instance.initialize();
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
        // Check if user document already exists
        final doc = await FirebaseService.usersCollection
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          // New User via Google - Create standard player document
          final userModel = UserModel(
            userId: userCredential.user!.uid,
            role: 'player', // Default to player for Google sign in
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'Google User',
            phone: userCredential.user!.phoneNumber,
            createdAt: DateTime.now(),
            profileCompleted: false,
          );

          await FirebaseService.usersCollection
              .doc(userCredential.user!.uid)
              .set(userModel.toMap());

          // Create base profile
          final playerProfile = PlayerProfileModel(
            userId: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            skillLevel: 5.0,
            gamesPlayed: 0,
            rating: 0.0,
            preferredSports: [],
            lastUpdated: DateTime.now(),
          );

          await FirebaseService.playerProfilesCollection
              .doc(userCredential.user!.uid)
              .set(playerProfile.toMap());
        }
      }
      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }
}
