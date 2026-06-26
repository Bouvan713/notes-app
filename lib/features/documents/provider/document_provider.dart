import 'package:flutter/material.dart';
import '../data/models/document_model.dart';
import '../data/models/document_type.dart';
import '../data/repository/document_repository.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _repository;

  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  DocumentType? _filterType;
  String _sortBy = 'date_desc';

  DocumentProvider(this._repository);

  // Getters
  List<DocumentModel> get documents => _documents;
  List<DocumentModel> get filteredDocuments => _filteredDocuments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  DocumentType? get filterType => _filterType;
  String get sortBy => _sortBy;

  void clearState() {
    _documents = [];
    _filteredDocuments = [];
    _searchQuery = '';
    _filterType = null;
    _sortBy = 'date_desc';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Fetch documents
  Future<void> fetchDocuments(String userId, {bool syncFromRemote = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _repository.getDocuments(userId, syncFromRemote: syncFromRemote);
      _applyFiltersAndSort();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete document
  Future<bool> deleteDocument(String userId, String docId) async {
    _errorMessage = null;
    try {
      await _repository.deleteDocument(userId, docId);
      _documents.removeWhere((doc) => doc.documentId == docId);
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Handle local update reflecting sync edits
  void updateLocalDocument(DocumentModel updatedDoc) {
    final index = _documents.indexWhere((doc) => doc.documentId == updatedDoc.documentId);
    if (index != -1) {
      _documents[index] = updatedDoc;
    } else {
      _documents.add(updatedDoc);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Filters & Search setting methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilterType(DocumentType? type) {
    _filterType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortBy(String sortOption) {
    _sortBy = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Filtering, Searching and Sorting algorithm
  void _applyFiltersAndSort() {
    var list = List<DocumentModel>.from(_documents);

    // 1. Filter by Document Type
    if (_filterType != null) {
      list = list
          .where((doc) => doc.documentType.toLowerCase() == _filterType!.name.toLowerCase())
          .toList();
    }

    // 2. Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((doc) {
        final typeMatch = parseDocumentType(doc.documentType).displayName.toLowerCase().contains(query);
        final rawTextMatch = doc.rawText.toLowerCase().contains(query);
        
        final parsedFieldsMatch = doc.parsedFields.entries.any((entry) =>
            entry.key.toLowerCase().contains(query) ||
            entry.value.toLowerCase().contains(query));

        return typeMatch || rawTextMatch || parsedFieldsMatch;
      }).toList();
    }

    // 3. Sort
    switch (_sortBy) {
      case 'date_asc':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'type':
        list.sort((a, b) => a.documentType.compareTo(b.documentType));
        break;
      case 'name':
        list.sort((a, b) {
          final nameA = a.parsedFields['Name'] ??
              a.parsedFields['Vendor Name'] ??
              a.parsedFields['Store Name'] ??
              a.documentType;
          final nameB = b.parsedFields['Name'] ??
              b.parsedFields['Vendor Name'] ??
              b.parsedFields['Store Name'] ??
              b.documentType;
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });
        break;
      case 'date_desc':
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredDocuments = list;
  }
}
