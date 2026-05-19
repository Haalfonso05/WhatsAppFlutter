import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class DebtsNotifier extends Notifier<List<Debt>> {
  @override
  List<Debt> build() => ref.read(storageServiceProvider).getDebts();

  void add({required String clientId, required double amount, required String description}) {
    final debt = Debt(
      id: _uuid.v4(),
      clientId: clientId,
      amount: amount,
      description: description,
      paid: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    final updated = [...state, debt];
    state = updated;
    ref.read(storageServiceProvider).saveDebts(updated);
  }

  void togglePaid(String id) {
    final updated = state.map((d) => d.id == id ? d.togglePaid() : d).toList();
    state = updated;
    ref.read(storageServiceProvider).saveDebts(updated);
  }

  void remove(String id) {
    final updated = state.where((d) => d.id != id).toList();
    state = updated;
    ref.read(storageServiceProvider).saveDebts(updated);
  }
}

final debtsProvider = NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);
