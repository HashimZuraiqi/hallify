import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // Alias for consistency
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isOrganizer => _currentUser?.isOrganizer ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  /// Initialize auth state
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Check if user is already signed in
      if (_authService.currentUser != null) {
        _currentUser = await _authService.getCurrentUserData();
        if (_currentUser != null) {
          _status = AuthStatus.authenticated;
          // Update FCM token
          await _updateFcmToken();
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Sign up
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      
      // Update FCM token
      await _updateFcmToken();
      
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      
      // Update FCM token
      await _updateFcmToken();
      
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
    String? profileImagePath, // Accept both URL and path
  }) async {
    if (_currentUser == null) return false;

    try {
      // Use profileImagePath if provided, otherwise use profileImageUrl
      final imageUrl = profileImagePath ?? profileImageUrl;
      
      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        name: name,
        phone: phone,
        profileImageUrl: imageUrl,
      );

      // Update local user data
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: imageUrl ?? _currentUser!.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount(String password) async {
    _errorMessage = null;

    try {
      await _authService.deleteAccount(password);
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update FCM token
  Future<void> _updateFcmToken() async {
    if (_currentUser == null) return;

    try {
      final token = await _notificationService.getToken();
      if (token != null) {
        await _authService.updateFcmToken(_currentUser!.uid, token);
        _currentUser = _currentUser!.copyWith(fcmToken: token);
      }

      // Listen for token refresh
      _notificationService.onTokenRefresh.listen((newToken) async {
        await _authService.updateFcmToken(_currentUser!.uid, newToken);
        _currentUser = _currentUser!.copyWith(fcmToken: newToken);
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    if (_authService.currentUserId == null) return;

    try {
      _currentUser = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
