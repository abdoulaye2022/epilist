// widgets/list_detail/voice_input_dialog.dart - Dicter sa liste, et la
// VÉRIFIER avant de l'ajouter.
//
// Le dialogue n'acceptait qu'un article par dictée, et il le présentait
// dans deux champs : un nom et une quantité. L'unité restait collée au
// nom (« Kilogrammes de tomates »), la quantité dite aussi (« Viande
// croissant 2 kg », quantité 1,0), et une phrase de plusieurs produits
// n'en faisait qu'un.
//
// Ici : une ligne par article — nom, quantité, unité, tous modifiables,
// avec le retrait — et un seul bouton « Ajouter les 3 articles ». Le
// micro peut rester ouvert d'un article à l'autre.
import 'package:epilist/services/voice_list_parser.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/list_detail/voice_input_button.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class VoiceInputDialog extends StatefulWidget {
  /// Appelé une fois, avec TOUS les articles vérifiés.
  final void Function(List<DictatedItem> items) onItemsConfirmed;

  const VoiceInputDialog({super.key, required this.onItemsConfirmed});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  /// Les articles entendus, dans l'ordre où ils ont été dits.
  final List<DictatedItem> _articles = [];

  /// La dernière phrase, telle qu'elle a été comprise. Affichée parce
  /// qu'un découpage inattendu s'explique presque toujours par ce que
  /// le micro a entendu.
  String? _phrase;

  bool _continu = false;

  void _entendu(String phrase) {
    final nouveaux = parseDictation(phrase);
    setState(() {
      _phrase = phrase;
      _articles.addAll(nouveaux);
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

  void _confirmer() {
    final retenus = _articles.where((a) => a.name.trim().isNotEmpty).toList();
    if (retenus.isEmpty) return;
    widget.onItemsConfirmed(retenus);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 520,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: theme.primaryColor, size: 26),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    l10n.voiceTapToSpeak,
                    style: AppFonts.displayStyle(
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            VoiceInputButton(
              onPhrase: _entendu,
              onPermissionDenied: _handlePermissionDenied,
              continu: _continu,
            ),
            const SizedBox(height: AppSpacing.sm),
            // « Le micro reste ouvert après chaque article » : son état
            // est écrit, comme partout ailleurs.
            AppSwitchTile(
              title: l10n.voiceContinuous,
              stateLabel:
                  _continu ? l10n.voiceContinuousOn : l10n.voiceContinuousOff,
              value: _continu,
              onChanged: (v) => setState(() => _continu = v),
            ),
            if (_phrase != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.voiceHeard(_phrase!),
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const Divider(height: AppSpacing.lg + 8),
            Flexible(
              child:
                  _articles.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          l10n.voiceNothingYet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _articles.length,
                        itemBuilder:
                            (context, i) => _ligne(l10n, i, _articles[i]),
                      ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _articles.isEmpty ? null : _confirmer,
              child: Text(l10n.voiceAddAll(_articles.length)),
            ),
          ],
        ),
      ),
    );
  }

  /// Une ligne de vérification : le nom, la quantité, l'unité, et le
  /// retrait. Tout est modifiable — c'est une dictée, elle se trompe.
  Widget _ligne(AppLocalizations l10n, int index, DictatedItem article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: article.name,
                  decoration: InputDecoration(
                    labelText: l10n.voiceItemName,
                    isDense: true,
                  ),
                  onChanged: (v) => article.name = v,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: _nombre(article.quantity),
                  decoration: InputDecoration(
                    labelText: l10n.voiceQuantity,
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    final valeur = double.tryParse(v.replaceAll(',', '.'));
                    if (valeur != null && valeur > 0) {
                      setState(() {
                        article.quantity = valeur;
                        article.quantityStated = true;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: article.unit ?? '',
                  decoration: InputDecoration(
                    labelText: l10n.voiceUnit,
                    isDense: true,
                  ),
                  onChanged:
                      (v) => article.unit = v.trim().isEmpty ? null : v.trim(),
                ),
              ),
              IconButton(
                tooltip: l10n.voiceRemoveItem,
                onPressed: () => setState(() => _articles.removeAt(index)),
                icon: Icon(Icons.close_rounded, color: AppColors.errorInk),
              ),
            ],
          ),
          // « Quantité absente : mettre 1 par défaut, mais l'indiquer
          // visiblement pour que l'utilisatrice la corrige. »
          if (!article.quantityStated)
            Text(
              l10n.voiceQuantityDefault,
              style: TextStyle(fontSize: 16, color: AppColors.warningInk),
            ),
        ],
      ),
    );
  }

  String _nombre(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
}

/// Fonction helper pour afficher le dialogue
Future<void> showVoiceInputDialog(
  BuildContext context, {
  required void Function(List<DictatedItem> items) onItemsConfirmed,
}) {
  return showDialog(
    context: context,
    builder: (context) => VoiceInputDialog(onItemsConfirmed: onItemsConfirmed),
  );
}
