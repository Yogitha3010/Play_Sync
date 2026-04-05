import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/game_constants.dart';
import '../models/player_profile_model.dart';
import '../models/turf_model.dart';
import '../models/match_model.dart';
import '../models/feedback_model.dart';
import '../models/team_model.dart';
import '../models/booking_model.dart';
import '../models/play_request_model.dart';
import '../models/app_notification_model.dart';
import 'firebase_service.dart';

class BookingConflictException implements Exception {
  final String message;

  BookingConflictException(this.message);

  @override
  String toString() => message;
}

class FirestoreService {
  String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  // Player Profile Operations
  Future<void> createPlayerProfile(PlayerProfileModel profile) async {
    await FirebaseService.playerProfilesCollection
        .doc(profile.userId)
        .set(profile.toMap());
  }

  Future<PlayerProfileModel?> getPlayerProfile(String userId) async {
    final doc = await FirebaseService.playerProfilesCollection
        .doc(userId)
        .get();
    if (doc.exists) {
      return PlayerProfileModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updatePlayerProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    updates['lastUpdated'] = DateTime.now().toIso8601String();
    await FirebaseService.playerProfilesCollection.doc(userId).update(updates);
  }

  Stream<PlayerProfileModel> streamPlayerProfile(String userId) {
    return FirebaseService.playerProfilesCollection
        .doc(userId)
        .snapshots()
        .map(
          (doc) =>
              PlayerProfileModel.fromMap(doc.data() as Map<String, dynamic>),
        );
  }

  // Turf Operations
  Future<void> createTurf(TurfModel turf) async {
    await FirebaseService.turfsCollection.doc(turf.turfId).set(turf.toMap());
  }

  Future<void> updateTurf(String turfId, Map<String, dynamic> updates) async {
    await FirebaseService.turfsCollection.doc(turfId).update(updates);
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
    Query query = FirebaseService.turfsCollection.where(
      'isActive',
      isEqualTo: true,
    );

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
          .where(
            (turf) =>
                turf.location.toLowerCase().contains(location.toLowerCase()),
          )
          .toList();
    }

    return turfs;
  }

  // Match Operations
  Future<void> createMatch(MatchModel match) async {
    await FirebaseService.matchesCollection
        .doc(match.matchId)
        .set(match.toMap());
  }

  Future<void> deleteMatch(String matchId) async {
    await FirebaseService.matchesCollection.doc(matchId).delete();
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

  Future<void> joinMatch(String matchId, String playerId) async {
    await FirebaseService.matchesCollection.doc(matchId).update({
      'players': FieldValue.arrayUnion([playerId]),
    });
  }

  Future<void> leaveMatch(String matchId, String playerId) async {
    await FirebaseService.matchesCollection.doc(matchId).update({
      'players': FieldValue.arrayRemove([playerId]),
    });
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

  Future<List<MatchModel>> getMatchesByGameAndStatus({
    required String gameType,
    required String status,
  }) async {
    final querySnapshot = await FirebaseService.matchesCollection
        .where('gameType', isEqualTo: gameType)
        .get();
    final matches = querySnapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((match) => match.matchStatus == status)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches;
  }

  Future<List<MatchModel>> getPlayerMatches(String playerId) async {
    final querySnapshot = await FirebaseService.matchesCollection
        .where('players', arrayContains: playerId)
        .limit(50)
        .get();
    final matches = querySnapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches;
  }

  Future<List<MatchModel>> getMatchesForTurfs(List<String> turfIds) async {
    if (turfIds.isEmpty) {
      return [];
    }

    final results = await Future.wait(
      turfIds.map(
        (turfId) => FirebaseService.matchesCollection
            .where('turfId', isEqualTo: turfId)
            .get(),
      ),
    );

    final matches = results
        .expand((snapshot) => snapshot.docs)
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return matches;
  }

  // Feedback Operations
  Future<void> createFeedback(FeedbackModel feedback) async {
    await FirebaseService.feedbackCollection
        .doc(feedback.feedbackId)
        .set(feedback.toMap());
  }

  Future<List<FeedbackModel>> getFeedbackForPlayer(String playerId) async {
    final querySnapshot = await FirebaseService.feedbackCollection
        .where('toUserId', isEqualTo: playerId)
        .get();
    final feedback = querySnapshot.docs
        .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return feedback;
  }

  Future<List<FeedbackModel>> getMatchFeedback(String matchId) async {
    final querySnapshot = await FirebaseService.feedbackCollection
        .where('matchId', isEqualTo: matchId)
        .get();
    return querySnapshot.docs
        .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hasSubmittedFeedback({
    required String matchId,
    required String fromUserId,
  }) async {
    final querySnapshot = await FirebaseService.feedbackCollection
        .where('matchId', isEqualTo: matchId)
        .where('fromUserId', isEqualTo: fromUserId)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> refreshPlayerRating(String playerId) async {
    final feedbacks = await getFeedbackForPlayer(playerId);
    final totalRatings = feedbacks.length;
    final avgRating = totalRatings == 0
        ? 0.0
        : feedbacks.fold<double>(0.0, (sum, item) => sum + item.rating) /
            totalRatings;
    final derivedSkillLevel = totalRatings == 0
        ? 5.0
        : (avgRating * 2).clamp(0.0, 10.0);

    await updatePlayerProfile(playerId, {
      'avgRating': avgRating,
      'rating': avgRating,
      'totalRatings': totalRatings,
      'skillLevel': derivedSkillLevel,
    });
  }

  Future<void> recordMatchResultForPlayer({
    required String playerId,
    required String gameType,
    required bool won,
    required bool tied,
  }) async {
    final profile = await getPlayerProfile(playerId);
    if (profile == null) {
      return;
    }

    final playedGames = {...profile.playedGames, gameType}.toList()..sort();
    await updatePlayerProfile(playerId, {
      'gamesPlayed': profile.gamesPlayed + 1,
      'totalWins': profile.totalWins + (won ? 1 : 0),
      'totalLosses': profile.totalLosses + (!won && !tied ? 1 : 0),
      'playedGames': playedGames,
    });
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
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUserId,
  }) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) {
      return false;
    }

    final querySnapshot = await FirebaseService.usersCollection
        .where('usernameLowercase', isEqualTo: normalized)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return true;
    }

    return querySnapshot.docs.first.id == excludingUserId;
  }

