import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class SalesStats {
  final double todaySales;
  final double monthSales;
  final bool loading;

  const SalesStats({
    this.todaySales = 0,
    this.monthSales = 0,
    this.loading = true,
  });
}

class SalesStatsNotifier extends Notifier<SalesStats> {
  @override
  SalesStats build() {
    Future.microtask(_load);
    return const SalesStats(loading: true);
  }

  Future<void> _load() async {
    try {
      
      final result = await ApiService.getOrdersPaged(
        page: 1,
        size: 200,
        status: 'Listo',
      );
      final orders = result['items'] as List;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final month = DateTime.now().toIso8601String().substring(0, 7);

      double todaySales = 0;
      double monthSales = 0;

      for (final order in orders) {
        final date = order.createdAt as String;
        final total = order.total as double;
        if (date.startsWith(today)) todaySales += total;
        if (date.startsWith(month)) monthSales += total;
      }

      state = SalesStats(
        todaySales: todaySales,
        monthSales: monthSales,
        loading: false,
      );
    } catch (_) {
      state = const SalesStats(loading: false);
    }
  }

  Future<void> reload() async {
    state = const SalesStats(loading: true);
    await _load();
  }
}

final salesStatsProvider =
    NotifierProvider<SalesStatsNotifier, SalesStats>(SalesStatsNotifier.new);
