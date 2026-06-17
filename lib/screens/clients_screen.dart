import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../providers/clients_provider.dart';
import '../providers/debts_provider.dart';
import '../services/api_service.dart' as svc;
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
    final paged = ref.watch(clientsPagedProvider);
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
                          TextSpan(text: '${paged.total} clientes · Pendiente: '),
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
              Tab(text: 'Clientes (${paged.total})'),
              Tab(text: 'Deudas (${debts.length})'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _search = v);
                ref.read(clientsPagedProvider.notifier).setSearch(v);
              },
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
    final paged = ref.watch(clientsPagedProvider);
    final debts = ref.watch(debtsProvider);

    if (paged.loading && paged.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (paged.items.isEmpty) {
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
      for (var i = 0; i < paged.items.length; i += cols) {
        final row = paged.items.sublist(i, (i + cols).clamp(0, paged.items.length));
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
                            _EditBtn(onTap: () => showDialog(
                              context: context,
                              builder: (_) => _EditClientDialog(client: client),
                            )),
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
        if (i + cols < paged.items.length) rows.add(const SizedBox(height: 16));
      }

      
      rows.add(const SizedBox(height: 24));
      rows.add(_PaginationBar(
        page: paged.page,
        totalPages: paged.totalPages,
        loading: paged.loading,
        onPage: (p) => ref.read(clientsPagedProvider.notifier).setPage(p),
      ));

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
    final paged = ref.watch(debtsPagedProvider);

    if (paged.loading && paged.items.isEmpty) {
      return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }

    if (paged.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          border: Border.all(color: kSlate200),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: const Column(
          children: [
            Icon(Icons.attach_money, size: 40, color: kSlate200),
            SizedBox(height: 12),
            Text('No hay deudas registradas', style: TextStyle(color: kSlate400, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        TextureCard(
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
              ...paged.items.indexed.map((rec) {
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
                              onTap: () async {
                                await ref.read(debtsProvider.notifier).togglePaid(debt.id);
                                ref.read(debtsPagedProvider.notifier).reload();
                              },
                              child: Icon(
                                debt.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: debt.paid ? kEmerald : kSlate300,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: Text(client?.fullName ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate800, fontSize: 13))),
                            Expanded(flex: 3, child: Text(debt.description.isEmpty ? '—' : debt.description, style: const TextStyle(fontSize: 13, color: kSlate500))),
                            SizedBox(
                              width: 110,
                              child: Text(formatCurrency(debt.amount), textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: debt.paid ? kSlate400 : kRed, decoration: debt.paid ? TextDecoration.lineThrough : null)),
                            ),
                            SizedBox(width: 90, child: Text(formatDate(debt.createdAt), style: const TextStyle(fontSize: 11, color: kSlate400))),
                            _DelBtn(onTap: () {
                              ref.read(debtsProvider.notifier).remove(debt.id);
                              ref.read(debtsPagedProvider.notifier).reload();
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        if (paged.totalPages > 1) ...[
          const SizedBox(height: 16),
          _PaginationBar(
            page: paged.page,
            totalPages: paged.totalPages,
            loading: paged.loading,
            onPage: (p) => ref.read(debtsPagedProvider.notifier).setPage(p),
          ),
        ],
      ],
    );
  }
}



class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
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
    if (totalPages <= 1) return const SizedBox.shrink();

    // Show at most 7 page buttons
    const maxButtons = 7;
    final List<int> pages = [];
    if (totalPages <= maxButtons) {
      pages.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      pages.add(1);
      int start = (page - 2).clamp(2, totalPages - 3);
      int end = (start + 4).clamp(5, totalPages - 1);
      start = (end - 4).clamp(2, totalPages - 3);
      if (start > 2) pages.add(-1); // ellipsis
      pages.addAll(List.generate(end - start + 1, (i) => start + i));
      if (end < totalPages - 1) pages.add(-1); // ellipsis
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
          if (p == -1) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: kSlate400, fontSize: 13)),
            );
          }
          final isCurrent = p == page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: (!isCurrent && !loading) ? () => onPage(p) : null,
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isCurrent ? null : Border.all(color: kSlate200),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrent ? Colors.white : kSlate600,
                    ),
                  ),
                ),
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
        if (loading)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }
}

class _EditBtn extends StatefulWidget {
  const _EditBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_EditBtn> createState() => _EditBtnState();
}

