import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/document_model.dart';

class LocalDocumentService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Directory> get _metadataDir async {
    final path = await _localPath;
    final dir = Directory('$path/documents/metadata');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> get _imagesDir async {
    final path = await _localPath;
    final dir = Directory('$path/documents/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveImageLocally(File imageFile, String docId) async {
    try {
      final imgDir = await _imagesDir;
      final fileExtension = imageFile.path.split('.').last;
      final localPath = '${imgDir.path}/$docId.$fileExtension';
      
      // If the destination file already exists, delete it first to overwrite clean
      final destFile = File(localPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }
      
      final savedFile = await imageFile.copy(localPath);
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  Future<void> saveDocumentLocally(DocumentModel doc) async {
    try {
      final metaDir = await _metadataDir;
      final file = File('${metaDir.path}/${doc.documentId}.json');
      await file.writeAsString(jsonEncode(doc.toJson()));
    } catch (e) {
      throw Exception('Failed to cache document locally: $e');
    }
  }

  Future<DocumentModel?> getDocumentLocally(String docId) async {
    try {
      final metaDir = await _metadataDir;
      final file = File('${metaDir.path}/$docId.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return DocumentModel.fromJson(jsonDecode(content));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<DocumentModel>> getAllLocalDocuments(String userId) async {
    try {
      final metaDir = await _metadataDir;
      final List<DocumentModel> docs = [];
      final List<FileSystemEntity> files = metaDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final doc = DocumentModel.fromJson(jsonDecode(content));
            if (doc.userId == userId) {
              docs.add(doc);
            }
          } catch (_) {
            // Skip corrupted JSON files
          }
        }
      }
      // Sort descending by createdAt
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteDocumentLocally(String docId) async {
    try {
      final metaDir = await _metadataDir;
      final file = File('${metaDir.path}/$docId.json');
      if (await file.exists()) {
        await file.delete();
      }
      
      // Also delete matching local image file
      final imgDir = await _imagesDir;
      final dirList = imgDir.listSync();
      for (final item in dirList) {
        if (item is File && item.path.split('/').last.startsWith(docId)) {
          await item.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete local document cache: $e');
    }
  }
}
