import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bill.dart';
import '../models/company_profile.dart';
import '../models/customer.dart';
import '../models/loyalty_models.dart';
import '../models/product.dart';
import '../models/return_models.dart';
import 'database_service.dart';

enum CloudSyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error;

  String get label {
    switch (this) {
      case CloudSyncStatus.idle:
        return 'Ready';
      case CloudSyncStatus.syncing:
        return 'Syncing Cloud...';
      case CloudSyncStatus.synced:
        return 'Cloud Synced';
      case CloudSyncStatus.offline:
        return 'Offline (Local)';
      case CloudSyncStatus.error:
        return 'Sync Warning';
    }
  }
}

class CloudSyncService extends ChangeNotifier {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  FirebaseFirestore? _firestore;
  CloudSyncStatus _status = CloudSyncStatus.idle;
  CloudSyncStatus get status => _status;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastError;
  String? get lastError => _lastError;

  static const Duration _cloudTimeout = Duration(seconds: 4);

  void initialize([FirebaseFirestore? firestore]) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('CloudSyncService init: $e');
    }
  }

  DocumentReference? _companyDoc(String companyId) {
    if (_firestore == null) return null;
    final cleanId = companyId.trim().isNotEmpty ? companyId.trim() : 'comp_ayesha_footwear';
    return _firestore!.collection('companies').doc(cleanId);
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND NON-BLOCKING PUSH HELPERS
  // ---------------------------------------------------------------------------

  void pushProduct(String companyId, Product product) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('products').doc(product.id);
      if (doc != null) {
        await doc.set(product.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushBill(String companyId, Bill bill) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('bills').doc(bill.id);
      if (doc != null) {
        await doc.set(bill.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCustomer(String companyId, Customer customer) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('customers').doc(customer.id);
      if (doc != null) {
        await doc.set(customer.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushReturn(String companyId, ReturnRecord returnRecord) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('returns').doc(returnRecord.id);
      if (doc != null) {
        await doc.set(returnRecord.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushOffer(String companyId, Offer offer) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('offers').doc(offer.id);
      if (doc != null) {
        await doc.set(offer.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void deleteOffer(String companyId, String offerId) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('offers').doc(offerId);
      if (doc != null) {
        await doc.delete().timeout(_cloudTimeout);
      }
    });
  }

  void pushOfferTracking(String companyId, OfferTracking tracking) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('offer_tracking').doc(tracking.id);
      if (doc != null) {
        await doc.set(tracking.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushLoyaltyConfig(String companyId, LoyaltyProgramConfig config) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('loyalty_settings').doc('config');
      if (doc != null) {
        await doc.set(config.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCustomerLoyalty(String companyId, String customerId, Map<String, dynamic> data) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('customer_loyalty').doc(customerId);
      if (doc != null) {
        await doc.set(data, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushStockMovement(String companyId, StockMovement movement) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('stock_movements').doc(movement.id);
      if (doc != null) {
        await doc.set(movement.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCategory(String companyId, String categoryName) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('categories').doc(categoryName);
      if (doc != null) {
        await doc.set({'name': categoryName}, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void deleteCategory(String companyId, String categoryName) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('categories').doc(categoryName);
      if (doc != null) {
        await doc.delete().timeout(_cloudTimeout);
      }
    });
  }

  void ensureCompanyProfile(CompanyProfile company) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(company.id);
      if (doc != null) {
        await doc.set(company.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void _safeBackgroundPush(Future<void> Function() action) {
    // Fire and forget asynchronously; never block the local UI or throw unhandled exceptions
    Future(() async {
      try {
        await action();
        _status = CloudSyncStatus.synced;
        _lastSyncedAt = DateTime.now();
        notifyListeners();
      } catch (e) {
        debugPrint('Cloud sync notice: $e');
        _status = CloudSyncStatus.offline;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // FULL TWO-WAY SYNCHRONIZATION (HYBRID ENGINE)
  // ---------------------------------------------------------------------------

  Future<bool> syncAll({
    required String companyId,
    required DatabaseService databaseService,
    required CompanyProfile companyProfile,
  }) async {
    if (_firestore == null) {
      _status = CloudSyncStatus.offline;
      notifyListeners();
      return false;
    }

    _status = CloudSyncStatus.syncing;
    notifyListeners();

    try {
      final cDoc = _companyDoc(companyId);
      if (cDoc == null) {
        _status = CloudSyncStatus.offline;
        notifyListeners();
        return false;
      }

      // 1. Ensure Company root document exists in Cloud Firestore
      await cDoc.set(companyProfile.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);

      final db = await databaseService.database;

      // 2. PUSH: Local SQLite -> Cloud Firestore
      await _pushLocalToCloud(db, cDoc);

      // 3. PULL: Cloud Firestore -> Local SQLite
      await _pullCloudToLocal(db, cDoc);

      _status = CloudSyncStatus.synced;
      _lastSyncedAt = DateTime.now();
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      _lastError = e.toString();
      _status = CloudSyncStatus.offline;
      notifyListeners();
      return false;
    }
  }

  Future<void> _pushLocalToCloud(Database db, DocumentReference cDoc) async {
    // Push products
    final localProducts = await db.query('products');
    for (final p in localProducts) {
      final id = p['id'] as String;
      await cDoc.collection('products').doc(id).set(p, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push bills
    final localBills = await db.query('bills');
    for (final b in localBills) {
      final id = b['id'] as String;
      await cDoc.collection('bills').doc(id).set(b, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push customers
    final localCustomers = await db.query('customers');
    for (final c in localCustomers) {
      final id = c['id'] as String;
      await cDoc.collection('customers').doc(id).set(c, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push returns
    final localReturns = await db.query('returns');
    for (final r in localReturns) {
      final id = r['id'] as String;
      await cDoc.collection('returns').doc(id).set(r, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push offers
    final localOffers = await db.query('offers');
    for (final o in localOffers) {
      final id = o['id'] as String;
      await cDoc.collection('offers').doc(id).set(o, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push offer tracking
    final localTracking = await db.query('offer_tracking');
    for (final t in localTracking) {
      final id = t['id'] as String;
      await cDoc.collection('offer_tracking').doc(id).set(t, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push loyalty settings
    final localSettings = await db.query('loyalty_settings', where: 'id = 1', limit: 1);
    if (localSettings.isNotEmpty) {
      await cDoc
          .collection('loyalty_settings')
          .doc('config')
          .set(localSettings.first, SetOptions(merge: true))
          .timeout(_cloudTimeout);
    }

    // Push customer loyalty
    final localLoyalty = await db.query('customer_loyalty');
    for (final l in localLoyalty) {
      final id = l['customer_id'] as String;
      await cDoc.collection('customer_loyalty').doc(id).set(l, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push stock movements
    final localMovements = await db.query('stock_movements');
    for (final m in localMovements) {
      final id = m['id'] as String;
      await cDoc.collection('stock_movements').doc(id).set(m, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push categories
    final localCategories = await db.query('categories');
    for (final cat in localCategories) {
      final name = cat['name'] as String;
      await cDoc.collection('categories').doc(name).set(cat, SetOptions(merge: true)).timeout(_cloudTimeout);
    }
  }

  Future<void> _pullCloudToLocal(Database db, DocumentReference cDoc) async {
    // Pull products
    final cloudProducts = await cDoc.collection('products').get().timeout(_cloudTimeout);
    for (final doc in cloudProducts.docs) {
      await db.insert('products', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull bills
    final cloudBills = await cDoc.collection('bills').get().timeout(_cloudTimeout);
    for (final doc in cloudBills.docs) {
      await db.insert('bills', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull customers
    final cloudCustomers = await cDoc.collection('customers').get().timeout(_cloudTimeout);
    for (final doc in cloudCustomers.docs) {
      await db.insert('customers', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull returns
    final cloudReturns = await cDoc.collection('returns').get().timeout(_cloudTimeout);
    for (final doc in cloudReturns.docs) {
      await db.insert('returns', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull offers
    final cloudOffers = await cDoc.collection('offers').get().timeout(_cloudTimeout);
    for (final doc in cloudOffers.docs) {
      await db.insert('offers', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull offer tracking
    final cloudTracking = await cDoc.collection('offer_tracking').get().timeout(_cloudTimeout);
    for (final doc in cloudTracking.docs) {
      await db.insert('offer_tracking', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull loyalty settings
    final cloudSettings = await cDoc.collection('loyalty_settings').doc('config').get().timeout(_cloudTimeout);
    if (cloudSettings.exists && cloudSettings.data() != null) {
      final data = Map<String, dynamic>.from(cloudSettings.data()!);
      data['id'] = 1;
      await db.insert('loyalty_settings', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull customer loyalty
    final cloudLoyalty = await cDoc.collection('customer_loyalty').get().timeout(_cloudTimeout);
    for (final doc in cloudLoyalty.docs) {
      await db.insert('customer_loyalty', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull stock movements
    final cloudMovements = await cDoc.collection('stock_movements').get().timeout(_cloudTimeout);
    for (final doc in cloudMovements.docs) {
      await db.insert('stock_movements', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Pull categories
    final cloudCategories = await cDoc.collection('categories').get().timeout(_cloudTimeout);
    for (final doc in cloudCategories.docs) {
      await db.insert('categories', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ---------------------------------------------------------------------------
  // MULTI-COMPANY DIRECTORY QUERY
  // ---------------------------------------------------------------------------

  Future<List<CompanyProfile>> fetchCompaniesForOwner(String ownerUid) async {
    if (_firestore == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('companies')
          .where('ownerUid', isEqualTo: ownerUid)
          .get()
          .timeout(_cloudTimeout);

      return snapshot.docs.map((doc) => CompanyProfile.fromMap(doc.data(), defaultId: doc.id)).toList();
    } catch (_) {
      return [];
    }
  }
}
