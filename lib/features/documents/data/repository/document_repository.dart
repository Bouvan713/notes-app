import 'dart:io';
import '../models/document_model.dart';
import '../services/local_document_service.dart';
import '../services/firestore_service.dart';

class DocumentRepository {
  final LocalDocumentService _localService;
  final FirestoreService _firestoreService;

  DocumentRepository({
    LocalDocumentService? localService,
    FirestoreService? firestoreService,
  })  : _localService = localService ?? LocalDocumentService(),
        _firestoreService = firestoreService ?? FirestoreService();

  // Fetch documents, priority to local, optionally synched from remote
  Future<List<DocumentModel>> getDocuments(String userId, {bool syncFromRemote = false}) async {
    final localDocs = await _localService.getAllLocalDocuments(userId);
    
    if (syncFromRemote) {
      try {
        final remoteDocs = await _firestoreService.getRemoteDocuments(userId);
        
        // Merge remote documents into local cache
        for (final rDoc in remoteDocs) {
          final matchingLocal = localDocs.where((l) => l.documentId == rDoc.documentId);
          if (matchingLocal.isEmpty) {
            // New remote document, save locally
            await _localService.saveDocumentLocally(rDoc.copyWith(isSynced: true));
          } else {
            final lDoc = matchingLocal.first;
            // If local has unsynced changes and is newer, do not overwrite. Otherwise overwrite
            if (!lDoc.isSynced && lDoc.updatedAt.isAfter(rDoc.updatedAt)) {
              continue;
            } else {
              await _localService.saveDocumentLocally(rDoc.copyWith(isSynced: true));
            }
          }
        }
        return await _localService.getAllLocalDocuments(userId);
      } catch (_) {
        return localDocs;
      }
    }
    return localDocs;
  }

  // Save new document
  Future<DocumentModel> saveDocument(DocumentModel doc, File imageFile) async {

    print('Harry Kratos = ${doc}');
    print('Harry Kratos UserId = ${doc.userId}');
    print('Harry Kratos DocID = ${doc.documentId}');
    // 1. Cache image locally
    final localPath = await _localService.saveImageLocally(imageFile, doc.documentId);
    var updatedDoc = doc.copyWith(localImagePath: localPath, isSynced: false);

    // 2. Save metadata locally
    await _localService.saveDocumentLocally(updatedDoc);

    // 3. Try to sync to remote
    try {
      updatedDoc = updatedDoc.copyWith(imageUrl: '', isSynced: true);

      // Update local and Firestore
      await _localService.saveDocumentLocally(updatedDoc);
      await _firestoreService.saveDocument(updatedDoc);
    } catch (e,st) {
      // Keep isSynced = false on error
      print('Harry Kratos = $e');
      print('Harry Kratos = $st');
    }

    return updatedDoc;
  }

  // Update existing document
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    final now = DateTime.now();
    var updatedDoc = doc.copyWith(updatedAt: now, isSynced: false, isEdited: true);
    
    // Update local cache
    await _localService.saveDocumentLocally(updatedDoc);

    // Try syncing to Firestore
    try {
      updatedDoc = updatedDoc.copyWith(isSynced: true);
      await _firestoreService.saveDocument(updatedDoc);
      await _localService.saveDocumentLocally(updatedDoc);
    } catch (_) {
      // Keep isSynced = false on error
    }
    
    return updatedDoc;
  }

  // Delete document
  Future<void> deleteDocument(String userId, String docId) async {
    await _localService.deleteDocumentLocally(docId);
    try {
      await _firestoreService.deleteDocument(userId, docId);
    } catch (_) {
      // Firestore will retry queue or it will be resolved later
    }
  }

  // Sync helper for background sync
  Future<DocumentModel> syncDocument(DocumentModel doc) async {
    if (doc.isSynced) return doc;
    
    var syncedDoc = doc;
    try {
      syncedDoc = syncedDoc.copyWith(isSynced: true);
      await _firestoreService.saveDocument(syncedDoc);
      await _localService.saveDocumentLocally(syncedDoc);
    } catch (e) {
      rethrow;
    }
    return syncedDoc;
  }
}
