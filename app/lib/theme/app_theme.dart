// theme/app_theme.dart
//
// DESIGN SYSTEM EPILIST — source unique du look de l'application.
//
// Règle d'or : AUCUN écran ne définit ses propres couleurs, rayons ou
// styles de texte. Tout vient d'ici, via Theme.of(context) ou les
// jetons AppColors / AppRadius / AppSpacing ci-dessous. Le script
// `scripts/check_raw_colors.sh` fait respecter la règle.
//
// DIRECTION : la planche « Version B », accessibilité maximale.
// Sept couleurs, et aucune autre comme couleur d'interface — blanc,
// vert vif #22C55E, vert foncé #15803D, rouge #DC2626, jaune poussin
// #FACC15, orange #F97316, bleu #2563EB. Fonds blancs dominants, la
// couleur vit dans les cartes, les jauges et les icônes. Coins très
// arrondis, boutons en gélule de 60 dp de haut sur toute la largeur,
// textes agrandis : le corps du texte part de 17, plus de 14.
//
// DEUX MODES. Ce fichier contient deux palettes complètes ([AppPalette.light]
// et [AppPalette.dark]) et construit un ThemeData depuis chacune. Les
// jetons de AppColors ne sont donc PAS des constantes : ce sont des
// lectures de la palette active, que la racine de l'application pose à
// chaque changement de mode. C'est ce qui permet au mode sombre
// d'atteindre les ~1 900 appels de jetons déjà écrits sans les réécrire.

import 'package:flutter/material.dart';

