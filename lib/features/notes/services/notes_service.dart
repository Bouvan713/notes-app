import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/exceptions.dart';
import '../models/note_model.dart';

class NotesService {
  final FirebaseFirestore _firestore;

  NotesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of notes filtered by userId and sorted client-side to prevent composite index limits
  Stream<List<NoteModel>> getNotesStream(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort descending by createdAt
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Create Note
  Future<void> addNote(String userId, String title, String description) async {
    try {
      final newDoc = _firestore.collection('notes').doc();
      final now = Timestamp.now();
      
      final note = NoteModel(
        id: newDoc.id,
        userId: userId,
        title: title,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      await newDoc.set(note.toMap());
    } on FirebaseException catch (e) {
      throw NotesException(e.message ?? 'Failed to save note.', e.code);
    } catch (e) {
      throw NotesException(e.toString());
    }
  }

  // Update Note
  Future<void> updateNote(String noteId, String title, String description) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'title': title,
        'description': description,
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw NotesException(e.message ?? 'Failed to update note.', e.code);
    } catch (e) {
      throw NotesException(e.toString());
    }
  }

  // Delete Note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
    } on FirebaseException catch (e) {
      throw NotesException(e.message ?? 'Failed to delete note.', e.code);
    } catch (e) {
      throw NotesException(e.toString());
    }
  }
}
