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
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.login(event.email, event.password);
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
      emit(Unauthenticated());
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
      emit(RegistrationSuccess());
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

      // Émettre ProfileUpdated temporairement pour afficher le message de succès
      emit(ProfileUpdated(updatedUser));

      // Puis revenir à AuthSuccess avec les nouvelles données utilisateur
      emit(AuthSuccess(user: updatedUser));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));

      // Recharger l'utilisateur actuel en cas d'erreur
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
}
