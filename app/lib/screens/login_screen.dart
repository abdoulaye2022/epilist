import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/password_change_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:flutter/material.dart';
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
  bool _isObscure = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🔍 BlocListener - État reçu: ${state.runtimeType}');

          if (state is AuthLoading) {
            print('⏳ AuthLoading détecté');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          } else if (state is AuthFailure) {
            print('❌ AuthFailure détecté avec erreur: ${state.error}');
            print('🔍 Contenu de l\'erreur: "${state.error}"');

            setState(() {
              _isLoading = false;
            });

            // CORRECTION: Gestion immédiate sans délai
            if (_isEmailVerificationRequired(state.error)) {
              print('✅ Email non vérifié détecté - Affichage du dialogue');
              // Délai minimal pour permettre la mise à jour de l'UI
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showEmailVerificationDialog();
                }
              });
            } else {
              print('❌ Erreur normale - Affichage du message d\'erreur');
              setState(() {
                _errorMessage = state.error;
              });
            }
          } else if (state is AuthSuccess) {
            print('✅ AuthSuccess détecté, navigation vers HomeScreen');
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            setState(() {
              _isLoading = false;
            });
            print('❓ État non géré: ${state.runtimeType}');
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          size: 40,
                          color: Colors.green[600],
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
                        'Gérez vos courses facilement',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Créez vos listes avant d\'aller faire vos courses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  color: Colors.green[600],
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cochez vos achats en temps réel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Colors.green[600],
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Suivez vos dépenses d\'épicerie en CAD\$',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                // AFFICHAGE DE L'ERREUR - CORRECTION COMPLÈTE
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child:
                      _errorMessage != null
                          ? Container(
                            key: ValueKey(_errorMessage),
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getErrorMessage(_errorMessage!),
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // CORRECTION: Bouton d'urgence pour la vérification email
                                      if (_errorMessage!.toLowerCase().contains(
                                            'email',
                                          ) ||
                                          _errorMessage!.toLowerCase().contains(
                                            'vérif',
                                          ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _errorMessage = null;
                                              });
                                              _showEmailVerificationDialog();
                                            },
                                            icon: Icon(
                                              Icons.email,
                                              size: 16,
                                              color: Colors.orange[600],
                                            ),
                                            label: Text(
                                              'Vérifier mon email',
                                              style: TextStyle(
                                                color: Colors.orange[600],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              minimumSize: Size(0, 30),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.red[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : SizedBox.shrink(),
                ),

                // INDICATEUR DE CHARGEMENT DISCRET
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
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
                        SizedBox(width: 12),
                        Text(
                          'Connexion en cours...',
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
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _errorMessage != null
                                      ? Colors.red[300]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _errorMessage != null
                                      ? Colors.red[500]!
                                      : Colors.green[600]!,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              _errorMessage != null
                                  ? Colors.red[25]
                                  : Colors.grey[50],
                        ),
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
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
                              color:
                                  _errorMessage != null
                                      ? Colors.red[300]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _errorMessage != null
                                      ? Colors.red[500]!
                                      : Colors.green[600]!,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              _errorMessage != null
                                  ? Colors.red[25]
                                  : Colors.grey[50],
                        ),
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe';
                          }
                          if (value.length < 3) {
                            return 'Le mot de passe doit contenir au moins 3 caractères';
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
                                  : () {
                                    _showForgotPasswordDialog();
                                  },
                          child: Text(
                            'Mot de passe oublié ?',
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
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Se connecter',
                                    style: TextStyle(
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(color: Colors.grey[600]),
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
                                            (context) => const SignUpPage(),
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
                            'Créer un compte',
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

                      const SizedBox(height: 20),

                      // Message d'encouragement
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Simplifiez vos courses et maîtrisez votre budget !',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
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
          ),
        ),
      ),
    );
  }

  // CORRECTION: Détection améliorée du message de vérification email
  bool _isEmailVerificationRequired(String error) {
    print('🔍 Vérification du message d\'erreur: "$error"');

    // Détection stricte du message de vérification email (français + anglais)
    final verificationKeywords = [
      'verify your email',
      'please verify',
      'email not verified',
      'email address before logging',
      'vérifiez votre email',
      'email non vérifié',
      'veuillez vérifier votre email',
      'avant de vous connecter',
      'email_not_verified',
    ];

    final lowerError = error.toLowerCase();

    for (String keyword in verificationKeywords) {
      if (lowerError.contains(keyword.toLowerCase())) {
        print('✅ Mot-clé de vérification trouvé: "$keyword"');
        return true;
      }
    }

    print('❌ Aucun mot-clé de vérification email trouvé');
    print('🔍 Message complet reçu: "$error"');
    return false;
  }

  // CORRECTION: Dialogue de vérification email simplifié
  void _showEmailVerificationDialog() {
    print('📧 Affichage du dialogue de vérification email');

    if (!mounted) {
      print('❌ Widget non monté - dialogue annulé');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.orange[600], size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email non vérifié',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre compte existe mais votre email n\'est pas encore vérifié.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.green[600], size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _emailController.text.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  print('❌ Utilisateur a choisi "Plus tard"');
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('✅ Utilisateur a choisi "Vérifier maintenant"');
                  Navigator.of(dialogContext).pop();

                  // Navigation vers EmailVerificationScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EmailVerificationScreen(
                            email: _emailController.text.trim(),
                            fromRegistration: false,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Vérifier maintenant',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  String _getErrorMessage(String error) {
    // CORRECTION: Messages d'erreur plus clairs
    final lowerError = error.toLowerCase();

    if (lowerError.contains('invalid credentials') ||
        lowerError.contains('identifiants invalides') ||
        lowerError.contains('please try again')) {
      return 'Email ou mot de passe incorrect. Veuillez vérifier vos informations.';
    }

    if (lowerError.contains('user not found') ||
        lowerError.contains('utilisateur non trouvé') ||
        lowerError.contains('email not found') ||
        lowerError.contains('compte introuvable')) {
      return 'Aucun compte associé à cette adresse email. Créez un compte ou vérifiez votre email.';
    }

    if (lowerError.contains('wrong password') ||
        lowerError.contains('mot de passe incorrect') ||
        lowerError.contains('invalid password')) {
      return 'Mot de passe incorrect. Veuillez réessayer.';
    }

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    }

    if (lowerError.contains('account disabled') ||
        lowerError.contains('compte désactivé')) {
      return 'Compte désactivé. Contactez le support.';
    }

    if (lowerError.contains('too many attempts') ||
        lowerError.contains('trop de tentatives')) {
      return 'Trop de tentatives. Attendez quelques minutes.';
    }

    // Message par défaut
    return error.length > 100
        ? 'Erreur de connexion. Vérifiez vos informations.'
        : error;
  }

  void _login() {
    print('🚀 Tentative de connexion...');

    // Effacer les erreurs précédentes
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      print('✅ Validation réussie');

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('📤 Envoi LoginButtonPressed pour: $email');

      context.read<AuthBloc>().add(
        LoginButtonPressed(email: email, password: password),
      );
    } else {
      print('❌ Validation échouée');
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Mot de passe oublié'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, size: 48, color: Colors.orange[600]),
                SizedBox(height: 16),
                Text(
                  'Réinitialiser votre mot de passe en toute sécurité.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
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
                child: Text('Réinitialiser'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
