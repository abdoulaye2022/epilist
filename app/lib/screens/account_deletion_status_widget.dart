// widgets/profile/account_deletion_status_widget.dart - VERSION DEBUG
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/account_deletion_status.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/foundation.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(GetAccountDeletionStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      buildWhen: (previous, current) {
        debugPrint(
          '🔍 AccountDeletionStatusWidget buildWhen: ${current.runtimeType}',
        );
        return current is AccountDeletionStatusLoaded ||
            current is AuthLoading ||
            current is AuthFailure;
      },
      builder: (context, state) {
        debugPrint(
          '🎨 AccountDeletionStatusWidget builder: ${state.runtimeType}',
        );

        if (state is AccountDeletionStatusLoaded) {
          final status = state.status;
          debugPrint(
            '📊 Statut reçu: isDeletionRequested=${status.isDeletionRequested}',
          );

          if (status.isDeletionRequested) {
            debugPrint('✅ Affichage du widget de suppression programmée');
            return _buildDeletionScheduledCard(status);
          } else {
            debugPrint('ℹ️ Pas de suppression programmée, widget caché');
          }
        }

        if (state is AuthLoading) {
          debugPrint('⏳ État de chargement...');
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Vérification du statut de suppression...'),
              ],
            ),
          );
        }

        if (state is AuthFailure) {
          debugPrint('❌ Erreur lors du chargement du statut: ${state.error}');
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur de chargement du statut',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    debugPrint('🔄 Retry chargement statut...');
                    context.read<AuthBloc>().add(GetAccountDeletionStatus());
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // Ne rien afficher par défaut
        debugPrint('🚫 Aucun widget à afficher');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDeletionScheduledCard(AccountDeletionStatus status) {
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
                  'Suppression de compte programmée',
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
              'Votre compte sera définitivement supprimé le ${status.formattedDeletionDate}',
              style: TextStyle(color: Colors.orange[700], fontSize: 14),
            ),

            if (status.daysRemaining != null) ...[
              const SizedBox(height: 8),
              Text(
                'Temps restant : ${status.daysRemaining} jour${status.daysRemaining! > 1 ? 's' : ''}',
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
              'Raison : ${status.deletionReason}',
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
                onPressed: _cancelDeletion,
                icon: const Icon(Icons.undo),
                label: const Text('Annuler la suppression'),
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
                      'La période d\'annulation de 30 jours est écoulée',
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

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('🎧 AccountDeletionStatusWidget listener: ${state.runtimeType}');

    if (state is AccountDeletionCancelled) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Suppression de compte annulée avec succès !',
      );

      // Recharger le statut
      context.read<AuthBloc>().add(GetAccountDeletionStatus());
    } else if (state is AuthFailure) {
      debugPrint('❌ Erreur dans AccountDeletionStatusWidget: ${state.error}');
      // On affiche l'erreur dans le builder, pas ici
    }
  }

  void _cancelDeletion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.undo, color: Colors.green),
                SizedBox(width: 12),
                Text('Annuler la suppression'),
              ],
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler la suppression de votre compte ? '
              'Votre compte redeviendra actif immédiatement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Non, garder la suppression'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  debugPrint('🔄 Annulation de la suppression demandée...');
                  context.read<AuthBloc>().add(CancelAccountDeletion());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Oui, annuler'),
              ),
            ],
          ),
    );
  }
}
