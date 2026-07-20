import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/image_resizer.dart';
import '../../core/services/storage_service.dart';
import '../models/gallery_photo_model.dart';

class GalleryRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  GalleryRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _galleryRef => _firestore.collection('gallery');

  Stream<List<GalleryPhotoModel>> galleryStream({int limit = 50}) {
    return _galleryRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => GalleryPhotoModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addPhoto({required Uint8List imageBytes, required String uploaderId, String? imageExtension}) async {
    final resized = await ImageResizer.resizeGallery(imageBytes);
    final b64 = _storage.encodeImage(resized);

    await _galleryRef.add(
      GalleryPhotoModel(id: '', imageUrl: b64, uploaderId: uploaderId, createdAt: DateTime.now()).toMap(),
    );
  }

  Future<void> deletePhoto(String id) async {
    await _galleryRef.doc(id).delete();
  }
}
