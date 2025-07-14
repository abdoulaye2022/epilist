// screens/password_change_screen.dart - VERSION CORRIGÉE
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.changePassword),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is PasswordChangeCodeSent) {
            setState(() {
              _isLoading = false;
              _hasRequestedCode = true;
            });

            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.verificationCodeSentTo(state.email),
              duration: const Duration(seconds: 3),
            );
          } else if (state is PasswordChanged) {
            setState(() {
              _isLoading = false;
            });

            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.passwordChangedSuccessfully,
              duration: const Duration(seconds: 2),
            );

            context.read<AuthBloc>().add(LogoutRequested());

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (state is AuthFailure) {
            setState(() {
              _isLoading = false;
            });

            // ✅ AJOUT: Afficher l'erreur localement avec SmartSnackBarManager
            SmartSnackBarManager.showErrorSnackBar(
              context,
              state.error, // Le message est déjà traduit par AuthBloc
              duration: const Duration(seconds: 4),
            );
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // En-tête avec icône
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _hasRequestedCode
                          ? l10n.enterYourCode
                          : l10n.changePassword,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _hasRequestedCode
                          ? l10n.enterCodeAndNewPassword
                          : l10n.enterEmailForVerificationCode,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // ✅ INDICATEUR DE CHARGEMENT VISIBLE
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
                        _hasRequestedCode
                            ? l10n.changingPassword
                            : l10n.sendingCode,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Formulaire
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      _buildFormField(
                        controller: _emailController,
                        labelText: l10n.email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading && !_hasRequestedCode,
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

                      // Champs conditionnels
                      if (_hasRequestedCode) ...[
                        SizedBox(height: 20),
                        _buildFormField(
                          controller: _codeController,
                          labelText: l10n.verificationCode,
                          icon: Icons.security,
                          keyboardType: TextInputType.number,
                          enabled: !_isLoading,
                          hintText: l10n.enterSixDigitCode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.pleaseEnterVerificationCode;
                            }
                            if (value.trim().length != 6) {
                              return l10n.codeMustBeSixDigits;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20),
                        _buildFormField(
                          controller: _newPasswordController,
                          labelText: l10n.newPassword,
                          icon: Icons.lock_outline,
                          obscureText: _isObscureNew,
                          enabled: !_isLoading,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterNewPassword;
                            }
                            if (value.length < 6) {
                              return l10n.passwordMinSixCharacters;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20),
                        _buildFormField(
                          controller: _confirmPasswordController,
                          labelText: l10n.confirmNewPassword,
                          icon: Icons.lock_outline,
                          obscureText: _isObscureConfirm,
                          enabled: !_isLoading,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseConfirmNewPassword;
                            }
                            if (value != _newPasswordController.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Boutons d'action
              Column(
                children: [
                  _buildActionButton(
                    _hasRequestedCode ? l10n.changePassword : l10n.sendCode,
                    _hasRequestedCode ? Icons.lock_reset : Icons.send,
                    _isLoading ? null : _handleAction,
                    _hasRequestedCode ? Colors.green : Colors.orange,
                  ),
                  if (_hasRequestedCode) ...[
                    SizedBox(height: 12),
                    _buildActionButton(
                      l10n.resendCode,
                      Icons.refresh,
                      _isLoading ? null : _resendCode,
                      Colors.blue,
                    ),
                  ],
                ],
              ),

              SizedBox(height: 24),

              // Information
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _hasRequestedCode
                            ? l10n.codeExpiresInTwoHours
                            : l10n.verificationCodeWillBeSent,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          height: 1.5,
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
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    String? hintText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
      ),
      validator: validator,
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback? onPressed,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon:
            _isLoading && onPressed != null
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(icon, size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _handleAction() {
    if (_formKey.currentState!.validate()) {
      if (!_hasRequestedCode) {
        final email = _emailController.text.trim();
        context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
      } else {
        final email = _emailController.text.trim();
        final code = _codeController.text.trim();
        final newPassword = _newPasswordController.text;

        context.read<AuthBloc>().add(
          VerifyPasswordChangeCode(
            email: email,
            code: code,
            newPassword: newPassword,
          ),
        );
      }
    } else {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.pleaseFixFormErrors,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _resendCode() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<AuthBloc>().add(RequestPasswordChangeCode(email));
    }
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