/// Les jetons qui CHANGENT entre clair et sombre.
///
/// N'y figure que ce qui doit être redéfini : les fonds, les textes, les
/// teintes pleines. Tout ce qui vaut dans les deux modes — un blanc posé
/// sur un bouton vert, un fond teinté translucide, un voile noir — reste
/// une constante de [AppColors].
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryVivid,
    required this.onPrimary,
    required this.brandBand,
    required this.onBrandBand,
    required this.accent,
    required this.accentLight,
    required this.warning,
    required this.warningInk,
    required this.error,
    required this.errorInk,
    required this.successInk,
    required this.infoInk,
    required this.violet,
    required this.indigo,
    required this.teal,
    required this.gold,
    required this.goldInk,
    required this.brown,
    required this.slate,
  });

  final Brightness brightness;

  /// Fond d'écran, derrière les cartes.
  final Color background;

  /// Carte, barre, dialogue, feuille.
  final Color surface;

  /// Remplissage discret posé sur une surface (champ inerte, ligne alternée).
  final Color surfaceAlt;

  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color primary;
  final Color primaryDark;

  /// Fond teinté de marque, opaque — distinct de `primary.withValues()`.
  final Color primaryLight;

  /// Le vert VIF de la planche : jauges, illustrations, le bouton
  /// « Créer une liste ». Il est trop clair pour porter du blanc — ce
  /// qui se pose dessus est [AppColors.onVivid], jamais [onPrimary].
  final Color primaryVivid;

  /// Ce qui se pose SUR [primary] : blanc en mode clair, vert très
  /// sombre en mode sombre. Material le fait depuis toujours — une
  /// couleur forte s'éclaircit sur fond sombre, et du blanc dessus
  /// tomberait à 2,2 de contraste.
  final Color onPrimary;

  /// Bandeau de marque plein (l'en-tête du tableau de bord). Ni une
  /// surface, ni la couleur d'un bouton : une zone colorée qui porte du
  /// contenu, et qui en mode sombre doit cesser d'être lumineuse.
  final Color brandBand;
  final Color onBrandBand;

  final Color accent;
  final Color accentLight;

  final Color warning;
  final Color error;

  /// Les `*Ink` sont les couleurs de TEXTE posées sur le fond teinté de
  /// la même famille. En clair elles sont sombres, en sombre elles sont
  /// claires : c'est exactement ce qu'un `Colors.orange[800]` figé ne
  /// savait pas faire.
  final Color warningInk;
  final Color errorInk;
  final Color successInk;
  final Color infoInk;
  final Color goldInk;

  final Color violet;
  final Color indigo;
  final Color teal;
  final Color gold;
  final Color brown;
  final Color slate;

  bool get isDark => brightness == Brightness.dark;

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFDF9), // blanc chaud
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0FDF4),
    border: Color(0xFFDCE8CE),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textDisabled: Color(0xFF6B7280),
    primary: Color(0xFF15803D), // vert fonce : porte du blanc (5,02)
    primaryDark: Color(0xFF166534), // vert tres fonce (7,13, AAA)
    primaryLight: Color(0xFFDCFCE7),
    primaryVivid: Color(0xFF22C55E), // vert vif : ne porte QUE du sombre
    onPrimary: Color(0xFFFFFFFF),
    brandBand: Color(0xFF166534),
    onBrandBand: Color(0xFFFFFFFF),
    accent: Color(0xFF2563EB),
    accentLight: Color(0xFFDBEAFE),
    warning: Color(0xFFF97316),
    warningInk: Color(0xFFC2410C),
    error: Color(0xFFDC2626),
    errorInk: Color(0xFFB91C1C),
    successInk: Color(0xFF15803D),
    infoInk: Color(0xFF1D4ED8),
    violet: Color(0xFF1D4ED8),
    indigo: Color(0xFF16A34A),
    teal: Color(0xFF166534),
    gold: Color(0xFFFACC15),
    goldInk: Color(0xFF854D0E),
    brown: Color(0xFFC2410C),
    slate: Color(0xFF4B5563),
  );

  /// Mode sombre. Les fonds ne sont pas noirs mais tres sombres et
  /// legerement verdis, pour que la marque ne detonne pas ; les teintes
  /// pleines sont remontees d'environ deux tons, sinon elles passent
  /// sous le seuil de contraste sur fond sombre.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF10160F),
    surface: Color(0xFF1C2521),
    surfaceAlt: Color(0xFF26302A),
    border: Color(0xFF475569),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textDisabled: Color(0xFF8A9690),
    primary: Color(0xFF4ADE80),
    primaryDark: Color(0xFF86EFAC),
    primaryLight: Color(0xFF16281C),
    primaryVivid: Color(0xFF86EFAC),
    onPrimary: Color(0xFF06240F),
    brandBand: Color(0xFF16281C),
    onBrandBand: Color(0xFFF8FAFC),
    accent: Color(0xFF93C5FD),
    accentLight: Color(0xFF17263A),
    warning: Color(0xFFFB923C),
    warningInk: Color(0xFFFDBA74),
    error: Color(0xFFF87171),
    errorInk: Color(0xFFFCA5A5),
    successInk: Color(0xFF86EFAC),
    infoInk: Color(0xFFBFDBFE),
    violet: Color(0xFFBFDBFE),
    indigo: Color(0xFF86EFAC),
    teal: Color(0xFF4ADE80),
    gold: Color(0xFFFDE047),
    goldInk: Color(0xFFFDE68A),
    brown: Color(0xFFFDBA74),
    slate: Color(0xFFCBD5E1),
  );
}

/// Les jetons de couleur de l'application.
///
/// Les membres sans `const` sont des lectures de [palette] : ils suivent
/// le mode clair / sombre tout seuls. Les membres `const` sont ceux dont
/// la valeur ne dépend pas du mode.
abstract final class AppColors {
  /// Palette active. Posée par la racine de l'application à chaque
  /// changement de mode (voir `AppThemeScope`), jamais ailleurs.
  static AppPalette palette = AppPalette.light;

  static bool get isDark => palette.isDark;

  // ── Marque ────────────────────────────────────────────────────────
  static Color get primary => palette.primary;
  static Color get primaryDark => palette.primaryDark;
  static Color get primaryLight => palette.primaryLight;
  static Color get primaryVivid => palette.primaryVivid;
  static Color get accent => palette.accent;
  static Color get accentLight => palette.accentLight;

