import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/order.dart';
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
    return TextureCard(
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
          _Row(label: 'Cantidad', value: order.quantity.toString()),
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
                child: DropdownButtonFormField<String>(
                  initialValue: order.status,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  style: const TextStyle(fontSize: 13, color: kSlate700),
                  onChanged: (v) {
                    if (v != null) ref.read(ordersProvider.notifier).updateStatus(order.id, v);
                  },
                  items: orderStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              _IconDelBtn(onTap: () => ref.read(ordersProvider.notifier).remove(order.id)),
            ],
          ),
        ],
      ),
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

class _OrderDialog extends ConsumerStatefulWidget {
  const _OrderDialog();

  @override
  ConsumerState<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends ConsumerState<_OrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _clientCtrl.dispose(); _productCtrl.dispose(); _qtyCtrl.dispose();
    _totalCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(ordersProvider.notifier).add(
      clientName: _clientCtrl.text.trim(),
      product: _productCtrl.text.trim(),
      quantity: int.parse(_qtyCtrl.text),
      total: double.parse(_totalCtrl.text),
      notes: _notesCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo pedido'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _clientCtrl,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _productCtrl,
                decoration: const InputDecoration(labelText: 'Producto'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalido' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _totalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total (MXN)'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalido' : null)),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Crear pedido'),
        ),
      ],
    );
  }
}
