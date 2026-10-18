class Customer {
  const Customer({required this.id, required this.name, required this.mobile, required this.size, required this.colors, required this.lastItem, required this.totalSpent, required this.visits, this.note = ''});

  final String id;
  final String name;
  final String mobile;
  final String size;
  final String colors;
  final String lastItem;
  final int totalSpent;
  final int visits;
  final String note;

  factory Customer.fromMap(Map<String, Object?> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        mobile: map['mobile'] as String,
        size: map['size'] as String,
        colors: map['colors'] as String,
        lastItem: map['last_item'] as String,
        totalSpent: map['total_spent'] as int,
        visits: map['visits'] as int,
        note: map['note'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'size': size,
        'colors': colors,
        'last_item': lastItem,
        'total_spent': totalSpent,
        'visits': visits,
        'note': note,
      };
}
