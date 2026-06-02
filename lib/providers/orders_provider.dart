import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../services/api_service.dart';
import 'inventory_provider.dart';

// ── Paged state ───────────────────────────────────────────────────────────────

class OrdersPagedState {
  final List<Order> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loading;
  final String search;
  final String status;

  const OrdersPagedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.loading = false,
    this.search = '',
    this.status = '',
  });

  OrdersPagedState copyWith({
    List<Order>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loading,
    String? search,
    String? status,
  }) =>
      OrdersPagedState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loading: loading ?? this.loading,
        search: search ?? this.search,
        status: status ?? this.status,
      );
}

class OrdersPagedNotifier extends Notifier<OrdersPagedState> {
  @override
  OrdersPagedState build() {
    Future.microtask(_fetch);
    return const OrdersPagedState(loading: true);
  }

  Future<void> _fetch() async {
    try {
      final result = await ApiService.getOrdersPaged(
        page: state.page,
        size: 20,
        search: state.search,
        status: state.status,
      );
      state = state.copyWith(
        items: result['items'] as List<Order>,
        totalPages: result['pages'] as int,
        total: result['total'] as int,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void setStatus(String status) {
    state = state.copyWith(status: status, page: 1, loading: true);
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

final ordersPagedProvider =
    NotifierProvider<OrdersPagedNotifier, OrdersPagedState>(
        OrdersPagedNotifier.new);

// ── Mutations notifier (add / updateStatus / remove) ─────────────────────────

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => [];

  Future<void> add({
    required String clientName,
    required String customerDocument,
    required List<Map<String, dynamic>> lines, // [{productId, productName, quantity, price}]
    required String notes,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final total = lines.fold<double>(
        0, (sum, l) => sum + (l['quantity'] as int) * (l['price'] as double));
    final productNames =
        lines.map((l) => l['productName'] as String).join(', ');
    final order = Order(
      id: '0',
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
        orderId: created.id,
        customerDocument: customerDocument,
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
        Uri.parse('http://127.0.0.1:8000/orders/${int.parse(orderId)}/details'),
      );
      if (response.statusCode != 200) return;
      final List details = jsonDecode(response.body);
      for (final d in details) {
        final productId = d['product_id'].toString();
        final amount = (d['amount'] as num);
        await ApiService.adjustProductStock(productId, -amount);
      }
      ref.read(inventoryProvider.notifier).reload();
    } catch (_) {}
  }

  void remove(String id) {
    state = state.where((o) => o.id != id).toList();
  }

}

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
