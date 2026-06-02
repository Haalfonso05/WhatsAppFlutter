import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/client.dart';
import '../models/inventory_item.dart';
import '../models/order.dart';
import '../providers/clients_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/orders_provider.dart';
import '../services/api_service.dart' as svc;
import '../widgets/gradient_text.dart';
import '../widgets/texture_card.dart';
import '../widgets/status_badge.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'Todos';

  void _openForm() {
    showDialog(context: context, builder: (_) => const _OrderDialog());
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(ordersPagedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      'Pedidos',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text('${paged.total} pedidos en total',
                        style: const TextStyle(fontSize: 13, color: kSlate500)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo pedido'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', ...orderStatuses].map((s) {
                final sel = _filter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: s,
                    selected: sel,
                    onTap: () {
                      setState(() => _filter = s);
                      ref.read(ordersPagedProvider.notifier)
                          .setStatus(s == 'Todos' ? '' : s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (paged.loading && paged.items.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ))
          else if (paged.items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                border: Border.all(color: kSlate200),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 40, color: kSlate200),
                  const SizedBox(height: 12),
                  Text(
                    _filter == 'Todos' ? 'No hay pedidos registrados' : 'No hay pedidos con estado "$_filter"',
                    style: const TextStyle(color: kSlate400, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                LayoutBuilder(builder: (_, constraints) {
                  final cols = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                  return _OrderGrid(orders: paged.items, columns: cols);
                }),
                if (paged.totalPages > 1) ...[
                  const SizedBox(height: 24),
                  _OrdersPaginationBar(
                    page: paged.page,
                    totalPages: paged.totalPages,
                    loading: paged.loading,
                    onPage: (p) => ref.read(ordersPagedProvider.notifier).setPage(p),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kPrimary : kSlate200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : kSlate600,
          ),
        ),
      ),
    );
  }
}

class _OrdersPaginationBar extends StatelessWidget {
  const _OrdersPaginationBar({
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.onPage,
  });
  final int page;
  final int totalPages;
  final bool loading;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    final List<int> pages = [];
    if (totalPages <= 7) {
      pages.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      pages.add(1);
      int start = (page - 2).clamp(2, totalPages - 3);
      int end = (start + 4).clamp(5, totalPages - 1);
      start = (end - 4).clamp(2, totalPages - 3);
      if (start > 2) pages.add(-1);
      pages.addAll(List.generate(end - start + 1, (i) => start + i));
      if (end < totalPages - 1) pages.add(-1);
      pages.add(totalPages);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 18),
          onPressed: (page > 1 && !loading) ? () => onPage(page - 1) : null,
          color: kPrimary,
          disabledColor: kSlate200,
        ),
        ...pages.map((p) {
          if (p == -1) return const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...', style: TextStyle(color: kSlate400, fontSize: 13)));
          final isCurrent = p == page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: (!isCurrent && !loading) ? () => onPage(p) : null,
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCurrent ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isCurrent ? null : Border.all(color: kSlate200),
                ),
                child: Center(child: Text('$p', style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal, color: isCurrent ? Colors.white : kSlate600))),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 18),
          onPressed: (page < totalPages && !loading) ? () => onPage(page + 1) : null,
          color: kPrimary,
          disabledColor: kSlate200,
        ),
        if (loading) const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
      ],
    );
  }
}

class _OrderGrid extends StatelessWidget {
  const _OrderGrid({required this.orders, required this.columns});
  final List<Order> orders;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < orders.length; i += columns) {
      final rowItems = orders.sublist(i, (i + columns).clamp(0, orders.length));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowItems.indexed.map((rec) {
          final (j, order) = rec;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: j < rowItems.length - 1 ? 16 : 0),
              child: _OrderCard(order: order),
            ),
          );
        }).followedBy(
          List.generate(columns - rowItems.length, (_) => const Expanded(child: SizedBox())),
        ).toList(),
      ));
      if (i + columns < orders.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _OrderDetailDialog(order: order),
      ),
      child: TextureCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: kSlate900, fontSize: 15)),
                    Text(formatDate(order.createdAt),
                        style: const TextStyle(fontSize: 11, color: kSlate400)),
                  ],
                ),
              ),
              StatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          _Row(label: 'Producto', value: order.product),
          _Row(label: 'Total', value: formatCurrency(order.total), bold: true),
          if (order.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('"${order.notes}"',
                  style: const TextStyle(fontSize: 12, color: kSlate400, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: kSlate100),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OrderStepper(
                  status: order.status,
                  onAdvance: (next) async {
                    await ref.read(ordersProvider.notifier).updateStatus(order.id, next);
                    ref.read(ordersPagedProvider.notifier).reload();
                  },
                ),
              ),
              const SizedBox(width: 8),
              _IconDelBtn(onTap: () async {
                ref.read(ordersProvider.notifier).remove(order.id);
                ref.read(ordersPagedProvider.notifier).reload();
              }),
            ],
          ),
        ],
      ),
    ));
  }
}

