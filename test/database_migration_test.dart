import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ayesha_footwear/models/company_profile.dart';
import 'package:ayesha_footwear/services/database_migration_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late String testDbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() async {
    testDbPath = 'test_migration_${DateTime.now().millisecondsSinceEpoch}.db';
    databaseService = DatabaseService(testDbPath);
  });

  tearDown(() async {
    try {
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  });

  group('Database Migration Service Tests', () {
    test('Queries and counts all 10 existing SQLite tables accurately', () async {
      final service = DatabaseMigrationService.instance;
      final counts = await service.getLocalTableCounts(databaseService);

      expect(counts.length, 10);
      expect(counts.containsKey('categories'), isTrue);
      expect(counts.containsKey('products'), isTrue);
      expect(counts.containsKey('customers'), isTrue);
      expect(counts.containsKey('bills'), isTrue);
      expect(counts.containsKey('customer_loyalty'), isTrue);
      expect(counts.containsKey('loyalty_settings'), isTrue);
      expect(counts.containsKey('offers'), isTrue);
      expect(counts.containsKey('offer_tracking'), isTrue);
      expect(counts.containsKey('returns'), isTrue);
      expect(counts.containsKey('stock_movements'), isTrue);

      // Verify default seeded counts
      expect(counts['categories'], greaterThanOrEqualTo(8));
      expect(counts['products'], greaterThanOrEqualTo(4));
      expect(counts['loyalty_settings'], 1);
      expect(counts['offers'], greaterThanOrEqualTo(5));
    });

    test('Extracts complete SQLite records preserving IDs, fields, and image references', () async {
      final service = DatabaseMigrationService.instance;
      final company = CompanyProfile(
        id: 'comp_ayesha_footwear',
        name: 'Ayesha Footwear Kanpur',
        ownerUid: 'uid_test',
        mobile: '9876543210',
        upiId: 'ayesha@okaxis',
        createdAt: DateTime.now(),
      );

      final dump = await service.extractAllSqliteData(
        databaseService: databaseService,
        companyId: company.id,
        companyProfile: company,
      );

      expect(dump['companyId'], 'comp_ayesha_footwear');
      expect(dump['schemaVersion'], 2);

      final tables = dump['tables'] as Map<String, List<Map<String, dynamic>>>;
      expect(tables.length, 10);

      // Verify Products table preserves IDs and image_path
      final products = tables['products']!;
      expect(products.isNotEmpty, isTrue);
      final firstProduct = products.first;
      expect(firstProduct.containsKey('id'), isTrue);
      expect(firstProduct.containsKey('name'), isTrue);
      expect(firstProduct.containsKey('price'), isTrue);
      expect(firstProduct.containsKey('stock'), isTrue);
      expect(firstProduct.containsKey('image_path'), isTrue);

      // Verify Categories table preserves primary key name
      final categories = tables['categories']!;
      expect(categories.any((c) => c['name'] == 'Men Formal'), isTrue);

      // Verify Offers table preserves codes and IDs
      final offers = tables['offers']!;
      expect(offers.any((o) => o['code'] == 'WELCOME10'), isTrue);
    });

    test('Exports all SQLite records into local JSON file dump', () async {
      final service = DatabaseMigrationService.instance;
      final jsonPath = await service.exportSqliteToJsonFile(
        databaseService: databaseService,
        companyId: 'comp_ayesha_footwear',
        targetDirectoryPath: '.',
      );

      final file = File(jsonPath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('comp_ayesha_footwear'));
      expect(content, contains('Italian Formal Leather Shoes'));
      expect(content, contains('WELCOME10'));

      // Cleanup generated JSON file
      await file.delete();
    });
  });
}
