import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/bill.dart';
import '../models/bill_draft.dart';
import '../models/customer.dart';
import '../models/loyalty_models.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../models/return_models.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import 'shop_repository.dart';

class SqliteShopRepository implements ShopRepository {
  SqliteShopRepository(this._databaseService, [this.companyIdProvider]);

  final DatabaseService _databaseService;
  final String Function()? companyIdProvider;
  final Uuid _uuid = const Uuid();

  String get _currentCompanyId => companyIdProvider?.call() ?? 'comp_ayesha_footwear';

  String _whereCompany([String? prefix]) {
    final col = prefix != null ? '$prefix.company_id' : 'company_id';
    if (_currentCompanyId == 'comp_ayesha_footwear') {
      return "($col = ? OR $col IS NULL OR $col = '')";
    }
    return '$col = ?';
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'products',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<List<Customer>> fetchCustomers() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'customers',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  @override
  Future<List<Bill>> fetchBills() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'bills',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  @override
  Future<Product> saveProduct(ProductDraft draft) async {
    final db = await _databaseService.database;
    final product = Product(
      id: _uuid.v4(),
      name: draft.name,
      category: draft.category,
      stock: draft.stock,
      price: draft.price,
      sizes: draft.sizes,
      colors: draft.colors,
      imagePath: draft.imagePath,
      imageBase64: draft.imageBase64,
    );

    final map = Map<String, dynamic>.from(product.toMap());
    map['company_id'] = _currentCompanyId;
    await db.insert('products', map, conflictAlgorithm: ConflictAlgorithm.replace);

    // Initial stock movement record
    if (draft.stock > 0) {
      final movement = StockMovement(
        id: 'MOV-${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        movementType: 'adjustment',
        qtyChange: draft.stock,
        referenceId: product.id,
        createdAt: DateTime.now(),
        note: 'Initial catalog stock addition',
      );
      final mMap = Map<String, dynamic>.from(movement.toMap());
      mMap['company_id'] = _currentCompanyId;
      await db.insert('stock_movements', mMap);
      CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
    }

    // Background push to Cloud Firestore
    CloudSyncService.instance.pushProduct(_currentCompanyId, product);

    return product;
  }

  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    final db = await _databaseService.database;
    final productRows = await db.query(
      'products',
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [productId, _currentCompanyId],
      limit: 1,
    );
    final oldStock = productRows.isNotEmpty ? ((productRows.first['stock'] as num?)?.toInt() ?? 0) : 0;
    final productName = productRows.isNotEmpty ? (productRows.first['name'] as String? ?? 'Product') : 'Product';

    final validStock = newStock < 0 ? 0 : newStock;
    await db.update(
      'products',
      {'stock': validStock, 'company_id': _currentCompanyId},
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [productId, _currentCompanyId],
    );

    final diff = validStock - oldStock;
    if (diff != 0) {
      final movement = StockMovement(
        id: 'MOV-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        movementType: 'adjustment',
        qtyChange: diff,
        referenceId: productId,
        createdAt: DateTime.now(),
        note: 'Manual stock inventory restock / correction',
      );
      final mMap = Map<String, dynamic>.from(movement.toMap());
      mMap['company_id'] = _currentCompanyId;
      await db.insert('stock_movements', mMap);
      CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
    }

    if (productRows.isNotEmpty) {
      final updatedProduct = Product.fromMap(productRows.first).copyWith(stock: validStock);
      CloudSyncService.instance.pushProduct(_currentCompanyId, updatedProduct);
    }
  }

