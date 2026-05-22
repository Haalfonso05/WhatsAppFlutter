class Client {
  final String id;
  final String name1;
  final String name2;
  final String lastName1;
  final String lastName2;
  final String phone;
  final String email;
  final String createdAt;

  const Client({
    required this.id,
    required this.name1,
    this.name2 = '',
    required this.lastName1,
    this.lastName2 = '',
    required this.phone,
    this.email = '',
    required this.createdAt,
  });

  String get fullName {
    final parts = [name1, name2, lastName1, lastName2]
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  factory Client.fromJson(Map<String, dynamic> j) => Client(
    id: (j['document'] ?? j['id'] ?? '') as String,
    name1: (j['name_1'] as String? ?? ''),
    name2: (j['name_2'] as String? ?? ''),
    lastName1: (j['last_name_1'] as String? ?? ''),
    lastName2: (j['last_name_2'] as String? ?? ''),
    phone: (j['phone_number'] ?? j['phone'] ?? '') as String,
    email: (j['email'] as String?) ?? '',
    createdAt: (j['createdAt'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'document': id,
    'name_1': name1,
    if (name2.isNotEmpty) 'name_2': name2,
    'last_name_1': lastName1,
    if (lastName2.isNotEmpty) 'last_name_2': lastName2,
    'phone_number': phone,
  };
}
