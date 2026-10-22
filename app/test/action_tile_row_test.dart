// L'accueil est sorti BLANC sur l'appareil : ni degrade, ni salutation,
// ni chariot — rien que la barre du bas, remontee au milieu de l'ecran.
//
// La cause tenait en un mot. Les quatre tuiles vivent dans un
// defilement vertical, ou la hauteur disponible est infinie, et la
// rangee demandait `CrossAxisAlignment.stretch` : etire-toi sur toute
// la hauteur. Flutter leve « BoxConstraints forces an infinite height »,
// la rangee n'est pas mesuree, et l'echec remonte de parent en parent
// jusqu'a la page entiere — « RenderBox was not laid out », quatorze
// fois.
//
// Rien ne l'avait vu : les tests posaient les tuiles une par une, dans
// un cadre borne. Celui-ci les pose comme l'accueil les pose.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/home/action_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActionTile tuile(String libelle, Color teinte) => ActionTile(
    icon: Icons.mic_none_rounded,
    label: libelle,
    tint: teinte,
    onTap: () {},
  );

  Future<void> poser(WidgetTester tester, Widget enfant) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      // Le defilement est la moitie qui compte : c'est lui qui rend la
      // hauteur infinie.
      home: Scaffold(body: SingleChildScrollView(child: enfant)),
    ),
  );

  testWidgets('une rangee de tuiles tient dans un defilement vertical', (
    tester,
  ) async {
    await poser(
      tester,
      ActionTileRow(
        left: tuile('Dicter ma liste', AppColors.primaryVivid),
        right: tuile('Scanner', AppColors.accent),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Dicter ma liste'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
  });

  testWidgets('les deux tuiles gardent la meme hauteur', (tester) async {
    // Un libelle sur deux lignes face a un libelle sur une seule : sans
    // l'etirement, la rangee serait bancale.
    await poser(
      tester,
      ActionTileRow(
        left: tuile(
          'Dicter ma liste de courses a voix haute',
          AppColors.primaryVivid,
        ),
        right: tuile('Repas', AppColors.gold),
      ),
    );
    final hauteurs =
        tester
            .widgetList<ActionTile>(find.byType(ActionTile))
            .map((t) => tester.getSize(find.byWidget(t)).height)
            .toList();
    expect(hauteurs, hasLength(2));
    expect(hauteurs.first, hauteurs.last);
    expect(hauteurs.first, greaterThanOrEqualTo(104));
  });

  testWidgets('les quatre tuiles de l accueil, empilees comme la planche', (
    tester,
  ) async {
    await poser(
      tester,
      Column(
        children: [
          ActionTileRow(
            left: tuile('Dicter ma liste', AppColors.primaryVivid),
            right: tuile('Scanner un recu', AppColors.accent),
          ),
          const SizedBox(height: 10),
          ActionTileRow(
            left: tuile('Mes repas', AppColors.gold),
            right: tuile('Mes magasins', AppColors.warning),
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ActionTile), findsNWidgets(4));
  });
}