  // ── Neutres ───────────────────────────────────────────────────────
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceAlt => palette.surfaceAlt;
  static Color get border => palette.border;
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textDisabled => palette.textDisabled;

  /// Ce qui se pose SUR une couleur forte : le texte et les icônes d'un
  /// bouton vert, d'une pastille colorée, d'un état. Distinct de
  /// [surface] — un fond de carte devient sombre en mode sombre, le
  /// contenu d'un bouton suit la couleur du bouton. C'est cette
  /// confusion qui expliquait l'essentiel des 343 `Colors.white` écrits
  /// à la main dans lib/.
  static Color get onPrimary => palette.onPrimary;

  /// Ce qui se pose sur un fond ORANGÉ plein — `warning` ou `gold`. Du
  /// blanc dessus ne donne que 2,2 de contraste : ces deux teintes sont
  /// trop claires pour le porter. Ce brun très sombre tient dans les
  /// deux modes (6,8 et 8,0), donc il n'a pas à changer avec la palette.
  static const Color onWarning = Color(0xFF3B2200);

  /// Ce qui se pose sur un VOILE : une photo, un aperçu de caméra, un
  /// [scrim]. Toujours blanc, dans les deux modes, parce que ce qui est
  /// derrière est sombre dans les deux modes.
  static const Color onOverlay = Color(0xFFFFFFFF);

  /// Ce qui se pose sur [primaryVivid]. Le vert vif a une luminance de
  /// 0,45 : du blanc dessus ne donne que 2,2, l'encre sombre donne 7,8.
  /// Elle vaut dans les deux modes, le vert vif restant clair.
  static const Color onVivid = Color(0xFF111827);

  /// Bandeau de marque plein et son contenu.
  static Color get brandBand => palette.brandBand;
  static Color get onBrandBand => palette.onBrandBand;

  // ── Sémantiques ───────────────────────────────────────────────────
  // Quatre familles, quatre rôles. Chacune donne quatre jetons :
  //   `x`        la teinte pleine — icône, trait, point d'état
  //   `xInk`     le texte posé SUR le fond teinté de la famille
  //   `xTint`    le fond teinté — volontairement TRANSLUCIDE, pour qu'il
  //              se compose sur la surface au lieu de l'ignorer : c'est
  //              ce qui lui permet de suivre le mode sombre sans code
  //   `xBorder`  la bordure de ce fond, translucide pour la même raison
  static Color get success => palette.primary;
  static Color get successInk => palette.successInk;
  static const Color successTint = Color(0x1422C55E);
  static const Color successBorder = Color(0x5922C55E);

  static Color get warning => palette.warning;
  static Color get warningInk => palette.warningInk;
  static const Color warningTint = Color(0x1AF97316);
  static const Color warningBorder = Color(0x59F97316);

  static Color get error => palette.error;
  static Color get errorInk => palette.errorInk;
  static const Color errorTint = Color(0x14DC2626);
  static const Color errorBorder = Color(0x59DC2626);

  static Color get info => palette.accent;
  static Color get infoInk => palette.infoInk;
  static const Color infoTint = Color(0x142563EB);
  static const Color infoBorder = Color(0x592563EB);

  // ── Accents catégoriels ───────────────────────────────────────────
  // Ni marque ni état : ils ne servent qu'à DISTINGUER (une catégorie
  // d'une autre, un rôle d'un autre, une part de graphique de sa
  // voisine). Jamais pour dire « attention » ou « c'est fait ».
  static Color get violet => palette.violet;
  static const Color violetTint = Color(0x1A1D4ED8);
  static Color get indigo => palette.indigo;
  static const Color indigoTint = Color(0x1A16A34A);
  static Color get teal => palette.teal;
  static const Color tealTint = Color(0x1A166534);
  static Color get brown => palette.brown;
  static const Color brownTint = Color(0x1AC2410C);
  static Color get slate => palette.slate;
  static const Color slateTint = Color(0x1A4B5563);

