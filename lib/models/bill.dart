import 'dart:convert';

import 'bill_item.dart';

class Bill {
  const Bill({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.customer,
    required this.mobile,
    required this.item,
    required this.size,
    required this.color,
    required this.qty,
    required this.price,
    required this.discount,
    required this.total,
    required this.payMode,
    required this.note,
    required this.time,
    this.items = const [],
  });

  final String id;
  final String customerId;
  final String productId;
  final String customer;
  final String mobile;
  final String item;
  final String size;
  final String color;
  final int qty;
  final int price;
  final int discount;
  final int total;
  final String payMode;
  final String note;
  final DateTime time;
  final List<BillItem> items;

  List<BillItem> get allItems {
    if (items.isNotEmpty) return items;
    return [
      BillItem(
        productId: productId,
        productName: item,
        size: size,
        color: color,
        qty: qty,
        price: price,
      )
    ];
  }

  factory Bill.fromMap(Map<String, Object?> map) {
    List<BillItem> parsedItems = [];
    final itemsJson = map['items_json'] as String?;
    if (itemsJson != null && itemsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(itemsJson);
        if (decoded is List) {
          parsedItems = decoded
              .map((e) => BillItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    final pId = (map['product_id'] ?? '') as String;
    final pItem = (map['item'] ?? '') as String;
    final pSize = (map['size'] ?? '') as String;
    final pColor = (map['color'] ?? '') as String;
    final pQty = (map['qty'] as num?)?.toInt() ?? 1;
    final pPrice = (map['price'] as num?)?.toInt() ?? 0;

    if (parsedItems.isEmpty) {
      parsedItems = [
        BillItem(
          productId: pId,
          productName: pItem,
          size: pSize,
          color: pColor,
          qty: pQty,
          price: pPrice,
        ),
      ];
    }

    return Bill(
      id: map['id'] as String,
      customerId: (map['customer_id'] ?? '') as String,
      productId: pId,
      customer: (map['customer_name'] ?? '') as String,
      mobile: (map['mobile'] ?? '') as String,
      item: pItem,
      size: pSize,
      color: pColor,
      qty: pQty,
      price: pPrice,
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      payMode: (map['pay_mode'] ?? 'Cash') as String,
      note: (map['note'] as String?) ?? '',
      time: DateTime.tryParse((map['created_at'] ?? '') as String) ?? DateTime.now(),
      items: parsedItems,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_id': customerId,
        'product_id': productId,
        'customer_name': customer,
        'mobile': mobile,
        'item': item,
        'size': size,
        'color': color,
        'qty': qty,
        'price': price,
        'discount': discount,
        'total': total,
        'pay_mode': payMode,
        'note': note,
        'items_json': jsonEncode(allItems.map((e) => e.toMap()).toList()),
        'created_at': time.toIso8601String(),
      };
}
