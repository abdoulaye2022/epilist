// auth_bloc.dart - VERSION CORRIGÉE POUR REDIRECTION VERS LOGIN
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
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
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    print('🚀 AuthBloc._onLoginButtonPressed appelé');
    print('📧 Email: ${event.email}');

    emit(AuthLoading());
    print('⏳ État AuthLoading émis');

    try {
      print('🔐 Appel authService.login...');
      final user = await authService.login(event.email, event.password);
      print('✅ Utilisateur connecté avec succès: ${user.email}');
      emit(AuthSuccess(user: user));
      print('🎉 État AuthSuccess émis');
    } on AuthenticationException catch (e) {
      print('❌ AuthenticationException capturée dans le bloc: ${e.message}');
      emit(AuthFailure(error: e.message));
      print('💔 État AuthFailure émis avec le message: ${e.message}');
    } catch (e) {
      print('💥 Exception générale capturée dans le bloc: $e');
      print('🔍 Type d\'exception: ${e.runtimeType}');
      emit(AuthFailure(error: e.toString()));
      print('💔 État AuthFailure émis avec le message: ${e.toString()}');
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
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
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
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final tokens = await authService.refreshToken(event.refreshToken);
      emit(TokensRefreshed(tokens['access_token']!, tokens['refresh_token']!));
    } catch (e) {
      emit(AuthFailure(error: 'Failed to refresh token'));
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
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
      await Future.delayed(Duration(seconds: 2));
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

  // CORRIGÉ: Maintenant redirige vers login après vérification réussie
  Future<void> _onConfirmEmailRequested(
    ConfirmEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Appel du service qui vérifie l'email (ne retourne rien)
      await authService.confirmEmail(email: event.email, code: event.code);

      // Émettre le succès de confirmation (sans utilisateur)
      emit(EmailConfirmationSuccess());
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

      // Retourner à l'état de confirmation d'email
      await Future.delayed(Duration(milliseconds: 500));
      emit(EmailConfirmationRequired(event.email));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}