  /// L'or sert au distinctif : un favori, une étoile, un palmarès.
  /// Il a ses quatre jetons comme un état, parce qu'il porte souvent un
  /// fond teinté (une ligne de classement, un bandeau « top »).
  static Color get gold => palette.gold;
  static Color get goldInk => palette.goldInk;
  static const Color goldTint = Color(0x1AFACC15);
  static const Color goldBorder = Color(0x59FACC15);

  /// Ordre des séries d'un graphique ou des pastilles de catégorie.
  /// Toujours parcourir cette liste modulo sa longueur, pour que deux
  /// écrans donnent la même couleur à la même position.
  static List<Color> get chart => <Color>[
    primary,
    accent,
    warning,
    violet,
    teal,
    gold,
    error,
    indigo,
    slate,
    brown,
  ];

  // ── Voiles ────────────────────────────────────────────────────────
  // Noirs translucides : ils assombrissent ce qui est derrière, donc ils
  // valent dans les deux modes sans être redéfinis.
  /// Fond opaque derrière une photo plein écran ou un aperçu de caméra.
  /// Noir dans les deux modes : ce qu'il entoure est une image, pas une
  /// surface de l'application. Y mettre `textPrimary` — ce que donnait
  /// la traduction naïve de `Colors.black` — rendait le fond BLANC en
  /// mode sombre, avec une croix blanche dessus.
  static const Color backdrop = Color(0xFF000000);

  static const Color scrim = Color(0x8A000000); // derrière un dialogue
  static const Color overlay = Color(0x4D000000); // sur une photo, une caméra
  static const Color shadow = Color(0x14000000); // ombre portée discrète
}

/// Pose la palette qui correspond au thème effectif, puis rend l'enfant.
///
/// Se branche dans `MaterialApp.builder`, donc juste sous le Theme et
/// au-dessus du Navigator : c'est le SEUL endroit où [AppColors.palette]
/// est écrite.
///
/// Et il ne suffit pas de l'écrire. Les jetons se lisent par un
/// accesseur statique, sans `BuildContext` : un écran qui n'appelle
/// jamais `Theme.of(context)` — c'est le cas de la plupart, ici — ne
/// dépend d'aucun héritage et ne se reconstruit donc PAS quand le mode
/// change. Il garderait les couleurs de l'ancien mode jusqu'à sa
/// prochaine reconstruction, qui peut ne jamais venir.
///
/// D'où le parcours de l'arbre ci-dessous, au changement de mode : on
/// marque chaque élément à reconstruire. Les objets `State` sont
/// conservés — ce n'est pas un remontage — donc la pile de navigation,
/// les champs en cours de saisie et les positions de défilement
/// survivent, ce qu'un `KeyedSubtree` à clé changeante aurait détruit.
/// Le coût est une reconstruction complète, au seul moment où
/// l'utilisateur bascule de mode.
class AppPaletteBinding extends StatelessWidget {
  const AppPaletteBinding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light;
    final bascule = palette.brightness != AppColors.palette.brightness;
    AppColors.palette = palette;
    if (bascule) {
      // Apres la frame : marquer un element pendant une construction
      // serait refuse par le framework.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final racine = WidgetsBinding.instance.rootElement;
        if (racine != null) _marquerTout(racine);
      });
    }
    return child;
  }

  static void _marquerTout(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_marquerTout);
  }
}

/// Variantes d'une couleur QUELCONQUE — une catégorie choisie par
/// l'utilisateur, une série de graphique, une couleur reçue en paramètre.
///
/// L'ancien code écrivait `couleur[50]` ou `couleur[700]`, qui n'existe
/// que sur les `MaterialColor` de Flutter : cela obligeait à typer les
/// paramètres en `MaterialColor` et interdisait tout jeton. Ces trois
/// fonctions rendent les mêmes rôles pour n'importe quelle couleur.
abstract final class AppTint {
  /// Fond teinté. Translucide, donc il se compose sur la surface et
  /// suit le mode sombre sans rien savoir de lui.
  static Color fill(Color c) => c.withValues(alpha: 0.10);

