import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/notes_service.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesService _notesService;

  bool _isLoading = false;
  String? _errorMessage;

  NotesViewModel(this._notesService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stop listening / reset state on logout
  void clearNotesState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Returns the raw stream for StreamProvider/StreamBuilder usage
  Stream<List<NoteModel>> getNotesStream(String userId) {
    return _notesService.getNotesStream(userId);
  }

  // Add Note
  Future<bool> addNote(String userId, String title, String description) async {
    _setLoading(true);
    _clearError();
    try {
      await _notesService.addNote(userId, title, description);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Note
  Future<bool> updateNote(String noteId, String title, String description) async {
    _setLoading(true);
    _clearError();
    try {
      await _notesService.updateNote(noteId, title, description);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete Note
  Future<bool> deleteNote(String noteId) async {
    _setLoading(true);
    _clearError();
    try {
      await _notesService.deleteNote(noteId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

}
