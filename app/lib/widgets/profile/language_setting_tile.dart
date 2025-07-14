// widgets/profile/language_setting_tile.dart - VERSION AMÉLIORÉE
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
              splashColor: Colors.green.withOpacity(0.1),
              highlightColor: Colors.green.withOpacity(0.05),
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
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: Colors.green[600],
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
                              color: Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getLanguageDisplayName(currentLanguage, l10n),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
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
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey[400],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            color: Colors.green[600],
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.selectLanguage,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.choosePreferredLanguage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
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
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              l10n.continueButton,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          color: isSelected ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[300]! : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
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
                border: Border.all(color: Colors.grey[300]!),
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
                      color: isSelected ? Colors.green[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.green[600] : Colors.grey[600],
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
                  color: Colors.green[600],
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
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
