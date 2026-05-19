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
    id: j['id'] as String,
    clientId: j['clientId'] as String,
    amount: (j['amount'] as num).toDouble(),
    description: (j['description'] as String?) ?? '',
    paid: (j['paid'] as bool?) ?? false,
    createdAt: j['createdAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'amount': amount,
    'description': description,
    'paid': paid,
    'createdAt': createdAt,
  };
}
