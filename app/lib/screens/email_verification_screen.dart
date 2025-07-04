// email_verification_screen.dart - VERSION AMÉLIORÉE AVEC SNACKBAR_MANAGER
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/utils/snackbar_manager.dart'; // AJOUT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool fromRegistration;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.fromRegistration = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _canResend = true;
  bool _initialCodeSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Si c'est un cas de connexion (pas d'inscription), envoyer automatiquement le code
    if (!widget.fromRegistration && !_initialCodeSent) {
      _sendInitialVerificationCode();
    } else {
      // Pour l'inscription, le code a déjà été envoyé, on démarre juste le countdown
      _startResendCountdown();
    }
  }

  void _sendInitialVerificationCode() {
    print('📧 Envoi automatique du code de vérification pour: ${widget.email}');

    // Envoyer le code de vérification
    context.read<AuthBloc>().add(ResendVerificationCode(widget.email));

    setState(() {
      _initialCodeSent = true;
    });

    // Démarrer le countdown après l'envoi
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isCodeComplete {
    return _verificationCode.length == 6;
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isCodeComplete) {
      _verifyCode();
    }
  }

  void _verifyCode() {
    if (_isCodeComplete && !_isLoading) {
      // Fermer le clavier
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);

      context.read<AuthBloc>().add(
        ConfirmEmailRequested(email: widget.email, code: _verificationCode),
      );
    }
  }

  void _resendCode() {
    if (_canResend && !_isLoading) {
      context.read<AuthBloc>().add(ResendVerificationCode(widget.email));
      _startResendCountdown();
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed:
              _isLoading
                  ? null
                  : () {
                    // Toujours retourner vers LoginScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else if (state is EmailConfirmationSuccess) {
            setState(() => _isLoading = false);

            // Effacer tous les SnackBars avant d'afficher le nouveau
            SnackBarManager.clearAll(context);

            // Afficher un message de succès
            SnackBarManager.showSuccessSnackBar(
              context,
              '🎉 Email vérifié avec succès !',
              duration: const Duration(seconds: 3),
            );

            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                // Toujours rediriger vers login pour l'ancien comportement
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            });
          } else if (state is AuthSuccess) {
            setState(() => _isLoading = false);

            // NOUVEAU: Gestion de la connexion automatique après confirmation
            SnackBarManager.clearAll(context);

            SnackBarManager.showSuccessSnackBar(
              context,
              '🎉 Email vérifié et connexion automatique ! Bienvenue ${state.user.firstName}.',
              duration: const Duration(seconds: 3),
            );

            // L'AuthWrapper va automatiquement rediriger vers HomeScreen
            // car l'état AuthSuccess est émis
            debugPrint('✅ Connexion automatique après confirmation email');
          } else if (state is VerificationCodeResent) {
            setState(() => _isLoading = false);

            // Effacer tous les SnackBars avant d'afficher le nouveau
            SnackBarManager.clearAll(context);

            SnackBarManager.showSuccessSnackBar(
              context,
              widget.fromRegistration
                  ? 'Code de vérification renvoyé !'
                  : 'Code de vérification envoyé !',
              duration: const Duration(seconds: 2),
            );
            _clearCode();
          } else if (state is AuthFailure) {
            setState(() => _isLoading = false);

            // Utiliser le gestionnaire de SnackBar avec message en français
            final localizedError = AuthErrorMessages.getLocalizedError(
              state.error,
            );

            SnackBarManager.showErrorSnackBar(
              context,
              localizedError,
              duration: const Duration(seconds: 5),
            );

            print('Erreur de vérification email: ${state.error}');
            _clearCode();
          } else if (state is Unauthenticated) {
            setState(() => _isLoading = false);
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),

                  // Icône email
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 50,
                      color: Colors.green[600],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Titre
                  Text(
                    'Vérifiez votre email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12),

                  // Description dynamique selon le contexte
                  Text(
                    'Nous avons envoyé un code de vérification à',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8),

                  // Email
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 32),

                  // INDICATEUR DE CHARGEMENT (comme dans login et signup)
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
                            'Vérification en cours...',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Champs de saisie du code
                  Text(
                    'Entrez le code à 6 chiffres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Code input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 45,
                        height: 55,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _controllers[index].text.isEmpty
                                    ? Colors.grey[300]!
                                    : Colors.green[600]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color:
                              _controllers[index].text.isEmpty
                                  ? Colors.grey[50]
                                  : Colors.green[50],
                        ),
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          enabled: !_isLoading,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onCodeChanged(value, index),
                          onTap: () {
                            _controllers[index]
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _controllers[index].text.length,
                              ),
                            );
                          },
                          onEditingComplete: () {
                            if (_isCodeComplete && !_isLoading) {
                              _verifyCode();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 32),

                  // Bouton de vérification
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || !_isCodeComplete) ? null : _verifyCode,
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
                                'Vérifier le code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Section renvoyer le code
                  Column(
                    children: [
                      Text(
                        'Vous n\'avez pas reçu le code ?',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),

                      SizedBox(height: 8),

                      if (!_canResend)
                        Text(
                          'Renvoyer dans ${_resendCountdown}s',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isLoading ? null : _resendCode,
                          child: Text(
                            'Renvoyer le code',
                            style: TextStyle(
                              color:
                                  _isLoading
                                      ? Colors.grey[400]
                                      : Colors.green[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Bouton effacer
                  if (_verificationCode.isNotEmpty)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _clearCode,
                      icon: Icon(
                        Icons.clear,
                        color: _isLoading ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                      label: Text(
                        'Effacer le code',
                        style: TextStyle(
                          color:
                              _isLoading ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Message d'information
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
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vérifiez votre dossier de courrier indésirable si vous ne trouvez pas l\'email',
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

                  SizedBox(height: 20),

                  // Message informatif sur le flux
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          widget.fromRegistration
                              ? Colors.green[50]
                              : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            widget.fromRegistration
                                ? Colors.green[200]!
                                : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.fromRegistration ? Icons.login : Icons.refresh,
                          color:
                              widget.fromRegistration
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.fromRegistration
                                ? 'Après vérification, vous serez redirigé vers la page de connexion'
                                : 'Après vérification, vous pourrez vous reconnecter avec vos identifiants',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  widget.fromRegistration
                                      ? Colors.green[700]
                                      : Colors.orange[700],
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
