// email_verification_screen.dart - VERSION CORRIGÉE
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/utils/snackbar_manager.dart';
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
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();

    // For all cases, the code has already been sent by the AuthBloc
    // We just start the countdown
    _startResendCountdown();

    setState(() {
      _initialCodeSent = true;
    });
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
      // Close keyboard
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

  void _redirectToHome() {
    if (!_isRedirecting && mounted) {
      setState(() => _isRedirecting = true);

      // Completely replace the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
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
              _isLoading || _isRedirecting
                  ? null
                  : () {
                    // Return to LoginScreen
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

            SmartSnackBarManager.clearAll(context);

            SmartSnackBarManager.showSuccessSnackBar(
              context,
              '🎉 Email verified successfully!',
              duration: const Duration(seconds: 2),
            );

            // Immediate redirect to HomeScreen
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isRedirecting) {
                _redirectToHome();
              }
            });
          } else if (state is AuthSuccess) {
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);

            SmartSnackBarManager.showSuccessSnackBar(
              context,
              '🎉 Email verified! Automatic login successful!',
              duration: const Duration(seconds: 2),
            );

            // Immediate redirect to HomeScreen
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isRedirecting) {
                _redirectToHome();
              }
            });
          } else if (state is VerificationCodeResent) {
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);

            SmartSnackBarManager.showSuccessSnackBar(
              context,
              'Verification code resent!',
              duration: const Duration(seconds: 2),
            );
            _clearCode();
          } else if (state is AuthFailure) {
            setState(() => _isLoading = false);

            // ✅ CORRECTION : Plus d'utilisation de AuthErrorMessages
            // L'erreur sera gérée par AuthBloc via main.dart
            // Juste afficher l'erreur pour debug
            print('🔍 Erreur de vérification email: ${state.error}');

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

                  // Email icon
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

                  // Title
                  Text(
                    'Verify your email',
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
                    'We sent a verification code to',
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

                  // Enhanced loading indicator
                  if (_isLoading || _isRedirecting)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            _isRedirecting ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _isRedirecting
                                  ? Colors.green[200]!
                                  : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color:
                                  _isRedirecting
                                      ? Colors.green[600]
                                      : Colors.blue[600],
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            _isRedirecting
                                ? 'Login successful! Redirecting...'
                                : 'Verification in progress...',
                            style: TextStyle(
                              color:
                                  _isRedirecting
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Code input fields
                  Text(
                    'Enter the 6-digit code',
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
                          enabled: !_isLoading && !_isRedirecting,
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
                            if (_isCodeComplete &&
                                !_isLoading &&
                                !_isRedirecting) {
                              _verifyCode();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 32),

                  // Verification button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _isRedirecting || !_isCodeComplete)
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
                          (_isLoading || _isRedirecting)
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Verify code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Resend code section
                  Column(
                    children: [
                      Text(
                        'Didn\'t receive the code?',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),

                      SizedBox(height: 8),

                      if (!_canResend)
                        Text(
                          'Resend in ${_resendCountdown}s',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        TextButton(
                          onPressed:
                              (_isLoading || _isRedirecting)
                                  ? null
                                  : _resendCode,
                          child: Text(
                            'Resend code',
                            style: TextStyle(
                              color:
                                  (_isLoading || _isRedirecting)
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

                  // Clear button
                  if (_verificationCode.isNotEmpty && !_isRedirecting)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _clearCode,
                      icon: Icon(
                        Icons.clear,
                        color: _isLoading ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                      label: Text(
                        'Clear code',
                        style: TextStyle(
                          color:
                              _isLoading ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Information message
                  if (!_isRedirecting)
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
                              'Check your spam folder if you can\'t find the email',
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

                  if (!_isRedirecting) SizedBox(height: 20),

                  // Informative message about the flow
                  if (!_isRedirecting)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Colors.green[600], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'After verification, you will be automatically logged in and redirected to the home page',
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
