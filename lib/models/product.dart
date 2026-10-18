class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.sizes,
    required this.colors,
    this.imagePath = '',
  });

  final String id;
  final String name;
  final String category;
  final int stock;
  final int price;
  final List<String> sizes;
  final List<String> colors;
  final String imagePath;

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        stock: map['stock'] as int,
        price: map['price'] as int,
        sizes: (map['sizes'] as String).split(',').where((value) => value.isNotEmpty).toList(),
        colors: (map['colors'] as String).split(',').where((value) => value.isNotEmpty).toList(),
        imagePath: (map['image_path'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'stock': stock,
        'price': price,
        'sizes': sizes.join(','),
        'colors': colors.join(','),
        'image_path': imagePath,
      };

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? stock,
    int? price,
    List<String>? sizes,
    List<String>? colors,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      price: price ?? this.price,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
