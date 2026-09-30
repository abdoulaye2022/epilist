// screens/intelligence_settings_screen.dart - Réglages « Intelligence
// EpiList » (§43) : interrupteurs stockés en SharedPreferences, sauf
// le partage communautaire (§33) qui est un consentement SERVEUR.
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
    final predictions =
        await IntelligenceSettings.get(IntelligenceSettings.keyPredictions);
    final estimates = await IntelligenceSettings.get(
        IntelligenceSettings.keyInventoryEstimates);
    final autoAdd = await IntelligenceSettings.get(
        IntelligenceSettings.keyAutoAddOut,
        defaultValue: false);
    final forecast =
        await IntelligenceSettings.get(IntelligenceSettings.keyBudgetForecast);
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
      appBar: AppBar(title: Text(l10n.intelligenceSettings)),
      body: _loading
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
                    child: SwitchListTile(
                      title: Text(l10n.communityShareTitle,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.communityShareHint,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      value: _communityShare!,
                      onChanged: _setCommunityShare,
                    ),
                  ),
              ],
            ),
    );
  }
}
