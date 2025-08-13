// blocs/auth/auth_bloc.dart - VERSION ANDROID (GOOGLE SSO SEULEMENT)
import 'package:epilist/models/account_deletion_status.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/notification_service.dart';
import 'package:epilist/services/sso_service.dart';
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
    // Événements existants
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

    // ✅ ÉVÉNEMENTS SSO - GOOGLE SEULEMENT
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    // ❌ APPLE COMMENTÉ POUR ANDROID
    // on<AppleSignInRequested>(_onAppleSignInRequested);
    on<SSOLoginCompleted>(_onSSOLoginCompleted);
    on<SSORegisterCompleted>(_onSSORegisterCompleted);
    on<LinkSSOAccount>(_onLinkSSOAccount);
    on<UnlinkSSOAccount>(_onUnlinkSSOAccount);
  }

  @override
  Future<void> close() {
    _tokenRefreshTimer?.cancel();
    return super.close();
  }

  // ===================== ÉVÉNEMENTS SSO =====================

  /// ✅ CONNEXION GOOGLE
  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SSOLoading(provider: 'google', action: 'login'));

    try {
      print('🔵 [AuthBloc] Début de la connexion Google...');

      // 1. ✅ CONNEXION GOOGLE ET SAUVEGARDE AUTOMATIQUE DES TOKENS
      final tokens = await authService.loginWithGoogle();
      print(
        '🔵 [AuthBloc] Tokens Google reçus: ${tokens['access_token']?.substring(0, 20)}...',
      );

      // 2. ✅ VÉRIFICATION QUE LES TOKENS SONT BIEN SAUVEGARDÉS
      final savedToken = await authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        print('❌ [AuthBloc] PROBLÈME: Token non sauvegardé après login Google');
        throw AuthenticationException(
          'Token non sauvegardé',
          'TOKEN_SAVE_FAILED',
        );
      }
      print(
        '✅ [AuthBloc] Token sauvegardé confirmé: ${savedToken.substring(0, 20)}...',
      );

      // 3. ✅ RÉCUPÉRATION UTILISATEUR
      final user = await authService.getCurrentUser();
      if (user == null) {
        print('❌ [AuthBloc] PROBLÈME: Utilisateur null après login Google');
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        emit(SSOError(provider: 'google', error: errorMessage));
        return;
      }
      print('✅ [AuthBloc] Utilisateur récupéré: ${user.fullName}');

      // 4. ✅ FINALISATION
      _scheduleTokenRefresh();
      await _registerFCMAfterSuccessfulLogin();

      emit(AuthSuccess(user: user, authMethod: 'google'));
      print('✅ [AuthBloc] Connexion Google terminée avec succès');
    } catch (e) {
      print('❌ [AuthBloc] Erreur lors de la connexion Google: $e');
      final errorMessage = _extractAndTranslateError(e, 'google');
      emit(
        SSOError(
          provider: 'google',
          error: errorMessage,
          details: e.toString(),
        ),
      );
    }
  }

  // ❌ APPLE SIGN-IN COMMENTÉ POUR ANDROID
  /*
  /// ✅ CONNEXION APPLE RESTAURÉE AVEC GESTION AUTHSERVICE
  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // ✅ VÉRIFICATION PRÉALABLE DE LA PLATEFORME
    if (!Platform.isIOS) {
      emit(
        const SSOError(
          provider: 'apple',
          error: 'Apple Sign-In est uniquement disponible sur iOS',
        ),
      );
      return;
    }

    // ✅ VÉRIFICATION DE DISPONIBILITÉ VIA SSOSERVICE
    final isAvailable = await SSOService.isAppleSignInAvailable();
    if (!isAvailable) {
      emit(
        const SSOError(
          provider: 'apple',
          error: 'Apple Sign-In n\'est pas disponible sur cet appareil',
        ),
      );
      return;
    }

    emit(const SSOLoading(provider: 'apple', action: 'login'));

    try {
      print('🍎 [AuthBloc] Début de la connexion Apple...');

      // ✅ CONNEXION APPLE DIRECTE VIA SSOSERVICE PUIS AUTHSERVICE
      Map<String, String> tokens;

      try {
        // Essayer d'abord AuthService (pour compatibilité)
        tokens = await authService.loginWithApple();
        print('🍎 [AuthBloc] Tokens Apple reçus via AuthService');
      } catch (authServiceError) {
        print(
          '⚠️ [AuthBloc] AuthService Apple échoué, essai direct SSOService...',
        );

        // Si AuthService échoue, utiliser SSOService directement
        final ssoResult = await SSOService.signInWithApple();
        if (!ssoResult.success) {
          throw Exception(ssoResult.error ?? 'Erreur SSO Apple');
        }

        // Simuler des tokens pour la compatibilité
        tokens = {
          'access_token': ssoResult.idToken ?? '',
          'refresh_token': ssoResult.accessToken ?? '',
        };
        print('🍎 [AuthBloc] Tokens Apple reçus via SSOService direct');
      }

      // 2. ✅ VÉRIFICATION QUE LES TOKENS SONT BIEN SAUVEGARDÉS
      final savedToken = await authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        print('❌ [AuthBloc] PROBLÈME: Token non sauvegardé après login Apple');

        // Sauvegarder manuellement
        if (tokens['access_token']?.isNotEmpty == true) {
          await authService.saveTokens(
            tokens['access_token']!,
            tokens['refresh_token'] ?? '',
          );
          print('✅ [AuthBloc] Tokens Apple sauvegardés manuellement');
        } else {
          throw AuthenticationException(
            'Token non sauvegardé',
            'TOKEN_SAVE_FAILED',
          );
        }
      }
      print('✅ [AuthBloc] Token sauvegardé confirmé');

      // 3. ✅ RÉCUPÉRATION UTILISATEUR
      final user = await authService.getCurrentUser();
      if (user == null) {
        print('❌ [AuthBloc] PROBLÈME: Utilisateur null après login Apple');
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        emit(SSOError(provider: 'apple', error: errorMessage));
        return;
      }

      // 4. ✅ FINALISATION
      _scheduleTokenRefresh();
      await _registerFCMAfterSuccessfulLogin();

      emit(AuthSuccess(user: user, authMethod: 'apple'));
      print('✅ [AuthBloc] Connexion Apple terminée avec succès');
    } catch (e) {
      print('❌ [AuthBloc] Erreur lors de la connexion Apple: $e');
      final errorMessage = _extractAndTranslateError(e, 'apple');
      emit(
        SSOError(provider: 'apple', error: errorMessage, details: e.toString()),
      );
    }
  }
  */

  /// ✅ CONNEXION SSO GÉNÉRALISÉE - GOOGLE SEULEMENT
  Future<void> _onSSOLoginCompleted(
    SSOLoginCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(SSOLoading(provider: event.provider, action: 'login'));

    try {
      print('🔐 [AuthBloc] Traitement de la connexion SSO ${event.provider}');

      Map<String, String> tokens;

      if (event.provider == 'google') {
        tokens = await authService.loginWithGoogle();
      }
      // ❌ APPLE COMMENTÉ POUR ANDROID
      /* 
      else if (event.provider == 'apple') {
        tokens = await authService.loginWithApple();
      } 
      */
      else {
        throw Exception('Provider SSO non supporté: ${event.provider}');
      }

      // ✅ VÉRIFICATION CRITIQUE: LES TOKENS SONT-ILS SAUVEGARDÉS ?
      final savedToken = await authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        print(
          '❌ [AuthBloc] CRITIQUE: Token non sauvegardé après SSO ${event.provider}',
        );

        // ✅ TENTATIVE DE SAUVEGARDE MANUELLE
        if (tokens['access_token'] != null && tokens['refresh_token'] != null) {
          print('🔄 [AuthBloc] Tentative de sauvegarde manuelle des tokens...');
          await authService.saveTokens(
            tokens['access_token']!,
            tokens['refresh_token']!,
          );

          // Vérifier de nouveau
          final reCheckToken = await authService.getToken();
          if (reCheckToken == null) {
            throw AuthenticationException(
              'Impossible de sauvegarder les tokens',
              'TOKEN_SAVE_CRITICAL_FAILED',
            );
          }
          print('✅ [AuthBloc] Sauvegarde manuelle réussie');
        } else {
          throw AuthenticationException(
            'Tokens invalides reçus du serveur',
            'INVALID_TOKENS_RECEIVED',
          );
        }
      }

      final user = await authService.getCurrentUser();
      if (user == null) {
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        emit(SSOError(provider: event.provider, error: errorMessage));
        return;
      }

      _scheduleTokenRefresh();
      await _registerFCMAfterSuccessfulLogin();

      emit(AuthSuccess(user: user, authMethod: event.provider));
      print('✅ [AuthBloc] SSO ${event.provider} terminé avec succès');
    } catch (e) {
      print(
        '❌ [AuthBloc] Erreur lors de la connexion SSO ${event.provider}: $e',
      );
      final errorMessage = _extractAndTranslateError(e, event.provider);
      emit(
        SSOError(
          provider: event.provider,
          error: errorMessage,
          details: e.toString(),
        ),
      );
    }
  }

  /// ✅ INSCRIPTION SSO - GOOGLE SEULEMENT
  Future<void> _onSSORegisterCompleted(
    SSORegisterCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(SSOLoading(provider: event.provider, action: 'register'));

    try {
      print('📝 [AuthBloc] Traitement de l\'inscription SSO ${event.provider}');

      if (event.provider == 'google') {
        await authService.registerWithGoogle();
      }
      // ❌ APPLE COMMENTÉ POUR ANDROID
      /*
      else if (event.provider == 'apple') {
        await authService.registerWithApple();
      } 
      */
      else {
        throw Exception('Provider SSO non supporté: ${event.provider}');
      }

      // ✅ APRÈS INSCRIPTION, ESSAYER DE SE CONNECTER AUTOMATIQUEMENT
      print(
        '🔄 [AuthBloc] Inscription ${event.provider} terminée, connexion automatique...',
      );
      await Future.delayed(const Duration(milliseconds: 500));

      Map<String, String> tokens;
      if (event.provider == 'google') {
        tokens = await authService.loginWithGoogle();
      }
      // ❌ APPLE COMMENTÉ POUR ANDROID
      /*
      else {
        tokens = await authService.loginWithApple();
      }
      */
      else {
        throw Exception('Provider SSO non supporté: ${event.provider}');
      }

      // ✅ VÉRIFICATION DES TOKENS APRÈS INSCRIPTION
      final savedToken = await authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        print(
          '❌ [AuthBloc] Token non sauvegardé après inscription ${event.provider}',
        );

        if (tokens['access_token'] != null && tokens['refresh_token'] != null) {
          await authService.saveTokens(
            tokens['access_token']!,
            tokens['refresh_token']!,
          );
          print(
            '✅ [AuthBloc] Tokens sauvegardés manuellement après inscription',
          );
        } else {
          // ✅ Si pas de tokens, créer un utilisateur temporaire
          emit(
            SSORegistrationSuccess(
              provider: event.provider,
              user: _createTemporaryUser(event.provider),
            ),
          );
          return;
        }
      }

      final user = await authService.getCurrentUser();
      if (user == null) {
        emit(
          SSORegistrationSuccess(
            provider: event.provider,
            user: _createTemporaryUser(event.provider),
          ),
        );
        return;
      }

      _scheduleTokenRefresh();
      await _registerFCMAfterSuccessfulLogin();

      emit(AuthSuccess(user: user, authMethod: event.provider));
      print(
        '✅ [AuthBloc] Inscription et connexion ${event.provider} terminées',
      );
    } catch (e) {
      print(
        '❌ [AuthBloc] Erreur lors de l\'inscription SSO ${event.provider}: $e',
      );
      final errorMessage = _extractAndTranslateError(e, event.provider);
      emit(
        SSOError(
          provider: event.provider,
          error: errorMessage,
          details: e.toString(),
        ),
      );
    }
  }

  /// ✅ MÉTHODE POUR CRÉER UN UTILISATEUR TEMPORAIRE
  User _createTemporaryUser(String provider) {
    return User(
      id: DateTime.now().millisecondsSinceEpoch,
      firstName: 'Utilisateur',
      lastName: provider == 'google' ? 'Google' : 'Unknown',
      email: 'temp_${provider}@sso.com',
      emailVerified: true,
      accessToken: null,
      refreshToken: null,
      emailVerifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currency: null,
      isActive: true,
    );
  }

  // ===================== ÉVÉNEMENTS DE LIAISON SSO =====================

  Future<void> _onLinkSSOAccount(
    LinkSSOAccount event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('🔗 [AuthBloc] Liaison du compte ${event.provider}');

      SSOResult ssoResult;
      if (event.provider == 'google') {
        ssoResult = await SSOService.signInWithGoogle();
      }
      // ❌ APPLE COMMENTÉ POUR ANDROID
      /*
      else if (event.provider == 'apple') {
        ssoResult = await SSOService.signInWithApple();
      } 
      */
      else {
        throw Exception('Provider non supporté: ${event.provider}');
      }

      if (!ssoResult.success) {
        throw Exception(ssoResult.error ?? 'Erreur SSO');
      }

      await authService.linkSSOAccount(event.provider, ssoResult);

      emit(
        SSOAccountLinked(
          provider: event.provider,
          message: 'Compte ${event.provider} lié avec succès',
        ),
      );

      final user = await authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      }
    } catch (e) {
      print('❌ [AuthBloc] Erreur lors de la liaison ${event.provider}: $e');
      final errorMessage = _extractAndTranslateError(e, event.provider);
      emit(SSOAccountLinkError(provider: event.provider, error: errorMessage));
    }
  }

  Future<void> _onUnlinkSSOAccount(
    UnlinkSSOAccount event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('🔗❌ [AuthBloc] Déliaison du compte ${event.provider}');

      await authService.unlinkSSOAccount(event.provider);

      emit(
        SSOAccountUnlinked(
          provider: event.provider,
          message: 'Compte ${event.provider} délié avec succès',
        ),
      );

      final user = await authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      }
    } catch (e) {
      print('❌ [AuthBloc] Erreur lors de la déliaison ${event.provider}: $e');
      final errorMessage = _extractAndTranslateError(e, event.provider);
      emit(SSOAccountLinkError(provider: event.provider, error: errorMessage));
    }
  }

  // ===================== ÉVÉNEMENTS EXISTANTS (inchangés) =====================

  /// ✅ LOGIN CLASSIQUE
  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🔐 [AuthBloc] Début du login classique');

      final loginResponse = await authService.login(
        event.email,
        event.password,
      );
      print('🔐 [AuthBloc] Login réussi, tokens reçus');

      // ✅ VÉRIFICATION QUE LES TOKENS SONT SAUVEGARDÉS
      final savedToken = await authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        print(
          '❌ [AuthBloc] PROBLÈME: Token non sauvegardé après login classique',
        );

        // Sauvegarde manuelle
        await authService.saveTokens(
          loginResponse['access_token']!,
          loginResponse['refresh_token']!,
        );
        print('✅ [AuthBloc] Tokens sauvegardés manuellement');
      }

      final user = await authService.getCurrentUser();
      if (user == null) {
        final errorMessage = _getTranslatedErrorMessage('USER_INFO_ERROR', '');
        emit(AuthFailure(error: errorMessage));
        return;
      }

      _scheduleTokenRefresh();
      await _registerFCMAfterSuccessfulLogin();

      emit(AuthSuccess(user: user, authMethod: 'email'));
      print('✅ [AuthBloc] Login classique terminé avec succès');
    } on AuthenticationException catch (e) {
      print('❌ [AuthBloc] AuthenticationException: ${e.code} - ${e.message}');
      await _handleAuthenticationException(e, event.email, emit);
    } catch (e) {
      print('❌ [AuthBloc] Erreur générale login: $e');

      if (e is AuthenticationException) {
        await _handleAuthenticationException(e, event.email, emit);
        return;
      }

      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  /// ✅ CHECK AUTHENTICATION
  Future<void> _onCheckAuthentication(
    CheckAuthentication event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🔍 [AuthBloc] Vérification de l\'authentification...');

      final isAuthenticated = await authService.isAuthenticated();
      print('🔍 [AuthBloc] Authentifié: $isAuthenticated');

      if (isAuthenticated) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          print('✅ [AuthBloc] Utilisateur trouvé: ${user.fullName}');

          _scheduleTokenRefresh();

          try {
            await Future.delayed(const Duration(milliseconds: 500));
            final isRegistered = await NotificationService.isDeviceRegistered();
            if (!isRegistered) {
              print('📱 [AuthBloc] Device non enregistré, enregistrement...');
              await NotificationService.registerAfterLogin();
            }
          } catch (fcmError) {
            print(
              '⚠️ [AuthBloc] Erreur FCM lors de la vérification: $fcmError',
            );
          }

          final ssoProvider = await authService.getCurrentSSOProvider();
          emit(AuthSuccess(user: user, authMethod: ssoProvider ?? 'email'));
        } else {
          print('❌ [AuthBloc] Utilisateur null, nettoyage...');
          await authService.clearUserData();
          emit(Unauthenticated());
        }
      } else {
        print('❌ [AuthBloc] Non authentifié');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('❌ [AuthBloc] Erreur check authentication: $e');
      final errorMessage = _getTranslatedErrorMessage(
        'AUTH_CHECK_ERROR',
        e.toString(),
      );
      emit(AuthFailure(error: errorMessage));
      await Future.delayed(const Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  /// ✅ CONFIRMATION EMAIL
  Future<void> _onConfirmEmailRequested(
    ConfirmEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('📧 [AuthBloc] Confirmation d\'email...');

      final tokens = await authService.confirmEmail(
        email: event.email,
        code: event.code,
      );

      if (tokens != null) {
        print('📧 [AuthBloc] Tokens reçus après confirmation email');

        // ✅ VÉRIFICATION DES TOKENS
        final savedToken = await authService.getToken();
        if (savedToken == null || savedToken.isEmpty) {
          print('❌ [AuthBloc] Token non sauvegardé après confirmation email');
          await authService.saveTokens(
            tokens['access_token']!,
            tokens['refresh_token']!,
          );
          print(
            '✅ [AuthBloc] Tokens sauvegardés manuellement après confirmation',
          );
        }

        final user = await authService.getCurrentUser();
        if (user != null) {
          _scheduleTokenRefresh();
          await _registerFCMAfterSuccessfulLogin();
          emit(AuthSuccess(user: user, authMethod: 'email'));
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
      print('❌ [AuthBloc] Erreur confirmation email: $e');
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  // ===================== MÉTHODES UTILITAIRES =====================

  Future<void> _registerFCMAfterSuccessfulLogin() async {
    try {
      print(
        '🔔 [AuthBloc] Démarrage de l\'enregistrement FCM après connexion...',
      );
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService.registerAfterLogin();
      print('✅ [AuthBloc] Enregistrement FCM terminé avec succès');
    } catch (e) {
      print('⚠️ [AuthBloc] Erreur lors de l\'enregistrement FCM: $e');
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
        emit(EmailVerificationRequired(emailToUse));
        return;
      default:
        errorCode = 'INVALID_CREDENTIALS';
    }

    final errorMessage = _getTranslatedErrorMessage(errorCode, e.message);
    emit(AuthFailure(error: errorMessage));
  }

  String _extractAndTranslateError(dynamic error, String provider) {
    if (error is AuthenticationException) {
      return _getTranslatedErrorMessage(error.code, error.message);
    }

    final errorString = error.toString().toLowerCase();

    // Erreurs spécifiques Google
    if (provider == 'google') {
      if (errorString.contains('canceled') ||
          errorString.contains('cancelled')) {
        return _getTranslatedErrorMessage('GOOGLE_SIGNIN_CANCELLED', '');
      }
      if (errorString.contains('network')) {
        return _getTranslatedErrorMessage('GOOGLE_NETWORK_ERROR', '');
      }
      if (errorString.contains('account_exists_with_different_credential')) {
        return _getTranslatedErrorMessage('GOOGLE_ACCOUNT_EXISTS', '');
      }
    }

    // ❌ ERREURS APPLE COMMENTÉES POUR ANDROID
    /*
    // Erreurs spécifiques Apple
    if (provider == 'apple') {
      if (errorString.contains('canceled') ||
          errorString.contains('cancelled')) {
        return _getTranslatedErrorMessage('APPLE_SIGNIN_CANCELLED', '');
      }
      if (errorString.contains('not available')) {
        return _getTranslatedErrorMessage('APPLE_NOT_AVAILABLE', '');
      }
    }
    */

    // Erreurs génériques SSO
    if (errorString.contains('email_already_exists')) {
      return _getTranslatedErrorMessage('EMAIL_ALREADY_EXISTS', '');
    }
    if (errorString.contains('invalid_token')) {
      return _getTranslatedErrorMessage('INVALID_SSO_TOKEN', '');
    }
    if (errorString.contains('network')) {
      return _getTranslatedErrorMessage('NETWORK_ERROR', '');
    }

    return _getTranslatedErrorMessage('SSO_UNKNOWN_ERROR', error.toString());
  }

  // ===================== AUTRES ÉVÉNEMENTS (inchangés) =====================

  Future<void> _onUpdateUserData(
    UpdateUserData event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthSuccess) {
      final currentState = state as AuthSuccess;
      emit(
        AuthSuccess(
          user: event.user,
          message: currentState.message,
          authMethod: currentState.authMethod,
        ),
      );

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
      print('🔄 [AuthBloc] Tentative de refresh du token...');

      final tokens = await authService.refreshToken(event.refreshToken);

      await authService.saveTokens(
        tokens['access_token']!,
        tokens['refresh_token']!,
      );

      _scheduleTokenRefresh();

      print('✅ [AuthBloc] Token refreshé avec succès');
      emit(TokensRefreshed(tokens['access_token']!, tokens['refresh_token']!));
    } catch (e) {
      print('❌ [AuthBloc] Échec du refresh token: $e');

      // ✅ GESTION INTELLIGENTE DES ERREURS 401
      if (e.toString().contains('401') ||
          e.toString().contains('Invalid or expired access token') ||
          e.toString().contains('expired')) {
        print('🔄 [AuthBloc] Token/Refresh token expirés - Déconnexion propre');

        // Nettoyer les données sans essayer de faire un logout serveur
        try {
          _tokenRefreshTimer?.cancel();
          await authService.clearUserData();
          await SSOService.signOutAll();
          NotificationService.clearDeviceData();
          print('✅ [AuthBloc] Nettoyage local terminé');
        } catch (clearError) {
          print('⚠️ [AuthBloc] Erreur lors du nettoyage: $clearError');
        }

        // Émettre un état de déconnexion sans message d'erreur
        emit(Unauthenticated());
        return;
      }

      // Pour les autres erreurs, afficher le message d'erreur
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
        print(
          '🔄 [AuthBloc] Nettoyage des données FCM lors de la déconnexion...',
        );
        NotificationService.clearDeviceData();
        print('✅ [AuthBloc] Données FCM nettoyées');
      } catch (fcmError) {
        print('⚠️ [AuthBloc] Erreur lors du nettoyage FCM: $fcmError');
      }

      try {
        await authService.logout();
      } catch (logoutError) {
        print('⚠️ [AuthBloc] Erreur lors du logout serveur: $logoutError');
      }

      try {
        await authService.clearUserData();
      } catch (clearError) {
        print(
          '⚠️ [AuthBloc] Erreur lors du nettoyage des données: $clearError',
        );
      }

      try {
        await SSOService.signOutAll();
        print('✅ [AuthBloc] Déconnexion SSO terminée');
      } catch (ssoError) {
        print('⚠️ [AuthBloc] Erreur lors de la déconnexion SSO: $ssoError');
      }

      await Future.delayed(const Duration(milliseconds: 300));
      emit(Unauthenticated());
    } catch (e) {
      print('❌ [AuthBloc] Erreur générale lors du logout: $e');
      try {
        _tokenRefreshTimer?.cancel();
        await authService.clearUserData();
        await SSOService.signOutAll();
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
        final ssoProvider = await authService.getCurrentSSOProvider();
        emit(AuthSuccess(user: user, authMethod: ssoProvider ?? 'email'));
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

      final ssoProvider = await authService.getCurrentSSOProvider();
      emit(AuthSuccess(user: updatedUser, authMethod: ssoProvider ?? 'email'));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));

      try {
        final currentUser = await authService.getCurrentUser();
        if (currentUser != null) {
          final ssoProvider = await authService.getCurrentSSOProvider();
          emit(
            AuthSuccess(user: currentUser, authMethod: ssoProvider ?? 'email'),
          );
        } else {
          emit(Unauthenticated());
        }
      } catch (_) {
        emit(Unauthenticated());
      }
    }
  }

  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    if (state is AuthFailure || state is SSOError) {
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

  Future<void> _onResendVerificationCode(
    ResendVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.resendVerificationCode(event.email);
      emit(VerificationCodeResent(event.email));
    } catch (e) {
      final errorCode = _extractErrorCode(e);
      final errorMessage = _getTranslatedErrorMessage(errorCode, e.toString());
      emit(AuthFailure(error: errorMessage));
    }
  }

  // Événements de suppression de compte (inchangés)
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
      await SSOService.signOutAll();
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
        final ssoProvider = await authService.getCurrentSSOProvider();
        emit(AuthSuccess(user: user, authMethod: ssoProvider ?? 'email'));
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
      'TOO_MANY_ATTEMPTS': 'Trop de tentatives. Veuillez réessayer plus tard',
      'RATE_LIMITED': 'Trop de tentatives. Veuillez réessayer plus tard',
      'ACCOUNT_DISABLED': 'Ce compte utilisateur est désactivé',

      // Messages SSO - GOOGLE SEULEMENT
      'GOOGLE_SIGNIN_CANCELLED': 'Connexion Google annulée',
      'GOOGLE_NETWORK_ERROR': 'Erreur de réseau lors de la connexion Google',
      'GOOGLE_ACCOUNT_EXISTS': 'Un compte existe déjà avec cet email',
      // ❌ APPLE MESSAGES COMMENTÉS
      // 'APPLE_SIGNIN_CANCELLED': 'Connexion Apple annulée',
      // 'APPLE_NOT_AVAILABLE': 'Apple Sign-In non disponible sur cet appareil',
      'INVALID_SSO_TOKEN': 'Token d\'authentification invalide',
      'SSO_UNKNOWN_ERROR': 'Erreur inattendue lors de la connexion SSO',
      'SSO_ACCOUNT_ALREADY_LINKED': 'Ce compte est déjà lié',
      'SSO_EMAIL_MISMATCH': 'L\'email ne correspond pas au compte actuel',
      'SSO_ACCOUNT_CONFLICT': 'Conflit avec un autre compte',
      'SSO_NETWORK_ERROR': 'Erreur de réseau lors de l\'authentification SSO',

      // Messages pour les tokens
      'TOKEN_SAVE_FAILED': 'Erreur lors de la sauvegarde des tokens',
      'TOKEN_SAVE_CRITICAL_FAILED':
          'Erreur critique: impossible de sauvegarder les tokens',
      'INVALID_TOKENS_RECEIVED': 'Tokens invalides reçus du serveur',
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
      'TOO_MANY_ATTEMPTS': 'Too many attempts. Please try again later',
      'RATE_LIMITED': 'Too many attempts. Please try again later',
      'ACCOUNT_DISABLED': 'This user account is disabled',

      // SSO Messages in English - GOOGLE SEULEMENT
      'GOOGLE_SIGNIN_CANCELLED': 'Google sign-in cancelled',
      'GOOGLE_NETWORK_ERROR': 'Network error during Google sign-in',
      'GOOGLE_ACCOUNT_EXISTS': 'An account already exists with this email',
      // ❌ APPLE MESSAGES COMMENTÉS
      // 'APPLE_SIGNIN_CANCELLED': 'Apple Sign-In cancelled',
      // 'APPLE_NOT_AVAILABLE': 'Apple Sign-In not available on this device',
      'INVALID_SSO_TOKEN': 'Invalid authentication token',
      'SSO_UNKNOWN_ERROR': 'Unexpected error during SSO sign-in',
      'SSO_ACCOUNT_ALREADY_LINKED': 'This account is already linked',
      'SSO_EMAIL_MISMATCH': 'Email does not match current account',
      'SSO_ACCOUNT_CONFLICT': 'Conflict with another account',
      'SSO_NETWORK_ERROR': 'Network error during SSO authentication',

      // Token error messages in English
      'TOKEN_SAVE_FAILED': 'Error saving authentication tokens',
      'TOKEN_SAVE_CRITICAL_FAILED': 'Critical error: unable to save tokens',
      'INVALID_TOKENS_RECEIVED': 'Invalid tokens received from server',
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

    // Codes d'erreur SSO - GOOGLE SEULEMENT
    if (errorString.contains('google') && errorString.contains('cancel')) {
      return 'GOOGLE_SIGNIN_CANCELLED';
    }
    // ❌ APPLE ERROR CODES COMMENTÉS
    /*
    else if (errorString.contains('apple') &&
        errorString.contains('cancel')) {
      return 'APPLE_SIGNIN_CANCELLED';
    } else if (errorString.contains('apple') &&
        errorString.contains('not available')) {
      return 'APPLE_NOT_AVAILABLE';
    }
    */

    // Codes d'erreur pour les tokens
    if (errorString.contains('token') && errorString.contains('save')) {
      return 'TOKEN_SAVE_FAILED';
    }

    // Codes d'erreur existants
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
