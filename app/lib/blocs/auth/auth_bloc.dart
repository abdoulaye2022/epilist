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
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // await authService.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    // Nom corrigé (sans 'd' final)
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
      emit(
        AuthFailure(error: e.toString()),
      ); // Utilisez AuthError au lieu de AuthFailure pour la cohérence
    }
  }
}
