import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;

  AuthViewModel(this._authService) {
    _monitorAuthState();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;

  // Listen to Auth state changes and sync user profile automatically
  void _monitorAuthState() {
    _authSubscription = _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      } else {
        try {
          _currentUser = await _authService.getUserProfile(firebaseUser.uid);
        } catch (e) {
          // If we fail to load profile, reset currentUser
          _currentUser = null;
          _errorMessage = e.toString();
        } finally {
          _isInitialized = true;
          notifyListeners();
        }
      }
    });
  }

  // Login action
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signIn(email, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Signup action
  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signUp(name, email, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout action
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Clear current error state
  void _clearError() {
    _errorMessage = null;
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
