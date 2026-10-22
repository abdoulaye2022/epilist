// widgets/suggestion/suggestion_card.dart - VERSION CORRIGÉE
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/app_card.dart';

class SuggestionCard extends StatelessWidget {
  final ProductSuggestion suggestion;
  final VoidCallback onDelete;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: AppCard.tight(
        radius: 16,
        bordered: false,
        child: Material(
          // Material propre au ListTile : le fond du conteneur parent
          // masquerait sinon son fond et ses effets de pression
          // (assertion « ink splashes may be invisible »).
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildLeadingIcon(),
            title: _buildTitle(),
            subtitle: _buildSubtitle(context, l10n),
            trailing: _buildTrailing(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.infoTint, AppColors.infoBorder],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.shopping_basket_outlined,
        color: AppColors.accent,
        size: 24,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      suggestion.productName,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      overflow: TextOverflow.ellipsis, // Correction pour éviter l'overflow
      maxLines: 1,
    );
  }

  Widget _buildSubtitle(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildBadges(),
        const SizedBox(height: 8),
        _buildUsageInfo(context, l10n),
      ],
    );
  }

  Widget _buildBadges() {
    // Utilisation de Wrap au lieu de Row pour éviter l'overflow
    return Wrap(
      spacing: 8, // Espacement horizontal entre les badges
      runSpacing: 4, // Espacement vertical si ça passe à la ligne
      children: [
        if (suggestion.hasPrice)
          _buildBadge(
            text: suggestion.formattedPrice,
            color: AppColors.success,
            icon: Icons.attach_money,
          ),
        if (suggestion.hasStore)
          _buildBadge(
            text: suggestion.storeName!,
            color: AppColors.violet,
            icon: Icons.store,
          ),
      ],
    );
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTint.fill(color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppTint.line(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          // Limitation de la largeur du texte du badge
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80), // Largeur max
            child: Text(
              text,
              style: TextStyle(
                color: AppTint.ink(color),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Conteneur d'usage flexible
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, size: 12, color: AppColors.warningInk),
                const SizedBox(width: 4),
                Flexible(
                  // Permet au texte de s'adapter
                  child: Text(
                    suggestion.getUsageInfo(context),
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8), // Espacement fixe
        // Date de dernière utilisation flexible
        if (suggestion.lastUsedAt != null)
          Flexible(
            flex: 1,
            child: Text(
              '${l10n.lastUsed}: ${suggestion.getLastUsedFormatted(context)}',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 14.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisSize: MainAxisSize.min, // Évite l'expansion complète
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    // Permet au texte de s'adapter
                    child: Text(
                      l10n.deleteSuggestion,
                      style: TextStyle(color: AppColors.error),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}
