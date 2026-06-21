// Modelo de usuario
// clase AppUser
class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    name: j['name'] as String,
    email: j['email'] as String,
    password: j['password'] as String,
  );

  // convierte el objeto a JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
  };
}

// clase UserSession
class UserSession {
  final String id;
  final String name;
  final String email;

  const UserSession({required this.id, required this.name, required this.email});

  factory UserSession.fromJson(Map<String, dynamic> j) =>
      UserSession(id: j['id'] as String, name: j['name'] as String, email: j['email'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}