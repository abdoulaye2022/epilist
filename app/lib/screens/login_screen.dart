// screens/login_screen.dart - VERSION AVEC DIALOG MODERNE
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ✅ HEADER SIMPLIFIÉ
                _buildHeader(l10n),

                const SizedBox(height: 40),

                // ✅ BOUTONS SSO NORMAUX
                _buildSSOButtons(l10n),

                const SizedBox(height: 24),

                // ✅ DIVIDER NORMAL
                _buildDivider(l10n),

                const SizedBox(height: 24),

                // ✅ FORMULAIRE AVEC BORDURES VERTES FINES
                _buildLoginForm(l10n),

                const SizedBox(height: 24),

                // ✅ LIENS SIMPLIFIÉS
                _buildFooterLinks(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ GESTION D'ÉTAT SIMPLIFIÉE
  void _handleAuthState(BuildContext context, AuthState state) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = state is AuthLoading || state is SSOLoading);

    switch (state.runtimeType) {
      case AuthSuccess:
        final authState = state as AuthSuccess;
        SmartSnackBarManager.clearAll(context);

        String message =
            authState.authMethod == 'google'
                ? 'Connexion Google réussie !'
                : authState.authMethod == 'apple'
                ? 'Connexion Apple réussie !'
                : l10n.loginSuccessful;

        SmartSnackBarManager.showSuccessSnackBar(context, message);
        _navigateToHome();
        break;

      case AuthFailure:
        final failure = state as AuthFailure;
        SmartSnackBarManager.showErrorSnackBar(context, failure.error);
        break;

      case SSOError:
        final ssoError = state as SSOError;
        SmartSnackBarManager.showErrorSnackBar(context, ssoError.error);
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

  // ✅ HEADER SIMPLIFIÉ
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        // Logo simple sans background
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.transparent, // ✅ Background transparent
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => Icon(
                  Icons.shopping_cart_rounded,
                  size: 40,
                  color: Colors.green[600],
                ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'EpiList',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.manageGroceryListsEasily,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ BOUTONS SSO NORMAUX
  Widget _buildSSOButtons(AppLocalizations l10n) {
    return Column(
      children: [
        // Bouton Google normal
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon:
                _isLoading
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[600],
                      ),
                    )
                    : Image.asset(
                      'assets/images/google_logo.png',
                      width: 16,
                      height: 16,
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.g_mobiledata,
                            color: Colors.red[600],
                            size: 20,
                          ),
                    ),
            label: Text(
              _isLoading ? 'Connexion...' : l10n.continueWithGoogle,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Bouton Apple normal (iOS seulement)
        // if (Platform.isIOS) ...[
        //   const SizedBox(height: 12),
        //   SizedBox(
        //     width: double.infinity,
        //     height: 48,
        //     child: ElevatedButton.icon(
        //       onPressed: _isLoading ? null : _signInWithApple,
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.black,
        //         foregroundColor: Colors.white,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //       ),
        //       icon:
        //           _isLoading
        //               ? const SizedBox(
        //                 width: 16,
        //                 height: 16,
        //                 child: CircularProgressIndicator(
        //                   strokeWidth: 2,
        //                   color: Colors.white,
        //                 ),
        //               )
        //               : const Icon(Icons.apple, size: 18),
        //       label: Text(
        //         _isLoading ? 'Connexion...' : l10n.continueWithApple,
        //         style: const TextStyle(
        //           fontSize: 15,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }

  // ✅ DIVIDER NORMAL
  Widget _buildDivider(AppLocalizations l10n) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.or, style: TextStyle(color: Colors.grey[600])),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  // ✅ FORMULAIRE AVEC BORDURES VERTES FINES UNIQUEMENT
  Widget _buildLoginForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email avec bordure verte fine
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[600]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return l10n.pleaseEnterEmail;
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!.trim())) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password avec bordure verte fine
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[600]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onFieldSubmitted: (_) => _login(),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterPassword;
              if (value!.length < 3) return l10n.passwordMinThreeCharacters;
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _showForgotPasswordDialog,
              child: Text(
                l10n.forgotPassword,
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bouton de connexion normal
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        l10n.login,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ LIENS DU FOOTER SIMPLIFIÉS
  Widget _buildFooterLinks(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.dontHaveAccount,
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  ),
          child: Text(
            l10n.createAccount,
            style: TextStyle(
              color: Colors.green[600],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ MÉTHODES SIMPLIFIÉES
  void _signInWithGoogle() async {
    try {
      context.read<AuthBloc>().add(const GoogleSignInRequested());
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de la connexion Google',
      );
    }
  }

  void _signInWithApple() async {
    try {
      final isAvailable = await SSOService.isAppleSignInAvailable();
      if (!isAvailable) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          'Apple Sign-In non disponible',
        );
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

  // ✅ DIALOG MODERNE POUR MOT DE PASSE OUBLIÉ
  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône principale
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: Colors.orange[600],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Titre
                    Text(
                      l10n.forgotPassword,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      l10n.resetPasswordSecurely,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
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
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PasswordChangeScreen(
                                        initialEmail:
                                            _emailController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? _emailController.text.trim()
                                                : null,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.security, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.reset,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
            builder:
                (_) => EmailVerificationScreen(
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
