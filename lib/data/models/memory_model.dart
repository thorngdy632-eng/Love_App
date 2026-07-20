import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime memoryDate;
  final String authorId;
  final DateTime createdAt;

  const MemoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.memoryDate,
    required this.authorId,
    required this.createdAt,
  });

  factory MemoryModel.fromMap(Map<String, dynamic> map, String id) {
    return MemoryModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      memoryDate: (map['memoryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorId: map['authorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'memoryDate': Timestamp.fromDate(memoryDate),
      'authorId': authorId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
