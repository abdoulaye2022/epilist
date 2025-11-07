// services/voice_recognition_service.dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Vérifier et demander la permission du microphone
      final micPermission = await Permission.microphone.request();

      if (!micPermission.isGranted) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }

      // Initialiser le service de reconnaissance vocale
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
        debugPrint('❌ Failed to initialize voice recognition');
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
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Demander la permission du microphone
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Parser le texte vocal pour extraire les informations d'un item
  /// Exemples:
  /// - "3 pommes" → quantity: 3, name: "pommes"
  /// - "5 kilogrammes de tomates" → quantity: 5, name: "kilogrammes de tomates"
  /// - "pain" → quantity: 1, name: "pain"
  Map<String, dynamic> parseVoiceInput(String voiceText) {
    final text = voiceText.trim().toLowerCase();

    // Regex pour détecter les quantités au début
    // Exemples: "3 pommes", "5 kg de tomates", "2,5 litres de lait"
    final quantityRegex = RegExp(r'^(\d+(?:[.,]\d+)?)\s+(.+)$');
    final match = quantityRegex.firstMatch(text);

    if (match != null) {
      // Quantité trouvée
      final quantityStr = match.group(1)!.replaceAll(',', '.');
      final itemName = match.group(2)!;

      // Convertir en double pour supporter les décimales
      final quantity = double.tryParse(quantityStr) ?? 1.0;

      return {
        'name': _capitalizeFirstLetter(itemName),
        'quantity': quantity,
        'hasQuantity': true,
      };
    } else {
      // Pas de quantité détectée, utiliser 1 par défaut
      return {
        'name': _capitalizeFirstLetter(text),
        'quantity': 1.0,
        'hasQuantity': false,
      };
    }
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
