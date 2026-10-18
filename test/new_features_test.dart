import 'package:ayesha_footwear/models/customer.dart';
import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/views/customers_view.dart';
import 'package:ayesha_footwear/views/product_details_view.dart';
import 'package:ayesha_footwear/views/products_view.dart';
import 'package:ayesha_footwear/widgets/shop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Leading Dot Input Formatter Tests', () {
    test('Blocks leading dot such as .007 and .006', () {
      const formatter = NoLeadingDotNumberFormatter(allowDecimals: true);

      // Typing '.' when empty
      final res1 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '.'),
      );
      expect(res1.text, '');

      // Typing '.007' directly
      final res2 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '.007'),
      );
      expect(res2.text, '');

      // Typing '.006' directly
      final res3 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '.006'),
      );
      expect(res3.text, '');
    });

    test('Allows numbers with whole number before decimal like 1.100 and 800.600', () {
      const formatter = NoLeadingDotNumberFormatter(allowDecimals: true);

      final res1 = formatter.formatEditUpdate(
        const TextEditingValue(text: '1'),
        const TextEditingValue(text: '1.100'),
      );
      expect(res1.text, '1.100');

      final res2 = formatter.formatEditUpdate(
        const TextEditingValue(text: '800'),
        const TextEditingValue(text: '800.600'),
      );
      expect(res2.text, '800.600');

      final res3 = formatter.formatEditUpdate(
        const TextEditingValue(text: '0'),
        const TextEditingValue(text: '0.006'),
      );
      expect(res3.text, '0.006');
    });
  });

  group('Customer Card Safety Tests (No Red Screen)', () {
    testWidgets('CustomerCard renders safely without crashing even when customer name is empty', (tester) async {
      const emptyNameCustomer = Customer(
        id: 'cust_empty',
        name: '', // Empty name
        mobile: '9876543210',
        size: '8',
        colors: 'Black',
        lastItem: 'Formal Shoes',
        totalSpent: 1200,
        visits: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerCard(
              customer: emptyNameCustomer,
              onTap: () {},
              onOffer: () {},
            ),
          ),
        ),
      );

      // Should render fallback avatar initial and walk-in customer label without error
      expect(find.text('W'), findsOneWidget);
      expect(find.text('Walk-in Customer'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Products and Product Details Screen Tests', () {
    final testProduct = Product(
      id: 'PROD-001',
      name: 'Italian Leather Formal',
      category: 'Men Formal',
      stock: 12,
      price: 1499,
      sizes: ['7', '8', '9', '10'],
      colors: ['Black', 'Brown', 'Tan'],
    );

    testWidgets('ProductsView displays clean card and opens ProductDetailsView with sizes and colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductsView(
              products: [testProduct],
              onAddProduct: () {},
            ),
          ),
        ),
      );

      // List screen shows product name, price and stock count
      expect(find.text('Italian Leather Formal'), findsOneWidget);
      expect(find.text('Rs 1499'), findsOneWidget);
      expect(find.text('12 in stock'), findsOneWidget);

      // Tap on the product card to navigate to ProductDetailsView
      await tester.tap(find.text('Italian Leather Formal'));
      await tester.pumpAndSettle();

      // Product Details Screen appears
      expect(find.byType(ProductDetailsView), findsOneWidget);
      expect(find.text('Available Sizes (4)'), findsOneWidget);
      expect(find.text('Size 7'), findsOneWidget);
      expect(find.text('Size 8'), findsOneWidget);
      expect(find.text('Available Colors (3)'), findsOneWidget);
      expect(find.text('Black'), findsOneWidget);
      expect(find.text('Brown'), findsOneWidget);
      expect(find.text('Product Barcode & Article ID'), findsOneWidget);
    });
  });
}
