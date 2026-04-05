import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'local_notification_service.dart';
import '../models/play_request_model.dart';

class FirestoreNotificationService {
  FirestoreNotificationService._();
  static final FirestoreNotificationService instance = FirestoreNotificationService._();

  StreamSubscription<QuerySnapshot>? _incomingRequestsSubscription;
  StreamSubscription<QuerySnapshot>? _outgoingRequestsSubscription;

  bool _isListening = false;
  String? _currentUserId;

  final Set<String> _processedIncoming = {};
  final Set<String> _processedOutgoing = {};

  bool _isFirstIncoming = true;
  bool _isFirstOutgoing = true;

  void startListening(String userId) {
    if (_isListening && _currentUserId == userId) return;

    // Stop any existing subscriptions
    stopListening();

    _currentUserId = userId;
    _isListening = true;

    // Listener 1: Incoming Play Requests
    _incomingRequestsSubscription = FirebaseService.playRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (_isFirstIncoming) {
        _isFirstIncoming = false;
        // Populate cache without notifying
        for (var doc in snapshot.docs) {
          _processedIncoming.add(doc.id);
        }
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          if (!_processedIncoming.contains(change.doc.id)) {
            _processedIncoming.add(change.doc.id);
            _handleNewIncomingRequest(change.doc);
          }
        }
      }
    });

    // Listener 2: Outgoing Play Requests Status Updates
    _outgoingRequestsSubscription = FirebaseService.playRequestsCollection
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (_isFirstOutgoing) {
        _isFirstOutgoing = false;
        // Populate cache to avoid notifying about already accepted/rejected ones
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            _processedOutgoing.add('${doc.id}_$status');
          } catch (_) {}
        }
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleOutgoingRequestUpdate(change.doc);
        }
      }
    });
  }

  void stopListening() {
    _incomingRequestsSubscription?.cancel();
    _outgoingRequestsSubscription?.cancel();
    _incomingRequestsSubscription = null;
    _outgoingRequestsSubscription = null;
    _isListening = false;
    _currentUserId = null;
    _processedIncoming.clear();
    _processedOutgoing.clear();
    _isFirstIncoming = true;
    _isFirstOutgoing = true;
  }

  void _handleNewIncomingRequest(DocumentSnapshot doc) {
    if (!doc.exists) return;

    try {
      final data = doc.data() as Map<String, dynamic>;
      final request = PlayRequestModel.fromMap(data);

      if (request.status == 'pending') {
        LocalNotificationService.instance.showNotification(
          id: request.requestId.hashCode,
          title: 'New Game Request',
          body: 'Someone has sent you a game request!',
        );
      }
    } catch (e) {
      debugPrint('Error parsing incoming request: $e');
    }
  }

  void _handleOutgoingRequestUpdate(DocumentSnapshot doc) {
    if (!doc.exists) return;

    try {
      final data = doc.data() as Map<String, dynamic>;
      final request = PlayRequestModel.fromMap(data);
      
      final stateKey = '${doc.id}_${request.status}';
      if (_processedOutgoing.contains(stateKey)) {
        return; // We already notified about this exact status for this doc
      }
      _processedOutgoing.add(stateKey);

      // Check if it's accepted or rejected
      if (request.status == 'accepted' || request.status == 'rejected') {
        final title = request.status == 'accepted' ? 'Request Accepted!' : 'Request Rejected';
        final body = request.status == 'accepted'
            ? 'Your game request was accepted.'
            : 'Your game request has been rejected.';

        LocalNotificationService.instance.showNotification(
          id: request.requestId.hashCode + 1, // Offset ID so it doesn't clash with incoming
          title: title,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('Error parsing outgoing request update: $e');
    }
  }
}
