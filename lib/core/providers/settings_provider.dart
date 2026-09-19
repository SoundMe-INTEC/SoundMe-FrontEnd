import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave de almacenamiento local para la preferencia de traducción explícita.
const String _explicitTranslationPrefKey = 'explicit_translation_mode';

/// Estado de configuración de traducción del motor de SoundMe.
class TranslationSettingsState {
  /// Si es `true`, solo se traduce exactamente la palabra indicada,
  /// desactivando sinónimos y autocorrecciones ortográficas/fonéticas.
  /// Si es `false`, se aplica corrección inteligente de erratas y sinónimos.
  final bool explicitTranslation;

  const TranslationSettingsState({
    this.explicitTranslation = false,
  });

  TranslationSettingsState copyWith({
    bool? explicitTranslation,
  }) {
    return TranslationSettingsState(
      explicitTranslation: explicitTranslation ?? this.explicitTranslation,
    );
  }
}

/// Notificador que gestiona el estado y la persistencia local de configuración.
class TranslationSettingsNotifier extends StateNotifier<TranslationSettingsState> {
  TranslationSettingsNotifier() : super(const TranslationSettingsState()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final explicit = prefs.getBool(_explicitTranslationPrefKey) ?? false;
      state = state.copyWith(explicitTranslation: explicit);
    } catch (_) {
      // Si SharedPreferences no está disponible en ambiente de prueba, se mantiene el default
    }
  }

  /// Alterna o establece el modo de traducción explícita.
  Future<void> setExplicitTranslation(bool value) async {
    state = state.copyWith(explicitTranslation: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_explicitTranslationPrefKey, value);
    } catch (_) {
      // Ignorar excepciones de I/O en entornos sin plugins
    }
  }

  /// Invierte el valor actual del modo explícito.
  Future<void> toggleExplicitTranslation() async {
    await setExplicitTranslation(!state.explicitTranslation);
  }
}

/// Proveedor global del estado de configuración de traducción.
final translationSettingsProvider =
    StateNotifierProvider<TranslationSettingsNotifier, TranslationSettingsState>((ref) {
  return TranslationSettingsNotifier();
});

/// Selector de conveniencia booleano para observar directamente el modo explícito.
final explicitTranslationProvider = Provider<bool>((ref) {
  return ref.watch(translationSettingsProvider).explicitTranslation;
});
