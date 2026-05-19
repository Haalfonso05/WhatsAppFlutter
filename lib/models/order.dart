const orderStatuses = ['En espera', 'Listo', 'Enviado'];

class Order {
  final String id;
  final String clientName;
  final String product;
  final int quantity;
  final double total;
  final String notes;
  final String status;
  final String createdAt;

  const Order({
    required this.id,
    required this.clientName,
    required this.product,
    required this.quantity,
    required this.total,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Order copyWith({String? status}) => Order(
    id: id,
    clientName: clientName,
    product: product,
    quantity: quantity,
    total: total,
    notes: notes,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    clientName: j['clientName'] as String,
    product: j['product'] as String,
    quantity: (j['quantity'] as num).toInt(),
    total: (j['total'] as num).toDouble(),
    notes: (j['notes'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'En espera',
    createdAt: j['createdAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'product': product,
    'quantity': quantity,
    'total': total,
    'notes': notes,
    'status': status,
    'createdAt': createdAt,
  };
}
