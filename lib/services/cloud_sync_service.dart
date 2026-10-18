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
import 'product_image_service.dart';

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

  StreamSubscription<QuerySnapshot>? _companyProductsSub;
  StreamSubscription<QuerySnapshot>? _companyBillsSub;
  StreamSubscription<QuerySnapshot>? _companyCustomersSub;
  StreamSubscription<QuerySnapshot>? _companyCategoriesSub;
  StreamSubscription<DocumentSnapshot>? _companyProfileSub;

  // ---------------------------------------------------------------------------
  // BACKGROUND NON-BLOCKING PUSH HELPERS (STRICT COMPANY SUBCOLLECTION ISOLATION)
  // ---------------------------------------------------------------------------

  void pushProduct(String companyId, Product product) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(product.toMap());
      map['updated_at'] = DateTime.now().toIso8601String();
      map['company_id'] = companyId;

      // Multi-tenant company subcollection only: companies/$companyId/products
      final doc = _companyDoc(companyId)?.collection('products').doc(product.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushBill(String companyId, Bill bill) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(bill.toMap());
      map['updated_at'] = DateTime.now().toIso8601String();
      map['company_id'] = companyId;

      // Multi-tenant company subcollection only: companies/$companyId/bills
      final doc = _companyDoc(companyId)?.collection('bills').doc(bill.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCustomer(String companyId, Customer customer) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(customer.toMap());
      map['updated_at'] = DateTime.now().toIso8601String();
      map['company_id'] = companyId;

      // Multi-tenant company subcollection only: companies/$companyId/customers
      final doc = _companyDoc(companyId)?.collection('customers').doc(customer.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushReturn(String companyId, ReturnRecord returnRecord) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(returnRecord.toMap());
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('returns').doc(returnRecord.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushOffer(String companyId, Offer offer) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(offer.toMap());
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('offers').doc(offer.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
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
      final map = Map<String, dynamic>.from(tracking.toMap());
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('offer_tracking').doc(tracking.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushLoyaltyConfig(String companyId, LoyaltyProgramConfig config) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(config.toMap());
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('loyalty_settings').doc('config');
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCustomerLoyalty(String companyId, String customerId, Map<String, dynamic> data) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(data);
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('customer_loyalty').doc(customerId);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushStockMovement(String companyId, StockMovement movement) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(movement.toMap());
      map['company_id'] = companyId;
      final doc = _companyDoc(companyId)?.collection('stock_movements').doc(movement.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  void pushCategory(String companyId, String categoryName) {
    _safeBackgroundPush(() async {
      final doc = _companyDoc(companyId)?.collection('categories').doc(categoryName);
      if (doc != null) {
        await doc.set({'name': categoryName, 'company_id': companyId}, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  Future<void> deleteCategory(String companyId, String categoryName) async {
    final clean = categoryName.trim();
    if (clean.isEmpty) return;

    try {
      final cDoc = _companyDoc(companyId);
      if (cDoc != null) {
        // 1. Delete direct document by exact category name
        await cDoc.collection('categories').doc(clean).delete().timeout(_cloudTimeout);

        // 2. Query any documents matching the name in this company's subcollection
        final snap = await cDoc
            .collection('categories')
            .where('name', isEqualTo: clean)
            .get()
            .timeout(_cloudTimeout);
        for (final doc in snap.docs) {
          await doc.reference.delete().timeout(_cloudTimeout);
        }
      }
      _status = CloudSyncStatus.synced;
      _lastSyncedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud delete category error: $e');
    }
  }

  void ensureCompanyProfile(CompanyProfile company) {
    _safeBackgroundPush(() async {
      final map = Map<String, dynamic>.from(company.toMap());
      map['updated_at'] = DateTime.now().toIso8601String();

      // Root collection 'companies' document only
      final doc = _companyDoc(company.id);
      if (doc != null) {
        await doc.set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME FIRESTORE SYNCHRONIZATION (COMPANY-SCOPED)
  // ---------------------------------------------------------------------------

  void startRealtimeSync({
    required String companyId,
    required DatabaseService databaseService,
    required Future<void> Function() onDataRefreshed,
    void Function(Map<String, dynamic> companyData)? onCompanyRefreshed,
  }) {
    stopRealtimeListeners();
    if (_firestore == null) return;

    Timer? refreshDebounce;
    void scheduleRefresh() {
      refreshDebounce?.cancel();
      refreshDebounce = Timer(const Duration(milliseconds: 150), () async {
        try {
          await onDataRefreshed();
        } catch (e) {
          debugPrint('Debounced refresh notice: $e');
        }
      });
    }

    Future<void> handleProductSnapshot(QuerySnapshot snapshot) async {
      try {
        final db = await databaseService.database;
        bool hasChanges = false;

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final id = doc.id;
          if (change.type == DocumentChangeType.removed) {
            await db.delete('products', where: 'id = ?', whereArgs: [id]);
            hasChanges = true;
          } else {
            final base64Data = (data['image_base64'] as String?) ?? (data['imageBase64'] as String?) ?? '';
            String localPath = (data['image_path'] as String?) ?? (data['imagePath'] as String?) ?? '';

            if (base64Data.isNotEmpty) {
              if (localPath.isEmpty || !ProductImageService.instance.localImageExists(localPath)) {
                localPath = await ProductImageService.instance.restoreImageFromBase64(id, base64Data);
              }
            }

            final productMap = Map<String, dynamic>.from(data);
            productMap['id'] = id;
            productMap['company_id'] = companyId;
            productMap['image_path'] = localPath;
            productMap['image_base64'] = base64Data;
            if (productMap['sizes'] is List) {
              productMap['sizes'] = (productMap['sizes'] as List).join(',');
            }
            if (productMap['colors'] is List) {
              productMap['colors'] = (productMap['colors'] as List).join(',');
            }

            await db.insert('products', productMap, conflictAlgorithm: ConflictAlgorithm.replace);
            hasChanges = true;
          }
        }

        if (hasChanges) {
          scheduleRefresh();
        }
      } catch (e) {
        debugPrint('Real-time product sync notice: $e');
      }
    }

    Future<void> handleBillSnapshot(QuerySnapshot snapshot) async {
      try {
        final db = await databaseService.database;
        bool hasChanges = false;

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final id = doc.id;
          if (change.type == DocumentChangeType.removed) {
            await db.delete('bills', where: 'id = ?', whereArgs: [id]);
            hasChanges = true;
          } else {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            final bill = Bill.fromMap(data, defaultId: id);
            final sqliteMap = bill.toSqliteMap();
            sqliteMap['company_id'] = companyId;
            await db.insert(
              'bills',
              sqliteMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            hasChanges = true;
          }
        }

        if (hasChanges) {
          scheduleRefresh();
        }
      } catch (e) {
        debugPrint('Real-time bill sync notice: $e');
      }
    }

    Future<void> handleCustomerSnapshot(QuerySnapshot snapshot) async {
      try {
        final db = await databaseService.database;
        bool hasChanges = false;

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final id = doc.id;
          if (change.type == DocumentChangeType.removed) {
            await db.delete('customers', where: 'id = ?', whereArgs: [id]);
            hasChanges = true;
          } else {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            final customer = Customer.fromMap(data, defaultId: id);
            final cMap = customer.toMap();
            cMap['company_id'] = companyId;
            await db.insert(
              'customers',
              cMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            hasChanges = true;
          }
        }

        if (hasChanges) {
          scheduleRefresh();
        }
      } catch (e) {
        debugPrint('Real-time customer sync notice: $e');
      }
    }

    Future<void> handleCategorySnapshot(QuerySnapshot snapshot) async {
      try {
        final db = await databaseService.database;
        bool hasChanges = false;

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final catName = doc.id;
          if (change.type == DocumentChangeType.removed) {
            await db.delete(
              'categories',
              where: 'name = ? AND (company_id = ? OR company_id IS NULL OR company_id = "")',
              whereArgs: [catName, companyId],
            );
            hasChanges = true;
          } else {
            final data = doc.data() as Map<String, dynamic>?;
            final name = (data?['name'] as String?) ?? catName;
            await db.insert(
              'categories',
              {'name': name, 'company_id': companyId},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            hasChanges = true;
          }
        }

        if (hasChanges) {
          scheduleRefresh();
        }
      } catch (e) {
        debugPrint('Real-time category sync notice: $e');
      }
    }

    // Connect company-scoped listeners ONLY (multi-tenant)
    final cDoc = _companyDoc(companyId);
    if (cDoc != null) {
      _companyProductsSub = cDoc.collection('products').snapshots().listen(
        (snapshot) => handleProductSnapshot(snapshot),
        onError: (e) => debugPrint('Company products listener error: $e'),
      );
      _companyBillsSub = cDoc.collection('bills').snapshots().listen(
        (snapshot) => handleBillSnapshot(snapshot),
        onError: (e) => debugPrint('Company bills listener error: $e'),
      );
      _companyCustomersSub = cDoc.collection('customers').snapshots().listen(
        (snapshot) => handleCustomerSnapshot(snapshot),
        onError: (e) => debugPrint('Company customers listener error: $e'),
      );
      _companyCategoriesSub = cDoc.collection('categories').snapshots().listen(
        (snapshot) => handleCategorySnapshot(snapshot),
        onError: (e) => debugPrint('Company categories listener error: $e'),
      );
      _companyProfileSub = cDoc.snapshots().listen(
        (snapshot) {
          try {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data() as Map<String, dynamic>;
              if (onCompanyRefreshed != null) {
                onCompanyRefreshed(data);
              }
            }
          } catch (e) {
            debugPrint('Company profile listener notice: $e');
          }
        },
        onError: (e) => debugPrint('Company profile listener error: $e'),
      );
    }
  }

  void startRealtimeProductListener({
    required String companyId,
    required DatabaseService databaseService,
    required Future<void> Function() onDataRefreshed,
  }) {
    startRealtimeSync(
      companyId: companyId,
      databaseService: databaseService,
      onDataRefreshed: onDataRefreshed,
    );
  }

  void stopRealtimeListeners() {
    _companyProductsSub?.cancel();
    _companyProductsSub = null;
    _companyBillsSub?.cancel();
    _companyBillsSub = null;
    _companyCustomersSub?.cancel();
    _companyCustomersSub = null;
    _companyCategoriesSub?.cancel();
    _companyCategoriesSub = null;
    _companyProfileSub?.cancel();
    _companyProfileSub = null;
  }

  void _safeBackgroundPush(Future<void> Function() action) {
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
  // FULL TWO-WAY SYNCHRONIZATION (HYBRID ENGINE - MULTI-COMPANY ISOLATED)
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

      // 1. Ensure Company document exists in Cloud Firestore under 'companies/$companyId'
      await cDoc.set(companyProfile.toMap(), SetOptions(merge: true)).timeout(_cloudTimeout);

      final db = await databaseService.database;

      // 2. PUSH: Local SQLite -> Cloud Firestore (under company subcollections)
      await _pushLocalToCloud(db, cDoc, companyId);

      // 3. PULL: Cloud Firestore -> Local SQLite (from company subcollections)
      await _pullCloudToLocal(db, cDoc, companyId);

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

  Future<void> _pushLocalToCloud(Database db, DocumentReference cDoc, String companyId) async {
    final whereClause = companyId == 'comp_ayesha_footwear'
        ? "(company_id = ? OR company_id IS NULL OR company_id = '')"
        : 'company_id = ?';

    // Push products
    final localProducts = await db.query('products', where: whereClause, whereArgs: [companyId]);
    for (final p in localProducts) {
      final id = p['id'] as String;
      final map = Map<String, dynamic>.from(p);
      map['company_id'] = companyId;
      map['updated_at'] = DateTime.now().toIso8601String();
      await cDoc.collection('products').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push bills
    final localBills = await db.query('bills', where: whereClause, whereArgs: [companyId]);
    for (final b in localBills) {
      final id = b['id'] as String;
      final bill = Bill.fromMap(b);
      final map = Map<String, dynamic>.from(bill.toMap());
      map['company_id'] = companyId;
      map['updated_at'] = DateTime.now().toIso8601String();
      await cDoc.collection('bills').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push customers
    final localCustomers = await db.query('customers', where: whereClause, whereArgs: [companyId]);
    for (final c in localCustomers) {
      final id = c['id'] as String;
      final customer = Customer.fromMap(c);
      final map = Map<String, dynamic>.from(customer.toMap());
      map['company_id'] = companyId;
      map['updated_at'] = DateTime.now().toIso8601String();
      await cDoc.collection('customers').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push returns
    final localReturns = await db.query('returns', where: whereClause, whereArgs: [companyId]);
    for (final r in localReturns) {
      final id = r['id'] as String;
      final map = Map<String, dynamic>.from(r);
      map['company_id'] = companyId;
      await cDoc.collection('returns').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push offers
    final localOffers = await db.query('offers', where: whereClause, whereArgs: [companyId]);
    for (final o in localOffers) {
      final id = o['id'] as String;
      final map = Map<String, dynamic>.from(o);
      map['company_id'] = companyId;
      await cDoc.collection('offers').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push offer tracking
    final localTracking = await db.query('offer_tracking', where: whereClause, whereArgs: [companyId]);
    for (final t in localTracking) {
      final id = t['id'] as String;
      final map = Map<String, dynamic>.from(t);
      map['company_id'] = companyId;
      await cDoc.collection('offer_tracking').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push loyalty settings
    final localSettings = await db.query('loyalty_settings', where: 'id = 1', limit: 1);
    if (localSettings.isNotEmpty) {
      final map = Map<String, dynamic>.from(localSettings.first);
      map['company_id'] = companyId;
      await cDoc
          .collection('loyalty_settings')
          .doc('config')
          .set(map, SetOptions(merge: true))
          .timeout(_cloudTimeout);
    }

    // Push customer loyalty
    final localLoyalty = await db.query('customer_loyalty', where: whereClause, whereArgs: [companyId]);
    for (final l in localLoyalty) {
      final id = l['customer_id'] as String;
      final map = Map<String, dynamic>.from(l);
      map['company_id'] = companyId;
      await cDoc.collection('customer_loyalty').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push stock movements
    final localMovements = await db.query('stock_movements', where: whereClause, whereArgs: [companyId]);
    for (final m in localMovements) {
      final id = m['id'] as String;
      final map = Map<String, dynamic>.from(m);
      map['company_id'] = companyId;
      await cDoc.collection('stock_movements').doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }

    // Push categories
    final localCategories = await db.query('categories', where: whereClause, whereArgs: [companyId]);
    for (final cat in localCategories) {
      final name = cat['name'] as String;
      final map = Map<String, dynamic>.from(cat);
      map['company_id'] = companyId;
      await cDoc.collection('categories').doc(name).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
    }
  }

  Future<void> _pullCloudToLocal(Database db, DocumentReference cDoc, String companyId) async {
    // 1. Pull products from company collection 'companies/$companyId/products'
    final cloudProducts = await cDoc.collection('products').get().timeout(_cloudTimeout);
    for (final doc in cloudProducts.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final id = doc.id;
      final base64Data = (data['image_base64'] as String?) ?? (data['imageBase64'] as String?) ?? '';
      String localPath = (data['image_path'] as String?) ?? (data['imagePath'] as String?) ?? '';

      if (base64Data.isNotEmpty) {
        if (localPath.isEmpty || !ProductImageService.instance.localImageExists(localPath)) {
          localPath = await ProductImageService.instance.restoreImageFromBase64(id, base64Data);
        }
      }

      data['id'] = id;
      data['company_id'] = companyId;
      data['image_path'] = localPath;
      data['image_base64'] = base64Data;
      if (data['sizes'] is List) data['sizes'] = (data['sizes'] as List).join(',');
      if (data['colors'] is List) data['colors'] = (data['colors'] as List).join(',');

      await db.insert('products', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. Pull bills from company collection 'companies/$companyId/bills'
    final cloudBills = await cDoc.collection('bills').get().timeout(_cloudTimeout);
    for (final doc in cloudBills.docs) {
      final bill = Bill.fromMap(doc.data(), defaultId: doc.id);
      final sqliteMap = bill.toSqliteMap();
      sqliteMap['company_id'] = companyId;
      await db.insert('bills', sqliteMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Pull customers from company collection 'companies/$companyId/customers'
    final cloudCustomers = await cDoc.collection('customers').get().timeout(_cloudTimeout);
    for (final doc in cloudCustomers.docs) {
      final customer = Customer.fromMap(doc.data(), defaultId: doc.id);
      final cMap = customer.toMap();
      cMap['company_id'] = companyId;
      await db.insert('customers', cMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 4. Pull returns
    final cloudReturns = await cDoc.collection('returns').get().timeout(_cloudTimeout);
    for (final doc in cloudReturns.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('returns', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 5. Pull offers
    final cloudOffers = await cDoc.collection('offers').get().timeout(_cloudTimeout);
    for (final doc in cloudOffers.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('offers', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 6. Pull offer tracking
    final cloudTracking = await cDoc.collection('offer_tracking').get().timeout(_cloudTimeout);
    for (final doc in cloudTracking.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('offer_tracking', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 7. Pull loyalty settings
    final cloudSettings = await cDoc.collection('loyalty_settings').doc('config').get().timeout(_cloudTimeout);
    if (cloudSettings.exists && cloudSettings.data() != null) {
      final data = Map<String, dynamic>.from(cloudSettings.data()!);
      data['id'] = 1;
      data['company_id'] = companyId;
      await db.insert('loyalty_settings', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 8. Pull customer loyalty
    final cloudLoyalty = await cDoc.collection('customer_loyalty').get().timeout(_cloudTimeout);
    for (final doc in cloudLoyalty.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('customer_loyalty', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 9. Pull stock movements
    final cloudMovements = await cDoc.collection('stock_movements').get().timeout(_cloudTimeout);
    for (final doc in cloudMovements.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('stock_movements', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 10. Pull categories
    final cloudCategories = await cDoc.collection('categories').get().timeout(_cloudTimeout);
    for (final doc in cloudCategories.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['company_id'] = companyId;
      await db.insert('categories', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ---------------------------------------------------------------------------
  // MULTI-COMPANY DIRECTORY QUERY (AUTHORIZATION ENFORCED)
  // ---------------------------------------------------------------------------

  Future<List<CompanyProfile>> fetchCompaniesForOwner(String ownerUid) async {
    if (_firestore == null || ownerUid.trim().isEmpty) return [];
    try {
      final snapshot = await _firestore!
          .collection('companies')
          .where('ownerUid', isEqualTo: ownerUid)
          .get()
          .timeout(_cloudTimeout);

      return snapshot.docs
          .map((doc) => CompanyProfile.fromMap(doc.data(), defaultId: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Fetch owner companies error: $e');
      return [];
    }
  }
}
