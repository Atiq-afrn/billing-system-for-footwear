import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/company_profile.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/services/cloud_sync_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-Company Billing & Category Sync Tests', () {
    test('Can generate bills and isolate customers/bills across multiple companies', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      String activeCompanyId = 'comp_store_1';
      final repository = SqliteShopRepository(dbService, () => activeCompanyId);
      final viewModel = ShopViewModel(repository, ExcelExportService(), null, dbService);

      final db = await dbService.database;

      // 1. Seed Company 1
      await dbService.seedCompanyDefaults(db, 'comp_store_1');
      await viewModel.initialize();

      expect(viewModel.products.isNotEmpty, isTrue, reason: 'Company 1 should have starter products');
      expect(viewModel.allCategories.isNotEmpty, isTrue, reason: 'Company 1 should have categories');

      // 2. Generate Bill in Company 1
      final comp1Product = viewModel.products.first;
      final billDraft1 = BillDraft(
        customer: 'Aarav Sharma',
        mobile: '9876543210',
        items: [
          BillItem(
            productId: comp1Product.id,
            productName: comp1Product.name,
            size: '8',
            color: 'Black',
            qty: 1,
            price: comp1Product.price,
          ),
        ],
        discount: 0,
        payMode: 'Cash',
        note: 'First invoice Company 1',
      );

      await viewModel.createBill(billDraft1);

      // Verify Company 1 state
      expect(viewModel.bills.length, 1);
      expect(viewModel.bills.first.customer, 'Aarav Sharma');
      expect(viewModel.bills.first.mobile, '9876543210');
      expect(viewModel.customers.length, 1);
      expect(viewModel.customers.first.name, 'Aarav Sharma');
      expect(viewModel.customers.first.mobile, '9876543210');

      // 3. Register & Switch to Company 2
      final company2 = CompanyProfile(
        id: 'comp_store_2',
        name: 'Ayesha Footwear Branch #2',
        ownerUid: 'owner_1',
        mobile: '9876543210',
        upiId: 'branch2@okicici',
        createdAt: DateTime.now(),
      );

      activeCompanyId = 'comp_store_2';
      await viewModel.switchCompany(company2);

      // Verify Company 2 is isolated
      expect(viewModel.companyId, 'comp_store_2');
      expect(viewModel.bills.length, 0, reason: 'Company 2 should start with 0 bills');
      expect(viewModel.customers.length, 0, reason: 'Company 2 should start with 0 customers');
      expect(viewModel.products.isNotEmpty, isTrue, reason: 'Company 2 should have starter products seeded');
      expect(viewModel.allCategories.isNotEmpty, isTrue, reason: 'Company 2 should have categories seeded');

      // 4. Generate Bill in Company 2 for customer with SAME mobile number (must not crash with UNIQUE constraint error!)
      final comp2Product = viewModel.products.first;
      final billDraft2 = BillDraft(
        customer: 'Aarav Sharma',
        mobile: '9876543210', // Same mobile number as Company 1!
        items: [
          BillItem(
            productId: comp2Product.id,
            productName: comp2Product.name,
            size: '9',
            color: 'Brown',
            qty: 1,
            price: comp2Product.price,
          ),
        ],
        discount: 50,
        payMode: 'UPI',
        note: 'Invoice Company 2 with same customer',
      );

      // This previously crashed with `UNIQUE constraint failed: customers.mobile`
      await viewModel.createBill(billDraft2);

      // Verify Company 2 now shows bill and customer
      expect(viewModel.bills.length, 1);
      expect(viewModel.bills.first.customer, 'Aarav Sharma');
      expect(viewModel.bills.first.total, comp2Product.price - 50);
      expect(viewModel.customers.length, 1);
      expect(viewModel.customers.first.mobile, '9876543210');

      // 5. Add a 2nd customer in Company 2
      final billDraft3 = BillDraft(
        customer: 'Rohan Verma',
        mobile: '9123456780',
        items: [
          BillItem(
            productId: comp2Product.id,
            productName: comp2Product.name,
            size: '7',
            color: 'Tan',
            qty: 1,
            price: comp2Product.price,
          ),
        ],
        discount: 0,
        payMode: 'Card',
        note: 'Second customer in Company 2',
      );
      await viewModel.createBill(billDraft3);

      expect(viewModel.bills.length, 2);
      expect(viewModel.customers.length, 2);

      // 6. Switch back to Company 1 and verify data integrity
      final company1 = CompanyProfile(
        id: 'comp_store_1',
        name: 'Ayesha Footwear Main Store',
        ownerUid: 'owner_1',
        mobile: '9876543210',
        upiId: 'ayesha@okaxis',
        createdAt: DateTime.now(),
      );

      activeCompanyId = 'comp_store_1';
      await viewModel.switchCompany(company1);

      // Company 1 should still have ONLY its 1 original bill and 1 original customer
      expect(viewModel.companyId, 'comp_store_1');
      expect(viewModel.bills.length, 1);
      expect(viewModel.customers.length, 1);
      expect(viewModel.customers.first.name, 'Aarav Sharma');
    });

    test('Category addition, deletion, and cloud sync isolation work across companies', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      String activeCompanyId = 'comp_store_alpha';
      final repository = SqliteShopRepository(dbService, () => activeCompanyId);
      final viewModel = ShopViewModel(repository, ExcelExportService(), null, dbService);

      final db = await dbService.database;
      await dbService.seedCompanyDefaults(db, 'comp_store_alpha');
      await viewModel.initialize();

      // Add category in Store Alpha
      await viewModel.addCustomCategory('Wedding Collection');
      expect(viewModel.allCategories, contains('Wedding Collection'));

      // Switch to Store Beta
      final companyBeta = CompanyProfile(
        id: 'comp_store_beta',
        name: 'Store Beta',
        ownerUid: 'owner_1',
        mobile: '9999999999',
        upiId: 'beta@okaxis',
        createdAt: DateTime.now(),
      );
      activeCompanyId = 'comp_store_beta';
      await viewModel.switchCompany(companyBeta);

      // Store Beta should NOT have 'Wedding Collection'
      expect(viewModel.allCategories, isNot(contains('Wedding Collection')));

      // Store Beta adds its own category
      await viewModel.addCustomCategory('Monsoon Slippers');
      expect(viewModel.allCategories, contains('Monsoon Slippers'));

      // Store Beta removes a category
      await viewModel.removeCategory('Monsoon Slippers');
      expect(viewModel.allCategories, isNot(contains('Monsoon Slippers')));

      // Also remove a seeded category in Store Beta
      await viewModel.removeCategory('Accessories');
      expect(viewModel.allCategories, isNot(contains('Accessories')));

      // Switch back to Store Alpha
      final companyAlpha = CompanyProfile(
        id: 'comp_store_alpha',
        name: 'Store Alpha',
        ownerUid: 'owner_1',
        mobile: '8888888888',
        upiId: 'alpha@okaxis',
        createdAt: DateTime.now(),
      );
      activeCompanyId = 'comp_store_alpha';
      await viewModel.switchCompany(companyAlpha);

      // Store Alpha should still have 'Wedding Collection' and 'Accessories'
      expect(viewModel.allCategories, contains('Wedding Collection'));
      expect(viewModel.allCategories, contains('Accessories'));
    });
  });
}
