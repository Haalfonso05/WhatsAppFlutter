class Client {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String createdAt;

  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> j) => Client(
    id: (j['document'] ?? j['id'] ?? '') as String,
    name: j.containsKey('name_1')
        ? '${j['name_1']} ${j['last_name_1']}'
        : (j['name'] as String? ?? ''),
    phone: (j['phone_number'] ?? j['phone'] ?? '') as String,
    email: (j['email'] as String?) ?? '',
    createdAt: (j['createdAt'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'document': id,
    'name_1': name.split(' ').first,
    'last_name_1': name.split(' ').skip(1).join(' '),
    'phone_number': phone,
  };
}
