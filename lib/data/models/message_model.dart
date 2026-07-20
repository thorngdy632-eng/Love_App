import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class ReplyInfo {
  final String messageId;
  final String? text;
  final String? imageUrl;
  final String senderName;
  final String senderId;

  const ReplyInfo({
    required this.messageId,
    this.text,
    this.imageUrl,
    required this.senderName,
    required this.senderId,
  });

  factory ReplyInfo.fromMap(Map<String, dynamic> map) {
    return ReplyInfo(
      messageId: map['messageId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      senderName: map['senderName'] ?? '',
      senderId: map['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    if (text != null) 'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'senderName': senderName,
    'senderId': senderId,
  };
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final String? imageBase64;
  final String uploadStatus;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, String> reactions;
  final DateTime? editedAt;
  final ReplyInfo? replyTo;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.imageUrl,
    this.imageBase64,
    this.uploadStatus = 'sent',
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.reactions = const {},
    this.editedAt,
    this.replyTo,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    final rawReactions = map['reactions'];
    Map<String, String> reactions = {};
    if (rawReactions is Map) {
      reactions = rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      imageBase64: map['imageBase64'],
      uploadStatus: map['uploadStatus'] ?? 'sent',
      type: (map['type'] == 'image') ? MessageType.image : MessageType.text,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      reactions: reactions,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      replyTo: map['replyTo'] != null ? ReplyInfo.fromMap(Map<String, dynamic>.from(map['replyTo'])) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'uploadStatus': uploadStatus,
      'type': type == MessageType.image ? 'image' : 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      if (replyTo != null) 'replyTo': replyTo!.toMap(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    String? imageUrl,
    String? imageBase64,
    String? uploadStatus,
    MessageType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, String>? reactions,
    DateTime? editedAt,
    ReplyInfo? replyTo,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      editedAt: editedAt ?? this.editedAt,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
