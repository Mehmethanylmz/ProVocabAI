import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final _messages = [
    'Bugünkü {COUNT} kelimelik seansın seni bekliyor. Öğrenmeye hazır mısın?',
    'Günlük hedefini unutma! {COUNT} kelime çalışılmayı bekliyor.',
    'Zaman ayırma vakti! Bugünkü {COUNT} kelimelik dersine başla.',
    'İngilizce hazineni genişlet! {COUNT} yeni kelime seni bekliyor.',
  ];

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
    tz.initializeTimeZones();
  }

  static Future<void> scheduleDailyNotification(
    int wordCount,
    TimeOfDay time,
  ) async {
    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final randomMessage = _messages[Random().nextInt(_messages.length)]
        .replaceAll('{COUNT}', wordCount.toString());

    await _notifications.zonedSchedule(
      0,
      'Kelime Zamanı!',
      randomMessage,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_word_reminder_channel',
          'Günlük Hatırlatıcı',
          channelDescription: 'Günlük kelime öğrenme seansını hatırlatır.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
