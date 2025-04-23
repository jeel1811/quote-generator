import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen for authentication state changes
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        // User is signed in
        _fetchUserData(firebaseUser.uid);
      } else {
        // User is signed out
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getUserData(uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      // Don't set user here, it will be handled by the auth state listener
      // This avoids setState during build issues
      return true;
    } catch (e) {
      _error = _getReadableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getReadableAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided for this user.';
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled.';
        default:
          return e.message ?? 'An unknown authentication error occurred.';
      }
    }
    return e.toString();
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      // Don't set user here, it will be handled by the auth state listener
      return true;
    } catch (e) {
      _error = _getReadableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      // Don't set user here, it will be handled by the auth state listener
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getReadableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUserSettings({
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) return;

    try {
      AppUser updatedUser = _user!.copyWith(
        isDarkMode: isDarkMode,
        notificationsEnabled: notificationsEnabled,
      );

      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
