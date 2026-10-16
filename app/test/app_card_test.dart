// La carte et l'en-tete de section communs.
//
// Cinquante-quatre endroits peignaient leur propre carte : un Container,
// un BoxDecoration, un rayon choisi entre 8 et 16, parfois une ombre
// alors que le theme dit « bordure fine, pas d'ombre ». Ces deux
// composants ferment la question ; ces tests fixent ce qu'ils promettent.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_card.dart';
import 'package:epilist/widgets/common/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _hote(Widget enfant) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: enfant));

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  group('AppCard', () {
    testWidgets('porte la surface, le rayon et la bordure du theme', (
      tester,
    ) async {
      await tester.pumpWidget(_hote(const AppCard(child: Text('contenu'))));

      final materiau = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(materiau.color, AppColors.surface);
      final forme = materiau.shape as RoundedRectangleBorder;
      expect(forme.borderRadius, BorderRadius.circular(AppRadius.md));
      expect(forme.side.color, AppColors.border);
      // Pas d'ombre portee : c'est le choix du theme.
      expect(materiau.elevation, 0);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('decoupe son contenu, sinon l onde d appui deborde', (
      tester,
    ) async {
      await tester.pumpWidget(_hote(const AppCard(child: Text('x'))));
      final materiau = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(materiau.clipBehavior, Clip.antiAlias);
    });

    testWidgets('devient cliquable quand on lui donne onTap', (tester) async {
      var appuis = 0;
      await tester.pumpWidget(
        _hote(AppCard(onTap: () => appuis++, child: const Text('appuyer'))),
      );
      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('appuyer'));
      expect(appuis, 1);
    });

    testWidgets('sans onTap, aucune zone cliquable', (tester) async {
      await tester.pumpWidget(_hote(const AppCard(child: Text('x'))));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('tight n ajoute aucune marge interieure', (tester) async {
      await tester.pumpWidget(_hote(const AppCard.tight(child: Text('x'))));
      final rembourrage = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(rembourrage.padding, EdgeInsets.zero);
    });

    testWidgets('borderColor remplace la bordure neutre', (tester) async {
      await tester.pumpWidget(
        _hote(
          AppCard(borderColor: AppColors.successBorder, child: const Text('x')),
        ),
      );
      final materiau = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        (materiau.shape as RoundedRectangleBorder).side.color,
        AppColors.successBorder,
      );
    });

    testWidgets('suit le mode sombre sans rien savoir de lui', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder:
              (context, child) =>
                  AppPaletteBinding(child: child ?? const SizedBox.shrink()),
          home: const Scaffold(body: AppCard(child: Text('x'))),
        ),
      );
      await tester.pumpAndSettle();
      final materiau = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(materiau.color, AppPalette.dark.surface);
    });
  });

  group('AppSectionHeader', () {
    testWidgets('affiche le titre seul par defaut', (tester) async {
      await tester.pumpWidget(_hote(const AppSectionHeader(title: 'Dépenses')));
      expect(find.text('Dépenses'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('accole le compte au titre', (tester) async {
      await tester.pumpWidget(
        _hote(const AppSectionHeader(title: 'Factures', count: '12')),
      );
      expect(find.text('Factures · 12'), findsOneWidget);
    });

    testWidgets('l action de droite demande un libelle ET un geste', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hote(const AppSectionHeader(title: 'A', trailingLabel: 'Voir tout')),
      );
      expect(
        find.byType(TextButton),
        findsNothing,
        reason: 'un libelle sans geste ne doit pas afficher de bouton',
      );

      var appuis = 0;
      await tester.pumpWidget(
        _hote(
          AppSectionHeader(
            title: 'A',
            trailingLabel: 'Voir tout',
            onTrailing: () => appuis++,
          ),
        ),
      );
      await tester.tap(find.text('Voir tout'));
      expect(appuis, 1);
    });

    testWidgets('un titre trop long est coupe, pas deborde', (tester) async {
      await tester.pumpWidget(
        _hote(
          const AppSectionHeader(
            title:
                'Un titre deliberement tres long qui ne tient pas sur une '
                'seule ligne de telephone',
            trailingLabel: 'Voir tout',
          ),
        ),
      );
      final texte = tester.widget<Text>(find.textContaining('Un titre'));
      expect(texte.maxLines, 1);
      expect(texte.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}
