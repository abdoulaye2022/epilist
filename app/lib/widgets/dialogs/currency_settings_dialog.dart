// widgets/dialogs/currency_selection_dialog.dart - VERSION AVEC TRADUCTIONS COMPLÈTES
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
    context.read<CurrencyBloc>().add(const LoadCurrencies());
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

                      if (state.userCurrency != null) {
                        _selectedCurrency = state.userCurrency!.currency;
                      }
                    });
                  } else if (state is UserCurrencyLoaded) {
                    setState(() {
                      _selectedCurrency = state.userCurrency.currency;
                    });
                  } else if (state is UserCurrencyUpdated) {
                    Navigator.pop(context);
                    SmartSnackBarManager.showSuccessSnackBar(
                      context,
                      l10n.currencyUpdatedSuccessfully,
                      duration: const Duration(seconds: 2),
                    );

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
                      _buildIcon(),
                      const SizedBox(height: 20),
                      _buildTitle(l10n),
                      const SizedBox(height: 12),
                      _buildDescription(l10n),
                      const SizedBox(height: 24),
                      _buildContent(l10n),
                      const SizedBox(height: 24),
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

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.selectCurrency,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.chooseCurrencyDescription,
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
              l10n.loadingCurrencies,
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
              l10n.noCurrenciesAvailable,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cannotLoadCurrencies,
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
          l10n.currentCurrency,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

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
                                l10n.popular,
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
                  l10n.currencyDisplayOnly,
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
              l10n.cancel,
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
                              l10n.confirm,
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