class _OrderDetailDialog extends ConsumerStatefulWidget {
  const _OrderDetailDialog({required this.order});
  final Order order;

  @override
  ConsumerState<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends ConsumerState<_OrderDetailDialog> {
  List<Map<String, dynamic>> _details = [];
  bool _loading = true;
  final Map<int, bool> _checked = {};

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/orders/${widget.order.id}/details'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _details = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.order.clientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kSlate900)),
                      Text(formatDate(widget.order.createdAt),
                          style: const TextStyle(fontSize: 12, color: kSlate400)),
                    ],
                  ),
                ),
                StatusBadge(widget.order.status),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: kSlate400),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: kSlate100),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Productos',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSlate500)),
                ),
                if (!_loading && _details.isNotEmpty)
                  Text(
                    '${_checked.values.where((v) => v).length}/${_details.length} listos',
                    style: const TextStyle(fontSize: 12, color: kSlate400),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (_details.isEmpty)
              const Text('Sin detalle de productos',
                  style: TextStyle(color: kSlate400, fontSize: 13))
            else
              ..._details.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final productId = d['product_id']?.toString() ?? '';
                final amount = (d['amount'] as num?)?.toInt() ?? 0;
                final name = d['product_name'] as String? ?? productId;
                final subtotal = (d['subtotal'] as num?)?.toDouble() ?? 0;
                final checked = _checked[i] ?? false;

                // Buscar stock actual en inventario
                final invMatches = inventory.where((p) => p.id == productId);
                final invItem = invMatches.isEmpty ? null : invMatches.first;
                final currentStock = invItem?.stock ?? 0;
                final hasStock = currentStock >= amount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: hasStock
                          ? () => setState(() => _checked[i] = !checked)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: !hasStock
                                    ? const Color(0xFFFEE2E2)
                                    : checked
                                        ? kPrimary
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: !hasStock
                                      ? kRed
                                      : checked
                                          ? kPrimary
                                          : kSlate300,
                                  width: 1.5,
                                ),
                              ),
                              child: !hasStock
                                  ? const Icon(Icons.close, size: 13, color: kRed)
                                  : checked
                                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                                      : null,
                            ),
                            const SizedBox(width: 10),
                            // Nombre del producto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: checked ? kSlate400 : kSlate700,
                                        decoration: checked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      )),
                                  if (!hasStock)
                                    Text(
                                      'Stock insuficiente — hay $currentStock, se necesitan $amount',
                                      style: const TextStyle(
                                          fontSize: 11, color: kRed),
                                    ),
                                ],
                              ),
                            ),
                            // Cantidad y subtotal
                            Text('x$amount',
                                style: const TextStyle(fontSize: 13, color: kSlate500)),
                            const SizedBox(width: 16),
                            Text(formatCurrency(subtotal),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: checked ? kSlate400 : kSlate800,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            const Divider(color: kSlate100),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kSlate700)),
                Text(formatCurrency(widget.order.total),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: kSlate900)),
              ],
            ),
            if (widget.order.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('"${widget.order.notes}"',
                  style: const TextStyle(
                      fontSize: 12, color: kSlate400, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStepper extends StatelessWidget {
  const _OrderStepper({required this.status, required this.onAdvance});
  final String status;
  final void Function(String) onAdvance;

  static const _steps = ['En espera', 'Enviado', 'Listo'];
  static const _colors = [Color(0xFFF59E0B), Color(0xFF6366F1), Color(0xFF22C55E)];

  @override
  Widget build(BuildContext context) {
    final cur = _steps.indexOf(status);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Linea conectora
          final stepIdx = i ~/ 2;
          final done = stepIdx < cur;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? _colors[stepIdx] : kSlate200,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < cur;
        final active = idx == cur;
        final isNext = idx == cur + 1;
        final color = _colors[idx];

        return GestureDetector(
          onTap: isNext ? () => onAdvance(_steps[idx]) : null,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? color : Colors.white,
                  border: Border.all(
                    color: done || active ? color : (isNext ? color : kSlate200),
                    width: isNext ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : active
                          ? Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white))
                          : isNext
                              ? Icon(Icons.arrow_forward, size: 13, color: color)
                              : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: done || active ? color : (isNext ? kSlate500 : kSlate300),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: kSlate400)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                  fontSize: 13,
                  color: kSlate800,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                )),
          ),
        ],
      ),
    );
  }
}

