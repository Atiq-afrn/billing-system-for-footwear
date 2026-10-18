import 'package:ayesha_footwear/models/company_profile.dart';
import 'package:ayesha_footwear/models/user_profile.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/views/auth_view.dart';
import 'package:ayesha_footwear/views/company_selection_view.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:ayesha_footwear/services/excel_export_service.dart';
import 'package:ayesha_footwear/view_models/shop_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('Firebase Auth & Company Flow Tests', () {
    test('UserProfile model serialization and immutability', () {
      final profile = UserProfile(
        uid: 'user_123',
        name: 'Atiqu Khan',
        mobile: '9876543210',
        email: 'atiqu@ayeshafootwear.com',
        companyName: 'Ayesha Footwear Pro',
        upiId: 'atiqullahkhan554@okicici',
        createdAt: DateTime(2026, 10, 6),
      );

      final map = profile.toMap();
      expect(map['companyName'], 'Ayesha Footwear Pro');
      expect(map['upiId'], 'atiqullahkhan554@okicici');

      final deserialized = UserProfile.fromMap(map, defaultUid: 'user_123');
      expect(deserialized.companyName, 'Ayesha Footwear Pro');
      expect(deserialized.name, 'Atiqu Khan');
      expect(deserialized.upiId, 'atiqullahkhan554@okicici');

      final copied = profile.copyWith(companyName: 'Super Footwear');
      expect(copied.companyName, 'Super Footwear');
      expect(copied.upiId, 'atiqullahkhan554@okicici');
    });

    test('AuthService setDemoProfile and company selection lifecycle', () async {
      final auth = AuthService.instance;

      await auth.setDemoProfile(
        name: 'Test Owner',
        companyName: 'Test Footwear',
        upiId: 'test@upi',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.activeCompany?.name, 'Test Footwear');
      expect(auth.activeCompanyId, isNotEmpty);
      expect(auth.authorizedCompanies.length, 1);

      // Select another branch
      final branch = CompanyProfile(
        id: 'comp_branch_south',
        name: 'Ayesha Footwear South Branch',
        ownerUid: 'demo_user',
        mobile: '9876543210',
        upiId: 'branch@upi',
        createdAt: DateTime.now(),
      );
      await auth.selectCompany(branch);
      expect(auth.activeCompanyId, 'comp_branch_south');
      expect(auth.activeCompany?.name, 'Ayesha Footwear South Branch');

      // Logout clears active company and in-memory session
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentProfile, isNull);
      expect(auth.activeCompany, isNull);
      expect(auth.authorizedCompanies, isEmpty);
    });

    testWidgets('AuthView renders Sign In and Register Company modes smoothly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool authSuccessCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthView(
            onAuthSuccess: () {
              authSuccessCalled = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and brand
      expect(find.text('AYESHA FOOTWEAR'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Register Company'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);

      // Switch to Register Company mode
      await tester.tap(find.text('Register Company'));
      await tester.pumpAndSettle();

      expect(find.text('REGISTER & CREATE COMPANY'), findsOneWidget);
      expect(find.text('UPI ID (for QR billing) *'), findsOneWidget);
      expect(find.text('Company Name *'), findsOneWidget);

      // Tap demo access
      final demoBtn = find.text('Quick Demo Store / Offline Access');
      await tester.ensureVisible(demoBtn);
      await tester.pumpAndSettle();
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      expect(authSuccessCalled, isTrue);
    });

    testWidgets('CompanySelectionView lists authorized companies without passwords or emails', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await AuthService.instance.setDemoProfile(
        name: 'Atiqu Khan',
        companyName: 'Ayesha Footwear Main Store',
        upiId: 'ayesha@okicici',
      );

      final dbService = DatabaseService(inMemoryDatabasePath);
      final repo = SqliteShopRepository(dbService, () => AuthService.instance.activeCompanyId);
      final vm = ShopViewModel(repo, ExcelExportService(), null, dbService);

      CompanyProfile? selectedCompany;

      await tester.pumpWidget(
        MaterialApp(
          home: CompanySelectionView(
            viewModel: vm,
            onCompanySelected: (comp) async {
              selectedCompany = comp;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Must display company name, UPI ID, and ID
      expect(find.text('Ayesha Footwear Main Store'), findsOneWidget);
      expect(find.text('LAUNCH STORE'), findsOneWidget);
      expect(find.textContaining('ayesha@okicici'), findsOneWidget);

      // MUST NOT display password or email in company list
      expect(find.textContaining('password'), findsNothing);
      expect(find.text('atiqu@ayeshafootwear.com'), findsNothing);

      // Tap launch store
      await tester.tap(find.text('LAUNCH STORE'));
      await tester.pumpAndSettle();

      expect(selectedCompany, isNotNull);
      expect(selectedCompany?.name, 'Ayesha Footwear Main Store');
    });
  });
}
