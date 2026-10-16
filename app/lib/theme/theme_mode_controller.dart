// theme/theme_mode_controller.dart
//
// Le choix d'apparence de l'utilisateur : suivre le système, rester en
// clair, rester en sombre. Il vit hors de l'arbre de widgets parce que
// la racine de l'application doit le lire avant de construire le
// MaterialApp, et qu'il survit à la fermeture de l'application.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance unique, lue par `MyApp` et écrite par l'écran Apparence.
final appThemeMode = ThemeModeController();

class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  static const String _key = 'app_theme_mode';

  /// Relit le choix enregistré. À appeler une fois, avant `runApp`, pour
  /// que le premier écran s'affiche déjà dans le bon mode plutôt que de
  /// clignoter du clair au sombre.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = _parse(prefs.getString(_key));
    } catch (_) {
      // Un stockage indisponible ne doit pas empêcher le démarrage :
      // on reste sur le réglage système.
    }
  }

  Future<void> select(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Le choix s'applique quand même pour la session en cours.
    }
  }

  static ThemeMode _parse(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
