// screens/intelligence_settings_screen.dart - Réglages « Intelligence
// EpiList » (§43) : interrupteurs stockés en SharedPreferences, sauf
// le partage communautaire (§33) qui est un consentement SERVEUR.
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IntelligenceSettingsScreen extends StatefulWidget {
  const IntelligenceSettingsScreen({super.key});

  @override
  State<IntelligenceSettingsScreen> createState() =>
      _IntelligenceSettingsScreenState();
}

class _IntelligenceSettingsScreenState
    extends State<IntelligenceSettingsScreen> {
  bool _predictions = true;
  bool _inventoryEstimates = true;
  bool _autoAddOut = false;
  bool _budgetForecast = true;
  bool _loading = true;
  // Consentement serveur (§33) ; null = état inconnu (hors ligne)
  bool? _communityShare;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final predictions = await IntelligenceSettings.get(
      IntelligenceSettings.keyPredictions,
    );
    final estimates = await IntelligenceSettings.get(
      IntelligenceSettings.keyInventoryEstimates,
    );
    final autoAdd = await IntelligenceSettings.get(
      IntelligenceSettings.keyAutoAddOut,
      defaultValue: false,
    );
    final forecast = await IntelligenceSettings.get(
      IntelligenceSettings.keyBudgetForecast,
    );
    if (!mounted) return;
    setState(() {
      _predictions = predictions;
      _inventoryEstimates = estimates;
      _autoAddOut = autoAdd;
      _budgetForecast = forecast;
      _loading = false;
    });

    // Consentement communautaire : lecture serveur, best-effort
    try {
      final share = await context.read<SpaceService>().getCommunitySharing();
      if (!mounted) return;
      setState(() => _communityShare = share);
    } catch (_) {}
  }

  Future<void> _setCommunityShare(bool value) async {
    final previous = _communityShare;
    setState(() => _communityShare = value);
    try {
      await context.read<SpaceService>().setCommunitySharing(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _communityShare = previous);
    }
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required bool value,
    required String key,
    required void Function(bool) apply,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSwitchTile(
        title: title,
        subtitle: subtitle,
        stateLabel: value ? l10n.settingOn : l10n.settingOff,
        value: value,
        onChanged: (v) {
          setState(() => apply(v));
          IntelligenceSettings.set(key, v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.intelligenceSettings),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _tile(
                    title: l10n.settingPredictions,
                    subtitle: l10n.settingPredictionsHint,
                    value: _predictions,
                    key: IntelligenceSettings.keyPredictions,
                    apply: (v) => _predictions = v,
                  ),
                  _tile(
                    title: l10n.settingInventoryEstimates,
                    subtitle: l10n.settingInventoryEstimatesHint,
                    value: _inventoryEstimates,
                    key: IntelligenceSettings.keyInventoryEstimates,
                    apply: (v) => _inventoryEstimates = v,
                  ),
                  _tile(
                    title: l10n.settingAutoAddOut,
                    subtitle: l10n.settingAutoAddOutHint,
                    value: _autoAddOut,
                    key: IntelligenceSettings.keyAutoAddOut,
                    apply: (v) => _autoAddOut = v,
                  ),
                  _tile(
                    title: l10n.settingBudgetForecast,
                    subtitle: l10n.settingBudgetForecastHint,
                    value: _budgetForecast,
                    key: IntelligenceSettings.keyBudgetForecast,
                    apply: (v) => _budgetForecast = v,
                  ),
                  // Consentement communautaire (§33) — réglage SERVEUR
                  if (_communityShare != null)
                    Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppSwitchTile(
                        title: l10n.communityShareTitle,
                        subtitle: l10n.communityShareHint,
                        stateLabel:
                            _communityShare! ? l10n.settingOn : l10n.settingOff,
                        value: _communityShare!,
                        onChanged: _setCommunityShare,
                      ),
                    ),
                ],
              ),
    );
  }
}
