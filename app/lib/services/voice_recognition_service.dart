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
        debugPrint(
          '❌ Failed to initialize voice recognition (permission may be denied)',
        );
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
        pauseFor: const Duration(
          seconds: 3,
        ), // Pause de 3 secondes avant d'arrêter
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

  // Le decoupage d'une phrase dictee et l'extraction des quantites
  // vivaient ici. Ils vivent maintenant dans
  // services/voice_list_parser.dart : une fonction pure, sans micro,
  // qui se verifie avec les phrases de l'analyse. Celle d'ici gardait
  // l'unite dans le nom (« Kilogrammes de tomates ») et ne savait lire
  // qu'un seul article par phrase.

  /// Nettoyer le service
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isInitialized = false;
    _isListening = false;
  }
}