  @override
  Future<Bill> saveBill(BillDraft draft) async {
    final db = await _databaseService.database;
    Customer? savedCustomer;

    final bill = await db.transaction((txn) async {
      final customer = await _upsertCustomer(txn, draft);
      savedCustomer = customer;

      final newBill = Bill(
        id: 'BILL-${DateTime.now().millisecondsSinceEpoch}',
        customerId: customer.id,
        productId: draft.primaryProductId,
        customer: draft.customer,
        mobile: draft.mobile,
        item: draft.primaryItemSummary,
        size: draft.primarySize,
        color: draft.primaryColor,
        qty: draft.totalQty,
        price: draft.subtotal,
        discount: draft.discount,
        total: draft.total,
        payMode: draft.payMode,
        note: draft.note,
        time: DateTime.now(),
        items: draft.items,
      );

      final billMap = newBill.toSqliteMap();
      billMap['company_id'] = _currentCompanyId;
      await txn.insert('bills', billMap, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final item in draft.items) {
        if (item.productId.isNotEmpty) {
          await txn.rawUpdate(
            'UPDATE products SET stock = CASE WHEN stock - ? < 0 THEN 0 ELSE stock - ? END WHERE id = ? AND ${_whereCompany()}',
            [item.qty, item.qty, item.productId, _currentCompanyId],
          );

          // Stock movement audit record
          final movement = StockMovement(
            id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            movementType: 'sale',
            qtyChange: -item.qty,
            referenceId: newBill.id,
            createdAt: newBill.time,
            note: 'Sold via Invoice ${newBill.id}',
          );
          final mMap = Map<String, dynamic>.from(movement.toMap());
          mMap['company_id'] = _currentCompanyId;
          await txn.insert('stock_movements', mMap, conflictAlgorithm: ConflictAlgorithm.replace);
          CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
        }
      }

      // Automatically credit loyalty points
      await _creditLoyaltyPoints(txn, customer.id, draft.total);

      return newBill;
    });

    // Cloud background sync
    CloudSyncService.instance.pushBill(_currentCompanyId, bill);
    if (savedCustomer != null) {
      CloudSyncService.instance.pushCustomer(_currentCompanyId, savedCustomer!);
    }

    // Sync updated product stocks to Cloud Firestore immediately
    for (final item in draft.items) {
      if (item.productId.isNotEmpty) {
        final pRows = await db.query(
          'products',
          where: 'id = ? AND ${_whereCompany()}',
          whereArgs: [item.productId, _currentCompanyId],
          limit: 1,
        );
        if (pRows.isNotEmpty) {
          CloudSyncService.instance.pushProduct(_currentCompanyId, Product.fromMap(pRows.first));
        }
      }
    }

    return bill;
  }

