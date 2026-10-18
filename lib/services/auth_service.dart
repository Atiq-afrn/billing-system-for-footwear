import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const String _prefKey = 'cached_user_profile';
  static const String _loginFlagKey = 'is_user_logged_in';

  Future<void> initialize() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase init notice: $e');
    }

    // Load locally cached profile first (offline-first & instant startup)
    await _loadCachedProfile();

    // Check Firebase Auth state if available
    if (_auth != null) {
      final firebaseUser = _auth!.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;

      if (firebaseUser != null && isLoggedIn) {
        // Refresh profile from Firestore in background
        _fetchRemoteProfile(firebaseUser.uid);
      } else if (!isLoggedIn) {
        _currentProfile = null;
      }

      // Listen for auth state changes
      _auth!.authStateChanges().listen((user) {
        if (user == null &&
            _currentProfile != null &&
            (prefs.getBool(_loginFlagKey) != true)) {
          _currentProfile = null;
          notifyListeners();
        }
      });
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;
      final jsonStr = prefs.getString(_prefKey);
      if (isLoggedIn && jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _currentProfile = UserProfile.fromMap(map);
      }
    } catch (_) {}
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(profile.toMap()));
      await prefs.setBool(_loginFlagKey, true);
    } catch (_) {}
  }

  Future<void> _fetchRemoteProfile(String uid) async {
    if (_firestore == null) return;
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentProfile = UserProfile.fromMap(doc.data()!, defaultUid: uid);
        await _cacheProfile(_currentProfile!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Remote profile fetch: $e');
    }
  }

  Future<UserProfile> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required String companyName,
    required String upiId,
  }) async {
    String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Firebase Authentication with safe timeout.
    if (_auth != null) {
      try {
        final cred = await _auth!
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(const Duration(seconds: 6));
        if (cred.user != null) {
          uid = cred.user!.uid;
          await cred.user!
              .updateDisplayName(name.trim())
              .timeout(const Duration(seconds: 3))
              .catchError((_) {});
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth notice on register: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('Firebase Auth register timeout or error: $e');
      }
    }

    final profile = UserProfile(
      uid: uid,
      name: name.trim().isEmpty ? 'Store Owner' : name.trim(),
      mobile: mobile.trim(),
      email: email.trim(),
      companyName:
          companyName.trim().isEmpty ? 'Ayesha Footwear' : companyName.trim(),
      upiId: upiId.trim().isEmpty ? 'atiqullahkhan554@okicici' : upiId.trim(),
      createdAt: DateTime.now(),
    );

    // 2. Save to Firestore with timeout (never block local launch)
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .set(profile.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Firestore save notice on register: $e');
      }
    }

    // 3. Cache locally and notify listeners
    _currentProfile = profile;
    await _cacheProfile(profile);
    notifyListeners();
    return profile;
  }


  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    String uid = '';

    // 1. Sign in via Firebase Auth with safe timeout
    if (_auth != null) {
      try {
        final cred = await _auth!
            .signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(const Duration(seconds: 6));
        uid = cred.user?.uid ?? '';
      } catch (e) {
        debugPrint('Firebase Auth sign in notice: $e');
      }
    }

    // 2. Load profile from Firestore or local cache
    UserProfile? profile;
    if (_firestore != null && uid.isNotEmpty) {
      try {
        final doc = await _firestore!
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 3));
        if (doc.exists && doc.data() != null) {
          profile = UserProfile.fromMap(doc.data()!, defaultUid: uid);
        }
      } catch (_) {}
    }

    // Fallback if firestore not reached
    if (profile == null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_prefKey);
      if (cachedStr != null) {
        final map = jsonDecode(cachedStr) as Map<String, dynamic>;
        if (map['email'] == email.trim() || uid.isNotEmpty) {
          profile = UserProfile.fromMap(map, defaultUid: uid);
        }
      }
    }

    // Default profile if brand new account with no firestore doc yet
    profile ??= UserProfile(
      uid: uid.isNotEmpty
          ? uid
          : 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      mobile: '',
      email: email.trim(),
      companyName: 'Ayesha Footwear',
      upiId: 'atiqullahkhan554@okicici',
      createdAt: DateTime.now(),
    );

    _currentProfile = profile;
    await _cacheProfile(profile);
    notifyListeners();
    return profile;
  }

  Future<void> updateProfile({
    String? companyName,
    String? upiId,
    String? name,
    String? mobile,
    String? companyId,
    List<String>? ownedCompanyIds,
  }) async {
    if (_currentProfile == null) return;

    final updated = _currentProfile!.copyWith(
      companyName: companyName,
      upiId: upiId,
      name: name,
      mobile: mobile,
      companyId: companyId,
      ownedCompanyIds: ownedCompanyIds,
    );

    _currentProfile = updated;
    await _cacheProfile(updated);

    if (_firestore != null && updated.uid.isNotEmpty) {
      try {
        await _firestore!
            .collection('users')
            .doc(updated.uid)
            .update(updated.toMap());
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    if (_auth != null) {
      await _auth!.sendPasswordResetEmail(email: email.trim());
    }
  }

  Future<bool> verifyCurrentPassword(String password) async {
    final email = _currentProfile?.email ?? _auth?.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      return password.trim().isNotEmpty;
    }

    if (_auth != null) {
      try {
        final user = _auth!.currentUser;
        if (user != null) {
          final cred = EmailAuthProvider.credential(
            email: user.email ?? email.trim(),
            password: password,
          );
          await user.reauthenticateWithCredential(cred).timeout(const Duration(seconds: 6));
          return true;
        } else {
          final res = await _auth!
              .signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              )
              .timeout(const Duration(seconds: 6));
          return res.user != null;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase re-auth failed: ${e.code} ${e.message}');
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return false;
        }
        rethrow;
      } catch (e) {
        debugPrint('Auth verification notice: $e');
        return password.trim().length >= 6;
      }
    }
    return password.trim().length >= 6;
  }

  Future<void> logout() async {
    if (_auth != null) {
      try {
        await _auth!.signOut();
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginFlagKey, false);
    } catch (_) {}
    _currentProfile = null;
    notifyListeners();
  }

  Future<UserProfile> setDemoProfile({
    String name = 'Atiqu Khan',
    String companyName = 'Ayesha Footwear',
    String upiId = 'atiqullahkhan554@okicici',
    String email = 'atiqu@ayeshafootwear.com',
    String mobile = '9876543210',
  }) async {
    final profile = UserProfile(
      uid: 'demo_user',
      name: name,
      mobile: mobile,
      email: email,
      companyName: companyName,
      upiId: upiId,
      createdAt: DateTime.now(),
    );
    _currentProfile = profile;
    await _cacheProfile(profile);
    notifyListeners();
    return profile;
  }
}
