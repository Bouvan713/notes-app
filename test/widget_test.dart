import 'package:flutter_test/flutter_test.dart';
import 'package:notes_manager/features/auth/models/user_model.dart';
import 'package:notes_manager/features/documents/data/models/document_model.dart';

void main() {
  group('UserModel Tests', () {
    test('should serialize to and from Firestore map', () {
      final user = UserModel(
        id: 'user_123',
        name: 'John Doe',
        email: 'john@example.com',
      );

      final map = user.toMap();
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');

      final deserialized = UserModel.fromMap(map, 'user_123');
      expect(deserialized.id, 'user_123');
      expect(deserialized.name, 'John Doe');
      expect(deserialized.email, 'john@example.com');
    });
  });

  group('DocumentModel Tests', () {
    test('should copyWith matching attributes', () {
      final now = DateTime.now();
      final doc = DocumentModel(
        documentId: 'doc_1',
        userId: 'user_123',
        documentType: 'invoice',
        rawText: 'mock invoice text',
        parsedFields: {'invoiceNo': 'INV-100'},
        imageUrl: '',
        localImagePath: '',
        createdAt: now,
        updatedAt: now,
        isEdited: false,
        isSynced: false,
      );

      final updated = doc.copyWith(documentType: 'receipt');
      expect(updated.documentId, 'doc_1');
      expect(updated.documentType, 'receipt');
      expect(updated.rawText, 'mock invoice text');
    });
  });
}
