import 'bill_item.dart';

class BillDraft {
  const BillDraft({
    required this.customer,
    required this.mobile,
    required this.items,
    required this.discount,
    required this.payMode,
    required this.note,
  });

  final String customer;
  final String mobile;
  final List<BillItem> items;
  final int discount;
  final String payMode;
  final String note;

  int get subtotal => items.fold(0, (sum, it) => sum + it.total);
  int get total {
    final res = subtotal - discount;
    return res < 0 ? 0 : res;
  }
  int get totalQty => items.fold(0, (sum, it) => sum + it.qty);

  String get primaryProductId => items.isNotEmpty ? items.first.productId : '';
  String get primaryItemSummary {
    if (items.isEmpty) return 'Footwear';
    if (items.length == 1) return items.first.productName;
    return '${items.first.productName} (+${items.length - 1} more)';
  }
  String get primarySize => items.map((e) => e.size).where((s) => s.isNotEmpty).toSet().join(', ');
  String get primaryColor => items.map((e) => e.color).where((c) => c.isNotEmpty).toSet().join(', ');
}
