// widgets/category/color_picker.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color selectedColor;

  const ColorPickerDialog({super.key, required this.selectedColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  /// Les couleurs qu'une categorie peut porter.
  ///
  /// Il y en avait quarante-quatre, prises dans toute la palette
  /// Material : cyan, violet, magenta, gris anthracite. Or une couleur
  /// de categorie n'est pas une decoration — elle teinte des cartes,
  /// des icones et des pastilles sur toutes les pages. C'est donc une
  /// couleur d'INTERFACE, et la planche n'en admet que sept :
  ///
  ///   « Sept couleurs, et aucune autre comme couleur d'interface. »
  ///
  /// Celles-ci viennent du theme, suivent le mode sombre, et chacune a
  /// une encre verifiee pour porter du texte dessus.
  List<Color> get _predefinedColors => AppColors.chart;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    l10n.selectColor,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Aperçu de la couleur sélectionnée
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),
                ],
              ),
            ),

            // Grille de couleurs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _predefinedColors.length,
                  itemBuilder: (context, index) {
                    final color = _predefinedColors[index];
                    final isSelected =
                        _selectedColor.toARGB32() == color.toARGB32();

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child:
                            isSelected
                                ? Icon(
                                  Icons.check,
                                  color: AppColors.onPrimary,
                                  size: 20,
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedColor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: Text(l10n.select),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
