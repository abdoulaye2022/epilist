// widgets/dialogs/currency_selection_dialog.dart - EN-TÊTE SIMPLIFIÉ
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/blocs/currency/currency_state.dart';
import 'package:epilist/models/currency.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/l10n/app_localizations.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final Currency? currentCurrency;
  final Function(Currency)? onCurrencySelected;

  const CurrencySelectionDialog({
    super.key,
    this.currentCurrency,
    this.onCurrencySelected,
  });

  @override
  State<CurrencySelectionDialog> createState() =>
      _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  Currency? _selectedCurrency;
  List<Currency> _availableCurrencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _loadCurrencies();
  }

  void _loadCurrencies() {
    // Charger les devises depuis l'API
    context.read<CurrencyBloc>().add(const LoadCurrencies());

    // Charger aussi la devise utilisateur actuelle
    context.read<CurrencyBloc>().add(const LoadUserCurrency());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: BlocListener<CurrencyBloc, CurrencyState>(
                listener: (context, state) {
                  if (state is CurrenciesLoaded) {
                    setState(() {
                      _availableCurrencies = state.currencies;
                      _isLoading = false;

                      // Si devise utilisateur disponible, la sélectionner
                      if (state.userCurrency != null) {
                        _selectedCurrency = state.userCurrency!.currency;
                      }
                    });
                  } else if (state is UserCurrencyLoaded) {
                    setState(() {
                      _selectedCurrency = state.userCurrency.currency;
                    });
                  } else if (state is UserCurrencyUpdated) {
                    // Fermer le dialog et notifier le succès
                    Navigator.pop(context);
                    SmartSnackBarManager.showSuccessSnackBar(
                      context,
                      'Devise mise à jour vers ${state.userCurrency.currency.code}',
                      duration: const Duration(seconds: 2),
                    );

                    // Callback optionnel
                    if (widget.onCurrencySelected != null) {
                      widget.onCurrencySelected!(state.userCurrency.currency);
                    }
                  } else if (state is CurrencyError) {
                    SmartSnackBarManager.showErrorSnackBar(
                      context,
                      state.message,
                      duration: const Duration(seconds: 3),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ EN-TÊTE SIMPLIFIÉ (comme add_item_dialog)
                      _buildIcon(),
                      const SizedBox(height: 20),
                      _buildTitle(l10n),
                      const SizedBox(height: 12),
                      _buildDescription(l10n),
                      const SizedBox(height: 24),

                      // Contenu principal
                      _buildContent(l10n),
                      const SizedBox(height: 24),

                      // Boutons
                      _buildButtons(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Icône simple comme add_item_dialog
  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.currency_exchange, size: 40, color: Colors.green[600]),
    );
  }

  // ✅ NOUVEAU: Titre simple
  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      'Sélectionner une devise',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // ✅ NOUVEAU: Description simple
  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      'Choisissez votre devise d\'affichage préférée',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green[600], strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Chargement des devises...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_availableCurrencies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune devise disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les devises depuis le serveur',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Devise actuelle',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

        // Dropdown de sélection
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.green[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Currency>(
              value:
                  _selectedCurrency != null &&
                          _availableCurrencies.any(
                            (c) => c.id == _selectedCurrency!.id,
                          )
                      ? _selectedCurrency
                      : _availableCurrencies.first,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
                fontWeight: FontWeight.w600,
              ),
              items:
                  _availableCurrencies.map((Currency currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Row(
                        children: [
                          // Symbole de la devise
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Text(
                                currency.symbol,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nom et code de la devise
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                Text(
                                  currency.code.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Indicateur de devise populaire
                          if (currency.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Populaire',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (Currency? newCurrency) {
                if (newCurrency != null) {
                  setState(() {
                    _selectedCurrency = newCurrency;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Information
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cette devise sera utilisée pour l\'affichage uniquement. Les prix ne sont pas convertis.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<CurrencyBloc, CurrencyState>(
            builder: (context, state) {
              final isLoading = state is CurrencyLoading;
              final canSave =
                  _selectedCurrency != null &&
                  !_isLoading &&
                  _availableCurrencies.isNotEmpty;

              return ElevatedButton(
                onPressed: (canSave && !isLoading) ? _saveCurrency : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Confirmer',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveCurrency() {
    if (_selectedCurrency != null) {
      context.read<CurrencyBloc>().add(
        UpdateUserCurrency(_selectedCurrency!.id),
      );
    }
  }
}
