import 'package:ayesha_footwear/main.dart';
import 'package:ayesha_footwear/services/auth_service.dart';
import 'package:ayesha_footwear/widgets/shop_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('shows dashboard and opens side drawer when menu icon is tapped', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await AuthService.instance.setDemoProfile();
      await tester.pumpWidget(const AyeshaFootwearApp());
      // Wait for SQLite async initialization to finish
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Footwear Store'), findsWidgets);
    expect(find.text('Create Bill'), findsWidgets);
    expect(find.text("Today's Sales"), findsWidgets);

    // Tap menu icon on Dashboard to open side drawer
    final menuButtonFinder = find.byIcon(Icons.menu_rounded);
    expect(menuButtonFinder, findsOneWidget);
    await tester.tap(menuButtonFinder);
    await tester.pumpAndSettle();

    // Verify side drawer is opened
    expect(find.byType(ShopDrawer), findsOneWidget);
    expect(find.text('CUSTOMER RETENTION'), findsOneWidget);
    expect(find.text('Loyal Customers & Offers'), findsOneWidget);

    // Close the drawer by tapping outside
    await tester.tapAt(const Offset(400, 100));
    await tester.pumpAndSettle();
    expect(find.byType(ShopDrawer), findsNothing);

    // Tap on Customers in bottom nav
    await tester.tap(find.text('Customers').last);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Customers'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });
}
