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
    required String name1,
    String name2 = '',
    required String lastName1,
    String lastName2 = '',
    required String phone,
  }) async {
    final client = Client(
      id: id,
      name1: name1,
      name2: name2,
      lastName1: lastName1,
      lastName2: lastName2,
      phone: phone,
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
