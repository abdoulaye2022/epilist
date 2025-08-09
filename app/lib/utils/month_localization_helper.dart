// utils/month_localization_helper.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MonthLocalizationHelper {
  /// Mapping des noms de mois français vers les mois en anglais
  static const Map<String, int> _frenchMonthsToNumber = {
    'janvier': 1,
    'jan': 1,
    'février': 2,
    'fév': 2,
    'fevrier': 2,
    'fev': 2,
    'mars': 3,
    'mar': 3,
    'avril': 4,
    'avr': 4,
    'mai': 5,
    'juin': 6,
    'jun': 6,
    'juillet': 7,
    'jul': 7,
    'juil': 7,
    'août': 8,
    'aou': 8,
    'aout': 8,
    'septembre': 9,
    'sep': 9,
    'sept': 9,
    'octobre': 10,
    'oct': 10,
    'novembre': 11,
    'nov': 11,
    'décembre': 12,
    'déc': 12,
    'dec': 12,
  };

  /// Convertit un nom de mois (possiblement en français) vers la locale actuelle
  static String localizeMonthName(BuildContext context, String monthName) {
    if (monthName.isEmpty) return monthName;

    try {
      final locale = Localizations.localeOf(context);

      // Extraire le nom du mois et l'année si présente
      final parts = monthName.split(' ');
      String monthPart = parts[0].toLowerCase().trim();
      String? yearPart = parts.length > 1 ? parts[1] : null;

      // Chercher le numéro du mois
      int? monthNumber = _frenchMonthsToNumber[monthPart];

      if (monthNumber != null) {
        // Créer une date avec ce mois
        final date = DateTime(
          yearPart != null
              ? int.tryParse(yearPart) ?? DateTime.now().year
              : DateTime.now().year,
          monthNumber,
        );

        // Formatter selon la locale
        final formatter = DateFormat.MMMM(locale.toString());
        String localizedMonth = formatter.format(date);

        // Capitaliser la première lettre
        localizedMonth =
            localizedMonth[0].toUpperCase() + localizedMonth.substring(1);

        // Retourner avec l'année si elle était présente
        return yearPart != null ? '$localizedMonth $yearPart' : localizedMonth;
      }

      // Si pas trouvé, essayer de parser directement comme date
      final dateFormats = ['MMMM yyyy', 'MMM yyyy', 'MMMM', 'MMM'];

      for (final format in dateFormats) {
        try {
          final date = DateFormat(format, 'fr').parse(monthName);
          final formatter = DateFormat.MMMM(locale.toString());
          String localizedMonth = formatter.format(date);
          localizedMonth =
              localizedMonth[0].toUpperCase() + localizedMonth.substring(1);

          if (yearPart != null) {
            return '$localizedMonth $yearPart';
          }
          return localizedMonth;
        } catch (e) {
          // Continue to next format
        }
      }
    } catch (e) {
      print('Erreur lors de la localisation du mois: $e');
    }

    // Fallback: retourner le nom original
    return monthName;
  }

  /// Convertit un nom de mois court (3 lettres)
  static String localizeShortMonthName(
    BuildContext context,
    String monthShort,
  ) {
    if (monthShort.isEmpty) return monthShort;

    try {
      final locale = Localizations.localeOf(context);

      // Mapping direct pour les abréviations françaises
      const shortFrenchMonths = {
        'jan': 1, 'fév': 2, 'mar': 3, 'avr': 4, 'mai': 5, 'jun': 6,
        'jul': 7, 'aoû': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'déc': 12,
        'fev': 2, 'aou': 8, 'dec': 12, // Variantes sans accents
      };

      final monthKey = monthShort.toLowerCase().trim();
      final monthNumber = shortFrenchMonths[monthKey];

      if (monthNumber != null) {
        final date = DateTime(DateTime.now().year, monthNumber);
        final formatter = DateFormat.MMM(locale.toString());
        return formatter.format(date);
      }
    } catch (e) {
      print('Erreur lors de la localisation du mois court: $e');
    }

    return monthShort;
  }

  /// Extrait et localise le nom du mois depuis une chaîne de format "Mois Année"
  static String extractAndLocalizeMonth(BuildContext context, String fullDate) {
    if (fullDate.isEmpty) return fullDate;

    // Essayer de parser différents formats
    final patterns = [
      RegExp(r'^([a-zàâäéèêëïîôùûüÿç]+)\s+(\d{4})$', caseSensitive: false),
      RegExp(r'^([a-zàâäéèêëïîôùûüÿç]+)$', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fullDate.trim());
      if (match != null) {
        final monthPart = match.group(1)!;
        final yearPart = match.group(2);

        final localizedMonth = localizeMonthName(context, monthPart);
        return yearPart != null ? '$localizedMonth $yearPart' : localizedMonth;
      }
    }

    return fullDate;
  }
}
