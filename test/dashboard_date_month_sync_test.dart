import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/models/product_draft.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/dashboard_view.dart';
import 'package:flutter/material.dart';
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
      (MethodCall methodCall) async => '.',
    );
  });

  group('Dashboard Month and Date Real-time Sync Tests', () {
    testWidgets('Dashboard dynamically updates sales, metrics, and recent bills on month change', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final vm = ShopViewModel(repo, ExcelExportService());

      await tester.runAsync(() async {
        await AuthService.instance.setDemoProfile(
          name: 'Atiqu Khan',
          companyName: 'Ayesha Footwear',
        );
        await vm.initialize();

        // Add a product
        final prod = await repo.saveProduct(
          const ProductDraft(
            name: 'Leather Formal Shoes',
            category: 'Men Formal',
            stock: 50,
            price: 2000,
            sizes: ['8', '9'],
            colors: ['Black'],
          ),
        );

        // Bill 1 in October 2026: Total ₹6,000 (3 items)
        await vm.createBill(
          BillDraft(
            customer: 'Aarav Sharma',
            mobile: '9876543210',
            discount: 0,
            note: '',
            payMode: 'Cash',
            items: [
              BillItem(
                productId: prod.id,
                productName: prod.name,
                size: '8',
                color: 'Black',
                price: 2000,
                qty: 3,
              ),
            ],
          ),
        );
        // Set time of Bill 1 to Oct 18, 2026
        final db = await dbService.database;
        final b1 = vm.bills.firstWhere((b) => b.customer == 'Aarav Sharma');
        await db.update('bills', {'created_at': '2026-10-18T10:30:00.000Z'}, where: 'id = ?', whereArgs: [b1.id]);

        // Bill 2 in September 2026: Total ₹4,000 (2 items)
        await vm.createBill(
          BillDraft(
            customer: 'Pooja Patel',
            mobile: '9123456780',
            discount: 0,
            note: '',
            payMode: 'UPI',
            items: [
              BillItem(
                productId: prod.id,
                productName: prod.name,
                size: '9',
                color: 'Black',
                price: 2000,
                qty: 2,
              ),
            ],
          ),
        );
        // Set time of Bill 2 to Sep 15, 2026
        final b2 = vm.bills.firstWhere((b) => b.customer == 'Pooja Patel');
        await db.update('bills', {'created_at': '2026-09-15T14:15:00.000Z'}, where: 'id = ?', whereArgs: [b2.id]);

        // Reload bills
        await vm.refresh();
      });

      // Initially set selected month to October 2026
      vm.setSelectedMonth(DateTime(2026, 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardView(
              viewModel: vm,
              onCreateBill: () {},
              onExportExcel: () {},
              onPreviewPdf: (_) {},
              onShare: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify October Data
      expect(find.text('Net Sales (October 2026)'), findsOneWidget);
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(find.text('₹6,000'), findsWidgets); // Net sales for October
      expect(find.text('3'), findsWidgets); // 3 items sold
      expect(find.text('Aarav Sharma'), findsOneWidget);

      // Now switch selected month to September 2026
      vm.setSelectedMonth(DateTime(2026, 9));
      await tester.pumpAndSettle();

      // Verify September Data reflects immediately
      expect(find.text('Net Sales (September 2026)'), findsOneWidget);
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('₹4,000'), findsWidgets); // Net sales for September
      expect(find.text('2'), findsWidgets); // 2 items sold
      expect(find.text('Pooja Patel'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsNothing); // October customer not in September recent bills

      // Now switch to August 2026 (Month with 0 sales)
      vm.setSelectedMonth(DateTime(2026, 8));
      await tester.pumpAndSettle();

      // Verify August Data reflects 0 sales without fake fallbacks
      expect(find.text('Net Sales (August 2026)'), findsOneWidget);
      expect(find.text('Aug 2026'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets); // Net sales is 0!
      expect(find.text('0'), findsWidgets); // 0 bills and 0 items!
      expect(find.text('No bills created in August 2026.'), findsOneWidget);
      expect(find.text('No product sales recorded in August.'), findsOneWidget);

      // Test specific day filter: Set selected date to Sep 15, 2026
      vm.setSelectedDate(DateTime(2026, 9, 15));
      await tester.pumpAndSettle();

      expect(find.text('15 Sep 2026'), findsOneWidget);
      expect(find.text('15 Sep Sales'), findsOneWidget);
      expect(find.text('₹4,000'), findsWidgets);
    });

    testWidgets('Tapping date pill opens Month Selection modal and selects month', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final vm = ShopViewModel(repo, ExcelExportService());

      await tester.runAsync(() async {
        await AuthService.instance.setDemoProfile();
        await vm.initialize();
      });

      vm.setSelectedMonth(DateTime(2026, 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardView(
              viewModel: vm,
              onCreateBill: () {},
              onExportExcel: () {},
              onPreviewPdf: (_) {},
              onShare: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the date pill
      final datePill = find.text('Oct 2026');
      expect(datePill, findsOneWidget);
      await tester.tap(datePill);
      await tester.pumpAndSettle();

      // Verify "Select Sales Month" dialog is open
      expect(find.text('Select Sales Month'), findsOneWidget);
      expect(find.text('Pick Date'), findsOneWidget);

      // Tap on 'Sep'
      final sepBtn = find.text('Sep');
      expect(sepBtn, findsOneWidget);
      await tester.tap(sepBtn);
      await tester.pumpAndSettle();

      // Dialog should close and dashboard should show Sep 2026
      expect(find.text('Select Sales Month'), findsNothing);
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(vm.selectedMonth.month, 9);
    });
  });
}
