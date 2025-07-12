// widgets/dialogs/security_settings_dialog.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SecuritySettingsDialog extends StatefulWidget {
  const SecuritySettingsDialog({super.key});

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            _buildIcon(),
            const SizedBox(height: 20),
            _buildTitle(l10n),
            const SizedBox(height: 12),
            _buildDescription(l10n),
            const SizedBox(height: 24),
            _buildSecurityOptions(l10n),
            const SizedBox(height: 24),
            _buildCloseButton(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.security, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.security,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.manageAccountSecurity,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildSecurityOptions(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSecurityOptionTile(
          icon: Icons.lock_outline,
          title: l10n.changePasswordTitle,
          description: l10n.changePasswordDescription,
          color: Colors.blue,
          onTap: _showChangePasswordDialog,
        ),
        const SizedBox(height: 12),
        _buildSecurityOptionTile(
          icon: Icons.delete_forever_outlined,
          title: l10n.deleteAccountTitle,
          description: l10n.deleteAccountDescription,
          color: Colors.red,
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSecurityOptionTile({
    required IconData icon,
    required String title,
    required String description,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: color[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Text(
          l10n.close,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.pop(context); // Fermer le dialogue actuel
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const ChangePasswordDialog(),
          ),
    );
  }

  void _showDeleteAccountDialog() {
    Navigator.pop(context); // Fermer le dialogue actuel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const DeleteAccountDialog(),
          ),
    );
  }
}

// Dialogue modernisé pour changer le mot de passe
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  late final TextEditingController emailController;
  late final TextEditingController codeController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  bool _showCodeStep = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    codeController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordChangeCodeSent) {
          setState(() => _showCodeStep = true);
          SmartSnackBarManager.showMessage(
            context,
            l10n.verificationCodeSentCheckEmail,
            type: SnackBarType.success,
          );
        } else if (state is PasswordChanged) {
          Navigator.pop(context);
          SmartSnackBarManager.showMessage(
            context,
            l10n.passwordChangedSuccessfully,
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
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 20),
                _buildTitle(l10n),
                const SizedBox(height: 12),
                _buildDescription(l10n),
                const SizedBox(height: 24),
                _buildForm(isLoading, l10n),
                const SizedBox(height: 8),
                _buildInfoNote(l10n),
                const SizedBox(height: 24),
                _buildButtons(isLoading, l10n),
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
        color: _showCodeStep ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        _showCodeStep ? Icons.mail_outline : Icons.lock_outline,
        size: 40,
        color: _showCodeStep ? Colors.green[600] : Colors.blue[600],
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      _showCodeStep ? l10n.newPasswordTitle : l10n.changePassword,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      _showCodeStep
          ? l10n.enterCodeAndNewPassword
          : l10n.verificationCodeWillBeSent,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(bool isLoading, AppLocalizations l10n) {
    if (_showCodeStep) {
      return _buildPasswordStep(isLoading, l10n);
    } else {
      return _buildEmailStep(isLoading, l10n);
    }
  }

  Widget _buildEmailStep(bool isLoading, AppLocalizations l10n) {
    return TextField(
      controller: emailController,
      enabled: !isLoading,
      decoration: InputDecoration(
        labelText: l10n.emailAddress,
        prefixIcon: Icon(Icons.email_outlined, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordStep(bool isLoading, AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: codeController,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: l10n.verificationCode,
            prefixIcon: Icon(Icons.security, color: Colors.green[600]),
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
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: _obscurePassword,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            prefixIcon: Icon(Icons.lock_outline, color: Colors.green[600]),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
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
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: l10n.confirmPasswordLabel,
            prefixIcon: Icon(Icons.lock_outline, color: Colors.green[600]),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed:
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
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
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _showCodeStep ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _showCodeStep ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _showCodeStep ? Colors.green[700] : Colors.blue[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showCodeStep
                  ? l10n.passwordMustBeSixCharacters
                  : l10n.youWillReceiveVerificationCode,
              style: TextStyle(
                fontSize: 12,
                color: _showCodeStep ? Colors.green[700] : Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool isLoading, AppLocalizations l10n) {
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
            onPressed: isLoading ? null : _handleAction,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _showCodeStep ? Colors.green[600] : Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  _showCodeStep ? Colors.green[300] : Colors.blue[300],
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
                      _showCodeStep ? l10n.modify : l10n.send,
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

  void _handleAction() {
    if (_showCodeStep) {
      _changePassword();
    } else {
      _requestCode();
    }
  }

  void _requestCode() {
    final l10n = AppLocalizations.of(context)!;
    final email = emailController.text.trim();

    if (email.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.emailRequired,
        type: SnackBarType.warning,
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.emailFormatInvalid,
        type: SnackBarType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
  }

  void _changePassword() {
    final l10n = AppLocalizations.of(context)!;
    final code = codeController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.allFieldsRequired,
        type: SnackBarType.warning,
      );
      return;
    }

    if (code.length != 6) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.codeMustBeSixDigits,
        type: SnackBarType.warning,
      );
      return;
    }

    if (password.length < 6) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.passwordMinSixChars,
        type: SnackBarType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.passwordsDoNotMatch,
        type: SnackBarType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyPasswordChangeCode(
        email: emailController.text.trim(),
        code: code,
        newPassword: password,
      ),
    );
  }
}
