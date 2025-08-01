// login_screen.dart - VERSION CORRIGÉE POUR LA VISIBILITÉ DU CLAVIER
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/password_change_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ AJOUT: Pour les corrections clavier
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ✅ AJOUT: FocusNodes pour une meilleure gestion du focus
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // ✅ AJOUT: Configuration pour améliorer la visibilité du clavier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force la mise à jour de la vue après la construction
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // ✅ AJOUT: Configuration pour éviter le redimensionnement automatique
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🟨 LoginScreen - State reçu: ${state.runtimeType}');

          if (state is AuthLoading) {
            print('🟨 AuthLoading détecté');
            setState(() => _isLoading = true);
          } else if (state is AuthFailure) {
            print('🟨 AuthFailure détecté');
            print('🟨 Message d\'erreur reçu: "${state.error}"');

            setState(() => _isLoading = false);

            // ✅ AJOUT: Vérifier le message avant de l'envoyer au SnackBar
            final errorMessage = state.error;
            print('🟨 Envoi du message au SnackBar: "$errorMessage"');

            SmartSnackBarManager.showErrorSnackBar(
              context,
              errorMessage, // ✅ Utiliser directement state.error
              duration: const Duration(seconds: 4),
            );
          } else if (state is EmailVerificationRequired) {
            print('🟨 EmailVerificationRequired détecté pour: ${state.email}');
            setState(() => _isLoading = false);

            SmartSnackBarManager.showErrorSnackBar(
              context,
              l10n.emailMustBeVerified,
              duration: const Duration(seconds: 4),
            );

            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EmailVerificationScreen(
                          email: state.email,
                          fromRegistration: false,
                        ),
                  ),
                );
              }
            });
          } else if (state is AuthSuccess) {
            print('🟨 AuthSuccess détecté');
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);

            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            });
          } else if (state is Unauthenticated) {
            print('🟨 Unauthenticated détecté');
            setState(() => _isLoading = false);
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: // ✅ CHANGEMENT: Utilisation de LayoutBuilder pour une meilleure gestion de l'espace
                LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // ✅ AJOUT: Configuration pour le comportement du scroll avec le clavier
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    // ✅ AJOUT: Padding dynamique basé sur la hauteur du clavier
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48.0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),

                          // Logo et titre
                          Center(
                            child: Column(
                              children: [
                                // ✅ Logo sans background
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color:
                                        Colors
                                            .transparent, // ✅ Background transparent
                                  ),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 80,
                                    height: 80,
                                    fit:
                                        BoxFit
                                            .contain, // ✅ Changé de cover à contain
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.green[400]!,
                                              Colors.green[600]!,
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_cart_rounded,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          Text(
                            l10n.loginTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // INDICATEUR DE CHARGEMENT
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue[600],
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.loggingIn,
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // ✅ CHAMP EMAIL AMÉLIORÉ
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  // ✅ AJOUT: Configuration pour améliorer la visibilité
                                  autocorrect: false,
                                  enableSuggestions: true,
                                  textCapitalization: TextCapitalization.none,
                                  inputFormatters: [
                                    // ✅ AJOUT: Empêcher les espaces dans l'email
                                    FilteringTextInputFormatter.deny(
                                      RegExp(r'\s'),
                                    ),
                                  ],
                                  onFieldSubmitted: (_) {
                                    // ✅ AJOUT: Navigation automatique vers le champ mot de passe
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocusNode);
                                  },
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.green[600]!,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    // ✅ AJOUT: Améliorer la visibilité du curseur
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  // ✅ AJOUT: Style du curseur
                                  cursorColor: Colors.green[600],
                                  cursorWidth: 2,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterEmail;
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return l10n.invalidEmail;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ✅ CHAMP MOT DE PASSE AMÉLIORÉ
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _isObscure,
                                  enabled: !_isLoading,
                                  textInputAction: TextInputAction.done,
                                  // ✅ AJOUT: Configuration pour améliorer la visibilité
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onFieldSubmitted: (_) {
                                    // ✅ AJOUT: Connexion automatique quand on appuie sur "Done"
                                    if (!_isLoading) {
                                      _login();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isObscure = !_isObscure;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.green[600]!,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  // ✅ AJOUT: Style du curseur
                                  cursorColor: Colors.green[600],
                                  cursorWidth: 2,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterPassword;
                                    }
                                    if (value.length < 3) {
                                      return l10n.passwordMinThreeCharacters;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Mot de passe oublié
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : _showForgotPasswordDialog,
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: TextStyle(
                                        color:
                                            _isLoading
                                                ? Colors.grey[400]
                                                : Colors.green[600],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Bouton de connexion
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        l10n.or,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Bouton inscription
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const SignUpPage(),
                                                ),
                                              );
                                            },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color:
                                            _isLoading
                                                ? Colors.grey[400]!
                                                : Colors.green[600]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.createAccount,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _isLoading
                                                ? Colors.grey[400]
                                                : Colors.green[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ✅ AJOUT: Espace flexible pour pousser le contenu vers le haut quand le clavier apparaît
                          const Spacer(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    // ✅ AJOUT: S'assurer que le clavier se ferme
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      context.read<AuthBloc>().add(
        LoginButtonPressed(email: email, password: password),
      );
    } else {
      setState(() => _isLoading = false);

      SmartSnackBarManager.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.pleaseFixFormErrors,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(l10n.forgotPassword),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, size: 48, color: Colors.orange[600]),
                const SizedBox(height: 16),
                Text(
                  l10n.resetPasswordSecurely,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PasswordChangeScreen(
                            initialEmail:
                                _emailController.text.trim().isNotEmpty
                                    ? _emailController.text.trim()
                                    : null,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.reset),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // ✅ AJOUT: Libérer les FocusNodes
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
