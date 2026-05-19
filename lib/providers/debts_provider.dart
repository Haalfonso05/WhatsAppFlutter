import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../services/api_service.dart';

class DebtsNotifier extends Notifier<List<Debt>> {
  @override
  List<Debt> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final debts = await ApiService.getDebts();
      state = debts;
    } catch (_) {}
  }

  Future<void> add({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    final debt = Debt(
      id: '',
      clientId: clientId,
      amount: amount,
      description: description,
      paid: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ApiService.createDebt(debt);
    state = [...state, created];
  }

  Future<void> togglePaid(String id) async {
    final debt = state.firstWhere((d) => d.id == id);
    await ApiService.toggleDebtPaid(int.parse(id), !debt.paid);
    state = state.map((d) => d.id == id ? d.togglePaid() : d).toList();
  }

  void remove(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);