  /// Bordure de ce fond teinté.
  static Color line(Color c) => c.withValues(alpha: 0.35);

  /// Texte lisible SUR ce fond teinté : la teinte poussée vers le noir
  /// en mode clair, vers le blanc en mode sombre.
  static Color ink(Color c) =>
      Color.lerp(
        c,
        AppColors.isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        0.4,
      )!;
}

/// Rayons de courbure — trois valeurs, pas plus.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18; // cartes, champs
  static const double lg = 26; // dialogues, bottom sheets, cartes fortes

  /// Gélule. Les boutons de la planche sont tous ronds aux deux bouts :
  /// c'est la forme qui dit « on appuie ici » sans dépendre d'une
  /// couleur, et elle ne laisse aucun doute sur la zone touchable.
  static const double pill = 999;
}

/// Hauteurs minimales touchables.
///
/// La planche impose 60 dp pour un bouton pleine largeur — bien au-delà
/// des 48 dp de Material, parce que la cible visée est une main qui
/// tremble, pas un pouce exercé.
abstract final class AppSizes {
  static const double button = 60;
  static const double buttonSmall = 56;
  static const double field = 56;
  static const double row = 64; // une ligne d'article cochable
}

/// Échelle d'espacement (multiples de 4).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Les dégradés de la planche.
///
/// Un seul, pour l'instant : le fond du tableau de bord, qui descend du
/// vert frais au jaune chaud — « supermarché lumineux et joyeux ». Il
/// vit ici et non dans l'écran, parce qu'il doit basculer en mode
/// sombre : les mêmes sept arrêts lumineux sur fond sombre
/// éblouiraient, et le texte sombre posé dessus disparaîtrait.
abstract final class AppGradients {
  /// Fond du tableau de bord. [AppColors.textPrimary] reste lisible
  /// dessus dans les deux modes : 9,0 au minimum en clair sur le vert
  /// vif, 11,0 sur le jaune, et au-delà de 12 en sombre.
  static LinearGradient get home => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppColors.isDark ? _sombre : _clair,
    stops: const [0, 0.16, 0.32, 0.50, 0.68, 0.86, 1],
  );

  static const List<Color> _clair = [
    Color(0xFF4ADE80),
    Color(0xFF7CEB8F),
    Color(0xFFC9F27E),
    Color(0xFFFEF9C3),
    Color(0xFFFDE68A),
    Color(0xFFFDE047),
    Color(0xFFFACC15),
  ];

  /// Le même mouvement — vert en haut, chaud en bas — mais tenu dans
  /// les luminances du mode sombre.
  static const List<Color> _sombre = [
    Color(0xFF13251A),
    Color(0xFF14241A),
    Color(0xFF17251A),
    Color(0xFF1C2518),
    Color(0xFF212516),
    Color(0xFF262414),
    Color(0xFF2A2412),
  ];
}

/// Les deux familles de la planche.
///
/// [body] porte tout le texte courant : Atkinson Hyperlegible, dessinée
/// pour la basse vision, distingue I l 1 et O 0 là où les fontes
/// d'interface les confondent.
///
/// [display] ne sert qu'aux titres. Sora est livrée en fonte VARIABLE :
/// `fontWeight` n'y change rien — le poids se demande sur l'axe `wght`
/// par `fontVariations`, sinon le titre sort en 400 maigre. D'où
/// [displayStyle], à utiliser plutôt que d'écrire la famille à la main.
abstract final class AppFonts {
  static const String body = 'Atkinson Hyperlegible';
  static const String display = 'Sora';

