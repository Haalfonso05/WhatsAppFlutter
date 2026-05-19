const orderStatuses = ['En espera', 'Enviado', 'Listo'];

class Order {
  final String id;
  final String clientName;
  final String customerDocument;
  final String product;
  final int quantity;
  final double total;
  final String notes;
  final String status;
  final String createdAt;

  const Order({
    required this.id,
    required this.clientName,
    this.customerDocument = '',
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
    customerDocument: customerDocument,
    product: product,
    quantity: quantity,
    total: total,
    notes: notes,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  static String _mapStatus(String? s) {
    switch (s) {
      case 'E': return 'Enviado';
      case 'D': return 'Listo';
      default:  return 'En espera';
    }
  }

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: (j['id_order'] ?? j['id'] ?? '') as String,
    clientName: (j['client_name'] ?? j['clientName'] ?? '') as String,
    customerDocument: (j['customer_document'] ?? '') as String,
    product: (j['product_name'] ?? j['product'] ?? '') as String,
    quantity: num.parse((j['quantity'] ?? '0').toString()).toInt(),
    total: num.parse((j['total'] ?? '0').toString()).toDouble(),
    notes: (j['observation'] ?? j['notes'] ?? '') as String,
    status: _mapStatus(j['delivery_status'] as String?),
    createdAt: (j['application_date'] ?? j['createdAt'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'id_order': id,
    'customer_document': customerDocument,
    'application_date': createdAt,
    'shipment_date': createdAt,
    'total': total,
    'payment_method_id': 'EF',
  };
}
