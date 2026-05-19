import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/clients_screen.dart';
import '../widgets/app_shell.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<Object?>(authProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: listenable,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider) != null;
      final loc = state.matchedLocation;
      final onAuth = loc == '/login' || loc == '/register';
      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && onAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, st) => const RegisterScreen()),
      ShellRoute(
        builder: (ctx, st, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (ctx, st) => const DashboardScreen()),
          GoRoute(path: '/inventory', builder: (ctx, st) => const InventoryScreen()),
          GoRoute(path: '/orders', builder: (ctx, st) => const OrdersScreen()),
          GoRoute(path: '/clients', builder: (ctx, st) => const ClientsScreen()),
        ],
      ),
    ],
  );
});
