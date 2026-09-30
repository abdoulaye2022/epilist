// screens/space_members_screen.dart - Membres d'un espace (Phase 1) :
// liste, invitation par email, invitations en attente (révocables),
// et sortie de l'espace. Les droits sont vérifiés côté serveur ; l'UI
// masque simplement ce que le rôle courant ne permet pas.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpaceMembersScreen extends StatefulWidget {
  final Space space;

  const SpaceMembersScreen({super.key, required this.space});

  @override
  State<SpaceMembersScreen> createState() => _SpaceMembersScreenState();
}

class _SpaceMembersScreenState extends State<SpaceMembersScreen> {
  List<SpaceMemberInfo>? _members;
  List<Map<String, dynamic>> _pending = const [];
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await _service.getMembers(widget.space.id);
      List<Map<String, dynamic>> pending = const [];
      if (widget.space.canManageMembers) {
        pending = await _service.pendingInvitations(widget.space.id);
      }
      if (!mounted) return;
      setState(() {
        _members = members;
        _pending = pending;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _showInviteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String role = 'member';

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDialogHeader(
                  icon: Icons.person_add_alt_1_rounded,
                  title: l10n.spaceInvite,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.spaceInviteEmail,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(
                    labelText: l10n.spaceRole,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'admin', child: Text(l10n.spaceRoleAdmin)),
                    DropdownMenuItem(
                        value: 'manager', child: Text(l10n.spaceRoleManager)),
                    DropdownMenuItem(
                        value: 'member', child: Text(l10n.spaceRoleMember)),
                    DropdownMenuItem(
                        value: 'viewer', child: Text(l10n.spaceRoleViewer)),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? 'member'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppDialogActions(
                  cancelLabel: l10n.cancel,
                  submitLabel: l10n.spaceInvite,
                  onCancel: () => Navigator.pop(dialogContext, false),
                  onSubmit: () async {
                    final email = controller.text.trim();
                    if (email.isEmpty) return;
                    try {
                      await _service.invite(widget.space.id, email, role);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (sent == true) {
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.spaceInviteSent);
      _load();
    }
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.logout_rounded,
                title: l10n.spaceLeave,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.spaceLeaveConfirm,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppDialogActions(
                cancelLabel: l10n.cancel,
                submitLabel: l10n.spaceLeave,
                destructive: true,
                onCancel: () => Navigator.pop(dialogContext, false),
                onSubmit: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _service.leave(widget.space.id);
      await ActiveSpaceStore.clear();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(
          context, AppLocalizations.of(context)!.anErrorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = widget.space.canManageMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.space.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              l10n.spaceMembers,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showInviteDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.spaceInvite),
            )
          : null,
      body: _members == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      for (final m in _members!) _memberTile(m, l10n),
                      if (canManage && _pending.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.spacePendingInvitations,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        for (final inv in _pending) _pendingTile(inv, l10n),
                      ],
                      if (widget.space.myRole != 'owner') ...[
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: _leave,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(l10n.spaceLeave),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  String _roleLabel(String role, AppLocalizations l10n) => switch (role) {
        'owner' => l10n.spaceRoleOwner,
        'admin' => l10n.spaceRoleAdmin,
        'manager' => l10n.spaceRoleManager,
        'viewer' => l10n.spaceRoleViewer,
        _ => l10n.spaceRoleMember,
      };

  Widget _memberTile(SpaceMemberInfo m, AppLocalizations l10n) {
    final initials = (m.firstName.isNotEmpty ? m.firstName[0] : '') +
        (m.lastName.isNotEmpty ? m.lastName[0] : '');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          m.fullName.isEmpty ? m.email : m.fullName,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          _roleLabel(m.role, l10n),
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: (widget.space.canManageMembers && m.role != 'owner')
            ? IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    size: 20, color: AppColors.error),
                tooltip: l10n.spaceRemoveMember,
                onPressed: () async {
                  try {
                    await _service.removeMember(widget.space.id, m.userId);
                    _load();
                  } catch (_) {}
                },
              )
            : null,
      ),
    );
  }

  Widget _pendingTile(Map<String, dynamic> inv, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.schedule_rounded,
            size: 20, color: AppColors.textSecondary),
        title: Text(
          inv['email'] as String? ?? '',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded,
              size: 20, color: AppColors.error),
          tooltip: l10n.spaceRevokeInvitation,
          onPressed: () async {
            try {
              await _service.revokeInvitation(
                  widget.space.id, inv['id'] as int);
              _load();
            } catch (_) {}
          },
        ),
      ),
    );
  }
}
