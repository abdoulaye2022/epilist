// blocs/auth/auth_bloc.dart - VERSION PRODUCTION

import 'package:epilist/models/account_deletion_status.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/notification_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/user.dart';
import 'dart:async';
import 'dart:io';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final AccountDeletionService accountDeletionService;
  final LocalizationBloc localizationBloc;
  Timer? _tokenRefreshTimer;

  AuthBloc({
    required this.authService,
    required this.accountDeletionService,
    required this.localizationBloc,
  }) : super(AuthInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthentication>(_onCheckAuthentication);
    on<RegisterRequested>(_onRegisterRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
    on<GetCurrentUser>(_onGetCurrentUser);
    on<UpdateProfile>(_onUpdateProfile);
    on<ClearAuthError>(_onClearAuthError);
    on<RequestPasswordChangeCode>(_onRequestPasswordChangeCode);
    on<VerifyPasswordChangeCode>(_onVerifyPasswordChangeCode);
    on<ConfirmEmailRequested>(_onConfirmEmailRequested);
    on<ResendVerificationCode>(_onResendVerificationCode);
    on<RequestAccountDeletion>(_onRequestAccountDeletion);
    on<ConfirmAccountDeletion>(_onConfirmAccountDeletion);
    on<CancelAccountDeletion>(_onCancelAccountDeletion);
    on<GetAccountDeletionStatus>(_onGetAccountDeletionStatus);
    on<UpdateUserData>(_onUpdateUserData);
  }

  @override
  Future<void> close() {
    _tokenRefreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🟦 Début de _onLoginButtonPressed');

      final loginResponse = await authService.login(
        event.email,
        event.password,
      );

      print('🟦 Login réussi, tokens reçus');

      await authService.saveTokens(
        loginResponse['access_token']!,
        loginResponse['refresh_token']!,
      );

      final user = await authService.getCurrentUser();
      if (user == null) {
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        print('🟦 Erreur utilisateur null: $errorMessage');
        emit(AuthFailure(error: errorMessage));
        return;
      }

      _scheduleTokenRefresh();
      await _updateFCMTokenAfterLogin();
      emit(AuthSuccess(user: user));
      print('🟦 AuthSuccess émis avec succès');
    } on AuthenticationException catch (e) {
      // ✅ CORRECTION: Ce catch doit être en PREMIER
      print('🔴 AuthenticationException attrapée dans _onLoginButtonPressed:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Email: ${e.email}');

      await _handleAuthenticationException(e, event.email, emit);
    } catch (e) {
      // ✅ CORRECTION: Ce catch général doit être en DERNIER
      print('🔴 Autre exception attrapée dans _onLoginButtonPressed: $e');
      print('🔴 Type de l\'exception: ${e.runtimeType}');

      // ✅ AJOUT: Vérifier si c'est quand même une AuthenticationException
      if (e is AuthenticationException) {
        print(
          '🔴 ATTENTION: AuthenticationException catchée dans le catch général !',
        );
        await _handleAuthenticationException(e, event.email, emit);
        return;
      }

      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());

      print('🔴 Code extrait: $errorCode');
      print('🔴 Message traduit: $errorMessage');
      print('🔴 Émission de AuthFailure avec: $errorMessage');

      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _updateFCMTokenAfterLogin() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      final currentToken = NotificationService.getCurrentToken();
      if (currentToken == null) {
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          final token = NotificationService.getCurrentToken();
          if (token != null) {
            break;
          }
        }
      }

      try {
        await NotificationService.reRegisterDevice();
        return;
      } catch (standardError) {
        // Fallback avec refresh token
        try {
          await NotificationService.reRegisterDeviceWithTokenRefresh();
          return;
        } catch (refreshError) {
          // Dernier recours
          await NotificationService.ensureDeviceIsRegistered();
        }
      }
    } catch (e) {
      // La connexion continue même si FCM échoue
    }
  }

  Future<void> _onCheckAuthentication(
    CheckAuthentication event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isAuthenticated = await authService.isAuthenticated();
      if (isAuthenticated) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          _scheduleTokenRefresh();

          try {
            await Future.delayed(const Duration(milliseconds: 500));
            await NotificationService.ensureDeviceIsRegistered();
          } catch (fcmError) {
            // Continuer malgré l'erreur FCM
          }

          emit(AuthSuccess(user: user));
        } else {
          await authService.clearUserData();
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      final errorMessage = _getTranslatedErrorMessage(
        'AUTH_CHECK_ERROR',
        e.toString(),
      );
      emit(AuthFailure(error: errorMessage));
      await Future.delayed(const Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _handleAuthenticationException(
    AuthenticationException e,
    String email,
    Emitter<AuthState> emit,
  ) async {
    String errorCode;
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        errorCode = 'INVALID_CREDENTIALS';
        break;
      case 'USER_NOT_FOUND':
        errorCode = 'USER_NOT_FOUND';
        break;
      case 'EMAIL_NOT_VERIFIED':
        final emailToUse = e.email?.isNotEmpty == true ? e.email! : email;

        // ✅ CORRECTION: Ne PAS renvoyer automatiquement le code
        // Juste émettre l'état pour rediriger vers l'écran de vérification
        emit(EmailVerificationRequired(emailToUse));
        return;
      default:
        errorCode = 'INVALID_CREDENTIALS';
    }

    final errorMessage = _getTranslatedErrorMessage(errorCode, e.message);
    emit(AuthFailure(error: errorMessage));
  }

  Future<void> _onUpdateUserData(
    UpdateUserData event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthSuccess) {
      final currentState = state as AuthSuccess;
      emit(AuthSuccess(user: event.user, message: currentState.message));

      try {
        await authService.saveUserToCache(event.user);
      } catch (e) {
        // Ne pas émettre d'erreur car la mise à jour en mémoire a réussi
      }
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final tokens = await authService.refreshToken(event.refreshToken);

      await authService.saveTokens(
        tokens['access_token']!,
        tokens['refresh_token']!,
      );

      _scheduleTokenRefresh();

      emit(TokensRefreshed(tokens['access_token']!, tokens['refresh_token']!));
    } catch (e) {
      final errorMessage = _getTranslatedErrorMessage(
        'SESSION_EXPIRED',
        e.toString(),
      );
      emit(AuthFailure(error: errorMessage));
      await Future.delayed(const Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      _tokenRefreshTimer?.cancel();

      try {
        NotificationService.clearDeviceData();
      } catch (fcmError) {
        // Non bloquant
      }

      try {
        await authService.logout();
      } catch (logoutError) {
        // Continuer le logout même si le serveur échoue
      }

      try {
        await authService.clearUserData();
      } catch (clearError) {
        // Continuer
      }

      await Future.delayed(const Duration(milliseconds: 300));
      emit(Unauthenticated());
    } catch (e) {
      try {
        _tokenRefreshTimer?.cancel();
        await authService.clearUserData();
        NotificationService.clearDeviceData();
        emit(Unauthenticated());
      } catch (clearError) {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.register(
        event.firstName,
        event.lastName,
        event.email,
        event.password,
      );
      emit(EmailConfirmationRequired(event.email));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      final errorMessage = _getTranslatedErrorMessage(
        'USER_INFO_ERROR',
        e.toString(),
      );
      emit(AuthFailure(error: errorMessage));
      await Future.delayed(const Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final updatedUser = await authService.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
      );

      emit(ProfileUpdated(updatedUser));
      emit(AuthSuccess(user: updatedUser));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));

      try {
        final currentUser = await authService.getCurrentUser();
        if (currentUser != null) {
          emit(AuthSuccess(user: currentUser));
        } else {
          emit(Unauthenticated());
        }
      } catch (_) {
        emit(Unauthenticated());
      }
    }
  }

  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    if (state is AuthFailure) {
      emit(AuthInitial());
    }
  }

  Future<void> _onRequestPasswordChangeCode(
    RequestPasswordChangeCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.requestPasswordChangeCode(event.email);
      emit(PasswordChangeCodeSent(event.email));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onVerifyPasswordChangeCode(
    VerifyPasswordChangeCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.verifyPasswordChangeCode(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
      );
      emit(PasswordChanged());
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onConfirmEmailRequested(
    ConfirmEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final tokens = await authService.confirmEmail(
        email: event.email,
        code: event.code,
      );

      if (tokens != null) {
        await authService.saveTokens(
          tokens['access_token']!,
          tokens['refresh_token']!,
        );

        final user = await authService.getCurrentUser();
        if (user != null) {
          _scheduleTokenRefresh();

          // Mettre à jour le token FCM après confirmation d'email
          await _updateFCMTokenAfterLogin();

          emit(AuthSuccess(user: user));
        } else {
          final errorMessage = _getTranslatedErrorMessage(
            'USER_INFO_ERROR',
            '',
          );
          emit(AuthFailure(error: errorMessage));
        }
      } else {
        emit(EmailConfirmationSuccess());
      }
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onResendVerificationCode(
    ResendVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.resendVerificationCode(event.email);

      // ✅ CORRECTION: Une seule émission
      emit(VerificationCodeResent(event.email));

      // ✅ CORRECTION: Pas de re-émission vers EmailConfirmationRequired
      // L'écran gère déjà le fait qu'il reste sur la même page
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onRequestAccountDeletion(
    RequestAccountDeletion event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await accountDeletionService.requestAccountDeletion(
        reason: event.reason,
      );

      emit(
        AccountDeletionCodeSent(
          email: result['email_sent_to'] ?? '',
          codeExpiresInMinutes: result['code_expires_in_minutes'] ?? 120,
        ),
      );
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onConfirmAccountDeletion(
    ConfirmAccountDeletion event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await accountDeletionService.confirmAccountDeletion(
        deletionCode: event.deletionCode,
        reason: event.reason,
      );

      emit(
        AccountDeletionConfirmed(
          deletionEffectiveDate: DateTime.parse(
            result['deletion_effective_date'],
          ),
          canCancelUntil: DateTime.parse(result['can_cancel_until']),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      _tokenRefreshTimer?.cancel();
      NotificationService.clearDeviceData();
      await authService.clearUserData();
      emit(Unauthenticated());
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onCancelAccountDeletion(
    CancelAccountDeletion event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await accountDeletionService.cancelAccountDeletion();

      emit(AccountDeletionCancelled());

      final user = await authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  Future<void> _onGetAccountDeletionStatus(
    GetAccountDeletionStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final status = await accountDeletionService.getAccountDeletionStatus();
      emit(AccountDeletionStatusLoaded(status));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  void _scheduleTokenRefresh() async {
    _tokenRefreshTimer?.cancel();

    try {
      final shouldRefresh = await authService.shouldRefreshSoon();

      if (shouldRefresh) {
        _tokenRefreshTimer = Timer(const Duration(days: 1), () async {
          try {
            final refreshToken = await authService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              add(RefreshTokenRequested(refreshToken));
            }
          } catch (e) {
            // Log error in production monitoring
          }
        });
      } else {
        _tokenRefreshTimer = Timer(const Duration(days: 7), () async {
          try {
            final refreshToken = await authService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              add(RefreshTokenRequested(refreshToken));
            }
          } catch (e) {
            // Log error in production monitoring
          }
        });
      }
    } catch (e) {
      _tokenRefreshTimer = Timer(const Duration(days: 1), () async {
        try {
          final refreshToken = await authService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            add(RefreshTokenRequested(refreshToken));
          }
        } catch (e) {
          // Log error in production monitoring
        }
      });
    }
  }

  String _getTranslatedErrorMessage(String errorCode, String errorMessage) {
    const Map<String, String> frenchMessages = {
      'INVALID_CREDENTIALS': 'Email ou mot de passe incorrect',
      'INVALID_PASSWORD': 'Email ou mot de passe incorrect',
      'USER_NOT_FOUND': 'Aucun compte trouvé avec cet email',
      'EMAIL_NOT_VERIFIED': 'Email non vérifié',
      'EMAIL_ALREADY_EXISTS': 'Cette adresse email est déjà utilisée',
      'NETWORK_ERROR': 'Erreur de réseau',
      'SERVER_ERROR': 'Erreur du serveur',
      'VALIDATION_ERROR': 'Les données saisies ne sont pas valides',
      'UNKNOWN_ERROR': 'Une erreur inattendue est survenue',
      'AUTH_ERROR': 'Une erreur est survenue lors de la connexion',
      'SESSION_EXPIRED': 'Session expirée - Veuillez vous reconnecter',
      'CONNECTION_ERROR': 'Erreur de connexion - Vérifiez votre réseau',
      'USER_INFO_ERROR': 'Impossible de récupérer les informations utilisateur',
      'AUTH_CHECK_ERROR': 'Échec de la vérification d\'authentification',
      'LOGOUT_ERROR': 'Erreur lors de la déconnexion',
      'INVALID_CODE': 'Le code de vérification est invalide',
      'CODE_EXPIRED': 'Le code de vérification a expiré',
      'VERIFICATION_ERROR': 'Erreur lors de la vérification',
      'PASSWORD_CHANGE_ERROR': 'Erreur lors du changement de mot de passe',
      'USER_INACTIVE': 'Ce compte utilisateur n\'est pas actif',
      'INVALID_VERIFICATION_CODE': 'Le code de vérification est invalide',
      'EXPIRED_VERIFICATION_CODE': 'Le code de vérification a expiré',
      'EMAIL_ALREADY_VERIFIED': 'Cet email est déjà vérifié',
      'SERVICE_UNAVAILABLE': 'Service temporairement indisponible',
      'RESEND_FAILED': 'Erreur lors du renvoi du code',
      'SERVER_CONFIG_ERROR': 'Erreur de configuration du serveur',
      'INVALID_EMAIL_FORMAT': 'Format d\'email invalide',
      'TOO_MANY_ATTEMPTS':
          'Trop de tentatives. Veuillez réessayer plus tard', // ✅ AJOUT
      'RATE_LIMITED':
          'Trop de tentatives. Veuillez réessayer plus tard', // ✅ AJOUT
      'ACCOUNT_DISABLED': 'Ce compte utilisateur est désactivé', // ✅ AJOUT
    };

    const Map<String, String> englishMessages = {
      'INVALID_CREDENTIALS': 'Invalid email or password',
      'INVALID_PASSWORD': 'Invalid email or password',
      'USER_NOT_FOUND': 'No account found with this email',
      'EMAIL_NOT_VERIFIED': 'Email not verified',
      'EMAIL_ALREADY_EXISTS': 'This email address is already in use',
      'NETWORK_ERROR': 'Network error',
      'SERVER_ERROR': 'Server error',
      'VALIDATION_ERROR': 'The entered data is not valid',
      'UNKNOWN_ERROR': 'An unexpected error occurred',
      'AUTH_ERROR': 'An error occurred during login',
      'SESSION_EXPIRED': 'Session expired - Please log in again',
      'CONNECTION_ERROR': 'Connection error - Check your network',
      'USER_INFO_ERROR': 'Unable to retrieve user information',
      'AUTH_CHECK_ERROR': 'Authentication check failed',
      'LOGOUT_ERROR': 'Error during logout',
      'INVALID_CODE': 'The verification code is invalid',
      'CODE_EXPIRED': 'The verification code has expired',
      'VERIFICATION_ERROR': 'Verification error occurred',
      'PASSWORD_CHANGE_ERROR': 'Error changing password',
      'USER_INACTIVE': 'This user account is not active',
      'INVALID_VERIFICATION_CODE': 'The verification code is invalid',
      'EXPIRED_VERIFICATION_CODE': 'The verification code has expired',
      'EMAIL_ALREADY_VERIFIED': 'This email is already verified',
      'SERVICE_UNAVAILABLE': 'Service temporarily unavailable',
      'RESEND_FAILED': 'Error sending code',
      'SERVER_CONFIG_ERROR': 'Server configuration error',
      'INVALID_EMAIL_FORMAT': 'Invalid email format',
      'TOO_MANY_ATTEMPTS':
          'Too many attempts. Please try again later', // ✅ AJOUT
      'RATE_LIMITED': 'Too many attempts. Please try again later', // ✅ AJOUT
      'ACCOUNT_DISABLED': 'This user account is disabled', //
    };

    final isEnglish =
        localizationBloc.state is LocalizationLoaded &&
        (localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishMessages[errorCode] ?? englishMessages['UNKNOWN_ERROR']!;
    } else {
      return frenchMessages[errorCode] ?? frenchMessages['UNKNOWN_ERROR']!;
    }
  }

  String _extractErrorCode(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid') &&
        (errorString.contains('credentials') ||
            errorString.contains('password'))) {
      return 'INVALID_CREDENTIALS';
    } else if (errorString.contains('user') &&
        errorString.contains('not found')) {
      return 'USER_NOT_FOUND';
    } else if (errorString.contains('email') &&
        errorString.contains('not verified')) {
      return 'EMAIL_NOT_VERIFIED';
    } else if (errorString.contains('email') &&
        (errorString.contains('exists') || errorString.contains('conflict'))) {
      return 'EMAIL_ALREADY_EXISTS';
    } else if (errorString.contains('too many') &&
        errorString.contains('attempts')) {
      return 'TOO_MANY_ATTEMPTS';
    } else if (errorString.contains('rate') && errorString.contains('limit')) {
      return 'RATE_LIMITED';
    } else if (errorString.contains('account') &&
        (errorString.contains('disabled') ||
            errorString.contains('inactive'))) {
      return 'USER_INACTIVE';
    } else if (errorString.contains('network') ||
        errorString.contains('réseau') ||
        errorString.contains('connection')) {
      return 'NETWORK_ERROR';
    } else if (errorString.contains('server') ||
        errorString.contains('serveur')) {
      return 'SERVER_ERROR';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid data')) {
      return 'VALIDATION_ERROR';
    } else if (errorString.contains('session') &&
        errorString.contains('expired')) {
      return 'SESSION_EXPIRED';
    } else if (errorString.contains('failed to check authentication')) {
      return 'AUTH_CHECK_ERROR';
    } else if (errorString.contains('impossible de récupérer') ||
        errorString.contains('unable to retrieve')) {
      return 'USER_INFO_ERROR';
    } else if (errorString.contains('déconnexion') ||
        errorString.contains('logout')) {
      return 'LOGOUT_ERROR';
    } else if (errorString.contains('invalid') &&
        errorString.contains('code')) {
      return 'INVALID_CODE';
    } else if (errorString.contains('code') &&
        (errorString.contains('expired') || errorString.contains('expiré'))) {
      return 'CODE_EXPIRED';
    } else if (errorString.contains('verification') &&
        errorString.contains('error')) {
      return 'VERIFICATION_ERROR';
    } else if (errorString.contains('password') &&
        errorString.contains('change')) {
      return 'PASSWORD_CHANGE_ERROR';
    } else if (errorString.contains('user') &&
        errorString.contains('inactive')) {
      return 'USER_INACTIVE';
    } else if (errorString.contains('email') &&
        errorString.contains('already verified')) {
      return 'EMAIL_ALREADY_VERIFIED';
    } else if (errorString.contains('service') &&
        errorString.contains('unavailable')) {
      return 'SERVICE_UNAVAILABLE';
    } else if (errorString.contains('resend') &&
        errorString.contains('failed')) {
      return 'RESEND_FAILED';
    } else if (errorString.contains('server') &&
        errorString.contains('config')) {
      return 'SERVER_CONFIG_ERROR';
    } else if (errorString.contains('invalid') &&
        errorString.contains('email')) {
      return 'INVALID_EMAIL_FORMAT';
    }

    return 'UNKNOWN_ERROR';
  }
}
