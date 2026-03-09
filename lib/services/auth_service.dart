import 'package:firebase_auth/firebase_auth.dart';
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
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
    await FirebaseService.usersCollection
        .doc(userId)
        .update({'profileCompleted': completed});
  }
}
