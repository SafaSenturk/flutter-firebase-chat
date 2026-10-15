import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/chat_repository.dart';

/// Runs in its own isolate when a push arrives while the app is closed.
/// Notification payloads are shown by the system, so nothing else is needed.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Push notifications (FCM) plus local notifications for new messages.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  String? _token;

  /// Fired with a chat id when the user taps a notification.
  final _taps = StreamController<String>.broadcast();
  Stream<String> get taps => _taps.stream;

  static const _channel = AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'New chat messages',
    importance: Importance.high,
  );

  Future<void> init() async {
    await _local.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final chatId? when chatId.isNotEmpty) _taps.add(chatId);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    // Tapping a system notification while the app is in the background…
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush);
    // …or when it launched the app.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _openFromPush(initial);
  }

  void _openFromPush(RemoteMessage m) {
    final chatId = m.data['chatId'] as String?;
    if (chatId != null) _taps.add(chatId);
  }

  /// Asks for permission and keeps this device's token on the user's profile,
  /// so a backend (see `functions/`) can push to it.
  Future<void> registerDevice(String uid, ChatRepository repo) async {
    try {
      await _messaging.requestPermission();
      // Registration tokens are what the Admin SDK's send() targets today; the
      // newer FID-based register()/onRegistered API can replace this later.
      // ignore: deprecated_member_use
      _token = await _messaging.getToken();
      if (_token != null) await repo.addPushToken(uid, _token!);
      await _tokenSub?.cancel();
      // ignore: deprecated_member_use
      _tokenSub = _messaging.onTokenRefresh.listen((t) {
        _token = t;
        repo.addPushToken(uid, t);
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> unregisterDevice(String uid, ChatRepository repo) async {
    await _tokenSub?.cancel();
    final t = _token;
    if (t != null) {
      try {
        await repo.removePushToken(uid, t);
      } catch (_) {}
    }
  }

  /// One notification per chat: a newer message replaces the older one.
  Future<void> showMessage({required String chatId, required String title, required String body}) =>
      _local.show(
        id: chatId.hashCode,
        title: title,
        body: body,
        payload: chatId,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            color: const Color(0xFF0FB9A0),
          ),
        ),
      );
}
