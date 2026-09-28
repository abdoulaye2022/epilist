// widgets/profile/language_setting_tile.dart - DIALOGUE SIMPLIFIÉ
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class LanguageSettingTile extends StatelessWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        String currentLanguage = 'fr';
        if (state is LocalizationLoaded) {
          currentLanguage = state.locale.languageCode;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLanguageDialog(context, l10n, currentLanguage),
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.green.withValues(alpha: 0.1),
              highlightColor: Colors.green.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icône avec conteneur coloré
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Contenu principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.language,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getLanguageDisplayName(currentLanguage, l10n),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Drapeau et indicateur
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getLanguageFlag(currentLanguage),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getLanguageCode(currentLanguage),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textDisabled,
                        ),
                      ],
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

  String _getLanguageDisplayName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'fr':
        return l10n.french;
      case 'en':
        return l10n.english;
      default:
        return l10n.french;
    }
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇺🇸';
      default:
        return '🇫🇷';
    }
  }

  String _getLanguageCode(String languageCode) {
    return languageCode.toUpperCase();
  }

  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    String currentLanguage,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
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

                    // Options de langue
                    _buildLanguageOption(
                      context,
                      'fr',
                      l10n.french,
                      '🇫🇷',
                      'Français',
                      currentLanguage == 'fr',
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context,
                      'en',
                      l10n.english,
                      '🇺🇸',
                      'English',
                      currentLanguage == 'en',
                    ),
                    const SizedBox(height: 24),

                    // Bouton fermer
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Text(
                          l10n.continueButton,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.language_rounded, size: 40, color: AppColors.primary),
    );
  }

  // ✅ NOUVEAU: Titre simple
  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.selectLanguage,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ✅ NOUVEAU: Description simple
  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.choosePreferredLanguage,
      style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String languageName,
    String flag,
    String nativeName,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<LocalizationBloc>().add(ChangeLanguage(languageCode));
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[300]! : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            // Drapeau
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 16),

            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur de sélection
            if (isSelected) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ] else ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
