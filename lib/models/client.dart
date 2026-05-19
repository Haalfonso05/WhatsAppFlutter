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
    id: j['id'] as String,
    name: j['name'] as String,
    phone: (j['phone'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    createdAt: j['createdAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'createdAt': createdAt,
  };
}
