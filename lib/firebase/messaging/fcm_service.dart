// lib/firebase/messaging/fcm_service.dart
//
// T-19: FCMService + Push Notification
// Blueprint:
//   initialize()       → permission request + token → Firestore güncelle
//   getToken()         → users/{uid}/profile.fcmToken kaydet
//   onMessage          → FlutterLocalNotifications (foreground)
//   onMessageOpenedApp → /study_zone deep link
//
// Bağımlılıklar: T-15 FirebaseAuth, T-14 DI
// pubspec.yaml:
//   firebase_messaging: ^15.0.0
//   flutter_local_notifications: ^19.0.0  (zaten mevcut — pubspec.lock'ta var)

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background message handler — top-level function (FCM requirement) ─────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background'da gelen mesajları işle — UI update yok
  debugPrint('FCM background: ${message.messageId}');
}

/// FCM token yönetimi, foreground bildirim gösterimi ve deep link navigasyonu.
///
/// Kullanım (DI):
///   getIt.registerSingletonAsync<FCMService>(() async {
///     final service = FCMService(...);
///     await service.initialize();
///     return service;
///   });
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

  // Stream: tap ile gelen route'u dışarı ilet
  final _navigationController = StreamController<String>.broadcast();
  Stream<String> get onNavigate => _navigationController.stream;

  static const _channelId = 'provocalai_main';
  static const _channelName = 'ProVocabAI Notifications';

  // ── Public API ────────────────────────────────────────────────────────────

  /// FCM'yi başlat: permission → token → listener'lar.
  /// main.dart'ta `await configureDependencies()` sonrasında çağrılır.
  Future<void> initialize() async {
    // 1. Background handler kaydı (top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. iOS/macOS permission request
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

    // 3. Local notifications kanalını kur (Android)
    await _initLocalNotifications();

    // 4. Token al ve Firestore'a kaydet
    await _fetchAndSaveToken();

    // 5. Token yenilendiğinde güncelle
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 6. Foreground mesaj listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Bildirime tıklanınca (app arka planda veya kapalıyken)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. App notification ile açıldıysa (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Güncel FCM token'ı döndür.
  Future<String?> getToken() => _messaging.getToken();

  void dispose() {
    _navigationController.close();
  }

  /// Test amacıyla onNavigate stream'e event ekle.
  @visibleForTesting
  void addNavigationEvent(String route) {
    _navigationController.add(route);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // zaten FCM'den istendi
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

    // Android notification channel
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

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .doc('users/$uid/profile/main')
        .set({'fcmToken': token}, SetOptions(merge: true));
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
