import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() => ref.read(storageServiceProvider).getInventory();

  void add({
    required String name,
    required String category,
    required int stock,
    required double price,
    required int threshold,
  }) {
    final item = InventoryItem(
      id: _uuid.v4(),
      name: name,
      category: category,
      stock: stock,
      price: price,
      threshold: threshold,
      createdAt: DateTime.now().toIso8601String(),
    );
    final updated = [...state, item];
    state = updated;
    ref.read(storageServiceProvider).saveInventory(updated);
  }

  void update(String id, {
    required String name,
    required String category,
    required int stock,
    required double price,
    required int threshold,
  }) {
    final updated = state.map((i) {
      if (i.id != id) return i;
      return i.copyWith(name: name, category: category, stock: stock, price: price, threshold: threshold);
    }).toList();
    state = updated;
    ref.read(storageServiceProvider).saveInventory(updated);
  }

  void remove(String id) {
    final updated = state.where((i) => i.id != id).toList();
    state = updated;
    ref.read(storageServiceProvider).saveInventory(updated);
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, List<InventoryItem>>(
  InventoryNotifier.new,
);
