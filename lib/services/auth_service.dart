import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    try {
      // Create user with Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user model
      final UserModel user = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
      );

      // Save user to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      // Update display name (do this after Firestore to avoid platform channel issues)
      try {
        await credential.user!.updateDisplayName(name);
      } catch (e) {
        // Ignore display name update errors
        print('Failed to update display name: $e');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in - this may throw a platform channel error internally
      try {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } catch (signInError) {
        // Ignore platform channel errors if authentication actually succeeded
        print('Sign in platform error (may be harmless): $signInError');
      }

      // Give Firebase a moment to update auth state
      await Future.delayed(const Duration(milliseconds: 200));

      // Check if we're actually signed in now
      if (_auth.currentUser == null) {
        throw Exception('Authentication failed');
      }

      final uid = _auth.currentUser!.uid;
      print('Successfully signed in with UID: $uid');

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        print('User document not found, creating default profile...');
        final defaultUser = UserModel(
          uid: uid,
          name: email.split('@')[0],
          email: email.trim(),
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );
        
        await _firestore
            .collection('users')
            .doc(uid)
            .set(defaultUser.toMap());
        
        return defaultUser;
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Final sign in error: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': Timestamp.now(),
      };

      if (name != null) {
        updates['name'] = name.trim();
        await currentUser?.updateDisplayName(name.trim());
      }
      if (phone != null) updates['phone'] = phone.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail if token update fails
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
