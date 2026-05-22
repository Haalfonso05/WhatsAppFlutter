import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/order.dart';
import '../providers/clients_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/orders_provider.dart';
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
    final all = ref.watch(ordersProvider);
    final filtered = _filter == 'Todos' ? all : all.where((o) => o.status == _filter).toList();
    final counts = {for (final s in orderStatuses) s: all.where((o) => o.status == s).length};

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
                    Text('${all.length} pedidos en total',
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
                    label: s == 'Todos' ? 'Todos' : '$s (${counts[s] ?? 0})',
                    selected: sel,
                    onTap: () => setState(() => _filter = s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
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
            LayoutBuilder(builder: (_, constraints) {
              final cols = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
              return _OrderGrid(orders: filtered, columns: cols);
            }),
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
                  onAdvance: (next) =>
                      ref.read(ordersProvider.notifier).updateStatus(order.id, next),
                ),
              ),
              const SizedBox(width: 8),
              _IconDelBtn(onTap: () => ref.read(ordersProvider.notifier).remove(order.id)),
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
                final productId = d['product_id'] as String? ?? '';
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
  String? productId;
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
  String? _selectedClientId;
  final List<_ProductLine> _lines = [_ProductLine()];
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double _calcTotal(List<dynamic> inventory) {
    double t = 0;
    for (final line in _lines) {
      if (line.productId == null) continue;
      final matches = inventory.where((p) => p.id == line.productId);
      if (matches.isEmpty) continue;
      t += matches.first.price * line.quantity;
    }
    return t;
  }

  String? _stockError(List<dynamic> inventory) {
    for (final line in _lines) {
      if (line.productId == null) continue;
      final matches = inventory.where((p) => p.id == line.productId);
      final item = matches.isEmpty ? null : matches.first;
      if (item == null) continue;
      if (item.stock <= 0) return 'Sin stock: ${item.name}';
      if (line.quantity > item.stock) {
        return '${item.name}: solo hay ${item.stock} en stock';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final clients = ref.read(clientsProvider);
    final inventory = ref.read(inventoryProvider);
    if (_selectedClientId == null) return;
    if (_lines.any((l) => l.productId == null)) return;
    if (_stockError(inventory) != null) return;

    final client = clients.firstWhere((c) => c.id == _selectedClientId);
    setState(() => _saving = true);
    try {
      final lines = _lines.map((l) {
        final item = inventory.firstWhere((p) => p.id == l.productId);
        return {
          'productId': item.id,
          'productName': item.name,
          'quantity': l.quantity,
          'price': item.price,
        };
      }).toList();

      await ref.read(ordersProvider.notifier).add(
        clientName: client.fullName,
        customerDocument: client.id,
        lines: lines,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRed,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final inventory = ref.watch(inventoryProvider);
    final total = _calcTotal(inventory);
    final stockError = _stockError(inventory);
    final canSubmit = !_saving &&
        _selectedClientId != null &&
        _lines.every((l) => l.productId != null) &&
        stockError == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
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

            // Cliente
            DropdownButtonFormField<String>(
              initialValue: _selectedClientId,
              decoration: const InputDecoration(labelText: 'Cliente'),
              onChanged: (v) => setState(() => _selectedClientId = v),
              items: clients
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName)))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Encabezado productos
            Row(
              children: [
                const Expanded(
                  child: Text('Producto',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500)),
                ),
                SizedBox(
                  width: 90,
                  child: const Text('Cant.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 6),

            // Lineas de producto
            ..._lines.asMap().entries.map((entry) {
              final i = entry.key;
              final line = entry.value;
              final selectedItem = line.productId == null
                  ? null
                  : (inventory.where((p) => p.id == line.productId).isEmpty
                      ? null
                      : inventory.firstWhere((p) => p.id == line.productId));
              final maxQty = selectedItem?.stock ?? 999;
              final outOfStock = selectedItem != null && selectedItem.stock <= 0;
              final overStock = selectedItem != null && line.quantity > selectedItem.stock;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: line.productId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              errorText: outOfStock ? 'Sin stock' : null,
                            ),
                            hint: const Text('Seleccionar', style: TextStyle(fontSize: 13)),
                            onChanged: (v) => setState(() {
                              line.productId = v;
                              line.quantity = 1;
                            }),
                            items: inventory.map((p) {
                              final noStock = p.stock <= 0;
                              final label = noStock
                                  ? '${p.name} — Sin stock'
                                  : '${p.name}  (${formatCurrency(p.price)})  ·  ${p.stock} uds';
                              return DropdownMenuItem(
                                value: p.id,
                                enabled: !noStock,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: noStock ? kSlate300 : kSlate800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallBtn(
                                icon: Icons.remove,
                                onTap: line.quantity > 1
                                    ? () => setState(() => line.quantity--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('${line.quantity}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: overStock ? kRed : kSlate800)),
                              ),
                              _SmallBtn(
                                icon: Icons.add,
                                onTap: line.quantity < maxQty
                                    ? () => setState(() => line.quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: _lines.length > 1
                              ? GestureDetector(
                                  onTap: () => setState(() => _lines.removeAt(i)),
                                  child: const Icon(Icons.close, size: 16, color: kSlate400),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                    if (overStock)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 4),
                        child: Text(
                          'Solo hay ${selectedItem.stock} en stock',
                          style: const TextStyle(fontSize: 11, color: kRed),
                        ),
                      ),
                  ],
                ),
              );
            }),

            // Agregar linea
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_ProductLine())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar producto', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: kPrimary),
            ),

            const SizedBox(height: 8),
            const Divider(color: kSlate100),
            const SizedBox(height: 8),

            // Error de stock
            if (stockError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 15, color: kRed),
                    const SizedBox(width: 6),
                    Text(stockError,
                        style: const TextStyle(fontSize: 12, color: kRed)),
                  ],
                ),
              ),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kSlate700)),
                Text(formatCurrency(total),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: kSlate900)),
              ],
            ),
            const SizedBox(height: 12),

            // Notas
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(backgroundColor: kPrimary),
                  child: _saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
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
