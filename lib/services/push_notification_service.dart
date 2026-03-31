import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/player_home_screen.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'play_requests',
    'Play Requests',
    description: 'Notifications for play request updates',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _messagingAvailable = true;
  String? _currentToken;
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) {
      _navigatorKey = navigatorKey;
      return;
    }

    _navigatorKey = navigatorKey;

    if (kIsWeb) {
      _messagingAvailable = false;
      _initialized = true;
      return;
    }

    try {
      await _configureLocalNotifications();
      await _requestPermissions();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage);
        });
      }

      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) async {
        if (user == null || !_messagingAvailable) {
          return;
        }
        await _syncTokenForUser(user.uid);
      });

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
        _currentToken = token;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestoreService.saveDeviceToken(user.uid, token);
        }
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _syncTokenForUser(currentUser.uid);
      }
    } on FirebaseException catch (e, stackTrace) {
      if (_shouldIgnoreMessagingError(e)) {
        _disableMessaging(e);
        debugPrint('Push notifications unavailable: ${e.code} ${e.message}');
        debugPrintStack(stackTrace: stackTrace);
      } else {
        rethrow;
      }
    }

    _initialized = true;
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_messagingAvailable) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = _currentToken ?? await _messaging.getToken();
      if (user != null && token != null && token.isNotEmpty) {
        await _firestoreService.removeDeviceToken(user.uid, token);
      }
    } on FirebaseException catch (e) {
      if (_shouldIgnoreMessagingError(e)) {
        _disableMessaging(e);
        return;
      }
      rethrow;
    }
  }

  Future<void> _syncTokenForUser(String userId) async {
    if (!_messagingAvailable) {
      return;
    }

    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      _currentToken = token;
      await _firestoreService.saveDeviceToken(userId, token);
    } on FirebaseException catch (e) {
      if (_shouldIgnoreMessagingError(e)) {
        _disableMessaging(e);
        return;
      }
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } on FirebaseException catch (e) {
      if (_shouldIgnoreMessagingError(e)) {
        _disableMessaging(e);
        return;
      }
      rethrow;
    }
  }

  Future<void> _configureLocalNotifications() async {
    if (kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _openRequestsTab();
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || kIsWeb) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'requests',
    );
  }

  bool _shouldIgnoreMessagingError(FirebaseException error) {
    if (error.plugin != 'firebase_messaging') {
      return false;
    }

    return error.code == 'permission-blocked' ||
        error.code == 'permission-default' ||
        error.code == 'unsupported-browser' ||
        error.code == 'notifications-blocked' ||
        error.code == 'token-subscribe-failed';
  }

  void _disableMessaging(FirebaseException _) {
    _messagingAvailable = false;
    _currentToken = null;
  }

  void _handleNotificationTap(RemoteMessage message) {
    final target = message.data['target'];
    if (target == 'requests') {
      _openRequestsTab();
    }
  }

  void _openRequestsTab() {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PlayerHomeScreen(initialIndex: 4),
      ),
      (route) => false,
    );
  }
}


