import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
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
            setState(() {
              _isLoading = false;
              _errorMessage = state.error;
            });
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
          child: Stack(
            children: [
              SingleChildScrollView(
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

                    // AFFICHAGE DE L'ERREUR
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _errorMessage != null ? null : 0,
                      margin: EdgeInsets.only(
                        bottom: _errorMessage != null ? 16 : 0,
                      ),
                      child:
                          _errorMessage != null
                              ? Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red[600],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getErrorMessage(_errorMessage!),
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.red[600],
                                      ),
                                      onPressed: () {
                                        print(
                                          '🔄 Effacement manuel de l\'erreur',
                                        );
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
                              // Effacer l'erreur quand l'utilisateur commence à taper
                              if (_errorMessage != null) {
                                print('🔄 Effacement erreur par saisie email');
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
                              // Effacer l'erreur quand l'utilisateur commence à taper
                              if (_errorMessage != null) {
                                print(
                                  '🔄 Effacement erreur par saisie password',
                                );
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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

              // Overlay de chargement global
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.green[600],
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Connexion en cours...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('invalid credentials') ||
        error.toLowerCase().contains('identifiants invalides') ||
        error.toLowerCase().contains('please try again')) {
      return 'Email ou mot de passe incorrect. Veuillez vérifier vos informations.';
    }

    if (error.toLowerCase().contains('user not found') ||
        error.toLowerCase().contains('utilisateur non trouvé') ||
        error.toLowerCase().contains('email not found') ||
        error.toLowerCase().contains('compte introuvable')) {
      return 'Aucun compte associé à cette adresse email. Veuillez vérifier votre email ou créer un compte.';
    }

    if (error.toLowerCase().contains('wrong password') ||
        error.toLowerCase().contains('mot de passe incorrect') ||
        error.toLowerCase().contains('invalid password') ||
        error.toLowerCase().contains('password mismatch')) {
      return 'Mot de passe incorrect. Veuillez réessayer ou réinitialiser votre mot de passe.';
    }

    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre connexion internet et réessayez.';
    }

    if (error.toLowerCase().contains('account disabled') ||
        error.toLowerCase().contains('compte désactivé')) {
      return 'Votre compte a été désactivé. Contactez le support pour plus d\'informations.';
    }

    if (error.toLowerCase().contains('email not verified') ||
        error.toLowerCase().contains('email non vérifié')) {
      return 'Veuillez vérifier votre email avant de vous connecter. Consultez votre boîte de réception.';
    }

    if (error.toLowerCase().contains('too many attempts') ||
        error.toLowerCase().contains('trop de tentatives')) {
      return 'Trop de tentatives de connexion. Veuillez attendre quelques minutes avant de réessayer.';
    }

    // Message générique si aucune correspondance
    return 'Erreur de connexion : $error';
  }

  void _login() {
    print('🚀 Tentative de connexion...');

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
    final forgotEmailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Mot de passe oublié'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Entrez votre email pour recevoir un lien de réinitialisation :',
                ),
                SizedBox(height: 16),
                TextField(
                  controller: forgotEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (forgotEmailController.text.isNotEmpty) {
                    Navigator.pop(context);
                    // Utiliser un SnackBar simple qui fonctionne
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Email de réinitialisation envoyé à ${forgotEmailController.text}',
                        ),
                        backgroundColor: Colors.green[600],
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: Text('Envoyer'),
              ),
            ],
          ),
    ).then((_) {
      forgotEmailController.dispose();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
