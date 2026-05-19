class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int stock;
  final double price;
  final int threshold;
  final String createdAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.threshold,
    required this.createdAt,
  });

  bool get isLowStock => stock <= threshold;

  InventoryItem copyWith({
    String? name,
    String? category,
    int? stock,
    double? price,
    int? threshold,
  }) =>
      InventoryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        stock: stock ?? this.stock,
        price: price ?? this.price,
        threshold: threshold ?? this.threshold,
        createdAt: createdAt,
      );

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    id: j['id'] as String,
    name: j['name'] as String,
    category: (j['category'] as String?) ?? '',
    stock: (j['stock'] as num).toInt(),
    price: (j['price'] as num).toDouble(),
    threshold: (j['threshold'] as num?)?.toInt() ?? 5,
    createdAt: j['createdAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'stock': stock,
    'price': price,
    'threshold': threshold,
    'createdAt': createdAt,
  };
}
