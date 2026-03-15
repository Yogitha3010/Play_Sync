import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_profile_model.dart';
import '../models/turf_model.dart';
import '../models/match_model.dart';
import '../models/feedback_model.dart';
import '../models/achievement_model.dart';
import '../models/team_model.dart';
import '../models/booking_model.dart';
import 'firebase_service.dart';

class FirestoreService {
  // Player Profile Operations
  Future<void> createPlayerProfile(PlayerProfileModel profile) async {
    await FirebaseService.playerProfilesCollection
        .doc(profile.userId)
        .set(profile.toMap());
  }

  Future<PlayerProfileModel?> getPlayerProfile(String userId) async {
    final doc =
        await FirebaseService.playerProfilesCollection.doc(userId).get();
    if (doc.exists) {
      return PlayerProfileModel.fromMap(
          doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updatePlayerProfile(
      String userId, Map<String, dynamic> updates) async {
    updates['lastUpdated'] = DateTime.now().toIso8601String();
    await FirebaseService.playerProfilesCollection
        .doc(userId)
        .update(updates);
  }

  Stream<PlayerProfileModel> streamPlayerProfile(String userId) {
    return FirebaseService.playerProfilesCollection
        .doc(userId)
        .snapshots()
        .map((doc) => PlayerProfileModel.fromMap(
            doc.data() as Map<String, dynamic>));
  }

  // Turf Operations
  Future<void> createTurf(TurfModel turf) async {
    await FirebaseService.turfsCollection.doc(turf.turfId).set(turf.toMap());
  }

  Future<TurfModel?> getTurf(String turfId) async {
    final doc = await FirebaseService.turfsCollection.doc(turfId).get();
    if (doc.exists) {
      return TurfModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<TurfModel>> getTurfsByOwner(String ownerId) async {
    final querySnapshot = await FirebaseService.turfsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return querySnapshot.docs
        .map((doc) => TurfModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<TurfModel>> searchTurfs({
    String? gameType,
    String? location,
  }) async {
    Query query = FirebaseService.turfsCollection.where('isActive', isEqualTo: true);

    if (gameType != null) {
      query = query.where('gamesAvailable', arrayContains: gameType);
    }

    final querySnapshot = await query.get();
    List<TurfModel> turfs = querySnapshot.docs
        .map((doc) => TurfModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Filter by location if provided (simple string matching)
    if (location != null && location.isNotEmpty) {
      turfs = turfs
          .where((turf) =>
              turf.location.toLowerCase().contains(location.toLowerCase()))
          .toList();
    }

    return turfs;
  }

  // Match Operations
  Future<void> createMatch(MatchModel match) async {
    await FirebaseService.matchesCollection.doc(match.matchId).set(match.toMap());
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await FirebaseService.matchesCollection.doc(matchId).get();
    if (doc.exists) {
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateMatch(String matchId, Map<String, dynamic> updates) async {
    await FirebaseService.matchesCollection.doc(matchId).update(updates);
  }

  Stream<MatchModel> streamMatch(String matchId) {
    return FirebaseService.matchesCollection
        .doc(matchId)
        .snapshots()
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>));
  }

  Future<List<MatchModel>> getMatchesByStatus(String status) async {
    final querySnapshot = await FirebaseService.matchesCollection
        .where('matchStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchModel>> getPlayerMatches(String playerId) async {
    final querySnapshot = await FirebaseService.matchesCollection
        .where('players', arrayContains: playerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return querySnapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Feedback Operations
  Future<void> createFeedback(FeedbackModel feedback) async {
    await FirebaseService.feedbackCollection
        .doc(feedback.feedbackId)
        .set(feedback.toMap());
  }

  Future<List<FeedbackModel>> getFeedbackForPlayer(String playerId) async {
    final querySnapshot = await FirebaseService.feedbackCollection
        .where('toPlayerId', isEqualTo: playerId)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) =>
            FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeedbackModel>> getMatchFeedback(String matchId) async {
    final querySnapshot = await FirebaseService.feedbackCollection
        .where('matchId', isEqualTo: matchId)
        .get();
    return querySnapshot.docs
        .map((doc) =>
            FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Achievement Operations
  Future<void> createAchievement(AchievementModel achievement) async {
    await FirebaseService.achievementsCollection
        .doc(achievement.achievementId)
        .set(achievement.toMap());
  }

  Future<List<AchievementModel>> getPlayerAchievements(String playerId) async {
    final querySnapshot = await FirebaseService.achievementsCollection
        .where('playerId', isEqualTo: playerId)
        .orderBy('unlockedAt', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) =>
            AchievementModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Team Operations
  Future<void> createTeam(TeamModel team) async {
    await FirebaseService.teamsCollection.doc(team.teamId).set(team.toMap());
  }

  Future<TeamModel?> getTeam(String teamId) async {
    final doc = await FirebaseService.teamsCollection.doc(teamId).get();
    if (doc.exists) {
      return TeamModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<TeamModel>> getTeamsStream() {
    return FirebaseService.teamsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> joinTeam(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'players': FieldValue.arrayUnion([playerId])
    });
  }

  Future<void> leaveTeam(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'players': FieldValue.arrayRemove([playerId])
    });
  }

  // Booking Operations
  Future<void> createBooking(BookingModel booking) async {
    await FirebaseService.bookingsCollection
        .doc(booking.bookingId)
        .set(booking.toMap());
  }

  Future<List<BookingModel>> getTurfBookings(String turfId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('turfId', isEqualTo: turfId)
        .orderBy('bookingDate', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> getPlayerBookings(String playerId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('playerId', isEqualTo: playerId)
        .orderBy('bookingDate', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
