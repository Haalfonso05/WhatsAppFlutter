// Pantalla de metricas
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_stats_provider.dart';
import '../widgets/texture_card.dart';
import '../widgets/gradient_text.dart';
import '../widgets/status_badge.dart';

// clase DashboardScreen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // construye la interfaz del widget
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final inventory = ref.watch(inventoryProvider);
    final stats = ref.watch(salesStatsProvider);

    final lowStock = inventory.where((i) => i.isLowStock).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Dashboard',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Bienvenido de vuelta, ${user?.name ?? ''}',
            style: const TextStyle(fontSize: 13, color: kSlate500),
          ),
          const SizedBox(height: 28),
          _MetricsGrid(
            todaySales: stats.todaySales,
            monthSales: stats.monthSales,
            lowStockCount: lowStock.length,
            loading: stats.loading,
          ),
          const SizedBox(height: 32),
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 18, color: kAmber),
              SizedBox(width: 8),
              Text(
                'Alertas de inventario bajo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kSlate800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lowStock.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: kSlate200, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: const Center(
                child: Text(
                  'Todos los productos tienen stock suficiente',
                  style: TextStyle(color: kSlate400, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: lowStock.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, color: Color(0xFFFDE68A)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 18, color: kAmber),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kSlate800)),
                                  Text(
                                    item.category.isEmpty ? 'Sin categoria' : item.category,
                                    style: const TextStyle(fontSize: 11, color: kSlate500),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge('${item.stock} unidades'),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// clase _MetricsGrid
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.todaySales,
    required this.monthSales,
    required this.lowStockCount,
    required this.loading,
  });

  final double todaySales;
  final double monthSales;
  final int lowStockCount;
  final bool loading;

  // construye la interfaz del widget
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final wide = c.maxWidth > 560;
      final cards = [
        _MetricCard(
          label: 'Ventas del dia',
          value: loading ? '...' : formatCurrency(todaySales),
          icon: Icons.attach_money,
          iconBg: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF065F46),
        ),
        _MetricCard(
          label: 'Ventas del mes',
          value: loading ? '...' : formatCurrency(monthSales),
          icon: Icons.trending_up,  
          iconBg: const Color(0xFFE0E7FF),
          iconColor: const Color(0xFF3730A3),
        ),
        _MetricCard(
          label: 'Productos stock bajo',
          value: lowStockCount.toString(),
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: kAmber,
        ),
      ];

      if (wide) {
        return Row(
          children: cards.indexed.map((rec) {
            final (i, card) = rec;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < cards.length - 1 ? 16 : 0),
                child: card,
              ),
            );
          }).toList(),
        );
      }
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: c,
        )).toList(),
      );
    });
  }
}

// clase _MetricCard
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  // construye la interfaz del widget
  @override
  Widget build(BuildContext context) {
    return TextureCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: kSlate500)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kSlate900)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ],
      ),
    );
  }
}