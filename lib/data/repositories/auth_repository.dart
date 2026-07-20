import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Thrown when credentials are valid Firebase-wise but the account
/// does not belong to one of the two authorized users.
class UnauthorizedUserException implements Exception {
  final String message;
  UnauthorizedUserException(this.message);
}

class AuthRepository {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth,
        _firestore = firestore;

  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get _firestoreInstance => _firestore ??= FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _authInstance.authStateChanges();

  User? get currentUser => _authInstance.currentUser;

  /// Resolves a raw identifier (email or phone number) typed by
  /// the user into the corresponding Firebase Auth email address.
  /// Returns null if the identifier does not match either authorized user.
  String? _resolveEmail(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      final lower = trimmed.toLowerCase();
      return AppConstants.authorizedUsersByEmail.containsKey(lower) ? lower : null;
    }
    // Normalize phone number: remove all non-digits, drop leading +855 or 855
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    String normalized;
    if (digits.startsWith('855') && digits.length > 9) {
      normalized = '0${digits.substring(3)}';
    } else if (digits.startsWith('0')) {
      normalized = digits;
    } else {
      normalized = '0$digits';
    }
    return AppConstants.phoneToEmail[normalized];
  }

  Future<UserModel> signIn({required String identifier, required String password}) async {
    final email = _resolveEmail(identifier);
    debugPrint('AuthRepository.signIn() identifier=$identifier → resolved=$email');
    if (email == null) {
      throw UnauthorizedUserException(KhmerText.unauthorizedUser);
    }

    try {
      await _authInstance.signInWithEmailAndPassword(email: email, password: password);
      final fbUser = _authInstance.currentUser;
      debugPrint('AuthRepository.signIn() FirebaseAuth succeeded — uid=${fbUser?.uid} email=${fbUser?.email}');
      if (fbUser != null) {
        await fbUser.getIdToken(true);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          throw UnauthorizedUserException(KhmerText.wrongCredentials);
        case 'operation-not-allowed':
          throw UnauthorizedUserException(
            'ការចូលដោយអ៊ីមែលមិនទាន់បើកទេ សូមបើកនៅក្នុង Firebase Console → Authentication → Sign-in method',
          );
        default:
          rethrow;
      }
    }

    final authorized = AppConstants.authorizedUsersByEmail[email];
    if (authorized == null) {
      await _authInstance.signOut();
      throw UnauthorizedUserException(KhmerText.unauthorizedUser);
    }

    // Single Firestore call: upsert with merge
    await _firestoreInstance.collection('users').doc(authorized.uid).set(
      {
        'uid': authorized.uid,
        'name': authorized.name,
        'email': authorized.email,
        'phone': authorized.phone,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Build model from constants to avoid a second read
    return UserModel(
      uid: authorized.uid,
      name: authorized.name,
      email: authorized.email,
      phone: authorized.phone,
      isOnline: true,
    );
  }

  Future<void> signOut() async {
    debugPrint('SignOut called');
    final email = _authInstance.currentUser?.email?.toLowerCase();
    final authorized = email != null ? AppConstants.authorizedUsersByEmail[email] : null;
    if (authorized != null) {
      try {
        await _firestoreInstance.collection('users').doc(authorized.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    await _authInstance.signOut();
    debugPrint('FirebaseAuth.signOut() completed');
  }

  Future<void> deleteAccount() async {
    final user = _authInstance.currentUser;
    if (user == null) return;
    final email = user.email?.toLowerCase();
    if (email != null) {
      final authorized = AppConstants.authorizedUsersByEmail[email];
      if (authorized != null) {
        await _firestoreInstance.collection('users').doc(authorized.uid).delete();
      }
    }
    await user.delete();
  }

  /// Returns the AuthorizedUser record (uid/name/etc) for the currently
  /// signed-in Firebase user, or null if not signed in / not authorized.
  AuthorizedUser? get currentAuthorizedUser {
    final email = _authInstance.currentUser?.email?.toLowerCase();
    if (email == null) return null;
    return AppConstants.authorizedUsersByEmail[email];
  }

  /// Returns the uid of the partner (the other authorized user).
  String? get partnerUid {
    final me = currentAuthorizedUser;
    if (me == null) return null;
    for (final u in AppConstants.authorizedUsersByEmail.values) {
      if (u.uid != me.uid) return u.uid;
    }
    return null;
  }

  /// Returns the display name of the partner from constants.
  String? get partnerName {
    final uid = partnerUid;
    if (uid == null) return null;
    return AppConstants.authorizedUsersByEmail.values
        .where((u) => u.uid == uid)
        .map((u) => u.name)
        .firstOrNull;
  }
}
