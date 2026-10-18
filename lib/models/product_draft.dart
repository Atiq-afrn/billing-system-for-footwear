class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.sizes,
    required this.colors,
    this.imagePath = '',
  });

  final String name;
  final String category;
  final int stock;
  final int price;
  final List<String> sizes;
  final List<String> colors;
  final String imagePath;
}
