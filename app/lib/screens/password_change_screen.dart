// screens/password_change_screen.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PasswordChangeScreen extends StatefulWidget {
  final String? initialEmail;

  const PasswordChangeScreen({super.key, this.initialEmail});

  @override
  _PasswordChangeScreenState createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _hasRequestedCode = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Changer le mot de passe',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          debugPrint('🔍 BlocListener - État reçu: ${state.runtimeType}');

          if (state is AuthLoading) {
            debugPrint('⏳ AuthLoading détecté');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          } else if (state is PasswordChangeCodeSent) {
            debugPrint(
              '📧 PasswordChangeCodeSent détecté pour: ${state.email}',
            );
            setState(() {
              _isLoading = false;
              _hasRequestedCode = true;
              _errorMessage = null;
            });

            // ✅ CORRECTION: Utiliser SmartSnackBarManager
            SmartSnackBarManager.showMessage(
              context,
              'Code de vérification envoyé à ${state.email}',
              type: SnackBarType.success,
              duration: const Duration(seconds: 3),
            );
          } else if (state is PasswordChanged) {
            debugPrint('✅ PasswordChanged détecté');
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });

            // ✅ CORRECTION: Utiliser SmartSnackBarManager
            SmartSnackBarManager.showMessage(
              context,
              'Mot de passe changé avec succès !',
              type: SnackBarType.success,
              duration: const Duration(seconds: 2),
            );

            // Retourner à l'écran de connexion après 2 secondes
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (state is AuthFailure) {
            debugPrint('❌ AuthFailure détecté avec erreur: ${state.error}');
            setState(() {
              _isLoading = false;
              _errorMessage = _getLocalizedErrorMessage(state.error);
            });

            // ✅ CORRECTION: Utiliser SmartSnackBarManager pour les erreurs
            SmartSnackBarManager.showMessage(
              context,
              _getLocalizedErrorMessage(state.error),
              type: SnackBarType.error,
              duration: const Duration(seconds: 4),
            );
          } else {
            setState(() {
              _isLoading = false;
            });
            debugPrint('❓ État non géré: ${state.runtimeType}');
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
                    const SizedBox(height: 20),

                    // En-tête avec icône
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.lock_reset,
                              size: 40,
                              color: Colors.orange[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasRequestedCode
                                ? 'Entrez votre code'
                                : 'Changement de mot de passe',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasRequestedCode
                                ? 'Saisissez le code reçu par email et votre nouveau mot de passe'
                                : 'Entrez votre email pour recevoir un code de vérification',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // AFFICHAGE DE L'ERREUR
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _errorMessage != null ? null : 0,
                      margin: EdgeInsets.only(
                        bottom: _errorMessage != null ? 16 : 0,
                      ),
                      child:
                          _errorMessage != null
                              ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
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
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
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
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading && !_hasRequestedCode,
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
                                  _hasRequestedCode
                                      ? Colors.grey[100]
                                      : (_errorMessage != null
                                          ? Colors.red[25]
                                          : Colors.grey[50]),
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

                          // Afficher les champs suivants seulement si le code a été demandé
                          if (_hasRequestedCode) ...[
                            const SizedBox(height: 16),

                            // Code de vérification
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'Code de vérification',
                                prefixIcon: const Icon(Icons.security),
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
                                hintText: 'Entrez le code à 6 chiffres',
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
                                  return 'Veuillez saisir le code de vérification';
                                }
                                if (value.trim().length != 6) {
                                  return 'Le code doit contenir 6 chiffres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Nouveau mot de passe
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _isObscureNew,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'Nouveau mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscureNew
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscureNew = !_isObscureNew;
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
                                  return 'Veuillez saisir votre nouveau mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confirmer le nouveau mot de passe
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _isObscureConfirm,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le nouveau mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscureConfirm = !_isObscureConfirm;
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
                                  return 'Veuillez confirmer votre nouveau mot de passe';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Bouton d'action
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _hasRequestedCode
                                        ? Colors.green[600]
                                        : Colors.orange[600],
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
                                        _hasRequestedCode
                                            ? 'Changer le mot de passe'
                                            : 'Envoyer le code',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),

                          // Bouton pour renvoyer le code (si déjà demandé)
                          if (_hasRequestedCode) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : _resendCode,
                              child: Text(
                                'Renvoyer le code',
                                style: TextStyle(
                                  color:
                                      _isLoading
                                          ? Colors.grey[400]
                                          : Colors.orange[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Informations utiles
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hasRequestedCode
                                        ? 'Le code expire dans 2 heures. Vérifiez vos emails et vos spams.'
                                        : 'Vous recevrez un code de vérification par email pour changer votre mot de passe.',
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                          const SizedBox(height: 16),
                          Text(
                            _hasRequestedCode
                                ? 'Changement en cours...'
                                : 'Envoi du code...',
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

  void _handleAction() {
    debugPrint('🚀 Tentative d\'action...');

    if (_formKey.currentState!.validate()) {
      debugPrint('✅ Validation réussie');

      if (!_hasRequestedCode) {
        // Demander le code
        final email = _emailController.text.trim();
        debugPrint('📤 Envoi RequestPasswordChangeCode pour: $email');

        context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
      } else {
        // Vérifier le code et changer le mot de passe
        final email = _emailController.text.trim();
        final code = _codeController.text.trim();
        final newPassword = _newPasswordController.text;

        debugPrint('📤 Envoi VerifyPasswordChangeCode pour: $email');

        context.read<AuthBloc>().add(
          VerifyPasswordChangeCode(
            email: email,
            code: code,
            newPassword: newPassword,
          ),
        );
      }
    } else {
      debugPrint('❌ Validation échouée');
    }
  }

  void _resendCode() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      debugPrint('📤 Renvoi du code pour: $email');
      context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
    }
  }

  // ✅ NOUVELLE MÉTHODE: Localisation des messages d'erreur
  String _getLocalizedErrorMessage(String error) {
    // Messages spécifiques pour le changement de mot de passe
    if (error.toLowerCase().contains('code invalid') ||
        error.toLowerCase().contains('invalid code') ||
        error.toLowerCase().contains('code_invalid')) {
      return 'Le code de vérification est invalide';
    }

    if (error.toLowerCase().contains('code expired') ||
        error.toLowerCase().contains('expired code') ||
        error.toLowerCase().contains('code_expired')) {
      return 'Le code de vérification a expiré. Demandez un nouveau code.';
    }

    if (error.toLowerCase().contains('user not found') ||
        error.toLowerCase().contains('email not found')) {
      return 'Aucun compte trouvé avec cet email';
    }

    if (error.toLowerCase().contains('email not verified')) {
      return 'Votre email n\'est pas encore vérifié';
    }

    if (error.toLowerCase().contains('password')) {
      return 'Erreur lors du changement de mot de passe';
    }

    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }

    if (error.toLowerCase().contains('validation')) {
      return 'Les données saisies ne sont pas valides';
    }

    // Message par défaut
    return error.isNotEmpty ? error : 'Une erreur inattendue est survenue';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
