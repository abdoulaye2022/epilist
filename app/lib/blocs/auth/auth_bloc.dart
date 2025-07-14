// auth_bloc.dart - VERSION CORRIGÉE AVEC LOCALISATION
import 'package:epilist/models/account_deletion_status.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart'; // ✅ NOUVEAU
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/models/user.dart';
import 'dart:async';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final AccountDeletionService accountDeletionService;
  final LocalizationBloc localizationBloc; // ✅ NOUVEAU
  Timer? _tokenRefreshTimer;

  AuthBloc({
    required this.authService,
    required this.accountDeletionService,
    required this.localizationBloc, // ✅ NOUVEAU
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
  }

  @override
  Future<void> close() {
    _tokenRefreshTimer?.cancel();
    return super.close();
  }

  /// ✅ NOUVEAU: Méthode pour obtenir les messages d'erreur traduits
  String _getTranslatedErrorMessage(String errorCode, String errorMessage) {
    // Messages en français
    const Map<String, String> frenchMessages = {
      'INVALID_CREDENTIALS': 'Email ou mot de passe incorrect',
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
    };

    // Messages en anglais
    const Map<String, String> englishMessages = {
      'INVALID_CREDENTIALS': 'Invalid email or password',
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
    };

    // Déterminer la langue
    final isEnglish =
        localizationBloc.state is LocalizationLoaded &&
        (localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    // Retourner le message traduit ou le message original en fallback
    if (isEnglish) {
      return englishMessages[errorCode] ?? englishMessages['UNKNOWN_ERROR']!;
    } else {
      return frenchMessages[errorCode] ?? frenchMessages['UNKNOWN_ERROR']!;
    }
  }

  /// ✅ NOUVEAU: Méthode pour analyser l'exception et extraire le code d'erreur
  String _extractErrorCode(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Codes d'erreur basés sur le contenu du message
    if (errorString.contains('invalid') &&
        errorString.contains('credentials')) {
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

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final loginResponse = await authService.login(
        event.email,
        event.password,
      );

      // Sauvegarder les tokens de manière persistante
      await authService.saveTokens(
        loginResponse['access_token']!,
        loginResponse['refresh_token']!,
      );

      // Récupérer l'utilisateur
      final user = await authService.getCurrentUser();
      if (user != null) {
        _scheduleTokenRefresh(); // Programmer le refresh adaptatif
        emit(AuthSuccess(user: user));
      } else {
        // ✅ UTILISER la traduction pour ce message d'erreur
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        emit(AuthFailure(error: errorMessage));
      }
    } on AuthenticationException catch (e) {
      // ✅ GÉRER les exceptions d'authentification avec traduction
      String errorCode;
      switch (e.code) {
        case 'INVALID_CREDENTIALS':
          errorCode = 'INVALID_CREDENTIALS';
          break;
        case 'USER_NOT_FOUND':
          errorCode = 'USER_NOT_FOUND';
          break;
        case 'EMAIL_NOT_VERIFIED':
          final email = e.email?.isNotEmpty == true ? e.email! : event.email;

          try {
            await authService.resendVerificationCode(email);
            emit(EmailVerificationRequired(email));
          } catch (resendError) {
            emit(EmailVerificationRequired(email));
          }
          return;
        default:
          errorCode = 'AUTH_ERROR';
      }

      final errorMessage = _getTranslatedErrorMessage(errorCode, e.message);
      emit(AuthFailure(error: errorMessage));
    } catch (e) {
      // ✅ GÉRER les autres erreurs avec traduction
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
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
          _scheduleTokenRefresh(); // Programmer le refresh adaptatif
          emit(AuthSuccess(user: user));
        } else {
          await authService.clearUserData();
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      // ✅ UTILISER la traduction pour l'erreur de vérification
      final errorMessage = _getTranslatedErrorMessage(
        'AUTH_CHECK_ERROR',
        e.toString(),
      );
      emit(AuthFailure(error: errorMessage));
      await Future.delayed(const Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final tokens = await authService.refreshToken(event.refreshToken);

      // Sauvegarder les nouveaux tokens
      await authService.saveTokens(
        tokens['access_token']!,
        tokens['refresh_token']!,
      );

      // Programmer le prochain refresh
      _scheduleTokenRefresh();

      // Émettre l'état de succès avec les tokens mis à jour
      emit(TokensRefreshed(tokens['access_token']!, tokens['refresh_token']!));
    } catch (e) {
      // ✅ UTILISER la traduction pour l'erreur de session expirée
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
      // Annuler le timer de refresh
      _tokenRefreshTimer?.cancel();

      // Effectuer la déconnexion côté serveur
      await authService.logout();

      // Nettoyer toutes les données locales
      await authService.clearUserData();

      await Future.delayed(const Duration(milliseconds: 100));
      emit(Unauthenticated());
    } catch (e) {
      // Forcer la déconnexion locale même en cas d'erreur
      try {
        _tokenRefreshTimer?.cancel();
        await authService.clearUserData();
        emit(Unauthenticated());
      } catch (clearError) {
        // ✅ UTILISER la traduction pour l'erreur de déconnexion
        final errorMessage = _getTranslatedErrorMessage(
          'LOGOUT_ERROR',
          e.toString(),
        );
        emit(AuthFailure(error: errorMessage));
        await Future.delayed(const Duration(seconds: 2));
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
      // ✅ UTILISER la traduction pour les erreurs d'inscription
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
      // ✅ UTILISER la traduction pour l'erreur de récupération utilisateur
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
      // ✅ UTILISER la traduction pour les erreurs de mise à jour profil
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
      // ✅ UTILISER la traduction pour les erreurs de demande de code
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
      // ✅ UTILISER la traduction pour les erreurs de vérification de code
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
          emit(AuthSuccess(user: user));
        } else {
          // ✅ UTILISER la traduction pour l'erreur d'informations utilisateur
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
      // ✅ UTILISER la traduction pour les erreurs de confirmation d'email
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
      emit(VerificationCodeResent(event.email));

      await Future.delayed(const Duration(milliseconds: 500));
      emit(EmailConfirmationRequired(event.email));
    } catch (e) {
      // ✅ UTILISER la traduction pour les erreurs de renvoi de code
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  // ⭐ MÉTHODE INCHANGÉE: Programmer le rafraîchissement adaptatif du token
  void _scheduleTokenRefresh() async {
    _tokenRefreshTimer?.cancel();

    try {
      // Vérifier si le token doit être rafraîchi bientôt
      final shouldRefresh = await authService.shouldRefreshSoon();

      if (shouldRefresh) {
        // Si le token expire dans moins de 7 jours, programmer un refresh dans 1 jour
        _tokenRefreshTimer = Timer(const Duration(days: 1), () async {
          try {
            final refreshToken = await authService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              add(RefreshTokenRequested(refreshToken));
            }
          } catch (e) {
            print('Erreur lors du refresh programmé: $e');
          }
        });

        print('Refresh programmé dans 1 jour (token expire bientôt)');
      } else {
        // Si le token a encore plus de 7 jours, programmer un refresh dans 7 jours
        _tokenRefreshTimer = Timer(const Duration(days: 7), () async {
          try {
            final refreshToken = await authService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              add(RefreshTokenRequested(refreshToken));
            }
          } catch (e) {
            print('Erreur lors du refresh programmé: $e');
          }
        });

        print('Refresh programmé dans 7 jours');
      }
    } catch (e) {
      print('Erreur lors de la programmation du refresh: $e');
      // En cas d'erreur, programmer un refresh dans 1 jour par sécurité
      _tokenRefreshTimer = Timer(const Duration(days: 1), () async {
        try {
          final refreshToken = await authService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            add(RefreshTokenRequested(refreshToken));
          }
        } catch (e) {
          print('Erreur lors du refresh de secours: $e');
        }
      });
    }
  }

  // [Les méthodes de suppression de compte avec traductions]
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
      // ✅ UTILISER la traduction pour les erreurs de suppression de compte
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
      await authService.clearUserData();
      emit(Unauthenticated());
    } catch (e) {
      // ✅ UTILISER la traduction pour les erreurs de confirmation de suppression
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
      // ✅ UTILISER la traduction pour les erreurs d'annulation de suppression
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
      // ✅ UTILISER la traduction pour les erreurs de statut de suppression
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }
}
