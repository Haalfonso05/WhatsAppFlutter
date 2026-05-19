import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../services/api_service.dart';
import 'inventory_provider.dart';

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final orders = await ApiService.getOrders();
      state = orders;
    } catch (_) {}
  }

  Future<void> add({
    required String clientName,
    required String customerDocument,
    required List<Map<String, dynamic>> lines, // [{productId, productName, quantity, price}]
    required String notes,
  }) async {
    final id = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final total = lines.fold<double>(
        0, (sum, l) => sum + (l['quantity'] as int) * (l['price'] as double));
    final productNames =
        lines.map((l) => l['productName'] as String).join(', ');
    final order = Order(
      id: id,
      clientName: clientName,
      customerDocument: customerDocument,
      product: productNames,
      quantity: lines.fold(0, (sum, l) => sum + (l['quantity'] as int)),
      total: total,
      notes: notes,
      status: 'En espera',
      createdAt: today,
    );
    final created = await ApiService.createOrder(order);
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      await ApiService.createOrderDetail(
        orderId: id,
        customerDocument: customerDocument,
        lineNumber: i + 1,
        productId: l['productId'] as String,
        amount: (l['quantity'] as int).toDouble(),
        salePrice: l['price'] as double,
      );
    }
    state = [...state, created];
  }

  Future<void> updateStatus(String id, String status) async {
    await ApiService.updateOrderStatus(id, status);
    state = state.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
    if (status == 'Listo') {
      await _decrementStockForOrder(id);
    }
  }

  Future<void> _decrementStockForOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/orders/$orderId/details'),
      );
      if (response.statusCode != 200) return;
      final List details = jsonDecode(response.body);
      for (final d in details) {
        final productId = d['product_id'] as String;
        final amount = (d['amount'] as num);
        await ApiService.adjustProductStock(productId, -amount);
      }
      ref.read(inventoryProvider.notifier).reload();
    } catch (_) {}
  }

  void remove(String id) {
    state = state.where((o) => o.id != id).toList();
  }

  Future<void> reload() async => _load();
}

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
