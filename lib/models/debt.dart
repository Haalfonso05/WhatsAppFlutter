class Debt {
  final String id;
  final String clientId;
  final double amount;
  final String description;
  final bool paid;
  final String createdAt;

  const Debt({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.description,
    required this.paid,
    required this.createdAt,
  });

  Debt togglePaid() => Debt(
    id: id,
    clientId: clientId,
    amount: amount,
    description: description,
    paid: !paid,
    createdAt: createdAt,
  );

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
    id: (j['id'] ?? '').toString(),
    clientId: (j['customer_document'] ?? j['clientId'] ?? '') as String,
    amount: (j['value'] ?? j['amount'] ?? 0 as num).toDouble(),
    description: (j['description'] as String?) ?? '',
    paid: j.containsKey('status')
        ? (j['status'] == 'P')
        : (j['paid'] as bool? ?? false),
    createdAt: (j['creation_date'] ?? j['createdAt'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'customer_document': clientId,
    'value': amount,
    'status': paid ? 'P' : 'A',
    'creation_date': createdAt,
  };
}
