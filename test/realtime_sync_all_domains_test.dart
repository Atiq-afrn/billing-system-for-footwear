import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayesha_footwear/models/bill.dart';
import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/company_profile.dart';
import 'package:ayesha_footwear/models/customer.dart';
import 'package:ayesha_footwear/models/product_draft.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/customer_details_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Bill & Customer Model Deserialization & SQLite Safety', () {
    test('Bill.fromMap handles Firestore array items and toSqliteMap produces clean map', () {
      final firestoreBillMap = {
        'id': 'BILL-1001',
        'customer_id': 'CUST-1',
        'product_id': 'PROD-1',
        'customer_name': 'Atiq Khan',
        'mobile': '9876543210',
        'item': 'Formal Leather Shoes',
        'size': '8',
        'color': 'Black',
        'qty': 2.0,
        'price': 1500.0,
        'discount': 100.0,
        'total': 2900.0,
        'pay_mode': 'UPI',
        'note': 'Test note',
        'created_at': DateTime(2026, 3, 15, 10, 30).toIso8601String(),
        'items': [
          {
            'product_id': 'PROD-1',
            'product_name': 'Formal Leather Shoes',
            'size': '8',
            'color': 'Black',
            'qty': 2,
            'price': 1500,
          }
        ],
      };

      final bill = Bill.fromMap(firestoreBillMap, defaultId: 'BILL-1001');
      expect(bill.id, equals('BILL-1001'));
      expect(bill.customer, equals('Atiq Khan'));
      expect(bill.total, equals(2900));
      expect(bill.items.length, equals(1));
      expect(bill.items.first.productName, equals('Formal Leather Shoes'));

      // toSqliteMap MUST NOT contain any List objects that would crash SQLite
      final sqliteMap = bill.toSqliteMap();
      expect(sqliteMap.containsKey('items'), isFalse);
      expect(sqliteMap['items_json'] is String, isTrue);
      expect(sqliteMap['total'], equals(2900));
    });

    test('Customer.fromMap safely parses numbers and defaults with fallback doc id', () {
      final firestoreCustomerMap = {
        'name': 'Rahim Uddin',
        'mobile': '9123456780',
        'size': '9',
        'colors': 'Tan',
        'last_item': 'Oxford Shoes',
        'total_spent': 4500.0,
        'visits': 3.0,
        'note': 'Prefers leather',
      };

      final customer = Customer.fromMap(firestoreCustomerMap, defaultId: 'CUST-AUTO-1');
      expect(customer.id, equals('CUST-AUTO-1'));
      expect(customer.name, equals('Rahim Uddin'));
      expect(customer.totalSpent, equals(4500));
      expect(customer.visits, equals(3));
      expect(customer.colors, equals('Tan'));

      final outMap = customer.toMap();
      expect(outMap['id'], equals('CUST-AUTO-1'));
      expect(outMap['total_spent'], equals(4500));
      expect(outMap['visits'], equals(3));
    });

    test('CompanyProfile.fromMap parses safely without throwing on various date formats', () {
      final profileMap = {
        'id': 'comp_test',
        'name': 'Ayesha Premium Store',
        'upiId': 'ayesha@upi',
        'mobile': '9988776655',
        'createdAt': '2026-01-01T00:00:00.000',
        'address': 'Main Market',
      };

      final company = CompanyProfile.fromMap(profileMap);
      expect(company.id, equals('comp_test'));
      expect(company.name, equals('Ayesha Premium Store'));
      expect(company.upiId, equals('ayesha@upi'));
      expect(company.createdAt.year, equals(2026));
    });
  });

  group('Reactive CustomerDetailsView Integration Tests', () {
    late Directory tempDir;
    late DatabaseService databaseService;
    late SqliteShopRepository repository;
    late ShopViewModel viewModel;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ayesha_sync_test_');
      final dbPath = '${tempDir.path}/test_sync.db';
      databaseService = DatabaseService(dbPath);
      repository = SqliteShopRepository(databaseService, () => 'comp_ayesha_footwear');
      viewModel = ShopViewModel(repository, ExcelExportService());
      await viewModel.initialize();
    });

    tearDown(() async {
      viewModel.dispose();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('CustomerDetailsView automatically reflects updated spent and visits in real-time',
        (tester) async {
      late Customer initialCustomer;

      await tester.runAsync(() async {
        // 1. Add product to inventory
        await viewModel.addProduct(const ProductDraft(
          name: 'Running Sneaker',
          category: 'Men Sports',
          stock: 20,
          price: 2500,
          sizes: ['8', '9'],
          colors: ['White'],
        ));

        // 2. Create initial bill
        final initialDraft = BillDraft(
          customer: 'Faizan Ahmed',
          mobile: '9888877777',
          items: [
            BillItem(
              productId: viewModel.products.first.id,
              productName: 'Running Sneaker',
              size: '9',
              color: 'White',
              qty: 1,
              price: 2500,
            ),
          ],
          discount: 0,
          payMode: 'Cash',
          note: 'First purchase',
        );
        await viewModel.createBill(initialDraft);

        initialCustomer = viewModel.customers.firstWhere((c) => c.mobile == '9888877777');
      });

      expect(initialCustomer.totalSpent, equals(2500));
      expect(initialCustomer.visits, equals(1));

      // 3. Pump CustomerDetailsView
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: initialCustomer,
            viewModel: viewModel,
            onPreviewPdf: (_) {},
            onShare: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial stats on screen
      expect(find.text('Faizan Ahmed'), findsOneWidget);
      expect(find.text('9888877777'), findsOneWidget);
      expect(find.text('Purchase History (1 Bills)'), findsOneWidget);

      // 4. Simulate a new bill being added
      await tester.runAsync(() async {
        final secondDraft = BillDraft(
          customer: 'Faizan Ahmed',
          mobile: '9888877777',
          items: [
            BillItem(
              productId: viewModel.products.first.id,
              productName: 'Running Sneaker',
              size: '9',
              color: 'White',
              qty: 1,
              price: 2500,
            ),
          ],
          discount: 200,
          payMode: 'UPI',
          note: 'Second purchase with discount',
        );
        await viewModel.createBill(secondDraft);
      });

      // Pump frame to trigger ListenableBuilder
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the screen INSTANTLY and AUTOMATICALLY updated!
      expect(find.text('Purchase History (2 Bills)'), findsOneWidget);
      expect(find.text('2 Pairs Total'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 bills issued hero stat
    });
  });
}
