// services/voice_recognition_service.dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service de reconnaissance vocale
  /// Le package speech_to_text gère automatiquement la demande de permission
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Initialiser le service de reconnaissance vocale
      // La permission sera demandée automatiquement par le package
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('🎤 Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        debugPrint('✅ Voice recognition initialized successfully');
      } else {
        debugPrint('❌ Failed to initialize voice recognition (permission may be denied)');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error initializing voice recognition: $e');
      return false;
    }
  }

  /// Démarrer l'écoute avec callback pour les résultats
  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onFinalResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return false;
    }

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          debugPrint('🎤 Recognized: $recognizedWords');

          if (recognizedWords.isNotEmpty) {
            onResult(recognizedWords);
          }

          // Si la reconnaissance est terminée (finalResult)
          if (result.finalResult) {
            _isListening = false;
            debugPrint('✅ Final result: $recognizedWords');

            // Appeler le callback pour le résultat final
            if (onFinalResult != null && recognizedWords.isNotEmpty) {
              onFinalResult(recognizedWords);
            }
          }
        },
        localeId: localeId ?? 'fr_FR', // Français par défaut
        pauseFor: const Duration(seconds: 3), // Pause de 3 secondes avant d'arrêter
        listenFor: const Duration(seconds: 30), // Timeout de 30 secondes
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true, // Afficher les résultats partiels
          cancelOnError: true,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error starting listening: $e');
      _isListening = false;
      return false;
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Stopped listening');
    }
  }

  /// Annuler l'écoute en cours
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      debugPrint('🚫 Cancelled listening');
    }
  }

  /// Obtenir les langues disponibles
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized) {
      return await _speech.locales();
    }

    return [];
  }

  /// Vérifier si le microphone est disponible
  /// Note: speech_to_text gère automatiquement les permissions
  Future<bool> checkMicrophonePermission() async {
    // Essayer d'initialiser pour vérifier si la permission est accordée
    if (!_isInitialized) {
      return await initialize();
    }
    return _isInitialized;
  }

  /// Demander la permission du microphone
  /// Note: speech_to_text demande automatiquement la permission lors de initialize()
  Future<bool> requestMicrophonePermission() async {
    return await initialize();
  }

  /// Parser le texte vocal pour extraire les informations d'un item
  /// Exemples:
  /// - "3 pommes" → quantity: 3, name: "pommes"
  /// - "trois pommes" → quantity: 3, name: "pommes"
  /// - "5 kilogrammes de tomates" → quantity: 5, name: "kilogrammes de tomates"
  /// - "pain" → quantity: 1, name: "pain"
  Map<String, dynamic> parseVoiceInput(String voiceText) {
    final text = voiceText.trim().toLowerCase();

    // Map des nombres en lettres (français + anglais)
    final numberWords = {
      // Français
      'un': 1.0, 'une': 1.0,
      'deux': 2.0,
      'trois': 3.0,
      'quatre': 4.0,
      'cinq': 5.0,
      'six': 6.0, // Identique en FR et EN
      'sept': 7.0,
      'huit': 8.0,
      'neuf': 9.0,
      'dix': 10.0,
      'onze': 11.0,
      'douze': 12.0,
      'treize': 13.0,
      'quatorze': 14.0,
      'quinze': 15.0,
      'seize': 16.0,
      'vingt': 20.0,
      'trente': 30.0,
      'quarante': 40.0,
      'cinquante': 50.0,
      // Anglais
      'one': 1.0, 'a': 1.0, 'an': 1.0,
      'two': 2.0,
      'three': 3.0,
      'four': 4.0,
      'five': 5.0,
      // 'six': 6.0, // Déjà défini en français
      'seven': 7.0,
      'eight': 8.0,
      'nine': 9.0,
      'ten': 10.0,
      'eleven': 11.0,
      'twelve': 12.0,
      'thirteen': 13.0,
      'fourteen': 14.0,
      'fifteen': 15.0,
      'sixteen': 16.0,
      'seventeen': 17.0,
      'eighteen': 18.0,
      'nineteen': 19.0,
      'twenty': 20.0,
      'thirty': 30.0,
      'forty': 40.0,
      'fifty': 50.0,
    };

    // Regex pour détecter les quantités numériques au début
    // Exemples: "3 pommes", "5 kg de tomates", "2,5 litres de lait"
    final numericRegex = RegExp(r'^(\d+(?:[.,]\d+)?)\s+(.+)$');
    final numericMatch = numericRegex.firstMatch(text);

    if (numericMatch != null) {
      // Quantité numérique trouvée
      final quantityStr = numericMatch.group(1)!.replaceAll(',', '.');
      final itemName = numericMatch.group(2)!;
      final quantity = double.tryParse(quantityStr) ?? 1.0;

      return {
        'name': _capitalizeFirstLetter(itemName),
        'quantity': quantity,
        'hasQuantity': true,
      };
    }

    // Regex pour détecter les quantités en lettres au début
    // Exemples: "trois pommes", "cinq tomates"
    final wordRegex = RegExp(r'^([a-zéèêà]+)\s+(.+)$');
    final wordMatch = wordRegex.firstMatch(text);

    if (wordMatch != null) {
      final firstWord = wordMatch.group(1)!;
      final restOfText = wordMatch.group(2)!;

      // Vérifier si le premier mot est un nombre
      if (numberWords.containsKey(firstWord)) {
        final quantity = numberWords[firstWord]!;

        return {
          'name': _capitalizeFirstLetter(restOfText),
          'quantity': quantity,
          'hasQuantity': true,
        };
      }
    }

    // Pas de quantité détectée, utiliser 1 par défaut
    return {
      'name': _capitalizeFirstLetter(text),
      'quantity': 1.0,
      'hasQuantity': false,
    };
  }

  /// Mettre en majuscule la première lettre
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Nettoyer le service
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isInitialized = false;
    _isListening = false;
  }
}
