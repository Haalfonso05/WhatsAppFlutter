import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../services/api_service.dart';

// ── Paged state ──────────────────────────────────────────────────────────────

class ClientsPagedState {
  final List<Client> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loading;
  final String search;

  const ClientsPagedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.loading = false,
    this.search = '',
  });

  ClientsPagedState copyWith({
    List<Client>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loading,
    String? search,
  }) =>
      ClientsPagedState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loading: loading ?? this.loading,
        search: search ?? this.search,
      );
}

class ClientsPagedNotifier extends Notifier<ClientsPagedState> {
  @override
  ClientsPagedState build() {
    Future.microtask(_fetch);
    return const ClientsPagedState(loading: true);
  }

  Future<void> _fetch() async {
    try {
      final result = await ApiService.getClientsPaged(
        page: state.page,
        size: 25,
        search: state.search,
      );
      state = state.copyWith(
        items: result['items'] as List<Client>,
        totalPages: result['pages'] as int,
        total: result['total'] as int,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void setSearch(String search) {
    state = state.copyWith(search: search, page: 1, loading: true);
    _fetch();
  }

  void setPage(int page) {
    state = state.copyWith(page: page, loading: true);
    _fetch();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _fetch();
  }
}

final clientsPagedProvider =
    NotifierProvider<ClientsPagedNotifier, ClientsPagedState>(
        ClientsPagedNotifier.new);

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
    String address = '',
  }) async {
    final client = Client(
      id: id,
      name1: name1,
      name2: name2,
      lastName1: lastName1,
      lastName2: lastName2,
      phone: phone,
      address: address,
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ApiService.createClient(client);
    state = [...state, created];
    return created;
  }

  Future<void> update(Client client) async {
    final updated = await ApiService.updateClient(client);
    state = state.map((c) => c.id == updated.id ? updated : c).toList();
  }

  Future<void> remove(String id) async {
    await ApiService.deleteClient(id);
    state = state.where((c) => c.id != id).toList();
  }
}

final clientsProvider =
    NotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);
