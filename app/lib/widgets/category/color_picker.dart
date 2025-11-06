// widgets/category/color_picker.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color selectedColor;

  const ColorPickerDialog({
    Key? key,
    required this.selectedColor,
  }) : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  // Palette de couleurs prédéfinies
  final List<Color> _predefinedColors = [
    // Verts
    const Color(0xFF4CAF50),
    const Color(0xFF8BC34A),
    const Color(0xFFCDDC39),
    const Color(0xFF009688),

    // Bleus
    const Color(0xFF2196F3),
    const Color(0xFF03A9F4),
    const Color(0xFF00BCD4),
    const Color(0xFF3F51B5),

    // Rouges
    const Color(0xFFF44336),
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFFFF5722),

    // Oranges/Jaunes
    const Color(0xFFFF9800),
    const Color(0xFFFFC107),
    const Color(0xFFFFEB3B),
    const Color(0xFFFF6F00),

    // Marrons/Gris
    const Color(0xFF795548),
    const Color(0xFF9E9E9E),
    const Color(0xFF607D8B),
    const Color(0xFF424242),

    // Roses
    const Color(0xFFFF4081),
    const Color(0xFFE040FB),
    const Color(0xFFEA80FC),
    const Color(0xFFF8BBD0),

    // Violets
    const Color(0xFF673AB7),
    const Color(0xFF9C27B0),
    const Color(0xFF7B1FA2),
    const Color(0xFF4A148C),

    // Cyans/Turquoise
    const Color(0xFF00E5FF),
    const Color(0xFF18FFFF),
    const Color(0xFF84FFFF),
    const Color(0xFF006064),

    // Verts foncés
    const Color(0xFF1B5E20),
    const Color(0xFF2E7D32),
    const Color(0xFF388E3C),
    const Color(0xFF43A047),

    // Bleus foncés
    const Color(0xFF0D47A1),
    const Color(0xFF1565C0),
    const Color(0xFF1976D2),
    const Color(0xFF1E88E5),

    // Tons chauds
    const Color(0xFFBF360C),
    const Color(0xFFD84315),
    const Color(0xFFE64A19),
    const Color(0xFFF4511E),
  ];

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: theme.primaryColor,
                  ),
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
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
                    final isSelected = _selectedColor.toARGB32() == color.toARGB32();

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
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
                      foregroundColor: Colors.white,
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
