// widgets/profile/account_deletion_status_widget.dart - DEBUG VERSION
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
    // Load deletion status on startup
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
            '📊 Status received: isDeletionRequested=${status.isDeletionRequested}',
          );

          if (status.isDeletionRequested) {
            debugPrint('✅ Displaying scheduled deletion widget');
            return _buildDeletionScheduledCard(status);
          } else {
            debugPrint('ℹ️ No scheduled deletion, widget hidden');
          }
        }

        if (state is AuthLoading) {
          debugPrint('⏳ Loading state...');
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
                Text('Checking deletion status...'),
              ],
            ),
          );
        }

        if (state is AuthFailure) {
          debugPrint('❌ Error loading status: ${state.error}');
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
                    'Error loading status',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    debugPrint('🔄 Retry loading status...');
                    context.read<AuthBloc>().add(GetAccountDeletionStatus());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Display nothing by default
        debugPrint('🚫 No widget to display');
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
                  'Account deletion scheduled',
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
              'Your account will be permanently deleted on ${status.formattedDeletionDate}',
              style: TextStyle(color: Colors.orange[700], fontSize: 14),
            ),

            if (status.daysRemaining != null) ...[
              const SizedBox(height: 8),
              Text(
                'Time remaining: ${status.daysRemaining} day${status.daysRemaining! > 1 ? 's' : ''}',
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
              'Reason: ${status.deletionReason}',
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
                label: const Text('Cancel deletion'),
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
                      'The 30-day cancellation period has expired',
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
        'Account deletion cancelled successfully!',
      );

      // Reload status
      context.read<AuthBloc>().add(GetAccountDeletionStatus());
    } else if (state is AuthFailure) {
      debugPrint('❌ Error in AccountDeletionStatusWidget: ${state.error}');
      // We display the error in the builder, not here
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
                Text('Cancel deletion'),
              ],
            ),
            content: const Text(
              'Are you sure you want to cancel the deletion of your account? '
              'Your account will become active immediately.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, keep deletion'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  debugPrint('🔄 Deletion cancellation requested...');
                  context.read<AuthBloc>().add(CancelAccountDeletion());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, cancel'),
              ),
            ],
          ),
    );
  }
}
