import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/models/product_draft.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:ayesha_footwear/views/app_splash_view.dart';
import 'package:ayesha_footwear/views/product_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Product Deletion Tests (Local SQLite & ShopViewModel)', () {
    test('SqliteShopRepository and ShopViewModel deleteProduct deletes product locally and from ViewModel', () async {
      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService, () => 'comp_test');
      final vm = ShopViewModel(repo, ExcelExportService(), null, dbService);

      await vm.initialize();

      // Add a product
      await vm.addProduct(
        const ProductDraft(
          name: 'Oxford Classic Brogues',
          category: 'Men Formal',
          stock: 15,
          price: 2499,
          sizes: ['7', '8', '9'],
          colors: ['Tan', 'Black'],
        ),
      );

      expect(vm.products.any((p) => p.name == 'Oxford Classic Brogues'), isTrue);
      final productToDelete = vm.products.firstWhere((p) => p.name == 'Oxford Classic Brogues');

      // Delete product
      await vm.deleteProduct(productToDelete.id);

      // Verify removed from ViewModel and Repository
      expect(vm.products.any((p) => p.id == productToDelete.id), isFalse);
      final refreshed = await repo.fetchProducts();
      expect(refreshed.any((p) => p.id == productToDelete.id), isFalse);
    });

    testWidgets('ProductDetailsView displays delete button, confirms via dialog, and executes deletion', (WidgetTester tester) async {
      Product? deletedProduct;

      final testProduct = Product(
        id: 'prod-delete-test',
        name: 'Royal Derby Shoes',
        category: 'Men Formal',
        stock: 5,
        price: 1899,
        sizes: const ['8', '9', '10'],
        colors: const ['Brown', 'Black'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailsView(
              product: testProduct,
              onDeleteProduct: (p) async {
                deletedProduct = p;
              },
            ),
          ),
        ),
      );

      // Verify product name and Delete button exist
      expect(find.text('Royal Derby Shoes'), findsOneWidget);
      final deleteBtn = find.text('DELETE PRODUCT FROM CATALOG');
      expect(deleteBtn, findsOneWidget);

      // Tap Delete button to open confirmation dialog
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog elements
      expect(find.text('Delete Product?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Royal Derby Shoes"?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel -> dialog closes, product NOT deleted
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Product?'), findsNothing);
      expect(deletedProduct, isNull);

      // Tap Delete button again, then confirm Delete
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify deletion callback was invoked
      expect(deletedProduct, isNotNull);
      expect(deletedProduct?.id, equals('prod-delete-test'));
    });
  });

  group('App Splash / Onboarding Flow & Goal Showcase Tests', () {
    testWidgets('AppSplashView renders all 4 goals, branding, and triggers get started flow', (WidgetTester tester) async {
      bool getStartedTapped = false;
      bool signInTapped = false;

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AppSplashView(
            onGetStarted: () => getStartedTapped = true,
            onSignIn: () => signInTapped = true,
          ),
        ),
      );

      // Pump animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      // Brand Title
      expect(find.text('FOOTWEAR POS'), findsOneWidget);
      expect(find.text('Everything your footwear store needs in one place'), findsOneWidget);

      // All 4 Goals of the entire app in a single screen
      expect(find.text('Fast POS Billing'), findsOneWidget);
      expect(find.text('Smart Stock & Sizes'), findsOneWidget);
      expect(find.text('Cloud Realtime Sync'), findsOneWidget);
      expect(find.text('Thermal & WhatsApp'), findsOneWidget);

      // Trust badges
      expect(find.text('100% Offline Ready'), findsOneWidget);
      expect(find.text('Multi-Tenant Isolated'), findsOneWidget);
      expect(find.text('Loyalty & Offers'), findsOneWidget);

      // Action Button
      final ctaBtn = find.text('GET STARTED / REGISTER STORE');
      expect(ctaBtn, findsOneWidget);

      // Tap CTA button
      await tester.tap(ctaBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(getStartedTapped, isTrue);
    });

    testWidgets('AppSplashView in Tour Mode hides get started / register and shows BACK TO STORE with dynamic store name', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSplashView(
              isTourMode: true,
              storeName: 'Royal Shoes Branch',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      // Brand Title should show dynamic store name
      expect(find.text('ROYAL SHOES BRANCH'), findsOneWidget);

      // Back button must be present in Tour Mode
      expect(find.text('BACK TO STORE'), findsOneWidget);

      // Registration/Get Started buttons must NOT be present in Tour Mode
      expect(find.text('GET STARTED / REGISTER STORE'), findsNothing);
      expect(find.text('Sign In'), findsNothing);
    });

    test('AuthService tracks splash completion and registration to prevent showing splash every time', () async {
      final auth = AuthService.instance;
      SharedPreferences.setMockInitialValues({});
      await auth.initialize();

      // Fresh state: not authenticated, splash not completed
      expect(auth.isAuthenticated, isFalse);
      expect(auth.hasCompletedSplash, isFalse);

      // User completes splash
      await auth.completeSplash();
      expect(auth.hasCompletedSplash, isTrue);

      // When registered, hasCompletedSplash remains true permanently
      await auth.setDemoProfile();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.hasCompletedSplash, isTrue);
    });
  });
}
