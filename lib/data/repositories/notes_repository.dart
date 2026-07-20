import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NotesRepository {
  final FirebaseFirestore _firestore;
  NotesRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notesRef => _firestore.collection('notes');

  Stream<List<NoteModel>> notesStream() {
    return _notesRef.orderBy('updatedAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => NoteModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> addNote({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    await _notesRef.add(
      NoteModel(
        id: '',
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    await _notesRef.doc(id).update(
          NoteModel(
            id: id,
            title: title,
            content: content,
            authorId: authorId,
            authorName: authorName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toMap(isUpdate: true),
        );
  }

  Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}
