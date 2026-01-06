import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider, který asynchronně poskytuje instanci SharedPreferences.
/// Ostatní provideři ho mohou použít pro přístup k úložišti.
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

/// Provider, který zjišťuje, zda existuje uložená hra.
///
/// Automaticky se stará o načítání (loading) a chybové stavy.
/// Pomocí `ref.watch` v UI můžeme zobrazit správný widget pro každý stav.
final existujeUlozeniProvider = FutureProvider<bool>((ref) async {
  // Počkáme, až bude k dispozici instance SharedPreferences
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  // Vrátíme hodnotu, nebo `false` pokud neexistuje
  return prefs.getBool('existujeUlozeni') ?? false;
});

// ============================================================================
// --- Správa Nastavení (Zvuky, Vibrace) ---
// ============================================================================

/// Neměnná (immutable) datová třída pro držení stavu nastavení.
@immutable
class AppSettings {
  const AppSettings({required this.zvukyZapnute, required this.vibraceZapnute});

  final bool zvukyZapnute;
  final bool vibraceZapnute;

  /// Vytvoří kopii tohoto objektu s novými hodnotami.
  AppSettings copyWith({bool? zvukyZapnute, bool? vibraceZapnute}) {
    return AppSettings(
      zvukyZapnute: zvukyZapnute ?? this.zvukyZapnute,
      vibraceZapnute: vibraceZapnute ?? this.vibraceZapnute,
    );
  }
}

/// Notifier, který spravuje stav nastavení aplikace.
///
/// Načítá data z SharedPreferences a umožňuje jejich změnu a uložení.
/// Pracuje s `AsyncValue`, aby správně ošetřil stavy načítání a chyby.
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  /// Interní metoda pro asynchronní načtení počátečního stavu.
  Future<void> _init() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final settings = AppSettings(
        zvukyZapnute: prefs.getBool('zvukyZapnute') ?? true,
        vibraceZapnute: prefs.getBool('vibraceZapnute') ?? true,
      );
      // Pokud je notifier stále aktivní, nastavíme data.
      if (mounted) {
        state = AsyncValue.data(settings);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Zapne/vypne zvuky a uloží volbu.
  Future<void> setZvuky(bool zapnute) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('zvukyZapnute', zapnute);
    // Aktualizujeme stav, pouze pokud máme platná data (ne při loadingu/erroru)
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(zvukyZapnute: zapnute));
    }
  }

  /// Zapne/vypne vibrace a uloží volbu.
  Future<void> setVibrace(bool zapnute) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('vibraceZapnute', zapnute);
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(vibraceZapnute: zapnute));
    }
  }
}

/// Provider, který poskytuje instanci [SettingsNotifier] a jeho stav.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>(
        (ref) => SettingsNotifier(ref));
