import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../data/repository/document_repository.dart';
import 'document_provider.dart';

class SyncProvider extends ChangeNotifier {
  final DocumentRepository _repository;
  DocumentProvider? _documentProvider;

  bool _isSyncing = false;
  String? _syncStatusMessage;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;

  SyncProvider(this._repository) {
    _initConnectivityListener();
  }

  // Getters
  bool get isSyncing => _isSyncing;
  String? get syncStatusMessage => _syncStatusMessage;
  bool get isOnline => _isOnline;

  void updateDocumentProvider(DocumentProvider provider) {
    _documentProvider = provider;
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> resultsList) {
      final hasConnection = resultsList.any((result) => result != ConnectivityResult.none);
      _isOnline = hasConnection;
      notifyListeners();

      if (hasConnection) {
        triggerBackgroundSync();
      }
    });

    Connectivity().checkConnectivity().then((List<ConnectivityResult> resultsList) {
      final hasConnection = resultsList.any((result) => result != ConnectivityResult.none);
      _isOnline = hasConnection;
      notifyListeners();
    });
  }

  Future<void> triggerBackgroundSync() async {
    if (_isSyncing || !_isOnline || _documentProvider == null) return;

    // Retrieve active userId from document list if available, or keep static check
    final userId = _documentProvider!.documents.isNotEmpty 
        ? _documentProvider!.documents.first.userId 
        : null;

    if (userId == null) return;

    _isSyncing = true;
    _syncStatusMessage = 'Syncing offline documents...';
    notifyListeners();

    try {
      final localDocs = await _repository.getDocuments(userId);
      final unsyncedDocs = localDocs.where((doc) => !doc.isSynced).toList();

      if (unsyncedDocs.isNotEmpty) {
        int successCount = 0;
        for (final doc in unsyncedDocs) {
          try {
            _syncStatusMessage = 'Syncing ${successCount + 1}/${unsyncedDocs.length} documents...';
            notifyListeners();

            final syncedDoc = await _repository.syncDocument(doc);
            _documentProvider?.updateLocalDocument(syncedDoc);
            successCount++;
          } catch (_) {
            // Silently continue syncing other files if one fails
          }
        }
        
        _syncStatusMessage = 'Successfully synced $successCount documents!';
      } else {
        _syncStatusMessage = 'All documents are up to date.';
      }
    } catch (_) {
      _syncStatusMessage = 'Sync failed. Will retry later.';
    } finally {
      _isSyncing = false;
      notifyListeners();
      
      // Auto-clear success messages after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _syncStatusMessage = null;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
