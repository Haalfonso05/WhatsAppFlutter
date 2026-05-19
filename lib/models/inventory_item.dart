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
    id: (j['id_product'] ?? j['id'] ?? '') as String,
    name: j['name'] as String,
    category: (j['product_type_id'] ?? j['category'] ?? '') as String,
    stock: num.parse((j['current_stock'] ?? j['stock'] ?? '0').toString()).toInt(),
    price: num.parse((j['reference_price'] ?? j['price'] ?? '0').toString()).toDouble(),
    threshold: (j['threshold'] as num?)?.toInt() ?? 5,
    createdAt: (j['createdAt'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id_product': id,
    'name': name,
    'description': name,
    'reference_price': price,
    'current_stock': stock,
    'available': 'Y',
    'product_type_id': category,
  };
}
