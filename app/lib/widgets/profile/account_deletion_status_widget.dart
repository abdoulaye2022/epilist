// widgets/profile/account_deletion_status_widget.dart - VERSION I18N
import 'package:epilist/models/account_deletion_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/l10n/app_localizations.dart';

class AccountDeletionStatusWidget extends StatefulWidget {
  const AccountDeletionStatusWidget({super.key});

  @override
  State<AccountDeletionStatusWidget> createState() =>
      _AccountDeletionStatusWidgetState();
}

class _AccountDeletionStatusWidgetState
    extends State<AccountDeletionStatusWidget> {
  @override
  void initState() {
    super.initState();
    // Charger le statut de suppression au démarrage
    context.read<AuthBloc>().add(GetAccountDeletionStatus());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener:
          (context, state) => _handleAuthStateChanges(context, state, l10n),
      buildWhen: (previous, current) => current is AccountDeletionStatusLoaded,
      builder: (context, state) {
        if (state is AccountDeletionStatusLoaded) {
          final status = state.status;

          if (status.isDeletionRequested) {
            return _buildDeletionScheduledCard(status, l10n);
          }
        }

        // Ne rien afficher si pas de demande de suppression
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDeletionScheduledCard(
    AccountDeletionStatus status,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.accountDeletionScheduled,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (status.deletionEffectiveDate != null) ...[
            Text(
              l10n.accountWillBeDeleted(status.formattedDeletionDate),
              style: TextStyle(color: Colors.orange[700], fontSize: 14),
            ),

            if (status.daysRemaining != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.timeRemaining(
                  status.daysRemaining!,
                  status.daysRemaining! > 1 ? 's' : '',
                ),
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],

          if (status.deletionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              l10n.reason(status.deletionReason!),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (status.canCancelDeletion) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _cancelDeletion(l10n),
                icon: const Icon(Icons.undo),
                label: Text(l10n.cancelDeletion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.cancellationPeriodExpired,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleAuthStateChanges(
    BuildContext context,
    AuthState state,
    AppLocalizations l10n,
  ) {
    if (state is AccountDeletionCancelled) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.accountDeletionCancelled,
      );

      // Recharger le statut
      context.read<AuthBloc>().add(GetAccountDeletionStatus());
    } else if (state is AuthFailure) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur : ${state.error}',
      );
    }
  }

  void _cancelDeletion(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.undo, color: Colors.green),
                const SizedBox(width: 12),
                Text(l10n.confirmCancelDeletion),
              ],
            ),
            content: Text(l10n.confirmCancelDeletionText),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.noKeepDeletion),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(CancelAccountDeletion());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.yesCancelDeletion),
              ),
            ],
          ),
    );
  }
}
