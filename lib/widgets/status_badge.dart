// Etiqueta de estado
import 'package:flutter/material.dart';

// clase StatusBadge
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;

  static const _styles = {
    'En espera': (bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309), border: Color(0xFFFDE68A)),
    'Listo':     (bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46), border: Color(0xFFA7F3D0)),
    'Enviado':   (bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF), border: Color(0xFFBFDBFE)),
    'Stock bajo':(bg: Color(0xFFFEE2E2), fg: Color(0xFFB91C1C), border: Color(0xFFFECACA)),
    'OK':        (bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46), border: Color(0xFFA7F3D0)),
  };

  // construye la interfaz del widget
  @override
  Widget build(BuildContext context) {
    final style = _styles[label] ?? (
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF334155),
      border: const Color(0xFFE2E8F0),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: style.fg),
      ),
    );
  }
}