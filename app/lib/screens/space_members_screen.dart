// screens/space_members_screen.dart - Membres d'un espace (Phase 1) :
// liste, invitation par email, invitations en attente (révocables),
// et sortie de l'espace. Les droits sont vérifiés côté serveur ; l'UI
// masque simplement ce que le rôle courant ne permet pas.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/widgets/common/app_card.dart';

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
    _members = ScreenCache.read<List<SpaceMemberInfo>>(
      'space_members_${widget.space.id}',
    );
    _pending =
        ScreenCache.read<List<Map<String, dynamic>>>(
          'space_pending_${widget.space.id}',
        ) ??
        const [];
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
      ScreenCache.write('space_members_${widget.space.id}', members);
      ScreenCache.write('space_pending_${widget.space.id}', pending);
      setState(() {
        _members = members;
        _pending = pending;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_members == null) setState(() => _error = true);
    }
  }

  Future<void> _showInviteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String role = 'member';
    // Un drapeau plutot qu'une valeur de retour : refermer le panneau
    // en touchant a cote rend `null` lui aussi, et on annoncerait une
    // erreur a qui a simplement renonce.
    var echec = false;

    // La planche demande que le role soit EXPLIQUE, pas seulement
    // nomme : « Peut modifier les listes » / « Lecture seulement ».
    // « Gestionnaire » ne dit rien a qui n'a pas lu la documentation.
    String ceQuePermet(String r) => switch (r) {
      'admin' => l10n.spaceRoleAdminWhat,
      'manager' => l10n.spaceRoleManagerWhat,
      'viewer' => l10n.spaceRoleViewerWhat,
      _ => l10n.spaceRoleMemberWhat,
    };

    final sent = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setLocal) => Dialog(
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
                        // La planche demande « nom, courriel ou
                        // telephone ». Le nom vient en premier : c'est
                        // par lui que le courriel d'invitation dira
                        // « Bonjour Sara » au lieu de « Bonjour ».
                        TextField(
                          controller: nomCtrl,
                          textCapitalization: TextCapitalization.words,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: l10n.spaceInviteName,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.spaceInviteEmail,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: telCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.spaceInvitePhone,
                            // Dire la verite : le numero est garde pour
                            // que l'invitant puisse relancer la personne
                            // lui-meme, mais rien ne part par SMS.
                            helperText: l10n.spaceInvitePhoneHint,
                            helperMaxLines: 3,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: InputDecoration(
                            labelText: l10n.spaceRole,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text(l10n.spaceRoleAdmin),
                            ),
                            DropdownMenuItem(
                              value: 'manager',
                              child: Text(l10n.spaceRoleManager),
                            ),
                            DropdownMenuItem(
                              value: 'member',
                              child: Text(l10n.spaceRoleMember),
                            ),
                            DropdownMenuItem(
                              value: 'viewer',
                              child: Text(l10n.spaceRoleViewer),
                            ),
                          ],
                          onChanged:
                              (v) => setLocal(() => role = v ?? 'member'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          ceQuePermet(role),
                          style: TextStyle(
                            fontSize: 16.5,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
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
                              await _service.invite(
                                widget.space.id,
                                email,
                                role,
                                name: nomCtrl.text,
                                phone: telCtrl.text,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (_) {
                              // Sans ceci, un envoi qui echoue refermait
                              // le panneau en silence : on croyait avoir
                              // annule.
                              echec = true;
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
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.spaceInviteSentTo(
          nomCtrl.text.trim().isNotEmpty
              ? nomCtrl.text.trim()
              : controller.text.trim(),
        ),
      );
      _load();
    } else if (echec) {
      SmartSnackBarManager.showErrorSnackBar(context, l10n.spaceInviteFailed);
    }
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Dialog(
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
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
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
        context,
        AppLocalizations.of(context)!.anErrorOccurred,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = widget.space.canManageMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.spaceMembers, subtitle: widget.space.name),
      floatingActionButton:
          canManage
              ? FloatingActionButton.extended(
                onPressed: _showInviteDialog,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l10n.spaceInvite),
              )
              : null,
      body:
          _members == null && !_error
              ? const Center(child: CircularProgressIndicator())
              : _error
              ? Center(
                child: Text(
                  l10n.anErrorOccurred,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
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
                        style: TextStyle(
                          fontSize: 16,
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
                          side: BorderSide(color: AppColors.error),
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
    final initials =
        (m.firstName.isNotEmpty ? m.firstName[0] : '') +
        (m.lastName.isNotEmpty ? m.lastName[0] : '');
    return AppCard.tight(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        // Material propre au ListTile : le fond du conteneur parent
        // masquerait sinon son fond et ses effets de pression
        // (assertion « ink splashes may be invisible »).
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            m.fullName.isEmpty ? m.email : m.fullName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            _roleLabel(m.role, l10n),
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          trailing:
              (widget.space.canManageMembers && m.role != 'owner')
                  ? IconButton(
                    icon: Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: AppColors.error,
                    ),
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
      ),
    );
  }

  Widget _pendingTile(Map<String, dynamic> inv, AppLocalizations l10n) {
    return AppCard.tight(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        // Material propre au ListTile : le fond du conteneur parent
        // masquerait sinon son fond et ses effets de pression
        // (assertion « ink splashes may be invisible »).
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          leading: Icon(
            Icons.schedule_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          title: Text(
            inv['email'] as String? ?? '',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: AppColors.error),
            tooltip: l10n.spaceRevokeInvitation,
            onPressed: () async {
              try {
                await _service.revokeInvitation(
                  widget.space.id,
                  inv['id'] as int,
                );
                _load();
              } catch (_) {}
            },
          ),
        ),
      ),
    );
  }
}
