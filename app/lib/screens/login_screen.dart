// screens/login_screen.dart - Connexion : sobre et directe. Les styles
// viennent du design system (app_theme.dart), l'écran n'en redéfinit aucun.
import 'package:epilist/theme/app_theme.dart';
import 'dart:io';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/password_change_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/services/sso_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _anyLoading => _isLoading || _isGoogleLoading || _isAppleLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(l10n),
                const SizedBox(height: AppSpacing.xl),
                _buildLoginForm(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildDivider(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildSSOButtons(l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildFooterLinks(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shopping_cart_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.login,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.manageGroceryListsEasily,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.mail_outline, size: 20),
            ),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return l10n.pleaseEnterEmail;
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!.trim())) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
            onFieldSubmitted: (_) => _login(),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterPassword;
              if (value!.length < 3) return l10n.passwordMinThreeCharacters;
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _showForgotPasswordDialog,
              child: Text(l10n.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _anyLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l10n.login),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppLocalizations l10n) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.or,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSSOButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _anyLoading ? null : _signInWithGoogle,
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.surface),
            icon: _isGoogleLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const Icon(
                    Icons.g_mobiledata,
                    size: 26,
                    color: Color(0xFF4285F4),
                  ),
            label: Text(
              _isGoogleLoading ? '…' : l10n.continueWithGoogle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: AppSpacing.sm + 4),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _anyLoading ? null : _signInWithApple,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              icon: _isAppleLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.apple, size: 20),
              label: Text(
                _isAppleLoading ? '…' : l10n.continueWithApple,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterLinks(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.dontHaveAccount,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }

  // ===========================================================================
  // LOGIQUE (inchangée par la refonte visuelle)
  // ===========================================================================

  void _handleAuthState(BuildContext context, AuthState state) {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      if (state is SSOLoading) {
        _isGoogleLoading = state.provider == 'google';
        _isAppleLoading = state.provider == 'apple';
        _isLoading = false;
      } else if (state is AuthLoading) {
        _isLoading = true;
        _isGoogleLoading = false;
        _isAppleLoading = false;
      } else {
        _isLoading = false;
        _isGoogleLoading = false;
        _isAppleLoading = false;
      }
    });

    switch (state.runtimeType) {
      case AuthSuccess:
        final authState = state as AuthSuccess;
        SmartSnackBarManager.clearAll(context);

        String message;
        if (authState.authMethod == 'google') {
          if (authState.message?.contains('créé') == true) {
            message = 'Compte Google créé et connecté avec succès !';
          } else {
            message = 'Connexion Google réussie !';
          }
        } else if (authState.authMethod == 'apple') {
          message = 'Connexion Apple réussie !';
        } else {
          message = l10n.loginSuccessful;
        }

        SmartSnackBarManager.showSuccessSnackBar(context, message);
        _navigateToHome();
        break;

      case AuthFailure:
        final failure = state as AuthFailure;
        SmartSnackBarManager.showErrorSnackBar(context, failure.error);
        break;

      case SSOError:
        final ssoError = state as SSOError;
        String errorMessage = ssoError.error;

        if (errorMessage.contains('Aucun compte trouvé')) {
          errorMessage =
              'Aucun compte trouvé avec cet email Google. Création automatique en cours...';
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isLoading) {
              _signInWithGoogle();
            }
          });
        } else if (errorMessage.contains('Un compte existe déjà')) {
          errorMessage =
              'Un compte existe avec cet email. Connectez-vous d\'abord avec votre mot de passe pour lier votre compte Google.';
          if (ssoError.details?.isNotEmpty == true) {
            try {
              final email = _extractEmailFromError(ssoError.details!);
              if (email.isNotEmpty) {
                _emailController.text = email;
              }
            } catch (e) {
              // Ignorer les erreurs d'extraction
            }
          }
        } else if (errorMessage.contains('network') ||
            errorMessage.contains('réseau')) {
          errorMessage =
              'Problème de connexion. Vérifiez votre internet et réessayez.';
        }

        SmartSnackBarManager.showErrorSnackBar(context, errorMessage);
        break;

      case EmailVerificationRequired:
        final emailState = state as EmailVerificationRequired;
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.emailMustBeVerified,
        );
        _navigateToEmailVerification(emailState.email);
        break;
    }
  }

  String _extractEmailFromError(String errorDetails) {
    try {
      final emailRegex = RegExp(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      );
      final match = emailRegex.firstMatch(errorDetails);
      return match?.group(0) ?? '';
    } catch (e) {
      return '';
    }
  }

  void _signInWithGoogle() async {
    if (_isLoading) return;
    try {
      context.read<AuthBloc>().add(const GoogleSignInRequested());
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de la connexion Google: ${e.toString()}',
      );
    }
  }

  void _signInWithApple() async {
    try {
      final isAvailable = await SSOService.isAppleSignInAvailable();
      if (!isAvailable) {
        String errorMessage = Platform.isIOS
            ? 'Apple Sign-In non disponible sur cet appareil'
            : 'Apple Sign-In est uniquement disponible sur iOS';
        SmartSnackBarManager.showErrorSnackBar(context, errorMessage);
        return;
      }
      context.read<AuthBloc>().add(const AppleSignInRequested());
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de la connexion Apple',
      );
    }
  }

  void _login() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginButtonPressed(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 22,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(child: Text(l10n.forgotPassword)),
          ],
        ),
        content: Text(l10n.resetPasswordSecurely),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PasswordChangeScreen(
                    initialEmail: _emailController.text.trim().isNotEmpty
                        ? _emailController.text.trim()
                        : null,
                  ),
                ),
              );
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  void _navigateToEmailVerification(String email) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: email,
              fromRegistration: false,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
