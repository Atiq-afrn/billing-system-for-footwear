class BillItem {
  const BillItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.qty,
    required this.price,
  });

  final String productId;
  final String productName;
  final String size;
  final String color;
  final int qty;
  final int price;

  int get total => price * qty;

  BillItem copyWith({
    String? productId,
    String? productName,
    String? size,
    String? color,
    int? qty,
    int? price,
  }) {
    return BillItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      color: color ?? this.color,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'size': size,
        'color': color,
        'qty': qty,
        'price': price,
      };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        productId: (map['product_id'] ?? map['productId'] ?? '') as String,
        productName: (map['product_name'] ?? map['productName'] ?? map['item'] ?? 'Footwear') as String,
        size: (map['size'] ?? '') as String,
        color: (map['color'] ?? '') as String,
        qty: (map['qty'] as num?)?.toInt() ?? 1,
        price: (map['price'] as num?)?.toInt() ?? 0,
      );
}
