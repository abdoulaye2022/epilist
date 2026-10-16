// La photo d'un article, visible sur sa ligne.
//
// Ce qui a motive le widget : la photo existait, mais rien a l'ecran ne
// l'annoncait — et l'entree « Photo » ajoutee au tour precedent l'avait
// ete dans `list_item_card.dart`, un widget que PLUS RIEN ne referencait
// (la ligne affichee vient de `_buildItemCard`, dans l'ecran). La
// fonction etait donc injoignable malgre la case cochee.
//
// D'ou ces tests : ils portent sur le widget que l'ecran utilise.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/product_photo_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ListItem _article({String? photo}) => ListItem(
  id: 7,
  listId: 3,
  productName: 'Lait',
  quantity: 1,
  isPurchased: false,
  imageUrl: photo,
  createdAt: DateTime(2026, 10, 16),
  updatedAt: DateTime(2026, 10, 16),
);

Future<void> _ouvrir(
  WidgetTester tester, {
  String? photo,
  required bool canEdit,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    home: Scaffold(
      body: ProductPhotoButton(item: _article(photo: photo), canEdit: canEdit),
    ),
  ),
);

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  testWidgets('sans photo, une liste modifiable invite a en ajouter',
      (tester) async {
    await _ouvrir(tester, canEdit: true);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(
      tester.getSize(find.byIcon(Icons.add_a_photo_outlined)).width,
      greaterThan(0),
      reason: 'l invitation doit occuper de la place a l ecran',
    );
  });

  testWidgets('sans photo et en lecture seule, rien du tout', (tester) async {
    // Inviter a faire ce qu'on n'a pas le droit de faire ne vaut rien.
    await _ouvrir(tester, canEdit: false);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('avec une photo, la vignette s affiche et reste cliquable',
      (tester) async {
    await _ouvrir(
      tester,
      photo: 'https://exemple.test/lait.jpg',
      canEdit: false,
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });

  testWidgets('le bouton s annonce aux lecteurs d ecran', (tester) async {
    final poignee = tester.ensureSemantics();
    await _ouvrir(tester, canEdit: true);
    expect(
      find.bySemanticsLabel('Ajouter une photo'),
      findsOneWidget,
      reason: 'une pastille sans nom est muette pour un lecteur d ecran',
    );
    poignee.dispose();
  });

  testWidgets('la vignette garde sa taille demandee', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: ProductPhotoButton(
              item: _article(),
              canEdit: true,
              size: 36,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(SizedBox).first),
      const Size(36, 36),
    );
  });
}
