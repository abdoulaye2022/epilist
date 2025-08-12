// screens/signup_screen.dart - VERSION CORRIGÉE AVEC BORDURES VERTES FINES
import 'dart:io';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/services/sso_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ HEADER SIMPLIFIÉ
                _buildHeader(l10n),

                const SizedBox(height: 24),

                // ✅ BOUTONS SSO NORMAUX
                _buildSSOButtons(l10n),

                const SizedBox(height: 24),

                // ✅ DIVIDER NORMAL
                _buildDivider(l10n),

                const SizedBox(height: 24),

                // ✅ FORMULAIRE AVEC BORDURES VERTES FINES
                _buildSignUpForm(l10n),

                const SizedBox(height: 24),

                // ✅ FOOTER SIMPLIFIÉ
                _buildFooter(l10n),
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
      case EmailConfirmationRequired:
        final emailState = state as EmailConfirmationRequired;
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          l10n.accountCreatedSuccessfully(
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
          ),
        );
        _navigateToEmailVerification(emailState.email);
        break;

      case SSORegistrationSuccess:
        final ssoState = state as SSORegistrationSuccess;
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          'Compte ${ssoState.provider} créé avec succès !',
        );
        _navigateToLogin();
        break;

      case AuthSuccess:
        final authState = state as AuthSuccess;
        String message =
            authState.authMethod == 'google'
                ? 'Compte Google créé avec succès !'
                : authState.authMethod == 'apple'
                ? 'Compte Apple créé avec succès !'
                : 'Compte créé et connecté !';

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

      case RegistrationSuccess:
        _navigateToLogin();
        break;
    }
  }

  // ✅ HEADER SIMPLIFIÉ
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createAccount,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.joinEpiListToManage,
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ✅ BOUTONS SSO NORMAUX
  Widget _buildSSOButtons(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.quickSignupWithSSO,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Bouton Google normal
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signUpWithGoogle,
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
              _isLoading ? 'Création...' : l10n.signUpWithGoogle,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Bouton Apple normal (iOS seulement)
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _signUpWithApple,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.apple, size: 18),
              label: Text(
                _isLoading ? 'Création...' : l10n.signUpWithApple,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Disclaimer SSO normal
        Text(
          l10n.ssoSignupDisclaimer,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
          textAlign: TextAlign.center,
        ),
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
  Widget _buildSignUpForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Prénom et Nom avec bordures vertes fines
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: l10n.firstName,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true)
                      return l10n.firstNameRequired;
                    if (value!.trim().length < 2) return l10n.tooShort;
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: l10n.lastName,
                  icon: Icons.person,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true)
                      return l10n.lastNameRequired;
                    if (value!.trim().length < 2) return l10n.tooShort;
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email avec bordure verte fine
          _buildTextField(
            controller: _emailController,
            label: l10n.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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

          // Mot de passe avec bordure verte fine
          _buildTextField(
            controller: _passwordController,
            label: l10n.password,
            icon: Icons.lock_outline,
            obscureText: _isObscure,
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
              onPressed:
                  _isLoading
                      ? null
                      : () => setState(() => _isObscure = !_isObscure),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterPassword;
              if (value!.length < 6) return l10n.atLeastSixCharacters;
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirmation mot de passe avec bordure verte fine
          _buildTextField(
            controller: _confirmPasswordController,
            label: l10n.confirmPassword,
            icon: Icons.lock_outline,
            obscureText: _isConfirmObscure,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed:
                  _isLoading
                      ? null
                      : () => setState(
                        () => _isConfirmObscure = !_isConfirmObscure,
                      ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.confirmYourPassword;
              if (value != _passwordController.text)
                return l10n.passwordsDifferent;
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Accepter les conditions normal
          _buildTermsCheckbox(l10n),

          const SizedBox(height: 24),

          // Bouton d'inscription normal
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_isLoading || !_acceptTerms) ? null : _signUp,
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
                        l10n.createMyAccount,
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

  // ✅ WIDGET TEXTFIELD AVEC BORDURES VERTES FINES ET PLACEHOLDERS NORMAUX
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon), // Couleur par défaut
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.green[400]!,
          ), // Bordure verte fine
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.green[300]!,
          ), // Bordure verte fine
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.green[600]!,
          ), // Bordure verte fine
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        // Pas de labelStyle pour garder les couleurs par défaut
      ),
      validator: validator,
    );
  }

  // ✅ CHECKBOX TERMES NORMAL
  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged:
              _isLoading
                  ? null
                  : (value) => setState(() => _acceptTerms = value!),
          activeColor: Colors.green[600],
        ),
        Expanded(
          child: GestureDetector(
            onTap:
                _isLoading
                    ? null
                    : () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: _isLoading ? Colors.grey[400] : Colors.black87,
                ),
                children: [
                  TextSpan(text: l10n.iAcceptThe),
                  TextSpan(
                    text: l10n.termsOfService,
                    style: TextStyle(
                      color: _isLoading ? Colors.grey[400] : Colors.green[600],
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: l10n.andThe),
                  TextSpan(
                    text: l10n.privacyPolicy,
                    style: TextStyle(
                      color: _isLoading ? Colors.grey[400] : Colors.green[600],
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FOOTER NORMAL
  Widget _buildFooter(AppLocalizations l10n) {
    return Column(
      children: [
        // Message d'information normal
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.green[600], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.afterRegistrationEmailVerification,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lien vers connexion
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.alreadyHaveAccount,
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                l10n.login,
                style: TextStyle(
                  color: _isLoading ? Colors.grey[400] : Colors.green[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ MÉTHODES SIMPLIFIÉES
  void _signUpWithGoogle() async {
    try {
      context.read<AuthBloc>().add(
        const SSORegisterCompleted(
          provider: 'google',
          idToken: '',
          userInfo: {},
        ),
      );
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de l\'inscription Google',
      );
    }
  }

  void _signUpWithApple() async {
    try {
      final isAvailable = await SSOService.isAppleSignInAvailable();
      if (!isAvailable) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          'Apple Sign-In non disponible',
        );
        return;
      }

      context.read<AuthBloc>().add(
        const SSORegisterCompleted(
          provider: 'apple',
          idToken: '',
          userInfo: {},
        ),
      );
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de l\'inscription Apple',
      );
    }
  }

  void _signUp() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  // ✅ MÉTHODES DE NAVIGATION SIMPLIFIÉES
  void _navigateToEmailVerification(String email) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => EmailVerificationScreen(
                  email: email,
                  fromRegistration: true,
                ),
          ),
        );
      }
    });
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