  Future<void> updateUsername({
    required String userId,
    required String username,
    String? name,
  }) async {
    final normalized = normalizeUsername(username);
    final isAvailable = await isUsernameAvailable(
      username,
      excludingUserId: userId,
    );

    if (!isAvailable) {
      throw Exception('That username is already taken.');
    }

    final userUpdates = <String, dynamic>{
      'username': username.trim(),
      'usernameLowercase': normalized,
    };
    final profileUpdates = <String, dynamic>{
      'username': username.trim(),
      'usernameLowercase': normalized,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    if (name != null && name.trim().isNotEmpty) {
      userUpdates['name'] = name.trim();
      profileUpdates['name'] = name.trim();
    }

    await FirebaseService.firestore.runTransaction((transaction) async {
      transaction.set(
        FirebaseService.usersCollection.doc(userId),
        userUpdates,
        SetOptions(merge: true),
      );
      transaction.set(
        FirebaseService.playerProfilesCollection.doc(userId),
        profileUpdates,
        SetOptions(merge: true),
      );
    });
  }

  Future<List<TeamModel>> getTeamsForPlayer(String playerId) async {
    final querySnapshot = await FirebaseService.teamsCollection
        .where('players', arrayContains: playerId)
        .get();
    return querySnapshot.docs
        .map(
          (doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> joinTeam(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'players': FieldValue.arrayUnion([playerId]),
      'joinRequests': FieldValue.arrayRemove([playerId]),
    });
  }

  Future<void> requestToJoinTeam(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'joinRequests': FieldValue.arrayUnion([playerId]),
    });
  }

