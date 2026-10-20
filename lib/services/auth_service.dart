import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/company_profile.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null;

  CompanyProfile? _activeCompany;
  CompanyProfile? get activeCompany => _activeCompany;

  List<CompanyProfile> _authorizedCompanies = [];
  List<CompanyProfile> get authorizedCompanies => List.unmodifiable(_authorizedCompanies);

  String get activeCompanyId =>
      _activeCompany?.id ?? _currentProfile?.effectiveCompanyId ?? 'comp_ayesha_footwear';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const String _prefKey = 'cached_user_profile';
  static const String _loginFlagKey = 'is_user_logged_in';
  static const String _activeCompanyKey = 'active_company_id';
  static const String _splashCompletedKey = 'has_completed_onboarding_splash';
  static const String _registeredKey = 'has_user_registered';

  bool _hasCompletedSplash = false;
  bool get hasCompletedSplash => _hasCompletedSplash || _isUserRegistered || isAuthenticated;

  bool _isUserRegistered = false;
  bool get isUserRegistered => _isUserRegistered;

  Future<void> completeSplash() async {
    _hasCompletedSplash = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_splashCompletedKey, true);
    } catch (_) {}
  }

  Future<void> initialize() async {
    try {
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

    // Load splash & registration state
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedSplash = prefs.getBool(_splashCompletedKey) ?? false;
      _isUserRegistered = prefs.getBool(_registeredKey) ?? false;
    } catch (_) {}

    // Load locally cached profile & active company (offline-first & instant startup)
    await _loadCachedProfile();

    // Check Firebase Auth state if available
    if (_auth != null) {
      final firebaseUser = _auth!.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;

      if (firebaseUser != null && isLoggedIn) {
        // Refresh profile and authorized companies from Firestore in background
        await _fetchRemoteProfile(firebaseUser.uid);
        await fetchAuthorizedCompanies();
      } else if (!isLoggedIn) {
        _currentProfile = null;
        _activeCompany = null;
      }

      // Listen for auth state changes
      _auth!.authStateChanges().listen((user) {
        if (user == null &&
            _currentProfile != null &&
            (prefs.getBool(_loginFlagKey) != true)) {
          _currentProfile = null;
          _activeCompany = null;
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

        final cachedCompanyId = prefs.getString(_activeCompanyKey);
        if (cachedCompanyId != null && cachedCompanyId.isNotEmpty) {
          _activeCompany = CompanyProfile(
            id: cachedCompanyId,
            name: _currentProfile!.companyName,
            ownerUid: _currentProfile!.uid,
            mobile: _currentProfile!.mobile,
            upiId: _currentProfile!.upiId,
            createdAt: _currentProfile!.createdAt,
          );
        }
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

  // ---------------------------------------------------------------------------
  // 1. COMPANY REGISTRATION FLOW
  // ---------------------------------------------------------------------------

  Future<UserProfile> register({
    required String companyName,
    required String email,
    required String password,
    required String mobile,
    required String upiId,
    String? name,
  }) async {
    String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Register with Firebase Authentication
    if (_auth != null) {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        uid = cred.user!.uid;
        final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : companyName.trim();
        await cred.user!.updateDisplayName(displayName).catchError((_) {});
      }
    }

    // 2. Generate unique companyId (never store password in Firestore)
    final slug = companyName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final companyId = 'comp_${slug.isNotEmpty ? slug : "store"}_$uniqueSuffix';

    final companyProfile = CompanyProfile(
      id: companyId,
      name: companyName.trim(),
      ownerUid: uid,
      mobile: mobile.trim(),
      upiId: upiId.trim().isEmpty ? 'atiqullahkhan554@okicici' : upiId.trim(),
      createdAt: DateTime.now(),
    );

    // 3. Save Company document in Firestore under companies/{companyId} (NO PASSWORDS)
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('companies')
            .doc(companyId)
            .set(companyProfile.toMap())
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Firestore company save notice: $e');
      }
    }

    // 4. Save User document in Firestore under users/{uid} (NO PASSWORDS)
    final profile = UserProfile(
      uid: uid,
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : companyName.trim(),
      mobile: mobile.trim(),
      email: email.trim(),
      companyName: companyName.trim(),
      upiId: upiId.trim().isEmpty ? 'atiqullahkhan554@okicici' : upiId.trim(),
      createdAt: DateTime.now(),
      companyId: companyId,
      ownedCompanyIds: [companyId],
    );

    if (_firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .set(profile.toMap())
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Firestore user save notice: $e');
      }
    }

    // 5. Select this registered company as active
    _currentProfile = profile;
    _activeCompany = companyProfile;
    _authorizedCompanies = [companyProfile];

    await _cacheProfile(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCompanyKey, companyId);
    await prefs.setBool(_registeredKey, true);
    await prefs.setBool(_splashCompletedKey, true);
    _isUserRegistered = true;
    _hasCompletedSplash = true;

    notifyListeners();
    return profile;
  }

  // ---------------------------------------------------------------------------
  // 2. LOGIN FLOW
  // ---------------------------------------------------------------------------

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    String uid = '';

    // 1. Authenticate with Firebase Authentication
    if (_auth != null) {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = cred.user?.uid ?? '';
    }

    // 2. Fetch User Profile
    UserProfile? profile;
    if (_firestore != null && uid.isNotEmpty) {
      try {
        final doc = await _firestore!
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 5));
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

    profile ??= UserProfile(
      uid: uid.isNotEmpty ? uid : 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      mobile: '',
      email: email.trim(),
      companyName: 'Footwear Store',
      upiId: '',
      createdAt: DateTime.now(),
    );

    _currentProfile = profile;
    await _cacheProfile(profile);

    // 3. Fetch authorized companies where ownerUid == uid
    await fetchAuthorizedCompanies();

    // 4. Resolve Active Company
    final prefs = await SharedPreferences.getInstance();
    final cachedCompanyId = prefs.getString(_activeCompanyKey);

    if (cachedCompanyId != null && _authorizedCompanies.any((c) => c.id == cachedCompanyId)) {
      _activeCompany = _authorizedCompanies.firstWhere((c) => c.id == cachedCompanyId);
    } else if (_authorizedCompanies.length == 1) {
      _activeCompany = _authorizedCompanies.first;
      await prefs.setString(_activeCompanyKey, _activeCompany!.id);
    } else {
      // Multiple companies or none yet - requires company selection
      _activeCompany = null;
    }

    notifyListeners();
    return profile;
  }

  // ---------------------------------------------------------------------------
  // 3. AUTHORIZED COMPANIES DIRECTORY
  // ---------------------------------------------------------------------------

  Future<List<CompanyProfile>> fetchAuthorizedCompanies() async {
    final uid = _currentProfile?.uid ?? _auth?.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _authorizedCompanies = [];
      return [];
    }

    if (_firestore != null) {
      try {
        final snap = await _firestore!
            .collection('companies')
            .where('ownerUid', isEqualTo: uid)
            .get()
            .timeout(const Duration(seconds: 5));

        final list = snap.docs
            .map((doc) => CompanyProfile.fromMap(doc.data(), defaultId: doc.id))
            .toList();

        if (list.isNotEmpty) {
          _authorizedCompanies = list;
          notifyListeners();
          return list;
        }
      } catch (e) {
        debugPrint('Fetch authorized companies notice: $e');
      }
    }

    // If no companies found in Firestore (e.g. offline or newly linked), provide active/default
    if (_authorizedCompanies.isEmpty && _currentProfile != null) {
      final defaultCompany = CompanyProfile(
        id: _currentProfile!.effectiveCompanyId,
        name: _currentProfile!.companyName,
        ownerUid: _currentProfile!.uid,
        mobile: _currentProfile!.mobile,
        upiId: _currentProfile!.upiId,
        createdAt: _currentProfile!.createdAt,
      );
      _authorizedCompanies = [defaultCompany];
    }

    notifyListeners();
    return _authorizedCompanies;
  }

  // ---------------------------------------------------------------------------
  // 4. SELECT COMPANY & DATA ISOLATION
  // ---------------------------------------------------------------------------

  Future<void> selectCompany(CompanyProfile company) async {
    _activeCompany = company;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCompanyKey, company.id);

    if (_currentProfile != null) {
      final updated = _currentProfile!.copyWith(
        companyId: company.id,
        companyName: company.name,
        upiId: company.upiId,
      );
      _currentProfile = updated;
      await _cacheProfile(updated);
    }

    notifyListeners();
  }

  Future<CompanyProfile> registerNewBranch({
    required String name,
    required String upiId,
    String mobile = '',
    String address = '',
  }) async {
    final uid = _currentProfile?.uid ?? _auth?.currentUser?.uid ?? 'user';
    final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final companyId = 'comp_${slug.isNotEmpty ? slug : "store"}_$uniqueSuffix';

    final company = CompanyProfile(
      id: companyId,
      name: name.trim(),
      ownerUid: uid,
      mobile: mobile.trim().isNotEmpty ? mobile.trim() : (_currentProfile?.mobile ?? ''),
      upiId: upiId.trim(),
      createdAt: DateTime.now(),
      address: address.trim(),
    );

    if (_firestore != null) {
      try {
        await _firestore!
            .collection('companies')
            .doc(companyId)
            .set(company.toMap())
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Branch save notice: $e');
      }
    }

    final updatedList = [..._authorizedCompanies, company];
    _authorizedCompanies = updatedList;

    await selectCompany(company);
    return company;
  }

  // ---------------------------------------------------------------------------
  // 5. PROFILE & PASSWORD RECOVERY
  // ---------------------------------------------------------------------------

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

    if (_activeCompany != null && (companyName != null || upiId != null || mobile != null)) {
      _activeCompany = _activeCompany!.copyWith(
        name: companyName,
        upiId: upiId,
        mobile: mobile,
      );
    }

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

  // ---------------------------------------------------------------------------
  // 6. LOGOUT (CLEARS ACTIVE COMPANY & SESSION WITHOUT DELETING SQLITE RECORDS)
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    if (_auth != null) {
      try {
        await _auth!.signOut();
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginFlagKey, false);
      await prefs.remove(_activeCompanyKey);
    } catch (_) {}

    _currentProfile = null;
    _activeCompany = null;
    _authorizedCompanies = [];
    notifyListeners();
  }

  Future<UserProfile> setDemoProfile({
    String name = 'Store Owner',
    String companyName = 'Footwear Store',
    String upiId = '',
    String email = 'owner@store.com',
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
    _activeCompany = CompanyProfile(
      id: profile.effectiveCompanyId,
      name: companyName,
      ownerUid: 'demo_user',
      mobile: mobile,
      upiId: upiId,
      createdAt: DateTime.now(),
    );
    _authorizedCompanies = [_activeCompany!];
    _hasCompletedSplash = true;
    _isUserRegistered = true;
    await _cacheProfile(profile);
    notifyListeners();
    return profile;
  }
}
