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
    this.imageBase64 = '',
  });

  final String id;
  final String name;
  final String category;
  final int stock;
  final int price;
  final List<String> sizes;
  final List<String> colors;
  final String imagePath;
  final String imageBase64;

  factory Product.fromMap(Map<String, Object?> map) {
    final sizesRaw = map['sizes'];
    List<String> sizesList = [];
    if (sizesRaw is List) {
      sizesList = sizesRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (sizesRaw is String) {
      sizesList = sizesRaw.split(',').map((e) => e.trim()).where((value) => value.isNotEmpty).toList();
    }

    final colorsRaw = map['colors'];
    List<String> colorsList = [];
    if (colorsRaw is List) {
      colorsList = colorsRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (colorsRaw is String) {
      colorsList = colorsRaw.split(',').map((e) => e.trim()).where((value) => value.isNotEmpty).toList();
    }

    return Product(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toInt() ?? 0,
      sizes: sizesList,
      colors: colorsList,
      imagePath: (map['image_path'] as String?) ?? (map['imagePath'] as String?) ?? '',
      imageBase64: (map['image_base64'] as String?) ?? (map['imageBase64'] as String?) ?? '',
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'stock': stock,
        'price': price,
        'sizes': sizes.join(','),
        'colors': colors.join(','),
        'image_path': imagePath,
        'image_base64': imageBase64,
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
    String? imageBase64,
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
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
