// lib/firebase/messaging/fcm_service.dart
//
// FAZ 6 FIX:
//   - Token'ı hem users/{uid} (root) hem users/{uid}/profile/main'e yaz
//   - Cloud Functions artık root dokümanı okuyor (FAZ 4 leaderboard ile uyumlu)
//   - onTokenRefresh → dual write

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background message handler — top-level function (FCM requirement) ─────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class FCMService {
  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _localNotifications;

  final _navigationController = StreamController<String>.broadcast();
  Stream<String> get onNavigate => _navigationController.stream;

  static const _channelId = 'provocalai_main';
  static const _channelName = 'ProVocabAI Notifications';

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied');
      return;
    }

    await _initLocalNotifications();
    await _fetchAndSaveToken();

    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  void dispose() {
    _navigationController.close();
  }

  @visibleForTesting
  void addNavigationEvent(String route) {
    _navigationController.add(route);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _navigationController.add(payload);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Vocabulary study reminders and streak alerts',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _fetchAndSaveToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  /// FAZ 6: Token dual-write — root users/{uid} + profile dokümanı
  ///
  /// Cloud Functions (sendDailyReminders, sendStreakReminder):
  ///   - Root dokümanı okur (FAZ 4'teki leaderboard yapısıyla uyumlu)
  ///   - Profile dokümanı da okunabilir (eski uyumluluk)
  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _firestore.batch();

      // Root doküman — Cloud Functions buradan okur
      batch.set(
        _firestore.doc('users/$uid'),
        {'fcmToken': token},
        SetOptions(merge: true),
      );

      // Profile doküman — eski uyumluluk
      batch.set(
        _firestore.doc('users/$uid/profile/main'),
        {'fcmToken': token},
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final route = message.data['route'] as String? ?? '/study_zone';

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: route,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String? ?? '/study_zone';
    _navigationController.add(route);
  }
}
