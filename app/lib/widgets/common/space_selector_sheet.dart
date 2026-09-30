// widgets/common/space_selector_sheet.dart - Sélecteur d'espace (§9) :
// mes espaces, invitations reçues (accepter/refuser), création.
// Phase 1 : changer d'espace change le contexte déclaré (X-Space-Id) ;
// le rattachement des données arrive en Phase 2.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/screens/create_space_screen.dart';
import 'package:epilist/screens/space_members_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpaceSelectorSheet extends StatefulWidget {
  final SpaceService service;

  const SpaceSelectorSheet({super.key, required this.service});

  static Future<void> show(BuildContext context) {
    final service = context.read<SpaceService>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SpaceSelectorSheet(service: service),
    );
  }

  @override
  State<SpaceSelectorSheet> createState() => _SpaceSelectorSheetState();
}

class _SpaceSelectorSheetState extends State<SpaceSelectorSheet> {
  List<Space>? _spaces;
  List<SpaceInvitationInfo> _invitations = const [];
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final spaces = await widget.service.getSpaces();
      final invitations = await widget.service.myInvitations();
      if (!mounted) return;
      setState(() {
        _spaces = spaces;
        _invitations = invitations;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  IconData _iconFor(String type) => switch (type) {
        'household' => Icons.family_restroom_rounded,
        'restaurant' => Icons.restaurant_rounded,
        'organization' => Icons.apartment_rounded,
        _ => Icons.person_rounded,
      };

  Future<void> _select(Space space) async {
    final l10n = AppLocalizations.of(context)!;
    await ActiveSpaceStore.set(space);
    if (!mounted) return;
    Navigator.of(context).pop();
    SmartSnackBarManager.showInfoSnackBar(
      context,
      l10n.spaceSwitched(space.isPersonal ? l10n.spacePersonal : space.name),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _answer(SpaceInvitationInfo inv, bool accept) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.service.answerInvitation(inv, accept);
      await _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeId = ActiveSpaceStore.current.value?.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.spaces,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_spaces == null && !_error)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.anErrorOccurred,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else ...[
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final space in _spaces!)
                      _spaceTile(space, l10n,
                          selected: space.isPersonal
                              ? activeId == null
                              : activeId == space.id),
                    if (_invitations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.spaceMyInvitations,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final inv in _invitations) _invitationTile(inv, l10n),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateSpaceScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.createSpace),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _spaceTile(Space space, AppLocalizations l10n,
      {required bool selected}) {
    final label = space.isPersonal ? l10n.spacePersonal : space.name;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(_iconFor(space.type),
            color: AppColors.primaryDark, size: 22),
        title: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: space.isPersonal
            ? null
            : Text(
                '${space.membersCount} · ${_roleLabel(space.myRole, l10n)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!space.isPersonal)
              IconButton(
                icon: const Icon(Icons.group_outlined,
                    size: 20, color: AppColors.textSecondary),
                tooltip: l10n.spaceMembers,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpaceMembersScreen(space: space),
                    ),
                  );
                },
              ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
        onTap: () => _select(space),
      ),
    );
  }

  String _roleLabel(String? role, AppLocalizations l10n) => switch (role) {
        'owner' => l10n.spaceRoleOwner,
        'admin' => l10n.spaceRoleAdmin,
        'manager' => l10n.spaceRoleManager,
        'viewer' => l10n.spaceRoleViewer,
        _ => l10n.spaceRoleMember,
      };

  Widget _invitationTile(SpaceInvitationInfo inv, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_iconFor(inv.spaceType),
              color: AppColors.primaryDark, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.spaceName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  l10n.spaceInvitedBy(inv.invitedByName),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _answer(inv, false),
            child: Text(l10n.spaceDecline,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => _answer(inv, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(l10n.spaceAccept),
          ),
        ],
      ),
    );
  }
}