class _IconDelBtn extends StatefulWidget {
  const _IconDelBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_IconDelBtn> createState() => _IconDelBtnState();
}

class _IconDelBtnState extends State<_IconDelBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? kRed.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete_outline, size: 18, color: _hovered ? kRed : kSlate300),
        ),
      ),
    );
  }
}

class _ProductLine {
  InventoryItem? item;
  int quantity = 1;
  _ProductLine();
}

class _OrderDialog extends ConsumerStatefulWidget {
  const _OrderDialog();

  @override
  ConsumerState<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends ConsumerState<_OrderDialog> {
  final _notesCtrl = TextEditingController();
  Client? _selectedClient;
  final List<_ProductLine> _lines = [_ProductLine()];
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double _calcTotal() {
    return _lines.fold(0, (sum, l) {
      if (l.item == null) return sum;
      return sum + l.item!.price * l.quantity;
    });
  }

  String? _stockError() {
    for (final line in _lines) {
      if (line.item == null) continue;
      if (line.item!.stock <= 0) return 'Sin stock: ${line.item!.name}';
      if (line.quantity > line.item!.stock) {
        return '${line.item!.name}: solo hay ${line.item!.stock} en stock';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedClient == null) return;
    if (_lines.any((l) => l.item == null)) return;
    if (_stockError() != null) return;
    setState(() => _saving = true);
    try {
      final lines = _lines.map((l) => {
        'productId': l.item!.id,
        'productName': l.item!.name,
        'quantity': l.quantity,
        'price': l.item!.price,
      }).toList();
      await ref.read(ordersProvider.notifier).add(
        clientName: _selectedClient!.fullName,
        customerDocument: _selectedClient!.id,
        lines: lines,
        notes: _notesCtrl.text.trim(),
      );
      ref.read(ordersPagedProvider.notifier).reload();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRed,
              duration: const Duration(seconds: 6)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcTotal();
    final stockError = _stockError();
    final canSubmit = !_saving &&
        _selectedClient != null &&
        _lines.every((l) => l.item != null) &&
        stockError == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nuevo pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kSlate900)),
              const SizedBox(height: 20),
              _SearchPicker<Client>(
                label: 'Buscar cliente (nombre o documento)',
                selected: _selectedClient,
                displaySelected: (c) => '${c.fullName}  ·  ${c.id}',
                onSearch: (q) async {
                  final r = await svc.ApiService.getClientsPaged(search: q, size: 8);
                  return r['items'] as List<Client>;
                },
                optionLabel: (c) => '${c.fullName}  ·  ${c.id}',
                onSelected: (c) => setState(() => _selectedClient = c),
                onCleared: () => setState(() => _selectedClient = null),
              ),
              const SizedBox(height: 20),

              const Row(children: [
                Expanded(child: Text('Producto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
                SizedBox(width: 90, child: Text('Cant.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500), textAlign: TextAlign.center)),
                SizedBox(width: 40),
              ]),
              const SizedBox(height: 6),

              ..._lines.asMap().entries.map((entry) {
                final i = entry.key;
                final line = entry.value;
                final overStock = line.item != null && line.quantity > line.item!.stock;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SearchPicker<InventoryItem>(
                              label: 'Buscar producto',
                              selected: line.item,
                              displaySelected: (p) => p.name,
                              onSearch: (q) async {
                                final r = await svc.ApiService.getProductsPaged(search: q, size: 8);
                                return r['items'] as List<InventoryItem>;
                              },
                              optionLabel: (p) => '${p.name}  ·  ${NumberFormat('#,##0', 'es_CO').format(p.price)}  ·  ${p.stock} uds',
                              optionDisabled: (p) => p.stock <= 0,
                              onSelected: (p) => setState(() { line.item = p; line.quantity = 1; }),
                              onCleared: () => setState(() { line.item = null; line.quantity = 1; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SmallBtn(
                                    icon: Icons.remove,
                                    onTap: line.quantity > 1 ? () => setState(() => line.quantity--) : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('${line.quantity}',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                            color: overStock ? kRed : kSlate800)),
                                  ),
                                  _SmallBtn(
                                    icon: Icons.add,
                                    onTap: line.item != null && line.quantity < line.item!.stock
                                        ? () => setState(() => line.quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 32,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _lines.length > 1
                                  ? GestureDetector(
                                      onTap: () => setState(() => _lines.removeAt(i)),
                                      child: const Icon(Icons.close, size: 16, color: kSlate400))
                                  : const SizedBox(),
                            ),
                          ),
                        ],
                      ),
                      if (overStock)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text('Solo hay ${line.item!.stock} en stock',
                              style: const TextStyle(fontSize: 11, color: kRed)),
                        ),
                    ],
                  ),
                );
              }),

              TextButton.icon(
                onPressed: () => setState(() => _lines.add(_ProductLine())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar producto', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: kPrimary),
              ),
              const SizedBox(height: 8),
              const Divider(color: kSlate100),
              const SizedBox(height: 8),

              if (stockError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 15, color: kRed),
                    const SizedBox(width: 6),
                    Text(stockError, style: const TextStyle(fontSize: 12, color: kRed)),
                  ]),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kSlate700)),
                  Text(formatCurrency(total),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kSlate900)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(backgroundColor: kPrimary),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Crear pedido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget de búsqueda con sugerencias ────────────────────────────────────────

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({
    required this.label,
    required this.selected,
    required this.displaySelected,
    required this.onSearch,
    required this.optionLabel,
    required this.onSelected,
    required this.onCleared,
    this.optionDisabled,
  });

  final String label;
  final T? selected;
  final String Function(T) displaySelected;
  final Future<List<T>> Function(String) onSearch;
  final String Function(T) optionLabel;
  final bool Function(T)? optionDisabled;
  final void Function(T) onSelected;
  final VoidCallback onCleared;

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<T> _results = [];
  bool _loading = false;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _open = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _results = []; _open = false; });
      return;
    }
    setState(() { _loading = true; _open = true; });
    try {
      final res = await widget.onSearch(q.trim());
      if (mounted) setState(() { _results = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If something is selected, show chip
    if (widget.selected != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: kPrimary),
          borderRadius: BorderRadius.circular(8),
          color: kPrimary.withValues(alpha: 0.05),
        ),
        child: Row(children: [
          Expanded(child: Text(widget.displaySelected(widget.selected!),
              style: const TextStyle(fontSize: 13, color: kSlate800))),
          GestureDetector(
            onTap: () { _ctrl.clear(); widget.onCleared(); },
            child: const Icon(Icons.close, size: 16, color: kSlate400),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : const Icon(Icons.search, size: 18, color: kSlate400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        if (_open && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kSlate200),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: _results.map((item) {
                final disabled = widget.optionDisabled?.call(item) ?? false;
                return InkWell(
                  onTap: disabled ? null : () {
                    _ctrl.clear();
                    setState(() { _results = []; _open = false; });
                    _focus.unfocus();
                    widget.onSelected(item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text(widget.optionLabel(item),
                          style: TextStyle(fontSize: 13,
                              color: disabled ? kSlate300 : kSlate800))),
                      if (disabled)
                        const Text('Sin stock', style: TextStyle(fontSize: 11, color: kRed)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        if (_open && !_loading && _results.isEmpty && _ctrl.text.length >= 2)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kSlate200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Sin resultados', style: TextStyle(fontSize: 13, color: kSlate400)),
          ),
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: enabled ? kSlate100 : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14,
            color: enabled ? kSlate600 : kSlate300),
      ),
    );
  }
}
