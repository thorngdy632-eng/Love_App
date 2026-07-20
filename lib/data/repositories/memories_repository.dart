import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/image_resizer.dart';
import '../../core/services/storage_service.dart';
import '../models/memory_model.dart';

class MemoriesRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  MemoriesRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _memoriesRef => _firestore.collection('memories');

  Stream<List<MemoryModel>> memoriesStream({int limit = 50}) {
    return _memoriesRef
        .orderBy('memoryDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MemoryModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addMemory({
    required String title,
    required String description,
    required Uint8List imageBytes,
    required DateTime memoryDate,
    required String authorId,
    String? imageExtension,
  }) async {
    final resized = await ImageResizer.resizeGallery(imageBytes);
    final b64 = _storage.encodeImage(resized);

    await _memoriesRef.add(
      MemoryModel(
        id: '',
        title: title,
        description: description,
        imageUrl: b64,
        memoryDate: memoryDate,
        authorId: authorId,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> deleteMemory(String id) async {
    await _memoriesRef.doc(id).delete();
  }
}
