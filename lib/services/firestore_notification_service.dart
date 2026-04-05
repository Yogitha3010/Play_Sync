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

  DateTime? _listenStartTime;
  final Set<String> _notifiedOutgoing = {};

  void startListening(String userId) {
    if (_isListening && _currentUserId == userId) return;

    // Stop any existing subscriptions
    stopListening();

    _listenStartTime = DateTime.now();
    _currentUserId = userId;
    _isListening = true;

    // Listener 1: Incoming Play Requests
    _incomingRequestsSubscription = FirebaseService.playRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewIncomingRequest(change.doc);
        }
      }
    });

    // Listener 2: Outgoing Play Requests Status Updates
    _outgoingRequestsSubscription = FirebaseService.playRequestsCollection
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
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
    _listenStartTime = null;
    _notifiedOutgoing.clear();
  }

  void _handleNewIncomingRequest(DocumentSnapshot doc) {
    if (!doc.exists) return;

    try {
      final data = doc.data() as Map<String, dynamic>;
      final request = PlayRequestModel.fromMap(data);

      if (request.status == 'pending' &&
          _listenStartTime != null &&
          request.createdAt.isAfter(_listenStartTime!)) {
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
      if (_notifiedOutgoing.contains(stateKey)) return;
      _notifiedOutgoing.add(stateKey);

      if (request.status == 'accepted' || request.status == 'rejected') {
        final title = request.status == 'accepted' ? 'Request Accepted!' : 'Request Rejected';
        final body = request.status == 'accepted'
            ? 'Your game request was accepted.'
            : 'Your game request has been rejected.';

        LocalNotificationService.instance.showNotification(
          id: request.requestId.hashCode + 1,
          title: title,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('Error parsing outgoing request update: $e');
    }
  }
}
