class Debt {
  final String id;
  final String clientId;
  final String orderId;
  final double amount;
  final String description;
  final bool paid;
  final String createdAt;

  const Debt({
    required this.id,
    required this.clientId,
    required this.orderId,
    required this.amount,
    required this.description,
    required this.paid,
    required this.createdAt,
  });

  Debt togglePaid() => Debt(
    id: id,
    clientId: clientId,
    orderId: orderId,
    amount: amount,
    description: description,
    paid: !paid,
    createdAt: createdAt,
  );

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
    id: (j['id'] ?? '').toString(),
    clientId: (j['customer_document'] ?? j['clientId'] ?? '') as String,
    orderId: (j['order_id'] ?? j['orderId'] ?? '').toString(),
    amount: ((j['value'] ?? j['amount'] ?? 0) as num).toDouble(),
    description: (j['description'] as String?) ?? '',
    paid: j.containsKey('status')
        ? (j['status'] == 'P')
        : (j['paid'] as bool? ?? false),
    createdAt: (j['creation_date'] ?? j['createdAt'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'customer_document': clientId,
    'order_id': int.tryParse(orderId) ?? 0,
    'value': amount,
    'status': paid ? 'P' : 'A',
    'creation_date': createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
  };
}
