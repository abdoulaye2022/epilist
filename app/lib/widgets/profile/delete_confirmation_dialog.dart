// widgets/dialogs/delete_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String itemName;
  final String? description;
  final String? warningText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;
  final Color? accentColor;
  final IconData? icon;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.onConfirm,
    this.description,
    this.warningText,
    this.onCancel,
    this.isLoading = false,
    this.accentColor,
    this.icon,
  });

  // Factory pour supprimer un article
  factory DeleteConfirmationDialog.deleteItem({
    required BuildContext context,
    required String itemName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return DeleteConfirmationDialog(
      title: l10n.deleteItemTitle,
      itemName: itemName,
      description: l10n.sureToDeleteItem,
      warningText: l10n.actionIrreversible,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isLoading: isLoading,
      accentColor: Colors.red[600],
      icon: Icons.delete_rounded,
    );
  }

  // Factory pour supprimer une liste
  factory DeleteConfirmationDialog.deleteList({
    required BuildContext context,
    required String listName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return DeleteConfirmationDialog(
      title: l10n.deleteListTitle,
      itemName: listName,
      description: l10n.sureToDeleteList,
      warningText: l10n.actionIrreversibleDeletesAllItems,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isLoading: isLoading,
      accentColor: Colors.red[600],
      icon: Icons.delete_rounded,
    );
  }

  // Factory pour quitter une liste partagée
  factory DeleteConfirmationDialog.leaveList({
    required BuildContext context,
    required String listName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return DeleteConfirmationDialog(
      title: l10n.leaveList,
      itemName: listName,
      description: l10n.sureToLeaveQuestion, // Utiliser une clé différente
      warningText: l10n.loseAccessWarning,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isLoading: isLoading,
      accentColor: Colors.orange[600],
      icon: Icons.exit_to_app,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveAccentColor = accentColor ?? Colors.red[600]!;
    final effectiveIcon = icon ?? Icons.delete_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(effectiveAccentColor, effectiveIcon),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildMessage(),
            if (warningText != null) ...[
              const SizedBox(height: 8),
              _buildWarning(effectiveAccentColor),
            ],
            const SizedBox(height: 24),
            _buildButtons(context, effectiveAccentColor, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color, IconData iconData) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(iconData, size: 40, color: color),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMessage() {
    if (description == null) {
      return Text(
        itemName,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        children: [
          TextSpan(text: '$description '),
          TextSpan(
            text: '"$itemName"',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const TextSpan(text: ' ?'),
        ],
      ),
    );
  }

  Widget _buildWarning(Color color) {
    return Text(
      warningText!,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    Color color,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed:
                isLoading ? null : (onCancel ?? () => Navigator.pop(context)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isLoading ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed:
                isLoading
                    ? null
                    : () {
                      onConfirm();
                      Navigator.pop(context);
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: color.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      _getConfirmButtonText(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  String _getConfirmButtonText(AppLocalizations l10n) {
    if (title.toLowerCase().contains('supprimer') ||
        title.toLowerCase().contains('delete')) {
      return l10n.delete;
    } else if (title.toLowerCase().contains('quitter') ||
        title.toLowerCase().contains('leave')) {
      return l10n.leave;
    } else {
      return l10n.confirm;
    }
  }

  // Méthodes statiques pour les cas d'usage courants
  static Future<bool?> showDeleteItem({
    required BuildContext context,
    required String itemName,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLoading,
      builder:
          (context) => DeleteConfirmationDialog.deleteItem(
            context: context,
            itemName: itemName,
            onConfirm: onConfirm,
            isLoading: isLoading,
          ),
    );
  }

  static Future<bool?> showDeleteList({
    required BuildContext context,
    required String listName,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLoading,
      builder:
          (context) => DeleteConfirmationDialog.deleteList(
            context: context,
            listName: listName,
            onConfirm: onConfirm,
            isLoading: isLoading,
          ),
    );
  }

  static Future<bool?> showLeaveList({
    required BuildContext context,
    required String listName,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLoading,
      builder:
          (context) => DeleteConfirmationDialog.leaveList(
            context: context,
            listName: listName,
            onConfirm: onConfirm,
            isLoading: isLoading,
          ),
    );
  }
}
