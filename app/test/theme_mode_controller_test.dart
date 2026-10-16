// Le choix d'apparence survit a la fermeture de l'application.
//
// Sans cela, un utilisateur qui prefere le mode sombre le rechoisirait a
// chaque lancement — et verrait l'ecran s'afficher en clair avant de
// basculer sous ses yeux, puisque la lecture se fait avant `runApp`.
import 'package:epilist/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sans rien d enregistre, on suit le systeme', () async {
    SharedPreferences.setMockInitialValues({});
    final controleur = ThemeModeController();
    await controleur.load();
    expect(controleur.value, ThemeMode.system);
  });

  test('le choix est relu au lancement suivant', () async {
    SharedPreferences.setMockInitialValues({});
    final premier = ThemeModeController();
    await premier.select(ThemeMode.dark);
    expect(premier.value, ThemeMode.dark);

    final second = ThemeModeController();
    await second.load();
    expect(second.value, ThemeMode.dark);
  });

  test('une valeur enregistree inconnue retombe sur le systeme', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'sepia'});
    final controleur = ThemeModeController();
    await controleur.load();
    expect(controleur.value, ThemeMode.system);
  });

  test(
    'choisir previent les auditeurs, une seule fois par changement',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controleur = ThemeModeController();
      var avis = 0;
      controleur.addListener(() => avis++);
      await controleur.select(ThemeMode.light);
      await controleur.select(ThemeMode.light); // deja ce mode
      expect(avis, 1);
    },
  );
}
