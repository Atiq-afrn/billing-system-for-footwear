import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/models/product_draft.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  group('Product with Image & Dynamic Categories Tests', () {
    test('Product and ProductDraft store imagePath and serialize properly', () {
      const draft = ProductDraft(
        name: 'Running Shoes Pro',
        category: 'Sports Footwear',
        stock: 25,
        price: 1999,
        sizes: ['8', '9', '10'],
        colors: ['Blue', 'Grey'],
        imagePath: '/path/to/shoe_photo.jpg',
      );

      expect(draft.imagePath, '/path/to/shoe_photo.jpg');

      const prod = Product(
        id: 'P-TEST-1',
        name: 'Running Shoes Pro',
        category: 'Sports Footwear',
        stock: 25,
        price: 1999,
        sizes: ['8', '9'],
        colors: ['Blue'],
        imagePath: '/path/to/shoe_photo.jpg',
      );

      final map = prod.toMap();
      expect(map['image_path'], '/path/to/shoe_photo.jpg');

      final restored = Product.fromMap(map);
      expect(restored.imagePath, '/path/to/shoe_photo.jpg');
    });

    test('SQLite repository persists and loads product imagePath', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);

      const draft = ProductDraft(
        name: 'Leather Boots',
        category: 'Boots',
        stock: 15,
        price: 2499,
        sizes: ['7', '8', '9'],
        colors: ['Brown'],
        imagePath: '/test/local/image.jpg',
      );

      final saved = await repo.saveProduct(draft);
      expect(saved.imagePath, '/test/local/image.jpg');

      final list = await repo.fetchProducts();
      final fetched = list.firstWhere((p) => p.id == saved.id);
      expect(fetched.imagePath, '/test/local/image.jpg');
    });
  });

  group('Month-wise Sales & Customer Analytics Tests', () {
    test('ViewModel dynamic comparisons and customer month filtering calculate accurately', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final excelService = ExcelExportService();
      final vm = ShopViewModel(repo, excelService);
      await vm.initialize();

      // Verify custom category addition
      expect(vm.allCategories.contains('Traditional Jutti'), isFalse);
      vm.addCustomCategory('Traditional Jutti');
      expect(vm.allCategories.contains('Traditional Jutti'), isTrue);

      // Create bill in selected month
      final initialProducts = vm.products;
      expect(initialProducts.isNotEmpty, isTrue);
      final p1 = initialProducts.first;

      await vm.createBill(
        BillDraft(
          customer: 'Rahul Verma',
          mobile: '9876543210',
          items: [
            BillItem(
              productId: p1.id,
              productName: p1.name,
              size: p1.sizes.first,
              color: p1.colors.first,
              qty: 2,
              price: p1.price,
            ),
          ],
          discount: 0,
          payMode: 'UPI',
          note: 'Test note',
        ),
      );

      // Customer search with month filter
      final currentMonth = vm.selectedMonth;
      final currentCustomers = vm.searchCustomers('', month: currentMonth);
      expect(currentCustomers.any((c) => c.name == 'Rahul Verma'), isTrue);

      // Bills for customer
      final customer = currentCustomers.firstWhere((c) => c.name == 'Rahul Verma');
      final customerBills = vm.getBillsForCustomer(customer);
      expect(customerBills.isNotEmpty, isTrue);
      expect(customerBills.first.customer, 'Rahul Verma');

      // Top selling products contains our sold item
      final topSelling = vm.topSellingProducts;
      expect(topSelling.any((t) => t.productId == p1.id), isTrue);

      // Verify Single-shot monthly bill export
      final exportPath = await vm.exportMonthlyBills(currentMonth);
      expect(exportPath.endsWith('.xlsx'), isTrue);
    });
  });
}
