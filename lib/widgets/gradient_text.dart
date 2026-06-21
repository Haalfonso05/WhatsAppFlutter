// Texto con degradado
import 'package:flutter/material.dart';

// clase GradientText
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF7C3AED)],
    ),
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;

  // construye la interfaz del widget
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}