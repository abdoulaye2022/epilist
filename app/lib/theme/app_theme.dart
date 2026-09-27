// theme/app_theme.dart
//
// DESIGN SYSTEM EPILIST — source unique du look de l'application.
//
// Règle d'or : AUCUN écran ne définit ses propres couleurs, rayons ou
// styles de texte. Tout vient d'ici, via Theme.of(context) ou les
// constantes AppColors / AppRadius / AppSpacing ci-dessous.
//
// Marque conservée : vert EpiList #4CAF50, bleu accent #2196F3.
// Direction : professionnel et épuré — surfaces blanches, fond gris très
// clair, une seule couleur forte (le vert), bordures discrètes plutôt que
// des ombres, rayons doux et constants, typographie sobre.

import 'package:flutter/material.dart';

/// Palette de marque. Toujours passer par ces constantes, jamais par
/// Colors.green[xxx] directement dans un écran.
abstract final class AppColors {
  // Marque
  static const Color primary = Color(0xFF43A047); // vert EpiList (ton 600)
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFFE8F5E9); // fonds teintés
  static const Color accent = Color(0xFF2196F3); // bleu EpiList
  static const Color accentLight = Color(0xFFE3F2FD);

  // Neutres
  static const Color background = Color(0xFFF7F8F7); // fond des écrans
  static const Color surface = Colors.white; // cartes, barres, dialogues
  static const Color border = Color(0xFFE6E8E6); // bordures discrètes
  static const Color textPrimary = Color(0xFF1C1F1D);
  static const Color textSecondary = Color(0xFF6B716D);
  static const Color textDisabled = Color(0xFFA6ACA8);

  // Sémantiques
  static const Color success = primary;
  static const Color warning = Color(0xFFF29D38);
  static const Color error = Color(0xFFD64545);
  static const Color info = accent;
}

/// Rayons de courbure — trois valeurs, pas plus.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12; // cartes, champs, boutons
  static const double lg = 20; // dialogues, bottom sheets
}

/// Échelle d'espacement (multiples de 4).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentLight,
      onSecondaryContainer: Color(0xFF0D47A1),
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: Color(0xFFF0F2F0),
      inverseSurface: Color(0xFF2E322F),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFFA5D6A7),
      shadow: Colors.black26,
      scrim: Colors.black54,
      surfaceTint: Colors.transparent, // pas de teinte M3 sur les surfaces
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Typographie : sobre, hiérarchie par le poids plus que par la taille.
    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25),
          titleLarge: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
          titleMedium: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.35),
          titleSmall: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.45),
          bodyMedium: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.45),
          bodySmall: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4),
          labelLarge: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Cartes : plates, bordure fine — pas d'ombre portée.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 1.6),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.6),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.background,
        labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        showDragHandle: true,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E322F),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.textDisabled, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
      ),
    );
  }
}
