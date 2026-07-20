import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/anniversary_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepo = ProfileRepository();
  StreamSubscription<UserModel?>? _userSub;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  AuthProvider({AuthRepository? authRepository}) : _authRepository = authRepository ?? AuthRepository();

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get partnerUid => _authRepository.partnerUid;
  AuthRepository get repository => _authRepository;
  bool get initialized => _initialized;

  void _subscribeUser(String uid) {
    _userSub?.cancel();
    _userSub = _profileRepo.watchUser(uid).listen(
      (user) {
        _currentUser = user;
        if (user != null) {
          final authorized = _authRepository.currentAuthorizedUser;
          if (authorized != null && user.name != authorized.name) {
            _profileRepo.updateName(uid: uid, name: authorized.name);
          }
        }
        notifyListeners();
      },
      onError: (_) {
        notifyListeners();
      },
    );
    NotificationService.startListening(uid);
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('AuthProvider.init() started');

    // On Android/iOS, LOCAL persistence is already the default — do NOT
    // call setPersistence here.  Doing so can trigger a re-auth cycle on
    // some Android API levels, briefly nulling currentUser and causing
    // the session to appear lost.  On web the call is unsupported and
    // would throw, so we skip it entirely.
    //
    // Firebase Auth session survives app restart, phone restart, and
    // APK update automatically on all platforms.

    // Use authStateChanges ONLY for detecting real sign-outs (intentional
    // logout or token invalidation).  The initial event is unreliable on
    // Android because session restoration from encrypted storage is async.
    _authRepository.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        // Only act on null if we were previously authenticated.
        // Ignore transient null events during initialization (the SDK
        // may briefly null currentUser while restoring from disk).
        if (_status != AuthStatus.authenticated) {
          debugPrint('authStateChanges: null (ignored, status=$_status)');
          return;
        }
        debugPrint('authStateChanges: null (signed out)');
        _userSub?.cancel();
        _userSub = null;
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        NotificationService.stopListening();
        notifyListeners();
      } else {
        debugPrint('authStateChanges: uid=${firebaseUser.uid} email=${firebaseUser.email}');
        if (_status != AuthStatus.authenticated) {
          final authorized = _authRepository.currentAuthorizedUser;
          if (authorized != null) {
            _subscribeUser(authorized.uid);
            _status = AuthStatus.authenticated;
            notifyListeners();
            AnniversaryService.checkAndNotify(myUid: authorized.uid);
          } else if (firebaseUser.email != null) {
            debugPrint('authStateChanges: unauthorized user, signing out');
            _status = AuthStatus.unauthenticated;
            notifyListeners();
            FirebaseAuth.instance.signOut();
          }
        }
      }
    });

    // Poll for currentUser to become available.
    // On Android, after a cold start, the SDK needs to read the encrypted
    // session from disk — this is asynchronous.  We poll up to 10 times
    // (× 300 ms = 3 seconds total) to wait for it.
    User? fbUser;
    for (int i = 0; i < 10; i++) {
      fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        debugPrint('AuthProvider.init() currentUser found on attempt $i: ${fbUser.email}');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (fbUser == null) {
      debugPrint('AuthProvider.init() no cached session after polling');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final authorized = _authRepository.currentAuthorizedUser;
    if (authorized == null) {
      debugPrint('AuthProvider.init() unauthorized user, signing out');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      await FirebaseAuth.instance.signOut();
      return;
    }

    _subscribeUser(authorized.uid);
    _status = AuthStatus.authenticated;
    notifyListeners();
    AnniversaryService.checkAndNotify(myUid: authorized.uid);
  }

  Future<bool> login({required String identifier, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signIn(identifier: identifier, password: password);
      _subscribeUser(user.uid);
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on UnauthorizedUserException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'មិនអាចចូលគណនីបានទេ សូមព្យាយាមម្តងទៀត';
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userSub?.cancel();
    _userSub = null;
    NotificationService.stopListening();
    await _authRepository.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    NotificationService.stopListening();
    super.dispose();
  }
}
