import 'package:ayesha_footwear/models/bill_draft.dart';
import 'package:ayesha_footwear/models/bill_item.dart';
import 'package:ayesha_footwear/repositories/sqlite_shop_repository.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Multi-item bill draft calculates totals and updates stock correctly', () async {
    final dbService = DatabaseService(inMemoryDatabasePath);
    final repo = SqliteShopRepository(dbService);

    // Fetch initial products seeded in database
    final initialProducts = await repo.fetchProducts();
    expect(initialProducts.isNotEmpty, isTrue);

    final prod1 = initialProducts[0];
    final prod2 = initialProducts.length > 1 ? initialProducts[1] : initialProducts[0];

    final initialStock1 = prod1.stock;
    final initialStock2 = prod2.stock;

    final draft = BillDraft(
      customer: 'Ayesha Test',
      mobile: '9998887770',
      items: [
        BillItem(
          productId: prod1.id,
          productName: prod1.name,
          size: prod1.sizes.first,
          color: prod1.colors.first,
          qty: 2,
          price: prod1.price,
        ),
        if (prod1.id != prod2.id)
          BillItem(
            productId: prod2.id,
            productName: prod2.name,
            size: prod2.sizes.first,
            color: prod2.colors.first,
            qty: 1,
            price: prod2.price,
          ),
      ],
      discount: 100,
      payMode: 'UPI',
      note: 'Multi-item test purchase',
    );

    expect(draft.items.length, prod1.id != prod2.id ? 2 : 1);
    expect(draft.totalQty, prod1.id != prod2.id ? 3 : 2);
    expect(draft.subtotal, (prod1.price * 2) + (prod1.id != prod2.id ? prod2.price : 0));
    expect(draft.total, draft.subtotal - 100);

    // Save multi-item bill
    final savedBill = await repo.saveBill(draft);
    expect(savedBill.id.startsWith('BILL-'), isTrue);
    expect(savedBill.total, draft.total);
    expect(savedBill.allItems.length, draft.items.length);

    // Verify stock was decremented in database
    final updatedProducts = await repo.fetchProducts();
    final updatedProd1 = updatedProducts.firstWhere((p) => p.id == prod1.id);
    expect(updatedProd1.stock, initialStock1 - 2);

    if (prod1.id != prod2.id) {
      final updatedProd2 = updatedProducts.firstWhere((p) => p.id == prod2.id);
      expect(updatedProd2.stock, initialStock2 - 1);
    }
  });
}
