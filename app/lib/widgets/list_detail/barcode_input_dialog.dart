// widgets/list_detail/barcode_input_dialog.dart - Alternative au scanner pour le simulateur
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
          Icon(Icons.edit, color: Colors.blue[600]),
          const SizedBox(width: 12),
          const Text('Saisir un code-barres'),
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
                'Scanner non disponible sur le simulateur',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saisissez un code-barres manuellement ou choisissez un exemple',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Champ de saisie
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Code-barres',
                  hintText: 'Ex: 3017620422003',
                  prefixIcon: Icon(Icons.qr_code, color: Colors.blue[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un code-barres';
                  }
                  if (value.length < 8) {
                    return 'Code-barres trop court (min 8 chiffres)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Exemples
              Text(
                'Exemples de codes-barres:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
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
                        backgroundColor: Colors.blue[50],
                        child: Icon(
                          Icons.shopping_basket,
                          color: Colors.blue[600],
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
                          color: Colors.grey[600],
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
            style: TextStyle(color: Colors.grey[600]),
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
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
