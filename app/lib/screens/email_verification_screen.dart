import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/login_screen.dart'; // Import du LoginScreen
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

  @override
  void initState() {
    super.initState();
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

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    if (_isCodeComplete) {
      context.read<AuthBloc>().add(
        ConfirmEmailRequested(email: widget.email, code: _verificationCode),
      );
    }
  }

  void _resendCode() {
    if (_canResend) {
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // CORRIGÉ: Redirection vers LoginScreen après vérification réussie
        if (state is EmailConfirmationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email vérifié avec succès ! 🎉\nVous pouvez maintenant vous connecter.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 3),
            ),
          );

          // CHANGEMENT: Redirection vers LoginScreen au lieu de HomeScreen
          Future.delayed(Duration(milliseconds: 800), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          });
        }

        if (state is VerificationCodeResent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code de vérification renvoyé !'),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 2),
            ),
          );
          _clearCode();
        }

        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
          _clearCode();
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

                // Description
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
                          if (_isCodeComplete) {
                            _verifyCode();
                          }
                        },
                      ),
                    );
                  }),
                ),

                SizedBox(height: 32),

                // Bouton de vérification
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (isLoading || !_isCodeComplete)
                                ? null
                                : _verifyCode,
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
                                  'Vérifier le code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    );
                  },
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
                        onPressed: _resendCode,
                        child: Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: Colors.green[600],
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
                    onPressed: _clearCode,
                    icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                    label: Text(
                      'Effacer le code',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

                // AJOUTÉ: Message informatif sur la redirection
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.login, color: Colors.green[600], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Après vérification, vous serez redirigé vers la page de connexion',
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
              ],
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
