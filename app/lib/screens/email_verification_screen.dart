// email_verification_screen.dart - VERSION COMPLÈTE CORRIGÉE
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
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
  bool _initialCodeSent = false;
  bool _isLoading = false;
  bool _isRedirecting = false;
  bool _hasNavigated = false; // ✅ AJOUT: Variable manquante

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    setState(() {
      _initialCodeSent = true;
    });
  }

  // ✅ MÉTHODE MANQUANTE: Démarrage du compte à rebours
  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  // ✅ NOUVELLE MÉTHODE: Gestion du collage automatique
  void _onCodeChanged(String value, int index) {
    // ✅ NOUVEAU: Détecter si un code complet a été collé
    if (value.length > 1) {
      _handlePastedCode(value);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isCodeComplete) {
      _verifyCode();
    }
  }

  // ✅ NOUVELLE MÉTHODE: Traitement du code collé
  void _handlePastedCode(String pastedText) {
    final l10n = AppLocalizations.of(context)!;

    // Nettoyer le texte collé (garder seulement les chiffres)
    String cleanCode = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    // Limiter à 6 chiffres maximum
    if (cleanCode.length > 6) {
      cleanCode = cleanCode.substring(0, 6);
    }

    // Remplir les champs avec le code collé
    for (int i = 0; i < 6; i++) {
      if (i < cleanCode.length) {
        _controllers[i].text = cleanCode[i];
      } else {
        _controllers[i].clear();
      }
    }

    // Mettre le focus sur le dernier champ rempli ou le premier vide
    if (cleanCode.length < 6) {
      _focusNodes[cleanCode.length].requestFocus();
    } else {
      // Si le code est complet, enlever le focus et vérifier
      FocusScope.of(context).unfocus();
      // Petite pause pour que l'UI se mette à jour
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isCodeComplete) {
          _verifyCode();
        }
      });
    }

    // Afficher un message de confirmation
    if (cleanCode.length >= 4) {
      final digitWord =
          Localizations.localeOf(context).languageCode == 'fr'
              ? 'chiffres'
              : 'digits';
      SmartSnackBarManager.showInfoSnackBar(
        context,
        cleanCode.length == 6
            ? l10n.codePastedSuccessfully
            : '${l10n.codePartiallyPasted} (${cleanCode.length}/6 $digitWord)',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ✅ NOUVELLE MÉTHODE: Coller depuis le presse-papiers
  Future<void> _pasteFromClipboard() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        _handlePastedCode(clipboardData.text!);
      } else {
        SmartSnackBarManager.showWarningSnackBar(
          context,
          l10n.noCodeFoundInClipboard,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        l10n.errorPastingCode,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ✅ MISE À JOUR: Amélioration des champs de saisie
  Widget _buildCodeInputField(int index, AppLocalizations l10n) {
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onCodeChanged(value, index),
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
        onEditingComplete: () {
          if (_isCodeComplete && !_isLoading) {
            _verifyCode();
          }
        },
        // ✅ NOUVEAU: Gestion du collage via le menu contextuel (VERSION LOCALISÉE)
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              ContextMenuButtonItem(
                onPressed: () {
                  ContextMenuController.removeAny();
                  _pasteFromClipboard();
                },
                label: l10n.pasteCode,
              ),
              ContextMenuButtonItem(
                onPressed: () {
                  ContextMenuController.removeAny();
                  _clearCode();
                },
                label: l10n.clear,
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ MISE À JOUR: Section des champs de code avec bouton coller
  Widget _buildCodeInputSection(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.enterSixDigitCode,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Champs de saisie du code
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => _buildCodeInputField(index, l10n),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ NOUVEAU: Bouton "Coller le code" (VERSION LOCALISÉE)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isLoading ? null : _pasteFromClipboard,
              icon: Icon(
                Icons.content_paste,
                color: _isLoading ? Colors.grey[400] : Colors.blue[600],
                size: 18,
              ),
              label: Text(
                l10n.pasteCode,
                style: TextStyle(
                  color: _isLoading ? Colors.grey[400] : Colors.blue[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Bouton effacer si il y a du contenu (VERSION LOCALISÉE)
            if (_verificationCode.isNotEmpty)
              TextButton.icon(
                onPressed: _isLoading ? null : _clearCode,
                icon: Icon(
                  Icons.clear,
                  color: _isLoading ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
                label: Text(
                  l10n.clear,
                  style: TextStyle(
                    color: _isLoading ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Propriétés calculées
  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isCodeComplete {
    return _verificationCode.length == 6;
  }

  // Méthodes d'action
  void _verifyCode() {
    if (_isCodeComplete && !_isLoading) {
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed:
              _isLoading || _isRedirecting
                  ? null
                  : () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
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
            // ✅ CAS RARE: Email vérifié mais pas de tokens (ne se produit normalement jamais)
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.emailConfirmedSuccess,
              duration: const Duration(seconds: 2),
            );

            // Rediriger vers LoginScreen pour reconnecter
            if (!_hasNavigated) {
              setState(() => _hasNavigated = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              });
            }
          } else if (state is AuthSuccess) {
            // ✅ CAS NORMAL: Email vérifié + utilisateur connecté automatiquement
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.emailConfirmedSuccess,
              duration: const Duration(seconds: 2),
            );

            // ✅ CORRECTION: TOUJOURS rediriger vers HomeScreen car l'utilisateur a une session
            if (!_hasNavigated) {
              setState(() => _hasNavigated = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              });
            }
          } else if (state is VerificationCodeResent) {
            setState(() => _isLoading = false);

            SmartSnackBarManager.clearAll(context);
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.verificationCodeSent,
              duration: const Duration(seconds: 2),
            );
            _clearCode();
            // ✅ CORRECTION: Rester sur la même page (pas de redirection)
          } else if (state is AuthFailure) {
            setState(() => _isLoading = false);

            SmartSnackBarManager.showErrorSnackBar(
              context,
              state.error,
              duration: const Duration(seconds: 4),
            );
            _clearCode();
            // ✅ Réinitialiser le flag en cas d'erreur
            setState(() => _hasNavigated = false);
          } else if (state is Unauthenticated) {
            setState(() => _isLoading = false);

            // ✅ OPTIONNEL: Rediriger vers LoginScreen si déconnecté
            if (!_hasNavigated) {
              setState(() => _hasNavigated = true);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              });
            }
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    l10n.emailVerified,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    l10n.verificationCodeSentTo(widget.email),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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

                  const SizedBox(height: 32),

                  // Indicateur de chargement
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
                            l10n.processing,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ✅ UTILISATION DE LA NOUVELLE SECTION
                  _buildCodeInputSection(l10n),

                  const SizedBox(height: 32),

                  // Verification button
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
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                l10n.verificationCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resend code section
                  Column(
                    children: [
                      Text(
                        l10n.verificationCodeSent,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      if (!_canResend)
                        Text(
                          '${l10n.resendCode} ${_resendCountdown}s',
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
                            l10n.resendCode,
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

                  const SizedBox(height: 20),

                  // Information message
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
                            l10n.checkEmailsAndSpam,
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

                  const SizedBox(height: 20),

                  // Message informatif sur la redirection automatique
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.home, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.afterRegistrationEmailVerification,
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
