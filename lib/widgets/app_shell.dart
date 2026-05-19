import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

const _kSidebar = Color(0xFF0F172A);      // slate-900
const _kSidebarHover = Color(0xFF1E293B); // slate-800
const _kSidebarActive = Color(0xFF4338CA);// indigo-700
const _kInactiveText = Color(0xFF94A3B8); // slate-400
const _kDivider = Color(0xFF1E293B);      // slate-800

const _navItems = [
  (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
  (icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Pedidos', path: '/orders'),
  (icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventario', path: '/inventory'),
  (icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Clientes', path: '/clients'),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _navItems.indexWhere((e) => loc.startsWith(e.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final selected = _selectedIndex(context);
    final user = ref.watch(authProvider);
    void onLogout() => ref.read(authProvider.notifier).logout();
    void onSelect(int i) => context.go(_navItems[i].path);

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            _DarkSidebar(
              selectedIndex: selected,
              userName: user?.name ?? '',
              userEmail: user?.email ?? '',
              onLogout: onLogout,
              onSelect: onSelect,
            ),
            Expanded(
              child: ClipRect(child: child),
            ),
          ],
        ),
      );
    }

    // Mobile: dark AppBar + Drawer
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kSidebar,
        iconTheme: const IconThemeData(color: _kInactiveText),
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Gestion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: _kSidebar,
        width: 240,
        child: _DarkSidebarContent(
          selectedIndex: selected,
          userName: user?.name ?? '',
          userEmail: user?.email ?? '',
          onLogout: () { Navigator.pop(context); onLogout(); },
          onSelect: (i) { Navigator.pop(context); onSelect(i); },
        ),
      ),
      body: child,
    );
  }
}

class _DarkSidebar extends StatelessWidget {
  const _DarkSidebar({
    required this.selectedIndex,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSelect,
  });

  final int selectedIndex;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        color: _kSidebar,
        child: _DarkSidebarContent(
          selectedIndex: selectedIndex,
          userName: userName,
          userEmail: userEmail,
          onLogout: onLogout,
          onSelect: onSelect,
        ),
      ),
    );
  }
}

class _DarkSidebarContent extends StatelessWidget {
  const _DarkSidebarContent({
    required this.selectedIndex,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSelect,
  });

  final int selectedIndex;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Logo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kDivider)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gestion',
                style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
        // Nav
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = i == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _NavItem(
                  icon: active ? item.activeIcon : item.icon,
                  label: item.label,
                  active: active,
                  onTap: () => onSelect(i),
                ),
              );
            }),
          ),
        ),
        const Spacer(),
        // User section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _kDivider)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0x336366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x4D6366F1)),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userEmail.isNotEmpty)
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _NavItem(
                icon: Icons.logout,
                label: 'Cerrar sesion',
                active: false,
                onTap: onLogout,
                isLogout: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.isLogout = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isLogout;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color fg = _kInactiveText;

    if (widget.active) {
      bg = _kSidebarActive;
      fg = Colors.white;
    } else if (_hovered) {
      bg = _kSidebarHover;
      fg = widget.isLogout ? const Color(0xFFF87171) : const Color(0xFFF1F5F9);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
