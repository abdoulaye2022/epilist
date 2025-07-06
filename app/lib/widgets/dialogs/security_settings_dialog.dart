// widgets/dialogs/security_settings_dialog.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
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
            _buildTitle(),
            const SizedBox(height: 12),
            _buildDescription(),
            const SizedBox(height: 24),
            _buildSecurityOptions(),
            const SizedBox(height: 24),
            _buildCloseButton(),
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

  Widget _buildTitle() {
    return const Text(
      'Sécurité',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Gérez la sécurité de votre compte',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildSecurityOptions() {
    return Column(
      children: [
        _buildSecurityOptionTile(
          icon: Icons.lock_outline,
          title: 'Changer le mot de passe',
          description: 'Modifiez votre mot de passe actuel',
          color: Colors.blue,
          onTap: _showChangePasswordDialog,
        ),
        const SizedBox(height: 12),
        _buildSecurityOptionTile(
          icon: Icons.delete_forever_outlined,
          title: 'Supprimer le compte',
          description: 'Supprimez définitivement votre compte',
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

  Widget _buildCloseButton() {
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
          'Fermer',
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordChangeCodeSent) {
          setState(() => _showCodeStep = true);
          SmartSnackBarManager.showMessage(
            context,
            'Code de vérification envoyé ! Vérifiez votre email.',
            type: SnackBarType.success,
          );
        } else if (state is PasswordChanged) {
          Navigator.pop(context);
          SmartSnackBarManager.showMessage(
            context,
            'Mot de passe modifié avec succès !',
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
                _buildTitle(),
                const SizedBox(height: 12),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildForm(isLoading),
                const SizedBox(height: 8),
                _buildInfoNote(),
                const SizedBox(height: 24),
                _buildButtons(isLoading),
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

  Widget _buildTitle() {
    return Text(
      _showCodeStep ? 'Nouveau mot de passe' : 'Changer le mot de passe',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      _showCodeStep
          ? 'Entrez le code et votre nouveau mot de passe'
          : 'Un code de vérification sera envoyé par email',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(bool isLoading) {
    if (_showCodeStep) {
      return _buildPasswordStep(isLoading);
    } else {
      return _buildEmailStep(isLoading);
    }
  }

  Widget _buildEmailStep(bool isLoading) {
    return TextField(
      controller: emailController,
      enabled: !isLoading,
      decoration: InputDecoration(
        labelText: 'Adresse email',
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

  Widget _buildPasswordStep(bool isLoading) {
    return Column(
      children: [
        TextField(
          controller: codeController,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Code de vérification',
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
            labelText: 'Nouveau mot de passe',
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
            labelText: 'Confirmer le mot de passe',
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

  Widget _buildInfoNote() {
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
                  ? 'Le mot de passe doit contenir au moins 6 caractères'
                  : 'Vous recevrez un code de vérification à 6 chiffres',
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

  Widget _buildButtons(bool isLoading) {
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
              'Annuler',
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
                      _showCodeStep ? 'Modifier' : 'Envoyer',
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
    final email = emailController.text.trim();

    if (email.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        'L\'email est requis',
        type: SnackBarType.warning,
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      SmartSnackBarManager.showMessage(
        context,
        'Format d\'email invalide',
        type: SnackBarType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
  }

  void _changePassword() {
    final code = codeController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        'Tous les champs sont obligatoires',
        type: SnackBarType.warning,
      );
      return;
    }

    if (code.length != 6) {
      SmartSnackBarManager.showMessage(
        context,
        'Le code doit contenir 6 chiffres',
        type: SnackBarType.warning,
      );
      return;
    }

    if (password.length < 6) {
      SmartSnackBarManager.showMessage(
        context,
        'Le mot de passe doit contenir au moins 6 caractères',
        type: SnackBarType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      SmartSnackBarManager.showMessage(
        context,
        'Les mots de passe ne correspondent pas',
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

// Dialogue pour supprimer le compte - AVEC ÉTAPES
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  late final TextEditingController reasonController;
  late final TextEditingController codeController;

  bool _showCodeStep = false;

  @override
  void initState() {
    super.initState();
    reasonController = TextEditingController();
    codeController = TextEditingController();
  }

  @override
  void dispose() {
    reasonController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AccountDeletionCodeSent) {
          setState(() => _showCodeStep = true);
          SmartSnackBarManager.showMessage(
            context,
            'Code de suppression envoyé ! Vérifiez votre email.',
            type: SnackBarType.success,
          );
        } else if (state is AccountDeletionConfirmed) {
          Navigator.pop(context);
          SmartSnackBarManager.showMessage(
            context,
            'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action.',
            type: SnackBarType.info,
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
                _buildTitle(),
                const SizedBox(height: 12),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildForm(isLoading),
                const SizedBox(height: 8),
                _buildWarningNote(),
                const SizedBox(height: 24),
                _buildButtons(isLoading),
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
        color: _showCodeStep ? Colors.orange[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        _showCodeStep ? Icons.mail_outline : Icons.delete_forever,
        size: 40,
        color: _showCodeStep ? Colors.orange[600] : Colors.red[600],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _showCodeStep ? 'Confirmer la suppression' : 'Supprimer le compte',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      _showCodeStep
          ? 'Entrez le code reçu par email pour confirmer'
          : 'Cette action est irréversible. Toutes vos données seront supprimées.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(bool isLoading) {
    if (_showCodeStep) {
      return _buildCodeStep(isLoading);
    } else {
      return _buildReasonStep(isLoading);
    }
  }

  Widget _buildReasonStep(bool isLoading) {
    return TextField(
      controller: reasonController,
      maxLines: 3,
      enabled: !isLoading,
      decoration: InputDecoration(
        labelText: 'Raison de la suppression (optionnel)',
        prefixIcon: Icon(Icons.comment_outlined, color: Colors.red[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildCodeStep(bool isLoading) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Code envoyé ! Vérifiez votre boîte email.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: codeController,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Code de suppression',
            prefixIcon: Icon(Icons.security, color: Colors.orange[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
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
      ],
    );
  }

  Widget _buildWarningNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _showCodeStep ? Colors.orange[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _showCodeStep ? Colors.orange[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: _showCodeStep ? Colors.orange[700] : Colors.red[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showCodeStep
                  ? 'Cette action est définitive. Votre compte sera supprimé dans 30 jours.'
                  : 'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action pendant cette période.',
              style: TextStyle(
                fontSize: 12,
                color: _showCodeStep ? Colors.orange[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool isLoading) {
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
              'Annuler',
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
                  _showCodeStep ? Colors.orange[600] : Colors.red[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  _showCodeStep ? Colors.orange[300] : Colors.red[300],
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
                      _showCodeStep ? 'Confirmer' : 'Envoyer',
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
      _confirmDeletion();
    } else {
      _requestDeletionCode();
    }
  }

  void _requestDeletionCode() {
    final reason = reasonController.text.trim();

    context.read<AuthBloc>().add(
      RequestAccountDeletion(reason: reason.isEmpty ? null : reason),
    );
  }

  void _confirmDeletion() {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      SmartSnackBarManager.showMessage(
        context,
        'Le code est requis',
        type: SnackBarType.warning,
      );
      return;
    }

    if (code.length != 6) {
      SmartSnackBarManager.showMessage(
        context,
        'Le code doit contenir 6 chiffres',
        type: SnackBarType.warning,
      );
      return;
    }

    final reason = reasonController.text.trim();

    context.read<AuthBloc>().add(
      ConfirmAccountDeletion(
        deletionCode: code,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }
}
