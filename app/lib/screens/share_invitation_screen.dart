// screens/share_invitation_screen.dart - VERSION WITH MINIMAL SNACKBARS
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/share_invitation.dart';
import 'package:epilist/models/shared_enums.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/screens/main_shell.dart';

class ShareInvitationScreen extends StatefulWidget {
  final String shareToken;

  const ShareInvitationScreen({super.key, required this.shareToken});

  @override
  State<ShareInvitationScreen> createState() => _ShareInvitationScreenState();
}

class _ShareInvitationScreenState extends State<ShareInvitationScreen> {
  bool _hasPerformedAction = false;

  @override
  void initState() {
    super.initState();
    context.read<SharedListBloc>().add(LoadShareInvitation(widget.shareToken));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasPerformedAction,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.siTitle),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed:
                _hasPerformedAction
                    ? null
                    : () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MainShell(),
                        ),
                        (route) => false,
                      );
                    },
          ),
        ),
        body: BlocConsumer<SharedListBloc, SharedListState>(
          listener: (context, state) {
            if (state is ShareInvitationAccepted) {
              _hasPerformedAction = true;

              SmartSnackBarManager.showSuccessSnackBar(
                context,
                AppLocalizations.of(context)!.siAccepted,
                duration: const Duration(seconds: 2),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainShell()),
                (route) => false,
              );
            } else if (state is ShareInvitationDeclined) {
              _hasPerformedAction = true;

              SmartSnackBarManager.showInfoSnackBar(
                context,
                AppLocalizations.of(context)!.siDeclined,
                duration: const Duration(seconds: 2),
              );

              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainShell()),
                    (route) => false,
                  );
                }
              });
            }
          },
          builder: (context, state) {
            if (state is SharedListLoading) {
              return _buildLoadingContent();
            }

            if (state is ShareInvitationLoaded) {
              return _buildInvitationContent(state.invitation);
            }

            if (state is SharedListError) {
              return _buildErrorContent(state.message);
            }

            return _buildLoadingContent();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)!.siValidating,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            AppLocalizations.of(context)!.siVerifyingToken,
            style: TextStyle(fontSize: 14, color: AppColors.textDisabled),
          ),

          const SizedBox(height: 32),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Token',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.shareToken,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationContent(ShareInvitation invitation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          _buildInvitationStatusBadge(invitation),

          const SizedBox(height: 20),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _getStatusColor(invitation).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: _getStatusColor(invitation).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getStatusIcon(invitation),
              size: 60,
              color: _getStatusColor(invitation),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            invitation.isExpired || !invitation.isPending
                ? 'Invitation ${invitation.statusDisplayName.toLowerCase()}'
                : AppLocalizations.of(context)!.siTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          _buildMainMessage(invitation),

          const SizedBox(height: 32),

          _buildListInfoCard(invitation),

          const SizedBox(height: 32),

          _buildPermissionDescription(invitation.permission),

          const SizedBox(height: 40),

          _buildActionButtons(invitation),

          const SizedBox(height: 24),

          _buildAdditionalInfo(invitation),
        ],
      ),
    );
  }

  Widget _buildInvitationStatusBadge(ShareInvitation invitation) {
    Color color;
    IconData icon;
    String text;

    if (invitation.isExpired) {
      color = Colors.red;
      icon = Icons.access_time;
      text = 'Expired';
    } else if (invitation.isAccepted) {
      color = Colors.green;
      icon = Icons.check_circle;
      text = 'Accepted';
    } else if (invitation.isDeclined) {
      color = Colors.orange;
      icon = Icons.cancel;
      text = 'Declined';
    } else {
      color = Colors.blue;
      icon = Icons.pending;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMessage(ShareInvitation invitation) {
    if (invitation.isExpired) {
      return Column(
        children: [
          Text(
            'This invitation expired on ${_formatDate(invitation.expiresAt)}',
            style: TextStyle(fontSize: 16, color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact ${invitation.ownerName} to receive a new invitation.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (invitation.isAccepted) {
      return Text(
        '${AppLocalizations.of(context)!.siAlreadyAccepted} "${invitation.listName}".',
        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }

    if (invitation.isDeclined) {
      return Text(
        '${AppLocalizations.of(context)!.siAlreadyDeclined} "${invitation.listName}".',
        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 18, color: AppColors.textSecondary, height: 1.4),
        children: [
          TextSpan(
            text: invitation.ownerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(text: ' invites you to access the list '),
          TextSpan(
            text: '"${invitation.listName}"',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ShareInvitation invitation) {
    if (invitation.isExpired ||
        invitation.isAccepted ||
        invitation.isDeclined) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainShell()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            invitation.isAccepted ? 'Go to list' : AppLocalizations.of(context)!.siBackHome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showDeclineConfirmation(invitation),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Decline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showAcceptConfirmation(invitation),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Accept',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(ShareInvitation invitation) {
    if (invitation.isPending && !invitation.isExpired) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This invitation expires on ${_formatDate(invitation.expiresAt)}.',
                style: TextStyle(color: AppColors.accent, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(ShareInvitation invitation) {
    if (invitation.isExpired) return Colors.red;
    if (invitation.isAccepted) return Colors.green;
    if (invitation.isDeclined) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(ShareInvitation invitation) {
    if (invitation.isExpired) return Icons.access_time;
    if (invitation.isAccepted) return Icons.check_circle;
    if (invitation.isDeclined) return Icons.cancel;
    return Icons.share_rounded;
  }

  Widget _buildListInfoCard(ShareInvitation invitation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  invitation.listName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.person,
            title: AppLocalizations.of(context)!.siSharedBy,
            value:
                '${invitation.ownerName}${invitation.ownerEmail.isNotEmpty ? ' (${invitation.ownerEmail})' : ''}',
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.security,
            title: 'Permissions',
            value: invitation.permissionDisplayName,
            valueColor: _getPermissionColor(invitation.permission),
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.schedule,
            title: AppLocalizations.of(context)!.siExpiresOn,
            value: _formatDate(invitation.expiresAt),
            valueColor: invitation.isExpired ? AppColors.error : null,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.calendar_today,
            title: AppLocalizations.of(context)!.siCreatedOn,
            value: _formatDate(invitation.createdAt),
          ),

          if (invitation.shoppingList != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.siListPreview,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.list_alt,
                    title: 'Items',
                    value: '${invitation.shoppingList!.apiItemsCount}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Completed',
                    value: '${invitation.shoppingList!.apiPurchasedItemsCount}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            if (invitation.shoppingList!.apiTotalPrice > 0) ...[
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.attach_money,
                title: AppLocalizations.of(context)!.siEstimatedBudget,
                value:
                    '${invitation.shoppingList!.apiTotalPrice.toStringAsFixed(2)} CAD',
                color: Colors.orange,
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showAcceptConfirmation(ShareInvitation invitation) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  AppLocalizations.of(context)!.siAccept,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)!.siAcceptConfirm,
                      ),
                      TextSpan(
                        text: invitation.ownerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(text: ' for the list '),
                      TextSpan(
                        text: '"${invitation.listName}"',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Permissions: ${invitation.permissionDisplayName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
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
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<SharedListBloc>().add(
                            AcceptShareInvitation(invitation.token),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeclineConfirmation(ShareInvitation invitation) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  AppLocalizations.of(context)!.siDecline,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)!.siDeclineConfirm,
                      ),
                      TextSpan(
                        text: invitation.ownerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(text: ' for the list '),
                      TextSpan(
                        text: '"${invitation.listName}"',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.siDeclineWarning,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
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
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<SharedListBloc>().add(
                            DeclineShareInvitation(invitation.token),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Decline',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color[600], size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDescription(SharePermission permission) {
    String title;
    String description;
    List<String> abilities;
    Color color;

    switch (permission) {
      case SharePermission.readOnly:
        title = AppLocalizations.of(context)!.readOnly;
        description = AppLocalizations.of(context)!.siReadOnlyDesc;
        abilities = [
          AppLocalizations.of(context)!.siPermViewItems,
          AppLocalizations.of(context)!.siPermViewPrices,
        ];
        color = AppColors.accent;
        break;
      case SharePermission.edit:
        title = 'Edit';
        description = AppLocalizations.of(context)!.siEditDesc;
        abilities = [
          AppLocalizations.of(context)!.siPermAddEdit,
          AppLocalizations.of(context)!.siPermMarkPurchased,
          AppLocalizations.of(context)!.siPermEditPrices,
        ];
        color = AppColors.primary;
        break;
      case SharePermission.admin:
        title = 'Administration';
        description = AppLocalizations.of(context)!.siFullRights;
        abilities = [
          AppLocalizations.of(context)!.siPermModifyDelete,
          AppLocalizations.of(context)!.siPermManageItems,
          AppLocalizations.of(context)!.siPermShare,
        ];
        color = Colors.purple[600]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...abilities.map(
            (ability) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ability,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.siInvalid,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainShell()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(AppLocalizations.of(context)!.siBackHome),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPermissionColor(SharePermission permission) {
    switch (permission) {
      case SharePermission.readOnly:
        return AppColors.accent;
      case SharePermission.edit:
        return AppColors.primary;
      case SharePermission.admin:
        return Colors.purple[600]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.tomorrow;
    } else if (difference < 7) {
      return AppLocalizations.of(context)!.siInDays(difference);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
