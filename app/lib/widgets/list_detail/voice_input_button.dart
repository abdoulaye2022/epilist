// widgets/list_detail/voice_input_button.dart
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:epilist/services/voice_recognition_service.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/l10n/app_localizations.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String itemName, double quantity) onItemRecognized;
  final VoidCallback? onPermissionDenied;

  const VoiceInputButton({
    super.key,
    required this.onItemRecognized,
    this.onPermissionDenied,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isListening = false;
  String _currentText = '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de connectivité
    _isOnline = _connectivityService.isConnected;
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
          // Arrêter l'écoute si on perd la connexion
          if (!isConnected && _isListening) {
            _voiceService.stopListening();
            _isListening = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    // Vérifier si on est en ligne
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.voiceRequiresInternet,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      // Arrêter l'écoute
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      // Détecter la langue de l'application AVANT les await
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode;

      // Déterminer le localeId pour la reconnaissance vocale
      String voiceLocaleId;
      if (languageCode == 'en') {
        voiceLocaleId = 'en_US'; // Anglais
      } else {
        voiceLocaleId = 'fr_FR'; // Français par défaut
      }

      debugPrint('🌐 Using voice locale: $voiceLocaleId for app language: $languageCode');

      // Initialiser si nécessaire (cela demandera la permission automatiquement)
      if (!_voiceService.isInitialized) {
        final initialized = await _voiceService.initialize();
        if (!initialized) {
          // Permission refusée ou erreur d'initialisation
          widget.onPermissionDenied?.call();
          return;
        }
      }

      // Démarrer l'écoute
      final started = await _voiceService.startListening(
        onResult: (recognizedText) {
          setState(() {
            _currentText = recognizedText;
          });
        },
        onFinalResult: (recognizedText) {
          // Résultat final - traiter l'item
          debugPrint('🎯 Final result received: $recognizedText');
          _processVoiceInput(recognizedText);
        },
        localeId: voiceLocaleId,
      );

      if (started) {
        setState(() {
          _isListening = true;
          _currentText = '';
        });
      } else {
        // Échec du démarrage (probablement permission refusée)
        widget.onPermissionDenied?.call();
      }
    }
  }

  void _processVoiceInput(String voiceText) {
    if (voiceText.isEmpty) {
      return;
    }

    // Parser le texte vocal pour extraire nom et quantité
    final parsed = _voiceService.parseVoiceInput(voiceText);
    final itemName = parsed['name'] as String;
    final quantity = parsed['quantity'] as double;

    debugPrint('📦 Item recognized: $itemName (x$quantity)');

    // Callback avec les données extraites
    widget.onItemRecognized(itemName, quantity);

    // Reset
    setState(() {
      _currentText = '';
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton avec animation de glow
        AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          glowRadiusFactor: 0.7,
          child: Material(
            elevation: _isListening ? 8.0 : 4.0,
            shape: const CircleBorder(),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _isListening
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 30,
                  color:
                      _isListening ? Colors.white : Theme.of(context).primaryColor,
                ),
                onPressed: _toggleListening,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Texte d'indication
        AnimatedOpacity(
          opacity: _isListening ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isListening
                ? (_currentText.isEmpty
                    ? l10n.voiceListening
                    : _currentText)
                : l10n.voiceTapToSpeak,
            style: TextStyle(
              fontSize: 14,
              fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
              color: _isListening
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
