import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo et titre corrigés pour EpiList
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
                                  Icons.euro,
                                  color: Colors.green[600],
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Suivez vos dépenses d\'épicerie',
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

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
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
                          onPressed: () {
                            _showForgotPasswordDialog();
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(color: Colors.green[600]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton de connexion
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  state is AuthLoading
                                      ? null
                                      : () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<AuthBloc>().add(
                                            LoginButtonPressed(
                                              email:
                                                  _emailController.text.trim(),
                                              password:
                                                  _passwordController.text
                                                      .trim(),
                                            ),
                                          );
                                        }
                                      },
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
                                  state is AuthLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          );
                        },
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green[600]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
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

  void _showForgotPasswordDialog() {
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email de réinitialisation envoyé !'),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: Text('Envoyer'),
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
