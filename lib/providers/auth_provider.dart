// Provider de autenticacion
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

// clase AuthNotifier
class AuthNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() => ref.read(storageServiceProvider).getCurrentUser();

  // funcion register
  Future<({String? error})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await ApiService.register(name: name, email: email, password: password);
    if (result.error != null) return (error: result.error);
    await ref.read(storageServiceProvider).setCurrentUser(result.user!);
    state = result.user;
    return (error: null);
  }

  // funcion login
  Future<({String? error})> login({
    required String email,
    required String password,
  }) async {
    final result = await ApiService.login(email: email, password: password);
    if (result.error != null) return (error: result.error);
    await ref.read(storageServiceProvider).setCurrentUser(result.user!);
    state = result.user;
    return (error: null);
  }

  // funcion logout
  void logout() {
    ref.read(storageServiceProvider).clearCurrentUser();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserSession?>(AuthNotifier.new);