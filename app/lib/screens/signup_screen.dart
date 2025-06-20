import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          // Message de succès avec le nom complet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Compte créé avec succès ! Bienvenue ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} !\nVeuillez vérifier votre e-mail pour confirmer votre compte.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 4),
            ),
          );

          // Redirection vers l'écran de connexion après un délai
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
        }

        if (state is AuthFailure) {
          // Message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                Text(
                  'Rejoignez EpiList pour gérer vos courses facilement',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Prénom et Nom sur la même ligne
                      Row(
                        children: [
                          // Prénom
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'Prénom',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Prénom requis';
                                }
                                if (value.trim().length < 2) {
                                  return 'Trop court';
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(width: 12),

                          // Nom
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nom requis';
                                }
                                if (value.trim().length < 2) {
                                  return 'Trop court';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
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

                      SizedBox(height: 16),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
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
                            return 'Veuillez saisir un mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Au moins 6 caractères';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Confirmation mot de passe
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmObscure,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmObscure = !_isConfirmObscure;
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
                            return 'Confirmez votre mot de passe';
                          }
                          if (value != _passwordController.text) {
                            return 'Mots de passe différents';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Accepter les conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value!;
                              });
                            },
                            activeColor: Colors.green[600],
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _acceptTerms = !_acceptTerms;
                                  });
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(text: 'J\'accepte les '),
                                      TextSpan(
                                        text: 'conditions d\'utilisation',
                                        style: TextStyle(
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' et la '),
                                      TextSpan(
                                        text: 'politique de confidentialité',
                                        style: TextStyle(
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Bouton d'inscription avec BlocBuilder
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  (isLoading || !_acceptTerms) ? null : _signUp,
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
                                  isLoading
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        'Créer mon compte',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      // Message d'information pour l'inscription
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.green[600],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Après inscription, vous serez redirigé vers la page de connexion',
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

                      SizedBox(height: 8),

                      // Lien vers connexion
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà un compte ? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Se connecter',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
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

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // Utilisation du BLoC pour l'inscription
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
