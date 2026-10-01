// screens/two_factor_screen.dart - Deuxième étape de connexion quand
// l'utilisateur a activé la vérification en deux étapes (par email).
// Un code à 6 chiffres vient d'être envoyé ; il vaut 10 minutes et ne
// sert qu'une fois. Le serveur reste seul juge : l'écran se contente de
// transmettre le code.
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/main_shell.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TwoFactorScreen extends StatefulWidget {
  final String email;
  final String? password; // pour renvoyer un code sans ressaisie

  const TwoFactorScreen({super.key, required this.email, this.password});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _loading = true);
    try {
      final service = context.read<AuthService>();
      await service.verifyTwoFactor(widget.email, code);

      // Jetons en place : on reprend le parcours normal de connexion.
      final user = await service.getCurrentUser();
      if (!mounted) return;
      if (user != null) {
        context.read<AuthBloc>().add(UpdateUserData(user));
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on AuthenticationException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SmartSnackBarManager.showErrorSnackBar(
          context, e.code == 'INVALID_CODE' ? l10n.twoFactorInvalidCode : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  /// Renvoi : une nouvelle tentative de connexion régénère un code.
  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.password == null) {
      SmartSnackBarManager.showInfoSnackBar(context, l10n.twoFactorResendHint);
      return;
    }
    setState(() => _resending = true);
    try {
      await context.read<AuthService>().login(widget.email, widget.password!);
    } on AuthenticationException catch (e) {
      // TWO_FACTOR_REQUIRED = comportement attendu : un code est reparti.
      if (!mounted) return;
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        e.code == 'TWO_FACTOR_REQUIRED'
            ? l10n.twoFactorCodeSent
            : l10n.anErrorOccurred,
      );
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.twoFactorTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 30, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.twoFactorSentTo(widget.email),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                enabled: !_loading,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '······',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (v) {
                  if (v.length == 6 && !_loading) _submit();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.twoFactorExpires,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDisabled),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.login),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? l10n.twoFactorResending : l10n.twoFactorResend,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
