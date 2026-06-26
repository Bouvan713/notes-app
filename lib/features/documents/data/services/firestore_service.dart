import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userDocsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('documents');
  }

  // Save document to Firestore
  Future<void> saveDocument(DocumentModel doc) async {
    try {
      print('Harry Kratos = ${doc}');
      print('Harry Kratos UserId = ${doc.userId}');
      print('Harry Kratos DocID = ${doc.documentId}');
      await _userDocsRef(doc.userId).doc(doc.documentId).set(doc.toMap());
    } catch (e,st) {
      print('Harry Kratos = $e');
      print('Harry Kratos = $st');
      throw Exception('Failed to save document to cloud: ${e.toString()}');
    }
  }

  // Update document on Firestore
  Future<void> updateDocument(DocumentModel doc) async {
    try {
      await _userDocsRef(doc.userId).doc(doc.documentId).update(doc.toMap());
    } catch (e) {
      throw Exception('Failed to update document on cloud: ${e.toString()}');
    }
  }

  // Delete document from Firestore
  Future<void> deleteDocument(String userId, String docId) async {
    try {
      await _userDocsRef(userId).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document from cloud: ${e.toString()}');
    }
  }

  // Get remote documents
  Future<List<DocumentModel>> getRemoteDocuments(String userId) async {
    try {
      final snapshot = await _userDocsRef(userId).get();
      return snapshot.docs
          .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cloud documents: ${e.toString()}');
    }
  }
}
