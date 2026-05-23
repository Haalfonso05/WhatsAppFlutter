import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';
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

  void _openForm() {
    showDialog(context: context, builder: (_) => const _InventoryDialog());
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
                onPressed: _openForm,
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
                    onDelete: (id) => ref.read(inventoryProvider.notifier).remove(id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTable extends ConsumerWidget {
  const _InventoryTable({required this.items, required this.onDelete});
  final List<InventoryItem> items;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              SizedBox(width: 80),
            ],
          ),
        ),
        ...items.indexed.map((rec) {
          final (i, item) = rec;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, color: Color(0xFAF8FAFC)),
              _TableRow(item: item, onDelete: () => onDelete(item.id)),
            ],
          );
        }),
      ],
    );
  }
}

class _TableRow extends ConsumerStatefulWidget {
  const _TableRow({required this.item, required this.onDelete});
  final InventoryItem item;
  final VoidCallback onDelete;

  @override
  ConsumerState<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends ConsumerState<_TableRow> {
  bool _editing = false;
  late final _nameCtrl  = TextEditingController(text: widget.item.name);
  late final _stockCtrl = TextEditingController(text: widget.item.stock.toString());
  late final _priceCtrl = TextEditingController(text: widget.item.price.toStringAsFixed(0));

  @override
  void dispose() {
    _nameCtrl.dispose(); _stockCtrl.dispose(); _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final stock = int.tryParse(_stockCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    if (stock == null || price == null || _nameCtrl.text.trim().isEmpty) return;
    await ref.read(inventoryProvider.notifier).update(
      widget.item.id,
      name: _nameCtrl.text.trim(),
      category: widget.item.category,
      stock: stock,
      price: price,
      threshold: widget.item.threshold,
    );
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _editing ? _editRow() : _viewRow(),
    );
  }

  Future<void> _adjustStock(int delta) async {
    await ApiService.adjustProductStock(widget.item.id, delta);
    ref.read(inventoryProvider.notifier).reload();
  }

  Widget _viewRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(widget.item.name,
              style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate800, fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            widget.item.category.isEmpty ? '—' : widget.item.category,
            style: const TextStyle(fontSize: 13, color: kSlate500),
          ),
        ),
        SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _StockBtn(icon: Icons.remove, onTap: () => _adjustStock(-1)),
              const SizedBox(width: 4),
              Text('${widget.item.stock}',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate700, fontSize: 13)),
              const SizedBox(width: 4),
              _StockBtn(icon: Icons.add, onTap: () => _adjustStock(1)),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(formatCurrency(widget.item.price), textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: kSlate700)),
        ),
        SizedBox(
          width: 90,
          child: Align(
            alignment: Alignment.centerRight,
            child: StatusBadge(widget.item.isLowStock ? 'Stock bajo' : 'OK'),
          ),
        ),
        SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _IconBtn(icon: Icons.edit_outlined, color: kPrimary,
                  onTap: () => setState(() => _editing = true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editRow() {
    const inputDec = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: OutlineInputBorder(),
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(controller: _nameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: inputDec),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            widget.item.category.isEmpty ? '—' : widget.item.category,
            style: const TextStyle(fontSize: 13, color: kSlate500),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(controller: _stockCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: inputDec),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: TextField(controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: inputDec),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _IconBtn(icon: Icons.check, color: kPrimary, onTap: _save),
              const SizedBox(width: 2),
              _IconBtn(icon: Icons.close, color: kSlate400,
                  onTap: () {
                    _nameCtrl.text = widget.item.name;
                    _stockCtrl.text = widget.item.stock.toString();
                    _priceCtrl.text = widget.item.price.toStringAsFixed(0);
                    setState(() => _editing = false);
                  }),
            ],
          ),
        ),
      ],
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

class _StockBtn extends StatelessWidget {
  const _StockBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: kSlate100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 13, color: kSlate500),
      ),
    );
  }
}

class _InventoryDialog extends ConsumerStatefulWidget {
  const _InventoryDialog();

  @override
  ConsumerState<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends ConsumerState<_InventoryDialog> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _threshCtrl = TextEditingController(text: '5');
  String? _selectedType;
  List<Map<String, String>> _types = [];

  @override
  void initState() {
    super.initState();
    ApiService.getProductTypes().then((t) => setState(() => _types = t));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _stockCtrl.dispose();
    _priceCtrl.dispose(); _threshCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;
    ref.read(inventoryProvider.notifier).add(
      name: _nameCtrl.text.trim(), category: _selectedType!,
      stock: int.parse(_stockCtrl.text), price: double.parse(_priceCtrl.text),
      threshold: int.parse(_threshCtrl.text));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo producto'),
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
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Categoria'),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) => v == null ? 'Selecciona una categoria' : null,
                items: _types.map((t) => DropdownMenuItem(
                  value: t['id'],
                  child: Text('${t['name']} (${t['id']})'),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalido' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio (COP)'),
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
