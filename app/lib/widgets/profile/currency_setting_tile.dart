// widgets/profile/currency_setting_tile.dart - VERSION AVEC TRADUCTIONS COMPLÈTES
import 'package:epilist/widgets/currency/currency_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/blocs/currency/currency_state.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/l10n/app_localizations.dart';

class CurrencySettingTile extends StatefulWidget {
  const CurrencySettingTile({super.key});

  @override
  State<CurrencySettingTile> createState() => _CurrencySettingTileState();
}

class _CurrencySettingTileState extends State<CurrencySettingTile> {
  Currency? _currentCurrency;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _currentUser = authState.user;
      _currentCurrency = authState.user.currency;
    }

    context.read<CurrencyBloc>().add(const LoadUserCurrency());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              setState(() {
                _currentUser = state.user;
                _currentCurrency = state.user.currency;
              });
            }
          },
        ),
        BlocListener<CurrencyBloc, CurrencyState>(
          listener: (context, state) {
            if (state is UserCurrencyLoaded) {
              setState(() {
                _currentCurrency = state.userCurrency.currency;
              });
            } else if (state is UserCurrencyUpdated) {
              setState(() {
                _currentCurrency = state.userCurrency.currency;
              });
              context.read<AuthBloc>().add(GetCurrentUser());
            }
          },
        ),
      ],
      child: _buildTile(l10n),
    );
  }

  Widget _buildTile(AppLocalizations l10n) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showCurrencySettings,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          _currentCurrency?.symbol ?? '\$',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.currency,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_currentCurrency != null) ...[
                            Text(
                              _currentCurrency!.code.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Text(
                              l10n.defaultCurrencyCAD,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCurrencySettings() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<CurrencyBloc>()),
              BlocProvider.value(value: context.read<AuthBloc>()),
            ],
            child: CurrencySelectionDialog(
              currentCurrency: _currentCurrency,
              onCurrencySelected: (Currency selectedCurrency) {
                setState(() {
                  _currentCurrency = selectedCurrency;
                });
              },
            ),
          ),
    );
  }
}
