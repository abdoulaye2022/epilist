import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ListsSectionHeader extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onCreateNew;

  const ListsSectionHeader({
    super.key,
    required this.onViewAll,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.myGroceryLists,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      l10n.viewAll,
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.newList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.myGroceryLists,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      l10n.viewAll,
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}
