import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class ClientsNotifier extends Notifier<List<Client>> {
  @override
  List<Client> build() => ref.read(storageServiceProvider).getClients();

  Client add({required String name, required String phone, required String email}) {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
    final updated = [...state, client];
    state = updated;
    ref.read(storageServiceProvider).saveClients(updated);
    return client;
  }

  void remove(String id) {
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    ref.read(storageServiceProvider).saveClients(updated);
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);
