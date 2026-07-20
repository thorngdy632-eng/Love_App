import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_resizer.dart';
import '../models/message_model.dart';

class ChatRepository {
  static String get chatRoomId => AppConstants.chatRoomId;

  final FirebaseFirestore _firestore;
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('chats').doc(AppConstants.chatRoomId).collection('messages');

  static const int pageSize = 50;

  /// Real-time stream of the most recent [pageSize] messages.
  /// The UI combines this with older pages loaded via [loadOlderMessages].
  Stream<List<MessageModel>> messagesStream() {
    return _messagesRef
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snap) {
          debugPrint('Messages loaded: ${snap.docs.length}');
          return snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList();
        });
  }

  Future<({List<MessageModel> messages, DocumentSnapshot? nextCursor})> loadOlderMessages({
    DocumentSnapshot? cursorDoc,
    int limit = pageSize,
  }) async {
    var query = _messagesRef.orderBy('createdAt', descending: true).limit(limit);
    if (cursorDoc != null) {
      query = query.startAfterDocument(cursorDoc);
    }
    final snap = await query.get();
    debugPrint(
      'loadOlderMessages: page=${snap.docs.length} cursorDoc=$cursorDoc',
    );
    return (
      messages: snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList(),
      nextCursor: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<DocumentSnapshot?> getMessageDoc(String messageId) async {
    try {
      return await _messagesRef.doc(messageId).get();
    } catch (e) {
      debugPrint('ChatRepo: getMessageDoc error: $e');
      return null;
    }
  }

  Future<void> sendTextMessage({
    required String senderId,
    required String senderName,
    required String text,
    ReplyInfo? replyTo,
  }) async {
    debugPrint('Firestore write: sendTextMessage senderId=$senderId text="${text.length > 50 ? '${text.substring(0, 50)}...' : text}"');
    await _messagesRef.add(
      MessageModel(
        id: '',
        senderId: senderId,
        senderName: senderName,
        text: text,
        type: MessageType.text,
        createdAt: DateTime.now(),
        replyTo: replyTo,
      ).toMap(),
    );
  }

  Future<void> sendImageMessage({
    required String senderId,
    required String senderName,
    required Uint8List imageBytes,
    String? imageExtension,
    ReplyInfo? replyTo,
  }) async {
    debugPrint('sendImageMessage: senderId=$senderId');

    // Fast path: if picker already returned small bytes (<512KB), encode directly.
    // Safe path: resize to 600px/45% to guarantee fit within 1 MiB Firestore limit.
    final imageBase64 = imageBytes.length < 524288
        ? base64Encode(imageBytes)
        : ImageResizer.resizeGalleryToBase64(imageBytes);
    final docRef = await _messagesRef.add({
      'senderId': senderId,
      'senderName': senderName,
      'imageBase64': imageBase64,
      'uploadStatus': 'sent',
      'type': 'image',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
    });
    debugPrint('sendImageMessage: base64 image written to Firestore — docId=${docRef.id}');

    // Fire background Storage upgrade (never awaited — silent, optional).
    unawaited(_upgradeToStorage(imageBytes, senderId, docRef));
  }

  Future<void> _upgradeToStorage(Uint8List imageBytes, String senderId, DocumentReference docRef) async {
    try {
      final resized = await ImageResizer.resizeGallery(imageBytes);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(senderId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      debugPrint('_upgradeToStorage: uploading ${resized.length} bytes to ${storageRef.fullPath}');
      await storageRef.putData(resized);
      final url = await storageRef.getDownloadURL();
      await docRef.update({
        'imageUrl': url,
        'imageBase64': FieldValue.delete(),
      });
      debugPrint('_upgradeToStorage: done');
    } catch (e) {
      debugPrint('_upgradeToStorage: skipped (base64 remains): $e');
    }
  }

  Future<void> updateMessage(String messageId, String newText) async {
    debugPrint('Firestore update: messageId=$messageId');
    await _messagesRef.doc(messageId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String messageId) async {
    debugPrint('Firestore delete: messageId=$messageId');
    await _messagesRef.doc(messageId).delete();
  }

  Future<void> toggleReaction(String messageId, String userId, String emoji) async {
    debugPrint('Firestore update: toggleReaction messageId=$messageId userId=$userId emoji=$emoji');
    await _firestore.runTransaction((transaction) async {
      final docRef = _messagesRef.doc(messageId);
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data()!;
      Map<String, dynamic> reactions = {};
      if (data['reactions'] is Map) {
        reactions = Map<String, dynamic>.from(data['reactions']);
      }

      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  Future<void> markMessagesAsRead(String myUid) async {
    final snapshot =
        await _messagesRef.where('senderId', isNotEqualTo: myUid).where('isRead', isEqualTo: false).limit(100).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
