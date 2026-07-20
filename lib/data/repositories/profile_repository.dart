import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/image_resizer.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  ProfileRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!, uid) : null,
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, uid) : null;
  }

  Future<void> updateBio({required String uid, required String bio}) async {
    await _firestore.collection('users').doc(uid).update({'bio': bio});
  }

  Future<void> updateProfileImage({required String uid, required Uint8List imageBytes, String? imageExtension}) async {
    final resized = await ImageResizer.resizeProfile(imageBytes);
    final b64 = _storage.encodeImage(resized);
    await _firestore.collection('users').doc(uid).set({'profileImageUrl': b64}, SetOptions(merge: true));
  }

  Future<void> updateName({required String uid, required String name}) async {
    await _firestore.collection('users').doc(uid).update({'name': name});
  }
}
