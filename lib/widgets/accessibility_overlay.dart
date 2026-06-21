// Boton flotante y panel de accesibilidad
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

// clase del overlay de accesibilidad
class AccessibilityOverlay extends ConsumerWidget {
  const AccessibilityOverlay({super.key});

  static const _accent = Color(0xFF10B981);
  static const _ink = Color(0xFF0F172A);
  static const _border = Color(0xFFE2E8F0);
  static const _muted = Color(0xFF64748B);

  // construye el overlay (panel + boton)
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(accessibilityProvider);
    final n = ref.read(accessibilityProvider.notifier);
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (a.panelOpen) _panel(a, n),
          const SizedBox(height: 10),
          _fab(a, n),
        ],
      ),
    );
  }

  // boton flotante que abre o cierra el panel
  Widget _fab(AccessibilityState a, AccessibilityNotifier n) {
    return GestureDetector(
      onTap: n.togglePanel,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Icon(
          a.panelOpen ? Icons.close_rounded : Icons.accessibility_new_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // panel con las opciones de accesibilidad
  Widget _panel(AccessibilityState a, AccessibilityNotifier n) {
    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accesibilidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.contrast_rounded, size: 20, color: _ink),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Alto contraste', style: TextStyle(fontSize: 14, color: _ink)),
              ),
              Switch(
                value: a.highContrast,
                onChanged: (_) => n.toggleContrast(),
                activeThumbColor: _accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.format_size_rounded, size: 20, color: _ink),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Tamaño de texto', style: TextStyle(fontSize: 14, color: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepButton('A-', a.textScale <= 1.0 ? null : n.decFont),
              Expanded(
                child: Center(
                  child: Text(
                    '${(a.textScale * 100).round()}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
                  ),
                ),
              ),
              _stepButton('A+', a.textScale >= 1.5 ? null : n.incFont),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: n.reset,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Restablecer',
                  style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // boton para subir o bajar el tamano de texto
  Widget _stepButton(String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? _accent : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }
}
