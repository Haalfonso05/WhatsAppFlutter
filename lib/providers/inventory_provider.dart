import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

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
    final nums = state
        .map((i) => int.tryParse(i.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final next = (nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b)) + 1;
    final id = 'P${next.toString().padLeft(4, '0')}';
    final item = InventoryItem(
      id: id,
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
