// screens/signup_screen.dart - VERSION CORRIGÉE AVEC GESTION INTELLIGENTE SSO
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

                // ✅ BOUTONS SSO CORRIGÉS
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

  // ✅ GESTION D'ÉTAT AMÉLIORÉE
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

      case AuthSuccess:
        final authState = state as AuthSuccess;
        String message;

        if (authState.authMethod == 'google') {
          message = 'Compte Google créé et connecté avec succès !';
        } else if (authState.authMethod == 'apple') {
          message = 'Compte Apple créé et connecté avec succès !';
        } else {
          message = 'Compte créé et connecté !';
        }

        SmartSnackBarManager.showSuccessSnackBar(context, message);
        _navigateToHome();
        break;

      case AuthFailure:
        final failure = state as AuthFailure;

        // ✅ ANDROID: Messages d'erreur spécifiques pour inscription
        String errorMessage = failure.error;
        if (errorMessage.contains('EMAIL_ALREADY_EXISTS') ||
            errorMessage.contains('Un compte existe déjà')) {
          errorMessage =
              'Un compte existe déjà avec cet email. Essayez de vous connecter.';

          // Suggérer de passer à l'écran de connexion
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          });
        }

        SmartSnackBarManager.showErrorSnackBar(context, errorMessage);
        break;

      case SSOError:
        final ssoError = state as SSOError;

        // ✅ ANDROID: Traiter les erreurs SSO d'inscription
        String errorMessage = ssoError.error;

        if (errorMessage.contains('EMAIL_ALREADY_EXISTS') ||
            errorMessage.contains('Un compte existe déjà')) {
          errorMessage =
              'Un compte Google existe déjà. Redirection vers la connexion...';

          SmartSnackBarManager.showInfoSnackBar(context, errorMessage);

          // Rediriger vers l'écran de connexion
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          });
        } else {
          SmartSnackBarManager.showErrorSnackBar(context, errorMessage);
        }
        break;

      case RegistrationSuccess:
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          'Compte créé avec succès ! Vérifiez votre email.',
        );
        _navigateToLogin();
        break;
    }
  }

  // ✅ DIALOG POUR COMPLÉTER LE PROFIL TEMPORAIRE
  void _showProfileCompletionDialog(SSORegistrationSuccess ssoState) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  ssoState.provider == 'google'
                      ? Icons.g_mobiledata
                      : Icons.apple,
                  color:
                      ssoState.provider == 'google'
                          ? Colors.red[600]
                          : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profil ${ssoState.provider == 'google' ? 'Google' : 'Apple'}',
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connexion ${ssoState.provider} réussie !',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voulez-vous compléter votre profil maintenant ou vous connecter plus tard ?',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ssoState.user.firstName} ${ssoState.user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ssoState.user.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToLogin();
                },
                child: Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fillFormWithSSOData(ssoState.user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Compléter'),
              ),
            ],
          ),
    );
  }

  // ✅ PRER-REMPLIR LE FORMULAIRE AVEC LES DONNÉES SSO
  void _fillFormWithSSOData(dynamic user) {
    setState(() {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
      _acceptTerms = true; // Auto-accepter les termes pour SSO
    });

    // Scroller vers le formulaire
    Future.delayed(const Duration(milliseconds: 300), () {
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
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

  // ✅ BOUTONS SSO CORRIGÉS AVEC LOGIQUE INTELLIGENTE
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

        // Bouton Google corrigé
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
                    : Icon(
                      Icons.g_mobiledata,
                      color: Colors.red[600],
                      size: 20,
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

        // Bouton Apple corrigé (iOS seulement) - PRÉSERVÉ
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

  // ✅ MÉTHODES SSO CORRIGÉES AVEC LOGIQUE INTELLIGENTE
  void _signUpWithGoogle() async {
    if (_isLoading) return;

    try {
      // ✅ ANDROID: Utiliser GoogleSignInRequested même pour l'inscription
      // Le serveur gère maintenant la création automatique
      context.read<AuthBloc>().add(const GoogleSignInRequested());
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de l\'inscription Google: ${e.toString()}',
      );
    }
  }

  void _signUpWithApple() async {
    if (_isLoading) return;

    try {
      final isAvailable = await SSOService.isAppleSignInAvailable();
      if (!isAvailable) {
        String errorMessage =
            Platform.isIOS
                ? 'Apple Sign-In non disponible sur cet appareil'
                : 'Apple Sign-In est uniquement disponible sur iOS';

        SmartSnackBarManager.showErrorSnackBar(context, errorMessage);
        return;
      }

      // ✅ Utiliser AppleSignInRequested pour l'inscription (PRÉSERVÉ)
      context.read<AuthBloc>().add(const AppleSignInRequested());
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors de l\'inscription Apple: ${e.toString()}',
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