  Future<void> approveTeamJoinRequest(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'players': FieldValue.arrayUnion([playerId]),
      'joinRequests': FieldValue.arrayRemove([playerId]),
    });
  }

  Future<void> rejectTeamJoinRequest(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'joinRequests': FieldValue.arrayRemove([playerId]),
    });
  }

  Future<void> leaveTeam(String teamId, String playerId) async {
    await FirebaseService.teamsCollection.doc(teamId).update({
      'players': FieldValue.arrayRemove([playerId]),
      'joinRequests': FieldValue.arrayRemove([playerId]),
    });
  }

  Future<List<PlayerProfileModel>> searchPlayers({
    String usernameQuery = '',
    String? gameType,
    int minMatches = 0,
    String? excludeUserId,
    int limit = 30,
  }) async {
    final normalizedQuery = normalizeUsername(usernameQuery);
    Query query = FirebaseService.playerProfilesCollection;
    if (gameType != null && gameType.isNotEmpty) {
      query = query.where('preferredSports', arrayContains: gameType);
    }

    final querySnapshot = await query.get();
    final players = querySnapshot.docs
        .map(
          (doc) => PlayerProfileModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .where((player) => player.userId != excludeUserId)
        .where((player) {
          final matchesOk = player.gamesPlayed >= minMatches;
          final gameOk = gameType == null ||
              gameType.isEmpty ||
              player.preferredSports.contains(gameType);
          final searchableName = (player.name ?? '').trim().toLowerCase();
          final searchableUsername = (player.username ?? '').trim().toLowerCase();
          final queryOk = normalizedQuery.isEmpty ||
              searchableName.contains(normalizedQuery) ||
              searchableUsername.contains(normalizedQuery);
          return matchesOk && gameOk && queryOk;
        })
        .toList()
      ..sort((a, b) {
        if (normalizedQuery.isNotEmpty) {
          final aName = (a.name ?? '').trim().toLowerCase();
          final bName = (b.name ?? '').trim().toLowerCase();
          final aStarts = aName.startsWith(normalizedQuery) ? 1 : 0;
          final bStarts = bName.startsWith(normalizedQuery) ? 1 : 0;
          if (aStarts != bStarts) {
            return bStarts.compareTo(aStarts);
          }
        }
        return b.avgRating.compareTo(a.avgRating);
      });

    return players.take(limit).toList();
  }

  Future<List<String>> getAvailableGameTypes() async {
    final turfSnapshot = await FirebaseService.turfsCollection.get();
    final gameTypes = <String>{};

    for (final doc in turfSnapshot.docs) {
      final turf = TurfModel.fromMap(doc.data() as Map<String, dynamic>);
      gameTypes.addAll(turf.gamesAvailable);
    }

    if (gameTypes.isEmpty) {
      return List<String>.from(GameConstants.supportedGames);
    }

    final games = gameTypes.toList()..sort();
    return games;
  }

  Future<void> createPlayRequest(PlayRequestModel request) async {
    await FirebaseService.playRequestsCollection
        .doc(request.requestId)
        .set(request.toMap());
  }

  Future<List<PlayRequestModel>> getIncomingPlayRequests(String userId) async {
    final snapshot = await FirebaseService.playRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .get();

    final requests = snapshot.docs
        .map((doc) => PlayRequestModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  Future<List<PlayRequestModel>> getOutgoingPlayRequests(String userId) async {
    final snapshot = await FirebaseService.playRequestsCollection
        .where('fromUserId', isEqualTo: userId)
        .get();

    final requests = snapshot.docs
        .map((doc) => PlayRequestModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  Future<void> updatePlayRequestStatus(
    String requestId,
    String status,
  ) async {
    final requestRef = FirebaseService.playRequestsCollection.doc(requestId);
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception('Play request not found.');
    }

    final request = PlayRequestModel.fromMap(
      requestDoc.data() as Map<String, dynamic>,
    );

    await requestRef.update({
      'status': status,
      'isReadBySender': false,
      'isReadByReceiver': true,
    });
  }

  Future<void> markIncomingRequestsAsRead(List<String> requestIds) async {
    if (requestIds.isEmpty) return;
    final batch = FirebaseService.firestore.batch();
    for (var id in requestIds) {
      batch.update(FirebaseService.playRequestsCollection.doc(id), {
        'isReadByReceiver': true,
      });
    }
    await batch.commit();
  }

  Future<void> markOutgoingRequestsAsRead(List<String> requestIds) async {
    if (requestIds.isEmpty) return;
    final batch = FirebaseService.firestore.batch();
    for (var id in requestIds) {
      batch.update(FirebaseService.playRequestsCollection.doc(id), {
        'isReadBySender': true,
      });
    }
    await batch.commit();
  }

  Stream<int> streamUnreadPlayRequestsCount(String userId) {
    final incomingStream = FirebaseService.playRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .where('isReadByReceiver', isEqualTo: false)
        .snapshots();

    final outgoingStream = FirebaseService.playRequestsCollection
        .where('fromUserId', isEqualTo: userId)
        .where('isReadBySender', isEqualTo: false)
        .snapshots();

    int incomingCount = 0;
    int outgoingCount = 0;
    
    // ignore: close_sinks
    late StreamController<int> controller;
    
    // We use a broadcast controller to prevent multiple subscriptions error
    controller = StreamController<int>.broadcast(
      onListen: () {
        incomingStream.listen((snapshot) {
          incomingCount = snapshot.docs.length;
          controller.add(incomingCount + outgoingCount);
        });

        outgoingStream.listen((snapshot) {
          outgoingCount = snapshot.docs.length;
          controller.add(incomingCount + outgoingCount);
        });
      },
    );

    return controller.stream;
  }


  Future<void> saveDeviceToken(String userId, String token) async {
    await FirebaseService.usersCollection.doc(userId).set({
      'userId': userId,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> removeDeviceToken(String userId, String token) async {
    await FirebaseService.usersCollection.doc(userId).set({
      'userId': userId,
      'fcmTokens': FieldValue.arrayRemove([token]),
      'lastTokenUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> createNotification(AppNotificationModel notification) async {
    await FirebaseService.notificationsCollection
        .doc(notification.notificationId)
        .set(notification.toMap());
  }

  Future<List<AppNotificationModel>> getNotificationsForUser(
    String userId,
  ) async {
    final snapshot = await FirebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final notifications = snapshot.docs
        .map(
          (doc) => AppNotificationModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  Stream<int> streamUnreadNotificationCount(String userId) {
    return FirebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] == false;
          }).length,
        );
  }

  Future<void> markNotificationsAsRead(String userId) async {
    final snapshot = await FirebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] == false) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  // Booking Operations
  Future<void> createBooking(
    BookingModel booking, {
    int maxBookingsPerSlot = 1,
  }) async {
    final normalizedDate = _normalizeBookingDate(booking.bookingDate);
    final normalizedSlot = _normalizeSlotTime(booking.slotTime);
    final slotDocId = _buildBookingSlotId(
      turfId: booking.turfId,
      gameType: booking.gameType,
      bookingDate: normalizedDate,
      slotTime: normalizedSlot,
    );

    final bookingMap = booking.toMap()
      ..['bookingId'] = booking.bookingId
      ..['bookingDate'] = normalizedDate.toIso8601String()
      ..['slotTime'] = normalizedSlot;

    final bookingRef = FirebaseService.bookingsCollection.doc(booking.bookingId);
    final slotRef = FirebaseService.bookingSlotsCollection.doc(slotDocId);

    await FirebaseService.firestore.runTransaction((transaction) async {
      final existingBooking = await transaction.get(bookingRef);
      if (existingBooking.exists) {
        throw BookingConflictException('This booking already exists.');
      }

      final existingSlot = await transaction.get(slotRef);
      final slotData = existingSlot.data() as Map<String, dynamic>?;
      final activeBookings = (slotData?['activeBookings'] ?? 0) as int;

      if (activeBookings >= maxBookingsPerSlot) {
        throw BookingConflictException(
          'This turf is already fully booked for ${booking.gameType} on ${normalizedSlot}.',
        );
      }

      transaction.set(slotRef, {
        'slotId': slotDocId,
        'turfId': booking.turfId,
        'gameType': booking.gameType,
        'bookingDate': normalizedDate.toIso8601String(),
        'slotTime': normalizedSlot,
        'activeBookings': activeBookings + 1,
        'maxBookings': maxBookingsPerSlot,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      transaction.set(bookingRef, bookingMap);
    });
  }

  Future<List<BookingModel>> getTurfBookings(String turfId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('turfId', isEqualTo: turfId)
        .get();
    final bookings = querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return bookings;
  }

  Future<List<BookingModel>> getPlayerBookings(String playerId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('playerId', isEqualTo: playerId)
        .get();
    final bookings = querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return bookings;
  }

  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('turfOwnerId', isEqualTo: ownerId)
        .get();
    final bookings = querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return bookings;
  }

  Future<BookingModel?> getMatchBooking(String matchId) async {
    final querySnapshot = await FirebaseService.bookingsCollection
        .where('matchId', isEqualTo: matchId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final bookings = querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookings.first;
  }

  Future<void> deleteBooking(String bookingId) async {
    final bookingRef = FirebaseService.bookingsCollection.doc(bookingId);

    await FirebaseService.firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      if (!bookingSnapshot.exists) {
        return;
      }

      final booking = BookingModel.fromMap(
        bookingSnapshot.data() as Map<String, dynamic>,
      );
      final normalizedDate = _normalizeBookingDate(booking.bookingDate);
      final normalizedSlot = _normalizeSlotTime(booking.slotTime);
      final slotRef = FirebaseService.bookingSlotsCollection.doc(
        _buildBookingSlotId(
          turfId: booking.turfId,
          gameType: booking.gameType,
          bookingDate: normalizedDate,
          slotTime: normalizedSlot,
        ),
      );

      final slotSnapshot = await transaction.get(slotRef);
      if (slotSnapshot.exists) {
        final slotData = slotSnapshot.data() as Map<String, dynamic>?;
        final activeBookings = (slotData?['activeBookings'] ?? 0) as int;
        final updatedCount = activeBookings > 0 ? activeBookings - 1 : 0;

        if (updatedCount == 0) {
          transaction.delete(slotRef);
        } else {
          transaction.update(slotRef, {
            'activeBookings': updatedCount,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      transaction.delete(bookingRef);
    });
  }

  Future<void> rescheduleBooking(
    BookingModel booking, {
    required DateTime newBookingDate,
    required String newSlotTime,
    int maxBookingsPerSlot = 1,
  }) async {
    final oldDate = _normalizeBookingDate(booking.bookingDate);
    final oldSlot = _normalizeSlotTime(booking.slotTime);
    final newDate = _normalizeBookingDate(newBookingDate);
    final normalizedNewSlot = _normalizeSlotTime(newSlotTime);

    final oldSlotRef = FirebaseService.bookingSlotsCollection.doc(
      _buildBookingSlotId(
        turfId: booking.turfId,
        gameType: booking.gameType,
        bookingDate: oldDate,
        slotTime: oldSlot,
      ),
    );
    final newSlotRef = FirebaseService.bookingSlotsCollection.doc(
      _buildBookingSlotId(
        turfId: booking.turfId,
        gameType: booking.gameType,
        bookingDate: newDate,
        slotTime: normalizedNewSlot,
      ),
    );
    final bookingRef = FirebaseService.bookingsCollection.doc(booking.bookingId);

    await FirebaseService.firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      if (!bookingSnapshot.exists) {
        throw BookingConflictException('This booking no longer exists.');
      }

      final sameSlot =
          _isSameBookingDay(oldDate, newDate) && oldSlot == normalizedNewSlot;

      if (!sameSlot) {
        final newSlotSnapshot = await transaction.get(newSlotRef);
        final newSlotData = newSlotSnapshot.data() as Map<String, dynamic>?;
        final newActiveBookings = (newSlotData?['activeBookings'] ?? 0) as int;

        if (newActiveBookings >= maxBookingsPerSlot) {
          throw BookingConflictException(
            'This turf is already fully booked for ${booking.gameType} on ${normalizedNewSlot}.',
          );
        }

        final oldSlotSnapshot = await transaction.get(oldSlotRef);
        if (oldSlotSnapshot.exists) {
          final oldSlotData = oldSlotSnapshot.data() as Map<String, dynamic>?;
          final oldActiveBookings = (oldSlotData?['activeBookings'] ?? 0) as int;
          final updatedOldCount = oldActiveBookings > 0 ? oldActiveBookings - 1 : 0;

          if (updatedOldCount == 0) {
            transaction.delete(oldSlotRef);
          } else {
            transaction.update(oldSlotRef, {
              'activeBookings': updatedOldCount,
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        }

        transaction.set(newSlotRef, {
          'slotId': newSlotRef.id,
          'turfId': booking.turfId,
          'gameType': booking.gameType,
          'bookingDate': newDate.toIso8601String(),
          'slotTime': normalizedNewSlot,
          'activeBookings': newActiveBookings + 1,
          'maxBookings': maxBookingsPerSlot,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      transaction.update(bookingRef, {
        'bookingDate': newDate.toIso8601String(),
        'slotTime': normalizedNewSlot,
      });
    });
  }

  String _buildBookingSlotId({
    required String turfId,
    required String gameType,
    required DateTime bookingDate,
    required String slotTime,
  }) {
    final safeGameType = _slugify(gameType);
    final safeSlot = _slugify(slotTime);
    final dateKey =
        '${bookingDate.year.toString().padLeft(4, '0')}${bookingDate.month.toString().padLeft(2, '0')}${bookingDate.day.toString().padLeft(2, '0')}';

    return '${turfId}_${safeGameType}_${dateKey}_$safeSlot';
  }

  DateTime _normalizeBookingDate(DateTime bookingDate) {
    return DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
  }

  bool _isSameBookingDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _normalizeSlotTime(String slotTime) {
    final parts = slotTime.split('-');
    if (parts.length != 2) {
      return slotTime.trim();
    }

    final start = _normalizeTimeLabel(parts[0]);
    final end = _normalizeTimeLabel(parts[1]);
    return '$start - $end';
  }

  String _normalizeTimeLabel(String value) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(value);
    if (match == null) {
      return value.trim();
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return value.trim();
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
