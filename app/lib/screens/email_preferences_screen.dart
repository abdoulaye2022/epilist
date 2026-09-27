// lib/screens/email_preferences_screen.dart

import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/email_preference.dart';
import '../services/email_preference_service.dart';
import '../utils/smart_snackbar_manager.dart';

class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({super.key});

  @override
  State<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  EmailPreference? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    final prefs = await EmailPreferenceService.getPreferences();

    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() => _isSaving = true);

    final success = await EmailPreferenceService.updatePreferences(_preferences!);

    setState(() => _isSaving = false);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      if (success) {
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          l10n.preferencesSavedSuccessfully,
        );
      } else {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.errorSavingPreferences,
        );
      }
    }
  }

  Future<void> _resetPreferences() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmAction),
        content: Text(AppLocalizations.of(context)!.epResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      final success = await EmailPreferenceService.resetPreferences();
      setState(() => _isSaving = false);

      if (success) {
        await _loadPreferences();
        if (mounted) {
          SmartSnackBarManager.showSuccessSnackBar(
            context,
            AppLocalizations.of(context)!.epResetDone,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.epTitle),
        actions: [
          if (!_isLoading && _preferences != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPreferences,
              tooltip: AppLocalizations.of(context)!.epResetDefaults,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.emailPreferencesUnavailableOffline,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.visitPageOnlineToCache,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPreferences,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.tryAgain),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSection(
                          title: AppLocalizations.of(context)!.epTransactional,
                          subtitle: AppLocalizations.of(context)!.epTransactionalDesc,
                          icon: Icons.security,
                          color: Colors.blue,
                          children: [
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epVerifTitle,
                              subtitle: AppLocalizations.of(context)!.epVerifDesc,
                              value: _preferences!.emailVerification,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(emailVerification: val);
                                });
                              },
                            ),
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epPwdReqTitle,
                              subtitle: AppLocalizations.of(context)!.epPwdReqDesc,
                              value: _preferences!.passwordChangeRequest,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(passwordChangeRequest: val);
                                });
                              },
                            ),
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epPwdChangedTitle,
                              subtitle: AppLocalizations.of(context)!.epPwdChangedDesc,
                              value: _preferences!.passwordChanged,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(passwordChanged: val);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: AppLocalizations.of(context)!.epListNotif,
                          subtitle: AppLocalizations.of(context)!.epListNotifDesc,
                          icon: Icons.list_alt,
                          color: Colors.green,
                          children: [
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epListSharedTitle,
                              subtitle: AppLocalizations.of(context)!.epListSharedDesc,
                              value: _preferences!.listSharedWithMe,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(listSharedWithMe: val);
                                });
                              },
                            ),
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epListCompletedTitle,
                              subtitle: AppLocalizations.of(context)!.epListCompletedDesc,
                              value: _preferences!.listCompleted,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(listCompleted: val);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: AppLocalizations.of(context)!.epBudgetAlerts,
                          subtitle: AppLocalizations.of(context)!.epBudgetAlertsDesc,
                          icon: Icons.account_balance_wallet,
                          color: Colors.orange,
                          children: [
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epBudgetExceededTitle,
                              subtitle: AppLocalizations.of(context)!.epBudgetExceededDesc,
                              value: _preferences!.budgetAlert,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(budgetAlert: val);
                                });
                              },
                            ),
                            _buildSwitchTile(
                              title: AppLocalizations.of(context)!.epMonthlySummaryTitle,
                              subtitle: AppLocalizations.of(context)!.epMonthlySummaryDesc,
                              value: _preferences!.budgetSummary,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(budgetSummary: val);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Tips & Tricks',
                          subtitle: AppLocalizations.of(context)!.epTipsDesc,
                          icon: Icons.lightbulb_outline,
                          color: Colors.amber,
                          children: [
                            _buildSwitchTile(
                              title: 'Tips & Reminders',
                              subtitle: AppLocalizations.of(context)!.epTipsToggleDesc,
                              value: _preferences!.tipsAndTricks,
                              onChanged: (val) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(tipsAndTricks: val);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                    if (_isSaving)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: !_isLoading && _preferences != null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _savePreferences,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
            )
          : null,
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
