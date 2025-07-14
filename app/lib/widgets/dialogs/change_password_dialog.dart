// widgets/dialogs/change_password_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showCodeStep = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener:
          (context, state) => _handleAuthStateChanges(context, state, l10n),
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _showCodeStep ? l10n.newPassword : l10n.changePassword,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: _buildContent(l10n),
        actions: _buildActions(l10n),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.processingInProgress),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showCodeStep) ..._buildEmailStep(l10n),
            if (_showCodeStep) ..._buildPasswordStep(l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep(AppLocalizations l10n) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
            const SizedBox(height: 8),
            Text(
              l10n.verificationCodeWillBeSent,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: l10n.emailAddressRequired,
          hintText: l10n.emailHint,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.emailRequired;
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return l10n.invalidEmailFormat;
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildPasswordStep(AppLocalizations l10n) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.mail_outline, color: Colors.green[600], size: 24),
            const SizedBox(height: 8),
            Text(
              l10n.verificationCodeSent,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.checkEmailAndEnterCode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _codeController,
        decoration: InputDecoration(
          labelText: l10n.verificationCodeRequired,
          hintText: l10n.sixDigitCodeHint,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.security),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.codeRequired;
          }
          if (value.length != 6) {
            return l10n.codeMustBeSixDigits;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: l10n.newPasswordRequired,
          hintText: l10n.minimumSixCharacters,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.passwordRequired;
          }
          if (value.length < 6) {
            return l10n.passwordMinSixChars;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        decoration: InputDecoration(
          labelText: l10n.confirmNewPassword,
          hintText: l10n.retypePassword,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
          ),
        ),
        obscureText: _obscureConfirmPassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.confirmationRequired;
          }
          if (value != _passwordController.text) {
            return l10n.passwordsDoNotMatch;
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildActions(AppLocalizations l10n) {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text(l10n.cancel),
      ),
      if (!_showCodeStep)
        ElevatedButton(
          onPressed: _isLoading ? null : _requestCode,
          child: Text(l10n.sendCode),
        ),
      if (_showCodeStep)
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: Text(l10n.changePasswordButton),
        ),
    ];
  }

  void _handleAuthStateChanges(
    BuildContext context,
    AuthState state,
    AppLocalizations l10n,
  ) {
    setState(() => _isLoading = false);

    if (state is PasswordChangeCodeSent) {
      setState(() => _showCodeStep = true);
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.verificationCodeSentCheckEmail,
      );
    } else if (state is PasswordChanged) {
      Navigator.pop(context);
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.passwordChangedSuccessfully,
      );
    } else if (state is AuthFailure) {
      SmartSnackBarManager.showErrorSnackBar(context, state.error);
    }
  }

  void _requestCode() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      RequestPasswordChangeCode(_emailController.text.trim()),
    );
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      VerifyPasswordChangeCode(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      ),
    );
  }
}
