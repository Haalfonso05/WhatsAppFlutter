import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/clients_provider.dart';
import '../providers/debts_provider.dart';
import '../widgets/gradient_text.dart';
import '../widgets/texture_card.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 2, vsync: this);
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openClientForm() {
    showDialog(context: context, builder: (_) => const _ClientDialog());
  }

  void _openDebtForm() {
    showDialog(context: context, builder: (_) => const _DebtDialog());
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final debts = ref.watch(debtsProvider);
    final totalPending = debts.where((d) => !d.paid).fold(0.0, (s, d) => s + d.amount);

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
                      'Clientes y Deudas',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: kSlate500),
                        children: [
                          TextSpan(text: '${clients.length} clientes · Pendiente: '),
                          TextSpan(
                            text: formatCurrency(totalPending),
                            style: const TextStyle(color: kRed, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openDebtForm,
                icon: const Icon(Icons.attach_money, size: 18),
                label: const Text('Nueva deuda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kSlate700,
                  side: const BorderSide(color: kSlate200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _openClientForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo cliente'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabCtrl,
            indicatorColor: kPrimary,
            labelColor: kPrimary,
            unselectedLabelColor: kSlate500,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            dividerColor: kSlate200,
            tabs: [
              Tab(text: 'Clientes (${clients.length})'),
              Tab(text: 'Deudas (${debts.length})'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search, size: 18, color: kSlate400),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tab content rendered inline
          ListenableBuilder(
            listenable: _tabCtrl,
            builder: (_, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _tabCtrl.index == 0
                    ? _ClientsTab(key: const ValueKey('clients'), search: _search)
                    : _DebtsTab(key: const ValueKey('debts'), search: _search),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClientsTab extends ConsumerWidget {
  const _ClientsTab({super.key, required this.search});
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final debts = ref.watch(debtsProvider);
    final q = search.toLowerCase();
    final filtered = q.isEmpty
        ? clients
        : clients.where((c) => c.fullName.toLowerCase().contains(q) || c.id.contains(q)).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          border: Border.all(color: kSlate200),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outlined, size: 40, color: kSlate200),
            const SizedBox(height: 12),
            Text(
              search.isEmpty ? 'No hay clientes registrados' : 'Sin resultados',
              style: const TextStyle(color: kSlate400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 800 ? 3 : (c.maxWidth > 500 ? 2 : 1);
      final rows = <Widget>[];
      for (var i = 0; i < filtered.length; i += cols) {
        final row = filtered.sublist(i, (i + cols).clamp(0, filtered.length));
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...row.indexed.map((rec) {
              final (j, client) = rec;
              final clientDebts = debts.where((d) => d.clientId == client.id).toList();
              final pending = clientDebts.where((d) => !d.paid).fold(0.0, (s, d) => s + d.amount);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: j < row.length - 1 ? 16 : 0),
                  child: TextureCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: kPrimary.withValues(alpha: 0.12),
                              child: Text(
                                client.name1.isNotEmpty ? client.name1[0].toUpperCase() : '?',
                                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            const Spacer(),
                            _DelBtn(onTap: () => ref.read(clientsProvider.notifier).remove(client.id)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(client.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: kSlate900, fontSize: 15)),
                        Text('Doc: ${client.id}', style: const TextStyle(fontSize: 12, color: kSlate500)),
                        if (client.phone.isNotEmpty)
                          Text(client.phone, style: const TextStyle(fontSize: 12, color: kSlate500)),
                        if (pending > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Text(
                                'Deuda pendiente: ${formatCurrency(pending)}',
                                style: const TextStyle(fontSize: 12, color: kRed, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            ...List.generate(cols - row.length, (_) => const Expanded(child: SizedBox())),
          ],
        ));
        if (i + cols < filtered.length) rows.add(const SizedBox(height: 16));
      }
      return Column(children: rows);
    });
  }
}

class _DebtsTab extends ConsumerWidget {
  const _DebtsTab({super.key, required this.search});
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final debts = ref.watch(debtsProvider);
    final q = search.toLowerCase();
    final filtered = q.isEmpty
        ? debts
        : debts.where((d) {
            final c = clients.where((c) => c.id == d.clientId).firstOrNull;
            return (c?.fullName ?? '').toLowerCase().contains(q) || d.description.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          border: Border.all(color: kSlate200),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            const Icon(Icons.attach_money, size: 40, color: kSlate200),
            const SizedBox(height: 12),
            Text(
              search.isEmpty ? 'No hay deudas registradas' : 'Sin resultados',
              style: const TextStyle(color: kSlate400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return TextureCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFAF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: kSlate100)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36),
                SizedBox(width: 12),
                Expanded(flex: 2, child: Text('Cliente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
                Expanded(flex: 3, child: Text('Descripcion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
                SizedBox(width: 110, child: Text('Monto', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
                SizedBox(width: 90, child: Text('Fecha', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSlate500))),
                SizedBox(width: 40),
              ],
            ),
          ),
          ...filtered.indexed.map((rec) {
            final (i, debt) = rec;
            final client = clients.where((c) => c.id == debt.clientId).firstOrNull;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: kSlate100),
                Opacity(
                  opacity: debt.paid ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(debtsProvider.notifier).togglePaid(debt.id),
                          child: Icon(
                            debt.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: debt.paid ? kEmerald : kSlate300,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(client?.fullName ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate800, fontSize: 13)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(debt.description.isEmpty ? '—' : debt.description,
                              style: const TextStyle(fontSize: 13, color: kSlate500)),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            formatCurrency(debt.amount),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: debt.paid ? kSlate400 : kRed,
                              decoration: debt.paid ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(formatDate(debt.createdAt),
                              style: const TextStyle(fontSize: 11, color: kSlate400)),
                        ),
                        _DelBtn(onTap: () => ref.read(debtsProvider.notifier).remove(debt.id)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DelBtn extends StatefulWidget {
  const _DelBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DelBtn> createState() => _DelBtnState();
}

class _DelBtnState extends State<_DelBtn> {
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
            color: _hovered ? kRed.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete_outline, size: 16, color: _hovered ? kRed : kSlate300),
        ),
      ),
    );
  }
}

class _ClientDialog extends ConsumerStatefulWidget {
  const _ClientDialog();

  @override
  ConsumerState<_ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends ConsumerState<_ClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _docCtrl      = TextEditingController();
  final _name1Ctrl    = TextEditingController();
  final _name2Ctrl    = TextEditingController();
  final _lastName1Ctrl = TextEditingController();
  final _lastName2Ctrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  @override
  void dispose() {
    _docCtrl.dispose();
    _name1Ctrl.dispose();
    _name2Ctrl.dispose();
    _lastName1Ctrl.dispose();
    _lastName2Ctrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(clientsProvider.notifier).add(
      id: _docCtrl.text.trim(),
      name1: _name1Ctrl.text.trim(),
      name2: _name2Ctrl.text.trim(),
      lastName1: _lastName1Ctrl.text.trim(),
      lastName2: _lastName2Ctrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo cliente'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _docCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Documento (CC / CE)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _name1Ctrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Primer nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _name2Ctrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Segundo nombre'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _lastName1Ctrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Primer apellido'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName2Ctrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Segundo apellido'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefono'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Guardar cliente'),
        ),
      ],
    );
  }
}

class _DebtDialog extends ConsumerStatefulWidget {
  const _DebtDialog();

  @override
  ConsumerState<_DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends ConsumerState<_DebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedClientId;

  @override
  void dispose() {
    _amountCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) return;
    ref.read(debtsProvider.notifier).add(
      clientId: _selectedClientId!,
      amount: double.parse(_amountCtrl.text),
      description: _descCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    return AlertDialog(
      title: const Text('Registrar deuda'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedClientId,
                decoration: const InputDecoration(labelText: 'Cliente'),
                onChanged: (v) => setState(() => _selectedClientId = v),
                validator: (v) => v == null ? 'Selecciona un cliente' : null,
                items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName))).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto (COP)'),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripcion')),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Registrar deuda'),
        ),
      ],
    );
  }
}
