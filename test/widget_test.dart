import 'package:flutter_test/flutter_test.dart';
import 'package:notes_manager/features/auth/models/user_model.dart';
import 'package:notes_manager/features/notes/models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  group('NoteModel Tests', () {
    test('should copyWith matching attributes', () {
      final now = Timestamp.now();
      final note = NoteModel(
        id: 'note_1',
        userId: 'user_123',
        title: 'Initial Title',
        description: 'Initial Desc',
        createdAt: now,
        updatedAt: now,
      );

      final updated = note.copyWith(title: 'Updated Title');
      expect(updated.id, 'note_1');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Initial Desc');
    });
  });
}