  Future<void> _creditLoyaltyPoints(Transaction txn, String customerId, int amountSpent) async {
    try {
      final configRows = await txn.query('loyalty_settings', where: 'id = 1', limit: 1);
      final config = configRows.isNotEmpty
          ? LoyaltyProgramConfig.fromMap(configRows.first)
          : const LoyaltyProgramConfig();

      final pointsEarned = ((amountSpent / 100).floor()) * config.pointsPer100Spent;

      final existing = await txn.query(
        'customer_loyalty',
        where: 'customer_id = ? AND ${_whereCompany()}',
        whereArgs: [customerId, _currentCompanyId],
        limit: 1,
      );

      if (existing.isEmpty) {
        final totalPoints = config.welcomeBonusPoints + pointsEarned;
        final data = {
          'customer_id': customerId,
          'points': totalPoints,
          'points_redeemed': 0,
          'marketing_consent': 1,
          'notes': 'Account opened with welcome points',
          'updated_at': DateTime.now().toIso8601String(),
          'company_id': _currentCompanyId,
        };
        await txn.insert('customer_loyalty', data, conflictAlgorithm: ConflictAlgorithm.replace);
        CloudSyncService.instance.pushCustomerLoyalty(_currentCompanyId, customerId, data);
      } else {
        final currentPoints = (existing.first['points'] as num?)?.toInt() ?? 0;
        final data = {
          'customer_id': customerId,
          'points': currentPoints + pointsEarned,
          'updated_at': DateTime.now().toIso8601String(),
          'company_id': _currentCompanyId,
        };
        await txn.update(
          'customer_loyalty',
          data,
          where: 'customer_id = ? AND ${_whereCompany()}',
          whereArgs: [customerId, _currentCompanyId],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        CloudSyncService.instance.pushCustomerLoyalty(_currentCompanyId, customerId, data);
      }
    } catch (_) {}
  }

  Future<Customer> _upsertCustomer(Transaction txn, BillDraft draft) async {
    final existing = await txn.query(
      'customers',
      where: 'mobile = ? AND ${_whereCompany()}',
      whereArgs: [draft.mobile, _currentCompanyId],
      limit: 1,
    );
    final itemSummary = draft.primaryItemSummary;
    final sizeSummary = draft.primarySize;
    final colorSummary = draft.primaryColor;

    if (existing.isEmpty) {
      final customer = Customer(
        id: _uuid.v4(),
        name: draft.customer.trim().isNotEmpty ? draft.customer.trim() : 'Customer',
        mobile: draft.mobile.trim(),
        size: sizeSummary.isEmpty ? 'Free' : sizeSummary,
        colors: colorSummary.isEmpty ? 'Standard' : colorSummary,
        lastItem: itemSummary,
        totalSpent: draft.total,
        visits: 1,
        note: draft.note,
      );
      final cMap = Map<String, dynamic>.from(customer.toMap());
      cMap['company_id'] = _currentCompanyId;
      await txn.insert(
        'customers',
        cMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return customer;
    }

    final previous = Customer.fromMap(existing.first);
    final customer = Customer(
      id: previous.id,
      name: draft.customer.trim().isNotEmpty ? draft.customer.trim() : previous.name,
      mobile: draft.mobile.trim(),
      size: sizeSummary.isNotEmpty ? sizeSummary : previous.size,
      colors: colorSummary.isNotEmpty ? colorSummary : previous.colors,
      lastItem: itemSummary,
      totalSpent: previous.totalSpent + draft.total,
      visits: previous.visits + 1,
      note: draft.note.isEmpty ? previous.note : draft.note,
    );
    final cMap = Map<String, dynamic>.from(customer.toMap());
    cMap['company_id'] = _currentCompanyId;
    await txn.update(
      'customers',
      cMap,
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [customer.id, _currentCompanyId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customer;
  }

  @override
  Future<List<String>> fetchCategories() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'categories',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  @override
  Future<void> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final db = await _databaseService.database;
    await db.insert(
      'categories',
      {'name': clean, 'company_id': _currentCompanyId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    CloudSyncService.instance.pushCategory(_currentCompanyId, clean);
  }

  @override
  Future<void> deleteCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final db = await _databaseService.database;
    await db.delete(
      'categories',
      where: 'name = ? AND ${_whereCompany()}',
      whereArgs: [clean, _currentCompanyId],
    );
    await CloudSyncService.instance.deleteCategory(_currentCompanyId, clean);
  }

  // ---------------------------------------------------------------------------
  // LOYALTY & OFFERS IMPLEMENTATION
  // ---------------------------------------------------------------------------

  @override
  Future<LoyaltyProgramConfig> fetchLoyaltyConfig() async {
    final db = await _databaseService.database;
    final rows = await db.query('loyalty_settings', where: 'id = 1', limit: 1);
    if (rows.isNotEmpty) {
      return LoyaltyProgramConfig.fromMap(rows.first);
    }
    const defaultConfig = LoyaltyProgramConfig();
    await saveLoyaltyConfig(defaultConfig);
    return defaultConfig;
  }

  @override
  Future<void> saveLoyaltyConfig(LoyaltyProgramConfig config) async {
    final db = await _databaseService.database;
    final map = Map<String, dynamic>.from(config.toMap());
    map['company_id'] = _currentCompanyId;
    await db.insert(
      'loyalty_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    CloudSyncService.instance.pushLoyaltyConfig(_currentCompanyId, config);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchAllCustomerLoyaltyData() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'customer_loyalty',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
    );
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final custId = row['customer_id'] as String;
      result[custId] = row;
    }
    return result;
  }

  @override
  Future<void> updateCustomerLoyalty({
    required String customerId,
    int? points,
    int? pointsRedeemed,
    bool? marketingConsent,
    String? notes,
  }) async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'customer_loyalty',
      where: 'customer_id = ? AND ${_whereCompany()}',
      whereArgs: [customerId, _currentCompanyId],
      limit: 1,
    );

    final map = <String, dynamic>{
      'customer_id': customerId,
      'company_id': _currentCompanyId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isEmpty) {
      map['points'] = points ?? 0;
      map['points_redeemed'] = pointsRedeemed ?? 0;
      map['marketing_consent'] = (marketingConsent ?? true) ? 1 : 0;
      map['notes'] = notes ?? '';
      await db.insert('customer_loyalty', map);
    } else {
      if (points != null) map['points'] = points;
      if (pointsRedeemed != null) map['points_redeemed'] = pointsRedeemed;
      if (marketingConsent != null) map['marketing_consent'] = marketingConsent ? 1 : 0;
      if (notes != null) map['notes'] = notes;
      await db.update(
        'customer_loyalty',
        map,
        where: 'customer_id = ? AND ${_whereCompany()}',
        whereArgs: [customerId, _currentCompanyId],
      );
    }

    CloudSyncService.instance.pushCustomerLoyalty(_currentCompanyId, customerId, map);
  }

  @override
  Future<List<Offer>> fetchOffers() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'offers',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'valid_until DESC',
    );
    return rows.map((r) => Offer.fromMap(r)).toList();
  }

  @override
  Future<void> saveOffer(Offer offer) async {
    final db = await _databaseService.database;
    final map = Map<String, dynamic>.from(offer.toMap());
    map['company_id'] = _currentCompanyId;
    await db.insert('offers', map, conflictAlgorithm: ConflictAlgorithm.replace);
    CloudSyncService.instance.pushOffer(_currentCompanyId, offer);
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    final db = await _databaseService.database;
    await db.delete(
      'offers',
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [offerId, _currentCompanyId],
    );
    CloudSyncService.instance.deleteOffer(_currentCompanyId, offerId);
  }

  @override
  Future<List<OfferTracking>> fetchOfferTracking() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'offer_tracking',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'sent_at DESC',
    );
    return rows.map((r) => OfferTracking.fromMap(r)).toList();
  }

  @override
  Future<void> recordOfferSent(OfferTracking tracking) async {
    final db = await _databaseService.database;
    final map = Map<String, dynamic>.from(tracking.toMap());
    map['company_id'] = _currentCompanyId;
    await db.insert('offer_tracking', map, conflictAlgorithm: ConflictAlgorithm.replace);
    CloudSyncService.instance.pushOfferTracking(_currentCompanyId, tracking);
  }

  @override
  Future<void> recordOfferRedeemed({
    required String trackingId,
    required String billId,
    required int salesAmount,
  }) async {
    final db = await _databaseService.database;
    await db.update(
      'offer_tracking',
      {
        'is_redeemed': 1,
        'redeemed_at': DateTime.now().toIso8601String(),
        'bill_id': billId,
        'sales_generated': salesAmount,
        'company_id': _currentCompanyId,
      },
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [trackingId, _currentCompanyId],
    );
    final rows = await db.query(
      'offer_tracking',
      where: 'id = ? AND ${_whereCompany()}',
      whereArgs: [trackingId, _currentCompanyId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      CloudSyncService.instance.pushOfferTracking(_currentCompanyId, OfferTracking.fromMap(rows.first));
    }
  }

  // ---------------------------------------------------------------------------
  // RETURNS & EXCHANGES IMPLEMENTATION
  // ---------------------------------------------------------------------------

  @override
  Future<List<ReturnRecord>> fetchReturns() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'returns',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => ReturnRecord.fromMap(r)).toList();
  }

  @override
  Future<ReturnRecord> createReturnOrExchange(ReturnRecord returnRecord) async {
    final db = await _databaseService.database;
    return db.transaction((txn) async {
      final map = Map<String, dynamic>.from(returnRecord.toMap());
      map['company_id'] = _currentCompanyId;
      await txn.insert('returns', map, conflictAlgorithm: ConflictAlgorithm.replace);

      // If return is approved or completed, apply inventory updates immediately
      if (returnRecord.status == ReturnStatus.approved || returnRecord.status == ReturnStatus.completed) {
        await _applyInventoryForReturn(txn, returnRecord);
      }

      // Cloud background sync
      CloudSyncService.instance.pushReturn(_currentCompanyId, returnRecord);

      return returnRecord;
    });
  }

  Future<void> _applyInventoryForReturn(Transaction txn, ReturnRecord returnRecord) async {
    // 1. Returned products stock adjustment
    for (final item in returnRecord.items) {
      if (item.productId.isNotEmpty) {
        if (item.condition.canRestock) {
          // Sellable condition -> restock into inventory
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ? AND ${_whereCompany()}',
            [item.qty, item.productId, _currentCompanyId],
          );

          final movement = StockMovement(
            id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            movementType: 'return_sellable',
            qtyChange: item.qty,
            referenceId: returnRecord.id,
            createdAt: DateTime.now(),
            note: 'Restocked from ${returnRecord.id} (Bill: ${returnRecord.billId}) - Condition: Sellable',
          );
          final mMap = Map<String, dynamic>.from(movement.toMap());
          mMap['company_id'] = _currentCompanyId;
          await txn.insert('stock_movements', mMap);
          CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
        } else {
          // Damaged / defective / worn -> quarantine
          final movement = StockMovement(
            id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            movementType: 'return_damaged',
            qtyChange: 0,
            referenceId: returnRecord.id,
            createdAt: DateTime.now(),
            note: 'Quarantined ${item.qty} units from ${returnRecord.id} - Condition: ${item.condition.displayName}',
          );
          final mMap = Map<String, dynamic>.from(movement.toMap());
          mMap['company_id'] = _currentCompanyId;
          await txn.insert('stock_movements', mMap);
          CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
        }
      }
    }

    // 2. Exchange replacement products deduction
    if (returnRecord.isExchange) {
      for (final exch in returnRecord.exchangeItems) {
        if (exch.productId.isNotEmpty) {
          await txn.rawUpdate(
            'UPDATE products SET stock = CASE WHEN stock - ? < 0 THEN 0 ELSE stock - ? END WHERE id = ? AND ${_whereCompany()}',
            [exch.qty, exch.qty, exch.productId, _currentCompanyId],
          );

          final movement = StockMovement(
            id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
            productId: exch.productId,
            productName: exch.productName,
            movementType: 'exchange_outflow',
            qtyChange: -exch.qty,
            referenceId: returnRecord.id,
            createdAt: DateTime.now(),
            note: 'Replacement given for ${returnRecord.id} (Bill: ${returnRecord.billId})',
          );
          final mMap = Map<String, dynamic>.from(movement.toMap());
          mMap['company_id'] = _currentCompanyId;
          await txn.insert('stock_movements', mMap);
          CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
        }
      }
    }
  }

  @override
  Future<void> updateReturnStatus({
    required String returnId,
    required ReturnStatus status,
    required String approvedBy,
    String? rejectionReason,
  }) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'returns',
        where: 'id = ? AND ${_whereCompany()}',
        whereArgs: [returnId, _currentCompanyId],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final previousRecord = ReturnRecord.fromMap(rows.first);
      final wasAlreadyApproved = previousRecord.status == ReturnStatus.approved ||
          previousRecord.status == ReturnStatus.completed;

      final updatedRecord = previousRecord.copyWith(
        status: status,
        approvedBy: approvedBy,
        rejectionReason: rejectionReason,
        processedAt: DateTime.now(),
        refundStatus: status == ReturnStatus.completed ? 'Completed' : previousRecord.refundStatus,
      );

      final rMap = Map<String, dynamic>.from(updatedRecord.toMap());
      rMap['company_id'] = _currentCompanyId;
      await txn.update(
        'returns',
        rMap,
        where: 'id = ? AND ${_whereCompany()}',
        whereArgs: [returnId, _currentCompanyId],
      );

      // If newly approved/completed and wasn't previously applied, update inventory
      if (!wasAlreadyApproved && (status == ReturnStatus.approved || status == ReturnStatus.completed)) {
        await _applyInventoryForReturn(txn, updatedRecord);
      }

      CloudSyncService.instance.pushReturn(_currentCompanyId, updatedRecord);
    });
  }

  @override
  Future<List<StockMovement>> fetchStockMovements() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'stock_movements',
      where: _whereCompany(),
      whereArgs: [_currentCompanyId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => StockMovement.fromMap(r)).toList();
  }

  @override
  Future<void> recordStockMovement(StockMovement movement) async {
    final db = await _databaseService.database;
    final mMap = Map<String, dynamic>.from(movement.toMap());
    mMap['company_id'] = _currentCompanyId;
    await db.insert('stock_movements', mMap, conflictAlgorithm: ConflictAlgorithm.replace);
    CloudSyncService.instance.pushStockMovement(_currentCompanyId, movement);
  }
}
