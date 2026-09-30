// screens/create_space_screen.dart - Création d'un espace (Phase 1).
// Onboarding court (§5 du cahier des charges) : le type, le nom, puis
// seulement des informations facultatives (ville, pays).
import 'package:epilist/l10n/app_localizations.dart';

import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  String? _type;
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (_type == null || name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final space = await context.read<SpaceService>().createSpace(
            type: _type!,
            name: name,
            city: _cityController.text.trim(),
            country: _countryController.text.trim().toUpperCase(),
          );
      await ActiveSpaceStore.set(space);
      if (!mounted) return;
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.spaceCreated);
      Navigator.of(context).pop(space);
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.createSpace)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createSpaceQuestion,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _typeCard('household', Icons.family_restroom_rounded,
                l10n.spaceTypeHousehold, l10n.spaceTypeHouseholdDesc),
            const SizedBox(height: AppSpacing.sm),
            _typeCard('restaurant', Icons.restaurant_rounded,
                l10n.spaceTypeRestaurant, l10n.spaceTypeRestaurantDesc),
            const SizedBox(height: AppSpacing.sm),
            _typeCard('organization', Icons.apartment_rounded,
                l10n.spaceTypeOrganization, l10n.spaceTypeOrganizationDesc),
            if (_type != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.spaceName,
                  hintText: _type == 'restaurant'
                      ? l10n.spaceNameHintRestaurant
                      : l10n.spaceNameHintHousehold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.spaceOptionalInfo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.spaceCity,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _countryController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.spaceCountry,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed:
                    _saving || _nameController.text.trim().isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.createSpace),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.spacePhase1Note,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDisabled),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String type, IconData icon, String title, String desc) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