  /// Un style de titre : la famille d'affichage, et son poids posé sur
  /// l'axe variable.
  static TextStyle displayStyle({
    required double size,
    required Color color,
    double weight = 800,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: display,
    fontVariations: [FontVariation('wght', weight)],
    fontWeight: weight >= 700 ? FontWeight.w800 : FontWeight.w600,
    fontSize: size,
    color: color,
    height: height,
  );
}

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  /// Construit le thème depuis une palette donnée — et seulement depuis
  /// elle. Ne JAMAIS lire `AppColors` ici : ce serait lire la palette
  /// active au lieu de celle qu'on construit.
  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryLight,
      onPrimaryContainer: p.primaryDark,
      secondary: p.accent,
      onSecondary: p.isDark ? const Color(0xFF042038) : p.onPrimary,
      secondaryContainer: p.accentLight,
      onSecondaryContainer: p.infoInk,
      error: p.error,
      onError: const Color(0xFFFFFFFF),
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
      surfaceContainerHighest: p.surfaceAlt,
      inverseSurface: p.isDark ? p.textPrimary : const Color(0xFF2E322F),
      onInverseSurface: p.isDark ? p.background : const Color(0xFFFFFFFF),
      inversePrimary: p.primaryDark,
      shadow: AppColors.shadow,
      scrim: AppColors.scrim,
      surfaceTint: const Color(0x00000000), // pas de teinte M3 sur les surfaces
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
    );

    // Typographie agrandie. Chaque taille monte de 2 à 4 points : le
    // corps du texte passe de 14 à 17, et les titres d'écran à 26.
    final textTheme = base.textTheme
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
        .copyWith(
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
            height: 1.35,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: p.textPrimary,
            height: 1.45,
          ),
          bodyMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: p.textPrimary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: p.textSecondary,
            height: 1.4,
          ),
          labelLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        )
        // La famille du corps de texte s'applique APRES les styles
        // explicites : un TextStyle ecrit a la main n'herite pas du
        // `fontFamily` du ThemeData, et le texte serait reparti sur la
        // fonte systeme sans qu'on le voie en analyse.
        .apply(fontFamily: AppFonts.body)
        // Les deux seuls styles d'AFFICHAGE, en Sora, posés en dernier
        // pour que l'application de la famille ne les efface pas.
        .copyWith(
          headlineSmall: AppFonts.displayStyle(
            size: 26,
            color: p.textPrimary,
            height: 1.25,
          ),
          titleLarge: AppFonts.displayStyle(
            size: 21,
            color: p.textPrimary,
            height: 1.3,
          ),
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    final onBrand = p.onPrimary;

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppFonts.displayStyle(size: 20, color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary, size: 26),
      ),

      // Cartes : plates, bordure fine — pas d'ombre portée.
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: p.border, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onBrand,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          minimumSize: const Size(64, AppSizes.button),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onBrand,
          minimumSize: const Size(64, AppSizes.button),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 3),
          minimumSize: const Size(64, AppSizes.button),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        constraints: const BoxConstraints(minHeight: AppSizes.field),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder(p.border, 2),
        enabledBorder: inputBorder(p.border, 2),
        focusedBorder: inputBorder(p.primary, 3),
        errorBorder: inputBorder(p.error, 2),
        focusedErrorBorder: inputBorder(p.error, 3),
        hintStyle: TextStyle(color: p.textSecondary, fontSize: 17),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 17),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primaryLight,
        disabledColor: p.background,
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: p.primaryDark,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        showDragHandle: true,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: onBrand,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceAlt : const Color(0xFF2E322F),
        contentTextStyle: TextStyle(
          color: p.isDark ? p.textPrimary : const Color(0xFFFFFFFF),
          fontSize: 17,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: p.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? p.primary
                  : const Color(0x00000000),
        ),
        side: BorderSide(color: p.textSecondary, width: 2.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFFFFFFFF)
                  : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.border,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),

      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
        dividerColor: p.border,
      ),
    );
  }
}
