import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/exceptions.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of auth changes mapped to UserModel
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current Firebase user ID
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  // Retrieve user metadata from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } on FirebaseException catch (e) {
      throw AuthException(e.message ?? 'Failed to retrieve user profile.', e.code);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Sign in
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw AuthException('User profile data does not exist in database.');
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthErrorCode(e.code, e.message), e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Sign up
  Future<UserModel> signUp(String name, String email, String password) async {
    try {
      // 1. Create firebase user credential
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Prepare user model
      final newUser = UserModel(id: uid, name: name, email: email);

      // 3. Save details to Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthErrorCode(e.code, e.message), e.code);
    } on FirebaseException catch (e) {
      throw AuthException(e.message ?? 'Database saving failed.', e.code);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Logout failed. Please try again.');
    }
  }

  // Helper method to give developer/user friendly error messages
  String _mapAuthErrorCode(String code, String? defaultMessage) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return defaultMessage ?? 'An unknown authentication error occurred.';
    }
  }
}
