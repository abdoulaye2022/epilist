// widgets/language_selector.dart - VERSION AMÉLIORÉE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final bool showTitle;
  final bool compact;
  final EdgeInsets? padding;

  const LanguageSelector({
    super.key,
    this.showTitle = true,
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle && !compact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: Colors.green[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.languageSelection,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          l10n.choosePreferredLanguage,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showTitle && compact) ...[
            Text(
              l10n.language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Sélecteurs de langue
          BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, state) {
              String currentLanguage = 'fr';
              if (state is LocalizationLoaded) {
                currentLanguage = state.locale.languageCode;
              }

              if (compact) {
                return _buildCompactSelector(context, l10n, currentLanguage);
              } else {
                return _buildFullSelector(context, l10n, currentLanguage);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    AppLocalizations l10n,
    String currentLanguage,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildLanguageOption(
            context,
            'fr',
            l10n.french,
            '🇫🇷',
            'Français',
            currentLanguage == 'fr',
            false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLanguageOption(
            context,
            'en',
            l10n.english,
            '🇺🇸',
            'English',
            currentLanguage == 'en',
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    AppLocalizations l10n,
    String currentLanguage,
  ) {
    return Column(
      children: [
        _buildLanguageOption(
          context,
          'fr',
          l10n.french,
          '🇫🇷',
          'Français',
          currentLanguage == 'fr',
          true,
        ),
        const SizedBox(height: 8),
        _buildLanguageOption(
          context,
          'en',
          l10n.english,
          '🇺🇸',
          'English',
          currentLanguage == 'en',
          true,
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String languageName,
    String flag,
    String nativeName,
    bool isSelected,
    bool isCompact,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<LocalizationBloc>().add(ChangeLanguage(languageCode));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isCompact ? double.infinity : null,
        padding: EdgeInsets.all(isCompact ? 16 : 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Drapeau avec conteneur
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            // Textes
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isCompact
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                children: [
                  Text(
                    languageName,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: isCompact ? TextAlign.left : TextAlign.center,
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 12,
                      fontWeight: FontWeight.w400,
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[600],
                    ),
                    textAlign: isCompact ? TextAlign.left : TextAlign.center,
                  ),
                ],
              ),
            ),

            // Indicateur de sélection
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                width: isCompact ? 24 : 20,
                height: isCompact ? 24 : 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.green[600],
                  size: isCompact ? 16 : 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Dialog amélioré
class LanguageSelectorDialog {
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog(
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
                  // Header élégant
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green[50]!, Colors.green[100]!],
                      ),
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
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: Colors.white,
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

                  // Content avec sélecteur compact
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        BlocProvider.value(
                          value: context.read<LocalizationBloc>(),
                          child: const LanguageSelector(
                            showTitle: false,
                            compact: true,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bouton fermer stylé
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.continueButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
}

// Widget d'indicateur amélioré
class CurrentLanguageIndicator extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showLabel;

  const CurrentLanguageIndicator({
    super.key,
    this.onTap,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        String flag = '🇫🇷';
        String label = l10n.french;

        if (state is LocalizationLoaded && state.locale.languageCode == 'en') {
          flag = '🇺🇸';
          label = l10n.english;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => LanguageSelectorDialog.show(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 16)),
                  if (showLabel) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
