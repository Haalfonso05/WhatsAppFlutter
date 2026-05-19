import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../widgets/gradient_text.dart';
import '../widgets/texture_card.dart';
import '../widgets/status_badge.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm({InventoryItem? editing}) {
    showDialog(context: context, builder: (_) => _InventoryDialog(editing: editing));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(inventoryProvider);
    final q = _search.toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((i) => i.name.toLowerCase().contains(q) || i.category.toLowerCase().contains(q)).toList();

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
                      'Inventario',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text('${all.length} productos registrados',
                        style: const TextStyle(fontSize: 13, color: kSlate500)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar producto'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search, size: 18, color: kSlate400),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextureCard(
            padding: EdgeInsets.zero,
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 40, color: kSlate200),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty ? 'No hay productos registrados' : 'Sin resultados',
                            style: const TextStyle(color: kSlate400, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : _InventoryTable(
                    items: filtered,
                    onEdit: (item) => _openForm(editing: item),
                    onDelete: (id) => ref.read(inventoryProvider.notifier).remove(id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.items, required this.onEdit, required this.onDelete});
  final List<InventoryItem> items;
  final void Function(InventoryItem) onEdit;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFAF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: kSlate100)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Producto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
              Expanded(flex: 2, child: Text('Categoria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
              SizedBox(width: 80, child: Text('Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500), textAlign: TextAlign.right)),
              SizedBox(width: 100, child: Text('Precio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500), textAlign: TextAlign.right)),
              SizedBox(width: 90, child: Text('Estado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500), textAlign: TextAlign.right)),
              SizedBox(width: 72),
            ],
          ),
        ),
        ...items.indexed.map((rec) {
          final (i, item) = rec;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, color: Color(0xFAF8FAFC)),
              _TableRow(item: item, onEdit: () => onEdit(item), onDelete: () => onDelete(item.id)),
            ],
          );
        }),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item, required this.onEdit, required this.onDelete});
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate800, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category.isEmpty ? '—' : item.category,
              style: const TextStyle(fontSize: 13, color: kSlate500),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text('${item.stock}', textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate700, fontSize: 13)),
          ),
          SizedBox(
            width: 100,
            child: Text(formatCurrency(item.price), textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: kSlate700)),
          ),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusBadge(item.isLowStock ? 'Stock bajo' : 'OK'),
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _IconBtn(icon: Icons.edit_outlined, color: kPrimary, onTap: onEdit),
                const SizedBox(width: 2),
                _IconBtn(icon: Icons.delete_outline, color: kRed, onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: _hovered ? widget.color : kSlate400),
        ),
      ),
    );
  }
}

class _InventoryDialog extends ConsumerStatefulWidget {
  const _InventoryDialog({this.editing});
  final InventoryItem? editing;

  @override
  ConsumerState<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends ConsumerState<_InventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
  late final _catCtrl = TextEditingController(text: widget.editing?.category ?? '');
  late final _stockCtrl = TextEditingController(text: widget.editing?.stock.toString() ?? '');
  late final _priceCtrl = TextEditingController(text: widget.editing?.price.toString() ?? '');
  late final _threshCtrl = TextEditingController(text: (widget.editing?.threshold ?? 5).toString());

  @override
  void dispose() {
    _nameCtrl.dispose(); _catCtrl.dispose(); _stockCtrl.dispose();
    _priceCtrl.dispose(); _threshCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final n = ref.read(inventoryProvider.notifier);
    if (widget.editing != null) {
      n.update(widget.editing!.id,
        name: _nameCtrl.text.trim(), category: _catCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text), price: double.parse(_priceCtrl.text),
        threshold: int.parse(_threshCtrl.text));
    } else {
      n.add(name: _nameCtrl.text.trim(), category: _catCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text), price: double.parse(_priceCtrl.text),
        threshold: int.parse(_threshCtrl.text));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editing != null ? 'Editar producto' : 'Nuevo producto'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _catCtrl,
                decoration: const InputDecoration(labelText: 'Categoria')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalido' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio (MXN)'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalido' : null)),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _threshCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Umbral de alerta'),
                validator: (v) => int.tryParse(v ?? '') == null ? 'Invalido' : null),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: Text(widget.editing != null ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}
