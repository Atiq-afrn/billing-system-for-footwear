import 'package:ayesha_footwear/models/user_profile.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/views/auth_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Firebase Auth & User Profile Tests', () {
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

    test('AuthService setDemoProfile and logout lifecycle', () async {
      final auth = AuthService.instance;

      await auth.setDemoProfile(
        name: 'Test Owner',
        companyName: 'Test Footwear',
        upiId: 'test@upi',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentProfile?.companyName, 'Test Footwear');
      expect(auth.currentProfile?.upiId, 'test@upi');

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentProfile, isNull);
    });

    testWidgets('AuthView renders Sign In and Register Store modes smoothly without overflow', (tester) async {
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
      expect(find.text('AYESHA FOOTWEAR POS'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Register Store'), findsOneWidget);
      expect(find.text('SIGN IN TO STORE'), findsOneWidget);

      // Switch to Register Store mode
      await tester.tap(find.text('Register Store'));
      await tester.pumpAndSettle();

      expect(find.text('Register Store Account'), findsOneWidget);
      expect(find.text('REGISTER & LAUNCH STORE'), findsOneWidget);
      expect(find.text('Business UPI ID'), findsOneWidget);
      expect(find.text('Company / Shop Name'), findsOneWidget);

      // Tap demo access
      final demoBtn = find.text('Quick Demo Store / Offline Access');
      await tester.ensureVisible(demoBtn);
      await tester.pumpAndSettle();
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      expect(authSuccessCalled, isTrue);
    });
  });
}
