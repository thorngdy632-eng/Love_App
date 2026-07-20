import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/chat_repository.dart';

class NotificationService {
  NotificationService._();

  static StreamSubscription<QuerySnapshot>? _listener;
  static final Set<String> _notifiedIds = {};

  static Future<void> init() async {}

  static Future<void> showNotification({required String title, required String body}) async {}

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
      Future.delayed(const Duration(seconds: 5), () {
        if (_listener != null) startListening(myUid);
      });
    });
  }

  static void stopListening() {
    _listener?.cancel();
    _listener = null;
  }

  static Future<void> clearBadge() async {}
}
