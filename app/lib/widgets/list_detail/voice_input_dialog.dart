// widgets/list_detail/voice_input_dialog.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/list_detail/voice_input_button.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class VoiceInputDialog extends StatefulWidget {
  final Function(String itemName, double quantity) onItemConfirmed;

  const VoiceInputDialog({
    super.key,
    required this.onItemConfirmed,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  String? _recognizedItemName;
  double? _recognizedQuantity;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleVoiceResult(String itemName, double quantity) {
    setState(() {
      _recognizedItemName = itemName;
      _recognizedQuantity = quantity;
      _itemController.text = itemName;
      _quantityController.text = quantity.toString();
    });
  }

  void _handlePermissionDenied() {
    final l10n = AppLocalizations.of(context)!;
    SmartSnackBarManager.showMessage(
      context,
      l10n.voicePermissionRequired,
      type: SnackBarType.error,
    );
  }

  void _confirmItem() {
    final itemName = _itemController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (itemName.isEmpty) {
      return;
    }

    final quantity = double.tryParse(quantityText) ?? 1.0;

    widget.onItemConfirmed(itemName, quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.voiceTapToSpeak,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton vocal avec animation
            VoiceInputButton(
              onItemRecognized: _handleVoiceResult,
              onPermissionDenied: _handlePermissionDenied,
            ),

            const SizedBox(height: 24),

            // Divider
            const Divider(),

            const SizedBox(height: 16),

            // Champs de texte pour vérification/modification
            if (_recognizedItemName != null) ...[
              Text(
                "Vérifiez et modifiez si nécessaire:",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Champ nom de l'article
              TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: "Nom de l'article",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_cart),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 12),

              // Champ quantité
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: "Quantité",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _recognizedItemName = null;
                          _recognizedQuantity = null;
                          _itemController.clear();
                          _quantityController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Réessayer"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Ajouter"),
                    ),
                  ),
                ],
              ),
            ],

            // Instructions si aucun résultat
            if (_recognizedItemName == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Exemples de commandes:",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• "3 pommes"\n'
                      '• "5 kilogrammes de tomates"\n'
                      '• "Pain"\n'
                      '• "2 litres de lait"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fonction helper pour afficher le dialogue
Future<void> showVoiceInputDialog(
  BuildContext context, {
  required Function(String itemName, double quantity) onItemConfirmed,
}) {
  return showDialog(
    context: context,
    builder: (context) => VoiceInputDialog(
      onItemConfirmed: onItemConfirmed,
    ),
  );
}
