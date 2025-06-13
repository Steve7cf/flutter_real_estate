import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Consider using a state management solution like Provider, Riverpod, or Bloc
// instead of ValueNotifier for more complex apps
ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  // Get user ID safely
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Email & Password Sign Up with email verification
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    bool sendVerification = true,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      if (sendVerification && result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred during sign up';
    }
  }

  // Email & Password Sign In
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred during sign in';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Error signing out: ${e.toString()}';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred while sending password reset email';
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw 'No user logged in or email already verified';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred while sending verification email';
    }
  }

  // Reload user to get updated email verification status
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (e) {
      throw 'Error reloading user data';
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      } else {
        throw 'No user logged in';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred while updating profile';
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'No user logged in';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred while updating password';
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithCredential({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw 'No user logged in';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred during re-authentication';
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw 'No user logged in';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unknown error occurred while deleting account';
    }
  }

  // Helper method to handle FirebaseAuthException
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Log in again.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      default:
        return e.message ?? 'An unknown Firebase error occurred.';
    }
  }
}

// Optional: Create a result wrapper for better error handling
class AuthResult {
  final User? user;
  final String? error;
  final bool success;

  AuthResult._({this.user, this.error, required this.success});

  factory AuthResult.success(User? user) {
    return AuthResult._(user: user, success: true);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(error: error, success: false);
  }
}

// Alternative AuthService with Result pattern (optional)
class AuthServiceWithResults {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get user => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('An unknown error occurred');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    // Same implementation as above
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      // ... other cases
      default:
        return e.message ?? 'An unknown Firebase error occurred.';
    }
  }
}