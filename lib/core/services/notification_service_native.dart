import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/chat_repository.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'messages_channel';
  static int _unreadCount = 0;
  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot>? _listener;
  static final Set<String> _notifiedIds = {};

  static Future<void> init() async {
    if (kIsWeb) return;

    // Request runtime permission on Android 13+ (API 33).
    // The manifest already declares POST_NOTIFICATIONS.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'សារថ្មី',
            description: 'ការជូនដំណឹងនៅពេលមានសារថ្មី',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {}

  static Future<void> showNotification({required String title, required String body}) async {
    if (!_initialized) return;
    _unreadCount++;
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'សារថ្មី',
      channelDescription: 'ការជូនដំណឹងនៅពេលមានសារថ្មី',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    final iosDetails = DarwinNotificationDetails(badgeNumber: _unreadCount);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Start listening for new chat messages from the partner.
  /// Only fires notifications for messages received AFTER this listener
  /// starts — the initial snapshot of existing unread messages is
  /// intentionally skipped to avoid flooding the user.
  static void startListening(String myUid) {
    _listener?.cancel();
    bool isFirstSnapshot = true;

    _listener = FirebaseFirestore.instance
        .collection('chats')
        .doc(ChatRepository.chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: myUid)
        .snapshots()
        .listen((snapshot) async {
      // Skip every document in the initial snapshot (existing messages).
      // Only fire notifications for real-time additions that arrive after.
      if (isFirstSnapshot) {
        isFirstSnapshot = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      if (!enabled) return;

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final msgId = change.doc.id;
          if (!_notifiedIds.add(msgId)) continue;
          final data = change.doc.data();
          if (data != null) {
            final type = data['type'] ?? 'text';
            final senderName = data['senderName'] ?? '';
            final isImage = type == 'image';
            showNotification(
              title: senderName,
              body: isImage ? 'បានផ្ញើរូបភាពមួយ' : (data['text'] ?? ''),
            );
          }
        }
      }
    }, onError: (e) {
      debugPrint('NotificationService listener error: $e');
      // Schedule a retry after 5 seconds on error.
      Future.delayed(const Duration(seconds: 5), () {
        if (_listener != null) startListening(myUid);
      });
    });
  }

  static void stopListening() {
    _listener?.cancel();
    _listener = null;
  }

  static Future<void> clearBadge() async {
    _unreadCount = 0;
    if (!_initialized) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.cancelAll();
  }
}
