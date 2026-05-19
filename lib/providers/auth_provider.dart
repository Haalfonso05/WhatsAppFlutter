import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class AuthNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() => ref.read(storageServiceProvider).getCurrentUser();

  ({String? error}) register({
    required String name,
    required String email,
    required String password,
  }) {
    final storage = ref.read(storageServiceProvider);
    final users = storage.getUsers();
    if (users.any((u) => u.email == email)) {
      return (error: 'El correo ya esta registrado');
    }
    final newUser = AppUser(id: _uuid.v4(), name: name, email: email, password: password);
    storage.saveUsers([...users, newUser]);
    final session = UserSession(id: newUser.id, name: newUser.name, email: newUser.email);
    storage.setCurrentUser(session);
    state = session;
    return (error: null);
  }

  ({String? error}) login({required String email, required String password}) {
    final storage = ref.read(storageServiceProvider);
    final found = storage
        .getUsers()
        .where((u) => u.email == email && u.password == password)
        .firstOrNull;
    if (found == null) return (error: 'Credenciales incorrectas');
    final session = UserSession(id: found.id, name: found.name, email: found.email);
    storage.setCurrentUser(session);
    state = session;
    return (error: null);
  }

  void logout() {
    ref.read(storageServiceProvider).clearCurrentUser();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserSession?>(AuthNotifier.new);
