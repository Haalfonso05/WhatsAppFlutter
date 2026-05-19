import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/api_service.dart';

class ClientsNotifier extends Notifier<List<Client>> {
  @override
  List<Client> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final clients = await ApiService.getClients();
      state = clients;
    } catch (_) {}
  }

  Future<Client> add({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    final client = Client(
      id: id,
      name: name,
      phone: phone,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ApiService.createClient(client);
    state = [...state, created];
    return created;
  }

  Future<void> remove(String id) async {
    await ApiService.deleteClient(id);
    state = state.where((c) => c.id != id).toList();
  }
}

final clientsProvider =
    NotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);
