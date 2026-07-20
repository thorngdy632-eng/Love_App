import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPhotoModel {
  final String id;
  final String imageUrl;
  final String uploaderId;
  final DateTime createdAt;

  const GalleryPhotoModel({
    required this.id,
    required this.imageUrl,
    required this.uploaderId,
    required this.createdAt,
  });

  factory GalleryPhotoModel.fromMap(Map<String, dynamic> map, String id) {
    return GalleryPhotoModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'uploaderId': uploaderId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
