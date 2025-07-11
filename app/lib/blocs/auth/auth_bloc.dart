// auth_bloc.dart - VERSION CORRIGÉE POUR JWT 1 AN
import 'package:epilist/models/account_deletion_status.dart';
import 'package:epilist/services/account_deletion_service.dart';
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
  Timer? _tokenRefreshTimer;

  AuthBloc({required this.authService, required this.accountDeletionService})
    : super(AuthInitial()) {
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
        emit(
          AuthFailure(
            error: 'Impossible de récupérer les informations utilisateur',
          ),
        );
      }
    } on AuthenticationException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'INVALID_CREDENTIALS':
          errorMessage = 'Email ou mot de passe incorrect';
          break;
        case 'USER_NOT_FOUND':
          errorMessage = 'Aucun compte trouvé avec cet email';
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
          errorMessage = e.message;
      }
      emit(AuthFailure(error: errorMessage));
    } catch (e) {
      emit(AuthFailure(error: 'Une erreur est survenue lors de la connexion'));
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
      emit(AuthFailure(error: 'Failed to check authentication'));
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
      emit(AuthFailure(error: 'Session expirée - Veuillez vous reconnecter'));
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
        emit(AuthFailure(error: 'Erreur lors de la déconnexion: $e'));
        await Future.delayed(const Duration(seconds: 2));
        emit(Unauthenticated());
      }
    }
  }

  // [Vos autres méthodes existantes restent identiques]
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
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: 'Failed to get current user'));
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
      emit(AuthFailure(error: e.toString()));

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
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
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
          emit(
            AuthFailure(
              error: 'Impossible de récupérer les informations utilisateur',
            ),
          );
        }
      } else {
        emit(EmailConfirmationSuccess());
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
    }
  }

  // ⭐ NOUVELLE MÉTHODE: Programmer le rafraîchissement adaptatif du token
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

  // [Vos méthodes de suppression de compte restent identiques]
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
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
    }
  }
}
