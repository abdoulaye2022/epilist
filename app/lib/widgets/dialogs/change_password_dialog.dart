// widgets/dialogs/change_password_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

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
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _showCodeStep
                    ? 'Nouveau mot de passe'
                    : 'Changer le mot de passe',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Traitement en cours...'),
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
            if (!_showCodeStep) ..._buildEmailStep(),
            if (_showCodeStep) ..._buildPasswordStep(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
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
            const Text(
              'Un code de vérification sera envoyé à votre adresse email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Adresse email *',
          hintText: 'votre@email.com',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.email_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'L\'email est requis';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Format d\'email invalide';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildPasswordStep() {
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
            const Text(
              'Code de vérification envoyé !',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vérifiez votre boîte email et entrez le code ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Code de vérification *',
          hintText: 'Code à 6 chiffres',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.security),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Le code est requis';
          }
          if (value.length != 6) {
            return 'Le code doit contenir 6 chiffres';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Nouveau mot de passe *',
          hintText: 'Minimum 6 caractères',
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
            return 'Le mot de passe est requis';
          }
          if (value.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      TextFormField(
        controller: _confirmPasswordController,
        decoration: InputDecoration(
          labelText: 'Confirmer le mot de passe *',
          hintText: 'Retapez le mot de passe',
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
            return 'La confirmation est requise';
          }
          if (value != _passwordController.text) {
            return 'Les mots de passe ne correspondent pas';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),

      if (!_showCodeStep)
        ElevatedButton(
          onPressed: _isLoading ? null : _requestCode,
          child: const Text('Envoyer le code'),
        ),

      if (_showCodeStep)
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: const Text('Changer le mot de passe'),
        ),
    ];
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    setState(() => _isLoading = false);

    if (state is PasswordChangeCodeSent) {
      setState(() => _showCodeStep = true);

      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Code de vérification envoyé ! Vérifiez votre email.',
      );
    } else if (state is PasswordChanged) {
      Navigator.pop(context);

      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Mot de passe modifié avec succès !',
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
