// Provider de accesibilidad (contraste y texto)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// clase AccessibilityState
class AccessibilityState {
  final bool highContrast;
  final double textScale;
  final bool panelOpen;

  const AccessibilityState({
    this.highContrast = false,
    this.textScale = 1.0,
    this.panelOpen = false,
  });

  // devuelve una copia con campos cambiados
  AccessibilityState copyWith({bool? highContrast, double? textScale, bool? panelOpen}) =>
      AccessibilityState(
        highContrast: highContrast ?? this.highContrast,
        textScale: textScale ?? this.textScale,
        panelOpen: panelOpen ?? this.panelOpen,
      );
}

const _kContrast = 'a11y_contrast';
const _kScale = 'a11y_scale';
const _min = 1.0;
const _max = 1.5;
const _step = 0.1;

// clase AccessibilityNotifier
class AccessibilityNotifier extends Notifier<AccessibilityState> {
  // construye la interfaz del widget
  @override
  AccessibilityState build() {
    final s = ref.read(storageServiceProvider);
    return AccessibilityState(
      highContrast: s.getBoolPref(_kContrast, false),
      textScale: s.getDoublePref(_kScale, 1.0),
    );
  }

  StorageService get _s => ref.read(storageServiceProvider);

  // activa o desactiva el alto contraste
  void toggleContrast() {
    final v = !state.highContrast;
    state = state.copyWith(highContrast: v);
    _s.setBoolPref(_kContrast, v);
  }

  // aumenta el tamano del texto
  void incFont() {
    final v = ((state.textScale + _step).clamp(_min, _max) * 10).round() / 10;
    state = state.copyWith(textScale: v);
    _s.setDoublePref(_kScale, v);
  }

  // reduce el tamano del texto
  void decFont() {
    final v = ((state.textScale - _step).clamp(_min, _max) * 10).round() / 10;
    state = state.copyWith(textScale: v);
    _s.setDoublePref(_kScale, v);
  }

  void togglePanel() => state = state.copyWith(panelOpen: !state.panelOpen);

  // restablece las opciones por defecto
  void reset() {
    state = state.copyWith(highContrast: false, textScale: 1.0);
    _s.setBoolPref(_kContrast, false);
    _s.setDoublePref(_kScale, 1.0);
  }
}

final accessibilityProvider =
    NotifierProvider<AccessibilityNotifier, AccessibilityState>(AccessibilityNotifier.new);