import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => ref.read(storageServiceProvider).getOrders();

  void add({
    required String clientName,
    required String product,
    required int quantity,
    required double total,
    required String notes,
  }) {
    final order = Order(
      id: _uuid.v4(),
      clientName: clientName,
      product: product,
      quantity: quantity,
      total: total,
      notes: notes,
      status: 'En espera',
      createdAt: DateTime.now().toIso8601String(),
    );
    final updated = [...state, order];
    state = updated;
    ref.read(storageServiceProvider).saveOrders(updated);
  }

  void updateStatus(String id, String status) {
    final updated = state.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
    state = updated;
    ref.read(storageServiceProvider).saveOrders(updated);
  }

  void remove(String id) {
    final updated = state.where((o) => o.id != id).toList();
    state = updated;
    ref.read(storageServiceProvider).saveOrders(updated);
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
