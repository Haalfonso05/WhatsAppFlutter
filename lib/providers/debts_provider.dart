// Provider de deudas (paginacion)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../services/api_service.dart';

// ── Paged state ───────────────────────────────────────────────────────────────

// clase DebtsPagedState
class DebtsPagedState {
  final List<Debt> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loading;

  const DebtsPagedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.loading = false,
  });

  // devuelve una copia con campos cambiados
  DebtsPagedState copyWith({
    List<Debt>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loading,
  }) =>
      DebtsPagedState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loading: loading ?? this.loading,
      );
}

// clase DebtsPagedNotifier
class DebtsPagedNotifier extends Notifier<DebtsPagedState> {
  // construye la interfaz del widget
  @override
  DebtsPagedState build() {
    Future.microtask(_fetch);
    return const DebtsPagedState(loading: true);
  }

  // funcion _fetch
  Future<void> _fetch() async {
    try {
      final result = await ApiService.getDebtsPaged(
        page: state.page,
        size: 20,
      );
      state = state.copyWith(
        items: result['items'] as List<Debt>,
        totalPages: result['pages'] as int,
        total: result['total'] as int,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  // funcion setPage
  void setPage(int page) {
    state = state.copyWith(page: page, loading: true);
    _fetch();
  }

  // funcion reload
  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _fetch();
  }
}

final debtsPagedProvider =
    NotifierProvider<DebtsPagedNotifier, DebtsPagedState>(
        DebtsPagedNotifier.new);

// clase DebtsNotifier
class DebtsNotifier extends Notifier<List<Debt>> {
  // construye la interfaz del widget
  @override
  List<Debt> build() {
    _load();
    return [];
  }

  // funcion _load
  Future<void> _load() async {
    try {
      final debts = await ApiService.getDebts();
      state = debts;
    } catch (_) {}
  }

  // funcion add
  Future<void> add({
    required String clientId,
    required String orderId,
    required double amount,
    required String description,
  }) async {
    final debt = Debt(
      id: '',
      clientId: clientId,
      orderId: orderId,
      amount: amount,
      description: description,
      paid: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ApiService.createDebt(debt);
    state = [...state, created];
  }

  // funcion togglePaid
  Future<void> togglePaid(String id) async {
    final debt = state.firstWhere((d) => d.id == id);
    await ApiService.toggleDebtPaid(int.parse(id), !debt.paid);
    state = state.map((d) => d.id == id ? d.togglePaid() : d).toList();
  }

  // funcion remove
  void remove(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);