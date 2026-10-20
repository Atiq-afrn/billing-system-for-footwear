import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/add_product_sheet.dart';
import 'package:ayesha_footwear/views/change_upi_view.dart';
import 'package:ayesha_footwear/widgets/shop_drawer.dart';
import 'package:ayesha_footwear/widgets/shop_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Category Persistence & Removal in SQLite Repository', () {
    test('Categories can be seeded, added, and removed from SQLite database', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);

      // 1. Initial categories should include seeded defaults
      final initialCategories = await repo.fetchCategories();
      expect(initialCategories, contains('Men Formal'));
      expect(initialCategories, contains('Women Heels'));

      // 2. Add custom category
      await repo.addCategory('Kids School Shoes');
      final afterAdd = await repo.fetchCategories();
      expect(afterAdd, contains('Kids School Shoes'));

      // 3. Delete category from database
      await repo.deleteCategory('Kids School Shoes');
      final afterDelete = await repo.fetchCategories();
      expect(afterDelete, isNot(contains('Kids School Shoes')));

      // Also remove seeded default
      await repo.deleteCategory('Accessories');
      final afterDeleteSeeded = await repo.fetchCategories();
      expect(afterDeleteSeeded, isNot(contains('Accessories')));
    });

    test('ShopViewModel loads, adds, and removes categories from database correctly', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final vm = ShopViewModel(repo, ExcelExportService());

      await vm.initialize();
      expect(vm.allCategories, contains('Men Sports'));

      // Add category
      await vm.addCustomCategory('Leather Boots');
      expect(vm.allCategories, contains('Leather Boots'));

      // Remove category
      await vm.removeCategory('Leather Boots');
      expect(vm.allCategories, isNot(contains('Leather Boots')));
    });
  });

  group('Professional Compact App Bar Tests', () {
    testWidgets('Header renders with clean compact background, professional dark company name and styled icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Header(
              title: 'Ayesha Footwear',
              subtitle: 'Sales & Business Overview',
              unreadAlertsCount: 2,
              onNotificationsPressed: () {},
            ),
          ),
        ),
      );

      // Verify Header container is rendered
      expect(find.text('Ayesha Footwear'), findsOneWidget);
      expect(find.text('Sales & Business Overview'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify title has professional dark slate color
      final titleText = tester.widget<Text>(find.text('Ayesha Footwear'));
      expect(titleText.style?.color, const Color(0xFF0F172A));

      // Verify menu icon has professional dark color
      final menuIcon = tester.widget<Icon>(find.byIcon(Icons.menu_rounded));
      expect(menuIcon.color, const Color(0xFF0F172A));

      // Verify bell icon has professional dark color
      final bellIcon = tester.widget<Icon>(find.byIcon(Icons.notifications_outlined));
      expect(bellIcon.color, const Color(0xFF0F172A));
    });
  });

  group('Change UPI ID Dedicated View Tests', () {
    testWidgets('ChangeUpiView displays current UPI, OTP input, password mode, and verifies identity', (tester) async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final vm = ShopViewModel(repo, ExcelExportService());

      await tester.runAsync(() async {
        await AuthService.instance.setDemoProfile(
          name: 'Atiqu Khan',
          companyName: 'Ayesha Footwear',
          upiId: 'atiqullahkhan554@okicici',
          email: 'atiqu@ayeshafootwear.com',
        );
        await vm.initialize();
      });

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeUpiView(viewModel: vm, enableTimer: false),
        ),
      );
      await tester.pump();

      // Check current UPI displayed
      expect(find.text('atiqullahkhan554@okicici'), findsOneWidget);
      expect(find.text('Owner: Atiqu Khan'), findsOneWidget);

      // Step 1: OTP field exists
      expect(find.text('Email OTP Verification'), findsOneWidget);
      expect(find.text('Verify OTP & Proceed'), findsOneWidget);

      // Switch to password mode
      final passwordModeBtn = find.text("Didn't receive OTP? Use Password");
      expect(passwordModeBtn, findsOneWidget);
      await tester.tap(passwordModeBtn);
      await tester.pump();

      // Check password mode is shown
      expect(find.text('Password Authentication'), findsOneWidget);
      expect(find.text('Verify Password via Firebase'), findsOneWidget);

      // Switch back to OTP
      final backToOtpBtn = find.text('← Back to Email OTP');
      expect(backToOtpBtn, findsOneWidget);
      await tester.tap(backToOtpBtn);
      await tester.pump();
      expect(find.text('Email OTP Verification'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ShopDrawer Owner, UPI, and Logout Confirmation Tests', () {
    testWidgets('ShopDrawer displays owner name, UPI with change button, and asks confirmation on logout', (tester) async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService);
      final vm = ShopViewModel(repo, ExcelExportService());

      await tester.runAsync(() async {
        await AuthService.instance.setDemoProfile(
          name: 'Atiqu Khan',
          companyName: 'Ayesha Footwear',
          upiId: 'atiqullahkhan554@okicici',
        );
        await vm.initialize();
      });

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: ShopDrawer(
              viewModel: vm,
              onSelectTab: (_) {},
              onExportExcel: () {},
              onPreviewPdf: () {},
              onSendOffer: () {},
              onOpenQrScanner: () {},
            ),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Owner name and UPI ID in drawer
      expect(find.text('Owner: Atiqu Khan'), findsOneWidget);
      expect(find.text('atiqullahkhan554@okicici'), findsOneWidget);
      expect(find.text('CHANGE'), findsOneWidget);
      expect(find.text('Change UPI ID'), findsOneWidget);

      // Tap Sign Out button
      final signOutBtn = find.text('SIGN OUT');
      expect(signOutBtn, findsOneWidget);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out? You will need to sign in again to access the store.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel -> stays in app
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Sign Out'), findsNothing);
    });

    testWidgets('AddProductSheet adds new category via dialog without controller disposal exception', (WidgetTester tester) async {
      String? addedCategory;
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddProductSheet(
              onSave: (_) {},
              categories: const ['Men Formal', 'Men Casual'],
              onAddCategory: (cat) {
                addedCategory = cat;
              },
            ),
          ),
        ),
      );

      // Tap 'Add' button to open dialog
      final addCategoryBtn = find.text('Add');
      expect(addCategoryBtn, findsWidgets);
      await tester.tap(addCategoryBtn.first);
      await tester.pumpAndSettle();

      // Verify Dialog is open
      expect(find.text('New category'), findsOneWidget);
      expect(find.text('Add category'), findsOneWidget);

      // Enter category name
      await tester.enterText(find.widgetWithText(TextField, 'Category name'), 'Formal Loafers');
      await tester.pump();

      // Tap 'Add category' button
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();

      // Verify dialog is closed and callback was triggered without any controller disposal crash
      expect(find.text('New category'), findsNothing);
      expect(addedCategory, equals('Formal Loafers'));
    });
  });
}

