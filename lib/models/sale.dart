class Sale {
  final String id;
  final double amount;
  final String date;

  const Sale({required this.id, required this.amount, required this.date});

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'] as String,
    amount: (j['amount'] as num).toDouble(),
    date: j['date'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'amount': amount, 'date': date};
}