class _EditBtnState extends State<_EditBtn> {
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
            color: _hovered ? kPrimary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_outlined, size: 16, color: _hovered ? kPrimary : kSlate300),
        ),
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
  final _addressCtrl  = TextEditingController();

  @override
  void dispose() {
    _docCtrl.dispose();
    _name1Ctrl.dispose();
    _name2Ctrl.dispose();
    _lastName1Ctrl.dispose();
    _lastName2Ctrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(clientsProvider.notifier).add(
      id: _docCtrl.text.trim(),
      name1: _name1Ctrl.text.trim(),
      name2: _name2Ctrl.text.trim(),
      lastName1: _lastName1Ctrl.text.trim(),
      lastName2: _lastName2Ctrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    ref.read(clientsPagedProvider.notifier).reload();
    if (context.mounted) Navigator.pop(context);
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Direccion'),
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
  Client? _selectedClient;
  Order? _selectedOrder;
  List<Order> _clientOrders = [];
  bool _loadingOrders = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClientOrders(Client client) async {
    setState(() { _loadingOrders = true; _selectedOrder = null; _clientOrders = []; });
    try {
      final result = await svc.ApiService.getOrdersPaged(
        search: client.fullName, size: 50);
      final orders = (result['items'] as List).cast<Order>();
      setState(() { _clientOrders = orders; _loadingOrders = false; });
    } catch (_) {
      setState(() => _loadingOrders = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) return;
    if (_selectedOrder == null) return;
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount <= 0) return;
    await ref.read(debtsProvider.notifier).add(
      clientId: _selectedClient!.id,
      orderId: _selectedOrder!.id,
      amount: amount,
      description: _descCtrl.text.trim(),
    );
    ref.read(debtsPagedProvider.notifier).reload();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedClient != null && _selectedOrder != null;

    return AlertDialog(
      title: const Text('Registrar deuda', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _DebtSearchPicker<Client>(
                label: 'Buscar cliente (nombre o documento)',
                selected: _selectedClient,
                displaySelected: (c) => '${c.fullName}  ·  ${c.id}',
                onSearch: (q) async {
                  final r = await svc.ApiService.getClientsPaged(search: q, size: 8);
                  return r['items'] as List<Client>;
                },
                optionLabel: (c) => '${c.fullName}  ·  ${c.id}',
                onSelected: (c) {
                  setState(() { _selectedClient = c; _selectedOrder = null; });
                  _loadClientOrders(c);
                },
                onCleared: () => setState(() {
                  _selectedClient = null;
                  _selectedOrder = null;
                  _clientOrders = [];
                }),
              ),
              const SizedBox(height: 12),
              if (_selectedClient != null) ...[
                if (_loadingOrders)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (_clientOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Este cliente no tiene pedidos registrados.',
                        style: TextStyle(fontSize: 12, color: kRed)),
                  )
                else
                  DropdownButtonFormField<Order>(
                    value: _selectedOrder,
                    decoration: const InputDecoration(labelText: 'Pedido asociado'),
                    validator: (v) => v == null ? 'Selecciona un pedido' : null,
                    onChanged: (v) {
                      setState(() => _selectedOrder = v);
                      if (v != null) {
                        _amountCtrl.text = v.total.toStringAsFixed(0);
                      }
                    },
                    items: _clientOrders.map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        'Pedido #${o.id}  ·  ${formatCurrency(o.total)}  ·  ${o.status}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )).toList(),
                  ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto (COP)'),
                validator: (v) {
                  final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (n == null) return 'Ingresa un número válido';
                  if (n <= 0) return 'El monto debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Registrar deuda'),
        ),
      ],
    );
  }
}

// ── SearchPicker reutilizable para el diálogo de deudas ──────────────────────

class _DebtSearchPicker<T> extends StatefulWidget {
  const _DebtSearchPicker({
    required this.label,
    required this.selected,
    required this.displaySelected,
    required this.onSearch,
    required this.optionLabel,
    required this.onSelected,
    required this.onCleared,
  });
  final String label;
  final T? selected;
  final String Function(T) displaySelected;
  final Future<List<T>> Function(String) onSearch;
  final String Function(T) optionLabel;
  final void Function(T) onSelected;
  final VoidCallback onCleared;

  @override
  State<_DebtSearchPicker<T>> createState() => _DebtSearchPickerState<T>();
}

class _DebtSearchPickerState<T> extends State<_DebtSearchPicker<T>> {
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
                ? const Padding(padding: EdgeInsets.all(12),
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: _results.map((item) => InkWell(
                onTap: () {
                  _ctrl.clear();
                  setState(() { _results = []; _open = false; });
                  _focus.unfocus();
                  widget.onSelected(item);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(widget.optionLabel(item),
                        style: const TextStyle(fontSize: 13, color: kSlate800))),
                  ]),
                ),
              )).toList(),
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

class _EditClientDialog extends ConsumerStatefulWidget {
  const _EditClientDialog({required this.client});
  final Client client;

  @override
  ConsumerState<_EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends ConsumerState<_EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name1Ctrl    = TextEditingController(text: widget.client.name1);
  late final _name2Ctrl    = TextEditingController(text: widget.client.name2);
  late final _lastName1Ctrl = TextEditingController(text: widget.client.lastName1);
  late final _lastName2Ctrl = TextEditingController(text: widget.client.lastName2);
  late final _phoneCtrl    = TextEditingController(text: widget.client.phone);
  late final _addressCtrl  = TextEditingController(text: widget.client.address);

  @override
  void dispose() {
    _name1Ctrl.dispose();
    _name2Ctrl.dispose();
    _lastName1Ctrl.dispose();
    _lastName2Ctrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = Client(
      id: widget.client.id,
      name1: _name1Ctrl.text.trim(),
      name2: _name2Ctrl.text.trim(),
      lastName1: _lastName1Ctrl.text.trim(),
      lastName2: _lastName2Ctrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      createdAt: widget.client.createdAt,
    );
    await ref.read(clientsProvider.notifier).update(updated);
    ref.read(clientsPagedProvider.notifier).reload();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar cliente · ${widget.client.id}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Documento solo lectura
              TextFormField(
                initialValue: widget.client.id,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Documento (no editable)'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Direccion (opcional)'),
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
          child: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}
