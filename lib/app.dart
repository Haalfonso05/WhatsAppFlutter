import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'providers/accessibility_provider.dart';
import 'widgets/accessibility_overlay.dart';

class App extends ConsumerWidget {
  const App({super.key});

  
  static const ColorFilter _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final a11y = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: 'Gestion App',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();

        content = MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(a11y.textScale)),
          child: content,
        );

        if (a11y.highContrast) {
          content = ColorFiltered(colorFilter: _invert, child: content);
        }

        return Stack(
          children: [
            Positioned.fill(child: content),
            const Positioned(right: 16, bottom: 16, child: AccessibilityOverlay()),
          ],
        );
      },
    );
  }
}
