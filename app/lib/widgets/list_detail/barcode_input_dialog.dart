// widgets/list_detail/barcode_input_dialog.dart - Alternative au scanner pour le simulateur
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

/// Dialog pour saisir manuellement un code-barres
/// Utile pour tester sur simulateur ou si la camera ne fonctionne pas
class BarcodeInputDialog extends StatefulWidget {
  const BarcodeInputDialog({super.key});

  @override
  State<BarcodeInputDialog> createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<BarcodeInputDialog> {
  final TextEditingController _barcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Quelques codes-barres de test
  final List<Map<String, String>> _exampleBarcodes = [
    {'code': '3017620422003', 'name': 'Nutella 400g'},
    {'code': '5449000000996', 'name': 'Coca-Cola 330ml'},
    {'code': '3228857000166', 'name': 'Danone Activia'},
    {'code': '7613034626844', 'name': 'Toblerone 100g'},
    {'code': '3017620425035', 'name': 'Nutella 750g'},
  ];

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(AppLocalizations.of(context)!.enterBarcodeTitle),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.scannerUnavailableSimulator,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.enterBarcodeHint,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Champ de saisie
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Code-barres',
                  hintText: 'Ex: 3017620422003',
                  prefixIcon: Icon(Icons.qr_code, color: AppColors.accent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterBarcode;
                  }
                  if (value.length < 8) {
                    return AppLocalizations.of(context)!.barcodeTooShort;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Exemples
              Text(
                AppLocalizations.of(context)!.barcodeExamples,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _exampleBarcodes.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final example = _exampleBarcodes[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentLight,
                        child: Icon(
                          Icons.shopping_basket,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        example['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        example['code']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _barcodeController.text = example['code']!;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _barcodeController.text);
            }
          },
          icon: const Icon(Icons.check),
          label: const Text('Valider'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
