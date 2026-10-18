import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService([this._customPath]);
  final String? _customPath;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath;
    if (_customPath != null) {
      dbPath = _customPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      dbPath = p.join(directory.path, 'ayesha_footwear.db');
    }

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedProducts(db);
        await _seedCategories(db);
        await _seedLoyaltyAndOffers(db);
      },
      onOpen: (db) async {
        await _createTables(db);
        try {
          await db.execute('ALTER TABLE bills ADD COLUMN items_json TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE products ADD COLUMN image_base64 TEXT');
        } catch (_) {}
        for (final table in [
          'products',
          'bills',
          'customers',
          'categories',
          'customer_loyalty',
          'loyalty_settings',
          'offers',
          'offer_tracking',
          'returns',
          'stock_movements',
        ]) {
          try {
            await db.execute('ALTER TABLE $table ADD COLUMN company_id TEXT DEFAULT "comp_ayesha_footwear"');
          } catch (_) {}
        }

        // Migrate existing tables that may have single-column UNIQUE constraints
        await _migrateCustomerTable(db);
        await _migrateCategoriesTable(db);
        await _migrateOffersTable(db);

        final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM products');
        final count = (result.first['cnt'] as num?)?.toInt() ?? 0;
        if (count == 0) {
          await _seedProducts(db);
        }
        try {
          final catRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM categories');
          final catCount = (catRes.first['cnt'] as num?)?.toInt() ?? 0;
          if (catCount == 0) {
            await _seedCategories(db);
          }
        } catch (_) {}
        await _seedLoyaltyAndOffers(db);
      },
    );
  }

  Future<void> _migrateCustomerTable(Database db) async {
    try {
      final res = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='customers'",
      );
      if (res.isNotEmpty) {
        final sql = (res.first['sql'] as String? ?? '').toLowerCase();
        if (sql.contains('mobile text not null unique') ||
            sql.contains('unique (mobile)') ||
            sql.contains('unique(mobile)')) {
          await db.execute('''
            CREATE TABLE customers_temp (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              mobile TEXT NOT NULL,
              size TEXT NOT NULL,
              colors TEXT NOT NULL,
              last_item TEXT NOT NULL,
              total_spent INTEGER NOT NULL,
              visits INTEGER NOT NULL,
              note TEXT NOT NULL,
              company_id TEXT DEFAULT 'comp_ayesha_footwear'
            )
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO customers_temp 
            SELECT id, name, mobile, size, colors, last_item, total_spent, visits, note, COALESCE(company_id, 'comp_ayesha_footwear')
            FROM customers
          ''');
          await db.execute('DROP TABLE customers');
          await db.execute('ALTER TABLE customers_temp RENAME TO customers');
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_mobile_company ON customers(mobile, company_id)',
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _migrateCategoriesTable(Database db) async {
    try {
      final res = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='categories'",
      );
      if (res.isNotEmpty) {
        final sql = (res.first['sql'] as String? ?? '').toLowerCase();
        if (sql.contains('name text primary key') || !sql.contains('primary key (name, company_id)')) {
          await db.execute('''
            CREATE TABLE categories_temp (
              name TEXT NOT NULL,
              company_id TEXT DEFAULT 'comp_ayesha_footwear',
              PRIMARY KEY (name, company_id)
            )
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO categories_temp 
            SELECT name, COALESCE(company_id, 'comp_ayesha_footwear')
            FROM categories
          ''');
          await db.execute('DROP TABLE categories');
          await db.execute('ALTER TABLE categories_temp RENAME TO categories');
        }
      }
    } catch (_) {}
  }

  Future<void> _migrateOffersTable(Database db) async {
    try {
      final res = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='offers'",
      );
      if (res.isNotEmpty) {
        final sql = (res.first['sql'] as String? ?? '').toLowerCase();
        if (sql.contains('code text not null unique')) {
          await db.execute('''
            CREATE TABLE offers_temp (
              id TEXT PRIMARY KEY,
              code TEXT NOT NULL,
              title TEXT NOT NULL,
              discount_type TEXT NOT NULL,
              discount_value REAL NOT NULL,
              min_spend INTEGER NOT NULL,
              applicable_category TEXT NOT NULL,
              target_segment TEXT NOT NULL,
              valid_from TEXT NOT NULL,
              valid_until TEXT NOT NULL,
              message_template TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              company_id TEXT DEFAULT 'comp_ayesha_footwear'
            )
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO offers_temp 
            SELECT id, code, title, discount_type, discount_value, min_spend, applicable_category, target_segment, valid_from, valid_until, message_template, is_active, COALESCE(company_id, 'comp_ayesha_footwear')
            FROM offers
          ''');
          await db.execute('DROP TABLE offers');
          await db.execute('ALTER TABLE offers_temp RENAME TO offers');
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_offers_code_company ON offers(code, company_id)',
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        name TEXT NOT NULL,
        company_id TEXT DEFAULT 'comp_ayesha_footwear',
        PRIMARY KEY (name, company_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        size TEXT NOT NULL,
        colors TEXT NOT NULL,
        last_item TEXT NOT NULL,
        total_spent INTEGER NOT NULL,
        visits INTEGER NOT NULL,
        note TEXT NOT NULL,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_mobile_company ON customers(mobile, company_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        stock INTEGER NOT NULL,
        price INTEGER NOT NULL,
        sizes TEXT NOT NULL,
        colors TEXT NOT NULL,
        image_path TEXT,
        image_base64 TEXT,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bills (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        item TEXT NOT NULL,
        size TEXT NOT NULL,
        color TEXT NOT NULL,
        qty INTEGER NOT NULL,
        price INTEGER NOT NULL,
        discount INTEGER NOT NULL,
        total INTEGER NOT NULL,
        pay_mode TEXT NOT NULL,
        note TEXT NOT NULL,
        items_json TEXT,
        created_at TEXT NOT NULL,
        company_id TEXT DEFAULT 'comp_ayesha_footwear',
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_loyalty (
        customer_id TEXT PRIMARY KEY,
        points INTEGER NOT NULL DEFAULT 0,
        points_redeemed INTEGER NOT NULL DEFAULT 0,
        marketing_consent INTEGER NOT NULL DEFAULT 1,
        notes TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS loyalty_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        points_per_100_spent INTEGER NOT NULL DEFAULT 1,
        point_value_rupees REAL NOT NULL DEFAULT 1.0,
        min_points_to_redeem INTEGER NOT NULL DEFAULT 50,
        welcome_bonus_points INTEGER NOT NULL DEFAULT 50,
        high_spending_threshold INTEGER NOT NULL DEFAULT 5000,
        loyal_visits_threshold INTEGER NOT NULL DEFAULT 3,
        inactive_days_threshold INTEGER NOT NULL DEFAULT 45,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        title TEXT NOT NULL,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        min_spend INTEGER NOT NULL,
        applicable_category TEXT NOT NULL,
        target_segment TEXT NOT NULL,
        valid_from TEXT NOT NULL,
        valid_until TEXT NOT NULL,
        message_template TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_offers_code_company ON offers(code, company_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offer_tracking (
        id TEXT PRIMARY KEY,
        offer_id TEXT NOT NULL,
        offer_code TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        is_redeemed INTEGER NOT NULL DEFAULT 0,
        redeemed_at TEXT,
        bill_id TEXT,
        sales_generated INTEGER NOT NULL DEFAULT 0,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS returns (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        return_reason TEXT NOT NULL,
        product_condition TEXT NOT NULL,
        returned_total_amount INTEGER NOT NULL,
        exchange_total_amount INTEGER NOT NULL,
        net_amount INTEGER NOT NULL,
        refund_method TEXT NOT NULL,
        refund_status TEXT NOT NULL,
        transaction_ref TEXT,
        approved_by TEXT NOT NULL,
        rejection_reason TEXT,
        created_at TEXT NOT NULL,
        processed_at TEXT,
        notes TEXT,
        items_json TEXT NOT NULL,
        exchange_items_json TEXT,
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        qty_change INTEGER NOT NULL,
        reference_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        company_id TEXT DEFAULT 'comp_ayesha_footwear'
      )
    ''');
  }

  Future<void> _seedLoyaltyAndOffers(Database db) async {
    // 1. Seed Loyalty settings if not exists
    await db.insert('loyalty_settings', {
      'id': 1,
      'points_per_100_spent': 1,
      'point_value_rupees': 1.0,
      'min_points_to_redeem': 50,
      'welcome_bonus_points': 50,
      'high_spending_threshold': 5000,
      'loyal_visits_threshold': 3,
      'inactive_days_threshold': 45,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 2. Seed default offers if empty
    final offerRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM offers');
    final offerCount = (offerRes.first['cnt'] as num?)?.toInt() ?? 0;
    if (offerCount == 0) {
      final now = DateTime.now();
      final nextMonth = now.add(const Duration(days: 45));
      final defaultOffers = [
        {
          'id': 'OFFER-001',
          'code': 'WELCOME10',
          'title': 'New Customer Welcome Gift',
          'discount_type': 'percentage',
          'discount_value': 10.0,
          'min_spend': 999,
          'applicable_category': 'All Categories',
          'target_segment': 'New Customer',
          'valid_from': now.toIso8601String(),
          'valid_until': nextMonth.toIso8601String(),
          'message_template': '',
          'is_active': 1,
        },
        {
          'id': 'OFFER-002',
          'code': 'LOYAL15',
          'title': 'Loyal Shopper Celebration',
          'discount_type': 'percentage',
          'discount_value': 15.0,
          'min_spend': 1499,
          'applicable_category': 'All Categories',
          'target_segment': 'Loyal Customer',
          'valid_from': now.toIso8601String(),
          'valid_until': nextMonth.toIso8601String(),
          'message_template': '',
          'is_active': 1,
        },
        {
          'id': 'OFFER-003',
          'code': 'VIP200',
          'title': 'High-Spending VIP Privilege',
          'discount_type': 'fixed',
          'discount_value': 200.0,
          'min_spend': 2499,
          'applicable_category': 'All Categories',
          'target_segment': 'High-Spending VIP',
          'valid_from': now.toIso8601String(),
          'valid_until': nextMonth.toIso8601String(),
          'message_template': '',
          'is_active': 1,
        },
        {
          'id': 'OFFER-004',
          'code': 'COMEBACK15',
          'title': 'We Miss You - Win Back Voucher',
          'discount_type': 'percentage',
          'discount_value': 15.0,
          'min_spend': 999,
          'applicable_category': 'All Categories',
          'target_segment': 'Inactive / At Risk',
          'valid_from': now.toIso8601String(),
          'valid_until': nextMonth.toIso8601String(),
          'message_template': '',
          'is_active': 1,
        },
        {
          'id': 'OFFER-005',
          'code': 'FESTIVE20',
          'title': 'Festive Footwear Bonanza',
          'discount_type': 'percentage',
          'discount_value': 20.0,
          'min_spend': 1999,
          'applicable_category': 'All Categories',
          'target_segment': 'All',
          'valid_from': now.toIso8601String(),
          'valid_until': nextMonth.toIso8601String(),
          'message_template': '',
          'is_active': 1,
        },
      ];
      for (final offer in defaultOffers) {
        await db.insert('offers', offer, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> _seedProducts(Database db, [String companyId = 'comp_ayesha_footwear']) async {
    final cleanCompanyId = companyId.trim().isNotEmpty ? companyId.trim() : 'comp_ayesha_footwear';
    final idPrefix = cleanCompanyId == 'comp_ayesha_footwear' ? 'PROD' : 'PROD-${cleanCompanyId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

    final seeds = [
      {
        'id': '$idPrefix-001',
        'name': 'Italian Formal Leather Shoes',
        'category': 'Men Formal',
        'stock': 15,
        'price': 2499,
        'sizes': '6,7,8,9,10',
        'colors': 'Black,Brown,Tan',
        'company_id': cleanCompanyId,
      },
      {
        'id': '$idPrefix-002',
        'name': 'Air Comfort Running Sneakers',
        'category': 'Men Sports',
        'stock': 20,
        'price': 1899,
        'sizes': '7,8,9,10,11',
        'colors': 'White,Black,Navy Blue',
        'company_id': cleanCompanyId,
      },
      {
        'id': '$idPrefix-003',
        'name': 'Designer Velvet High Heels',
        'category': 'Women Heels',
        'stock': 12,
        'price': 2199,
        'sizes': '5,6,7,8',
        'colors': 'Red,Black,Gold',
        'company_id': cleanCompanyId,
      },
      {
        'id': '$idPrefix-004',
        'name': 'Casual Comfort Daily Flat Sandals',
        'category': 'Women Flats',
        'stock': 25,
        'price': 999,
        'sizes': '4,5,6,7,8',
        'colors': 'Beige,Pink,Tan',
        'company_id': cleanCompanyId,
      },
    ];

    for (final product in seeds) {
      await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedCategories(Database db, [String companyId = 'comp_ayesha_footwear']) async {
    final cleanCompanyId = companyId.trim().isNotEmpty ? companyId.trim() : 'comp_ayesha_footwear';
    const defaultCats = [
      'Men Formal',
      'Men Casual',
      'Men Sports',
      'Women Heels',
      'Women Flats',
      'Women Sandals',
      'Kids',
      'Accessories',
    ];
    for (final cat in defaultCats) {
      await db.insert(
        'categories',
        {'name': cat, 'company_id': cleanCompanyId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> seedCompanyDefaults(Database db, String companyId) async {
    final cleanCompanyId = companyId.trim().isNotEmpty ? companyId.trim() : 'comp_ayesha_footwear';

    // 1. Seed Categories if empty for this company
    final catRes = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM categories WHERE company_id = ?',
      [cleanCompanyId],
    );
    final catCount = (catRes.first['cnt'] as num?)?.toInt() ?? 0;
    if (catCount == 0) {
      await _seedCategories(db, cleanCompanyId);
    }

    // 2. Seed Starter Products if empty for this company
    final prodRes = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE company_id = ?',
      [cleanCompanyId],
    );
    final prodCount = (prodRes.first['cnt'] as num?)?.toInt() ?? 0;
    if (prodCount == 0) {
      await _seedProducts(db, cleanCompanyId);
    }
  }
}

