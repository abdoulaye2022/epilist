// widgets/common/quick_actions_sheet.dart - Ce que fait le bouton + .
//
// La place la plus accessible de l'écran — le bouton vert central —
// servait à UNE chose : créer une liste, geste fait une fois par
// semaine. Elle ouvre maintenant les six actions du quotidien, dont
// quatre n'étaient atteignables que depuis le tableau de bord ou depuis
// le fond d'un dialogue.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:epilist/utils/product_photo_flow.dart';
import 'package:epilist/utils/receipt_scan_flow.dart';
import 'package:epilist/widgets/common/app_action_tile.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/receipts/add_receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class QuickActionsSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _QuickActionsSheet(),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Le contexte de la feuille meurt à sa fermeture : on garde celui de
    // l'écran, qui porte les providers et survit à la navigation.
    final host = Navigator.of(context).context;

    void run(Future<void> Function() action) {
      Navigator.of(context).pop();
      action();
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm + 2),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.quickActionsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          AppActionTile(
            icon: Icons.add_shopping_cart_outlined,
            title: l10n.quickAddItem,
            subtitle: l10n.toChosenList,
            onTap: () => run(() => _addItem(host)),
          ),
          AppActionTile(
            icon: Icons.document_scanner_outlined,
            title: l10n.scanReceipt,
            subtitle: l10n.scanReceiptSubtitle,
            onTap: () => run(() => _scanReceipt(host)),
          ),
          AppActionTile(
            icon: Icons.receipt_long_outlined,
            title: l10n.addReceipt,
            subtitle: l10n.manualEntry,
            onTap: () => run(() => _addReceipt(host)),
          ),
          AppActionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: l10n.scanBarcode,
            subtitle: l10n.toChosenList,
            onTap: () => run(() => _scanBarcode(host)),
          ),
          AppActionTile(
            icon: Icons.add_a_photo_outlined,
            title: l10n.qaProductPhoto,
            subtitle: l10n.qaProductPhotoHint,
            onTap: () => run(() => startProductPhoto(host)),
          ),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          AppActionTile(
            icon: Icons.playlist_add_rounded,
            title: l10n.createList,
            onTap: () => run(() => _createList(host)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  static Future<void> _addItem(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailScreen(
          shoppingList: list,
          initialAction: ListDetailAction.addItem,
        ),
      ),
    );
  }

  static Future<void> _scanReceipt(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !context.mounted) return;
    await startReceiptScan(context, listId: list.id);
  }

  static Future<void> _addReceipt(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AddReceiptDialog(listId: list.id),
    );
  }

  static Future<void> _scanBarcode(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailScreen(
          shoppingList: list,
          initialAction: ListDetailAction.barcodeItem,
        ),
      ),
    );
  }

  static Future<void> _createList(BuildContext context) async {
    final bloc = context.read<ShoppingListBloc>();
    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const CreateListDialog(),
      ),
    );
  }
}
