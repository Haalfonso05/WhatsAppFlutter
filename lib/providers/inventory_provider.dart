import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

// ── Paged state ──────────────────────────────────────────────────────────────

class InventoryPagedState {
  final List<InventoryItem> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loading;
  final String search;

  const InventoryPagedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.loading = false,
    this.search = '',
  });

  InventoryPagedState copyWith({
    List<InventoryItem>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loading,
    String? search,
  }) =>
      InventoryPagedState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loading: loading ?? this.loading,
        search: search ?? this.search,
      );
}

class InventoryPagedNotifier extends Notifier<InventoryPagedState> {
  @override
  InventoryPagedState build() {
    Future.microtask(_fetch);
    return const InventoryPagedState(loading: true);
  }

  Future<void> _fetch() async {
    try {
      final result = await ApiService.getProductsPaged(
        page: state.page,
        size: 25,
        search: state.search,
      );
      state = state.copyWith(
        items: result['items'] as List<InventoryItem>,
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

final inventoryPagedProvider =
    NotifierProvider<InventoryPagedNotifier, InventoryPagedState>(
        InventoryPagedNotifier.new);

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final items = await ApiService.getProducts();
      state = items;
    } catch (_) {}
  }

  Future<void> add({
    required String name,
    required String category,
    required int stock,
    required double price,
    required int threshold,
  }) async {
    final item = InventoryItem(
      id: '0',
      name: name,
      category: category,
      stock: stock,
      price: price,
      threshold: threshold,
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ApiService.createProduct(item);
    state = [...state, created];
  }

  Future<void> update(String id, {
    required String name,
    required String category,
    required int stock,
    required double price,
    required int threshold,
  }) async {
    final item = InventoryItem(
      id: id,
      name: name,
      category: category,
      stock: stock,
      price: price,
      threshold: threshold,
      createdAt: '',
    );
    final updated = await ApiService.updateProduct(item);
    state = state.map((i) => i.id == id ? updated : i).toList();
  }

  Future<void> remove(String id) async {
    await ApiService.deleteProduct(id);
    state = state.where((i) => i.id != id).toList();
  }

  Future<void> reload() async => _load();
}

final inventoryProvider = NotifierProvider<InventoryNotifier, List<InventoryItem>>(
  InventoryNotifier.new,
);
