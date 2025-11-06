// blocs/localization/localization_bloc.dart
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class LocalizationEvent extends Equatable {
  const LocalizationEvent();

  @override
  List<Object> get props => [];
}

class LoadLanguage extends LocalizationEvent {}

class ChangeLanguage extends LocalizationEvent {
  final String languageCode;

  const ChangeLanguage(this.languageCode);

  @override
  List<Object> get props => [languageCode];
}

// States
abstract class LocalizationState extends Equatable {
  const LocalizationState();

  @override
  List<Object> get props => [];
}

class LocalizationInitial extends LocalizationState {}

class LocalizationLoaded extends LocalizationState {
  final Locale locale;

  const LocalizationLoaded(this.locale);

  @override
  List<Object> get props => [locale];
}

// Bloc
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  static const String _languageKey = 'selected_language';
  final SharedPreferences sharedPreferences;

  LocalizationBloc({required this.sharedPreferences})
    : super(LocalizationInitial()) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      // Essayer de récupérer la langue sauvegardée
      final savedLanguage = sharedPreferences.getString(_languageKey);

      Locale locale;

      if (savedLanguage != null) {
        // Utiliser la langue sauvegardée (préférence de l'utilisateur)
        locale = Locale(savedLanguage);
        print('🌍 [Localisation] Langue sauvegardée trouvée: $savedLanguage');
      } else {
        // 🔍 PREMIER LANCEMENT: Détecter automatiquement la langue du système
        final systemLocale = PlatformDispatcher.instance.locale;
        final systemLanguage = systemLocale.languageCode;

        print('🔍 [Localisation] Premier lancement - détection langue système');
        print('🌍 [Localisation] Langue système détectée: $systemLanguage');

        // Vérifier si la langue du système est supportée (fr ou en)
        if (['fr', 'en'].contains(systemLanguage)) {
          locale = Locale(systemLanguage);
          print('✅ [Localisation] Langue système supportée - utilisation de: $systemLanguage');
        } else {
          // Par défaut: français si langue non supportée
          locale = const Locale('fr');
          print(
            '⚠️  [Localisation] Langue système non supportée ($systemLanguage)',
          );
          print('✅ [Localisation] Utilisation du français par défaut');
        }

        // Sauvegarder cette langue comme préférence initiale
        await sharedPreferences.setString(_languageKey, locale.languageCode);
        print('💾 [Localisation] Langue sauvegardée: ${locale.languageCode}');
      }

      emit(LocalizationLoaded(locale));
      print('✅ [Localisation] Langue chargée avec succès: ${locale.languageCode}');
    } catch (e) {
      print('❌ [Localisation] Erreur lors du chargement de la langue: $e');
      // En cas d'erreur, utiliser le français par défaut
      emit(const LocalizationLoaded(Locale('fr')));
      print('✅ [Localisation] Utilisation du français par défaut (fallback)');
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      print('🔄 [Localisation] Changement de langue demandé: ${event.languageCode}');

      // Vérifier que la langue est supportée
      if (!['fr', 'en'].contains(event.languageCode)) {
        print('❌ [Localisation] Langue non supportée: ${event.languageCode}');
        return;
      }

      // Sauvegarder la nouvelle langue
      await sharedPreferences.setString(_languageKey, event.languageCode);
      print('💾 [Localisation] Langue sauvegardée: ${event.languageCode}');

      // Émettre le nouvel état
      emit(LocalizationLoaded(Locale(event.languageCode)));

      print('✅ [Localisation] Langue changée avec succès pour: ${event.languageCode}');
    } catch (e) {
      print('❌ [Localisation] Erreur lors du changement de langue: $e');
      // En cas d'erreur, garder la langue actuelle
      if (state is LocalizationLoaded) {
        emit(state as LocalizationLoaded);
      }
    }
  }
}
