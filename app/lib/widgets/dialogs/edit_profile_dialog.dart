import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProfileDialog extends StatefulWidget {
  final User currentUser;

  const EditProfileDialog({super.key, required this.currentUser});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
      text: widget.currentUser.firstName,
    );
    lastNameController = TextEditingController(
      text: widget.currentUser.lastName,
    );
    emailController = TextEditingController(text: widget.currentUser.email);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          Navigator.pop(context);
          SmartSnackBarManager.showMessage(
            context,
            l10n.profileUpdatedSuccessfully,
            type: SnackBarType.success,
          );
        } else {
          SmartSnackBarManager.showForState(context, state);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIcon(),
                        const SizedBox(height: 20),
                        _buildTitle(l10n),
                        const SizedBox(height: 12),
                        _buildDescription(l10n),
                        const SizedBox(height: 24),
                        _buildForm(l10n, isLoading),
                        const SizedBox(height: 8),
                        _buildEmailNote(l10n),
                        const SizedBox(height: 24),
                        _buildButtons(l10n, isLoading),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.person_rounded, size: 40, color: Colors.green[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.editProfile,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.modifyPersonalInformation,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(AppLocalizations l10n, bool isLoading) {
    return Column(
      children: [
        _buildTextField(
          l10n: l10n,
          controller: firstNameController,
          label: l10n.firstName,
          icon: Icons.person_outline,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          l10n: l10n,
          controller: lastNameController,
          label: l10n.lastName,
          icon: Icons.badge_outlined,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          l10n: l10n,
          controller: emailController,
          label: l10n.email,
          icon: Icons.email_outlined,
          enabled: false,
          isDisabled: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    bool isDisabled = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDisabled ? Colors.grey[400] : Colors.green[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: isDisabled ? Colors.grey[100] : Colors.grey[50],
      ),
      enabled: enabled,
    );
  }

  Widget _buildEmailNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.emailCannotBeModified,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(AppLocalizations l10n, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
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
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _saveProfile(l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green[300],
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
                      l10n.save,
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

  void _saveProfile(AppLocalizations l10n) {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.firstNameAndLastNameRequired,
        type: SnackBarType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(
      UpdateProfile(firstName: firstName, lastName: lastName),
    );
  }
}
