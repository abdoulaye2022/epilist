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
        // Utiliser la langue sauvegardée
        locale = Locale(savedLanguage);
        print('Langue sauvegardée trouvée: $savedLanguage');
      } else {
        // Détecter la langue du système
        final systemLocale = PlatformDispatcher.instance.locale;
        final systemLanguage = systemLocale.languageCode;

        // Vérifier si la langue du système est supportée
        if (['fr', 'en'].contains(systemLanguage)) {
          locale = Locale(systemLanguage);
          print('Langue du système détectée: $systemLanguage');
        } else {
          // Par défaut: français
          locale = const Locale('fr');
          print(
            'Langue du système non supportée ($systemLanguage), utilisation du français par défaut',
          );
        }

        // Sauvegarder cette langue comme préférence
        await sharedPreferences.setString(_languageKey, locale.languageCode);
      }

      emit(LocalizationLoaded(locale));
    } catch (e) {
      print('Erreur lors du chargement de la langue: $e');
      // En cas d'erreur, utiliser le français par défaut
      emit(const LocalizationLoaded(Locale('fr')));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      // Sauvegarder la nouvelle langue
      await sharedPreferences.setString(_languageKey, event.languageCode);

      // Émettre le nouvel état
      emit(LocalizationLoaded(Locale(event.languageCode)));

      print('Langue changée pour: ${event.languageCode}');
    } catch (e) {
      print('Erreur lors du changement de langue: $e');
      // En cas d'erreur, garder la langue actuelle
      if (state is LocalizationLoaded) {
        emit(state as LocalizationLoaded);
      }
    }
  }
}
