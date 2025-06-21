// auth_bloc.dart - VERSION AVEC DEBUG COMPLET
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
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onLoginButtonPressed() - Début pour: ${event.email}');

    // 1. Émettre l'état de chargement
    emit(AuthLoading());
    print('📤 AuthBloc - État émis: AuthLoading');

    try {
      // 2. Tentative de connexion
      print('🔄 AuthBloc - Appel authService.login()...');
      final user = await authService.login(event.email, event.password);
      print('✅ AuthBloc - Connexion réussie pour: ${user.email}');

      // 3. Émettre le succès
      emit(AuthSuccess(user: user));
      print('📤 AuthBloc - État émis: AuthSuccess');
    } on AuthenticationException catch (e) {
      print('❌ AuthBloc - AuthenticationException capturée: ${e.message}');
      emit(AuthFailure(error: e.message));
      print('📤 AuthBloc - État émis: AuthFailure avec message: ${e.message}');
    } catch (e) {
      print('❌ AuthBloc - Exception générale capturée: $e');
      final errorMessage = e.toString();
      emit(AuthFailure(error: errorMessage));
      print('📤 AuthBloc - État émis: AuthFailure avec message: $errorMessage');
    }

    print('🔚 AuthBloc._onLoginButtonPressed() - Fin');
  }

  Future<void> _onCheckAuthentication(
    CheckAuthentication event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onCheckAuthentication() - Début');
    emit(AuthLoading());

    try {
      final isAuthenticated = await authService.isAuthenticated();
      if (isAuthenticated) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          print('✅ AuthBloc - Utilisateur authentifié trouvé: ${user.email}');
          emit(AuthSuccess(user: user));
        } else {
          print(
            '⚠️ AuthBloc - Token présent mais pas d\'utilisateur, nettoyage...',
          );
          await authService.clearUserData();
          emit(Unauthenticated());
        }
      } else {
        print('❌ AuthBloc - Pas authentifié');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('❌ AuthBloc - Erreur check auth: $e');
      emit(AuthFailure(error: 'Failed to check authentication'));
      // Après une pause, passer à Unauthenticated
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onLogoutRequested() - Début');
    emit(AuthLoading());

    try {
      await authService.logout();
      print('✅ AuthBloc - Déconnexion réussie');
      emit(Unauthenticated());
    } catch (e) {
      print('❌ AuthBloc - Erreur déconnexion: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onRegisterRequested() - Début pour: ${event.email}');
    emit(AuthLoading());

    try {
      await authService.register(
        event.firstName,
        event.lastName,
        event.email,
        event.password,
      );
      print('✅ AuthBloc - Inscription réussie');
      emit(RegistrationSuccess());
    } catch (e) {
      print('❌ AuthBloc - Erreur inscription: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onRefreshTokenRequested() - Début');
    emit(AuthLoading());

    try {
      final tokens = await authService.refreshToken(event.refreshToken);
      print('✅ AuthBloc - Token rafraîchi avec succès');
      emit(TokensRefreshed(tokens['access_token']!, tokens['refresh_token']!));
    } catch (e) {
      print('❌ AuthBloc - Erreur refresh token: $e');
      emit(AuthFailure(error: 'Failed to refresh token'));
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUser event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onGetCurrentUser() - Début');
    emit(AuthLoading());

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        print('✅ AuthBloc - Utilisateur trouvé: ${user.email}');
        emit(AuthSuccess(user: user));
      } else {
        print('❌ AuthBloc - Aucun utilisateur trouvé');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('❌ AuthBloc - Erreur get current user: $e');
      emit(AuthFailure(error: 'Failed to get current user'));
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc._onUpdateProfile() - Début');
    emit(AuthLoading());

    try {
      final updatedUser = await authService.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
      );

      print('✅ AuthBloc - Profil mis à jour avec succès');
      // Émettre ProfileUpdated temporairement pour afficher le message de succès
      emit(ProfileUpdated(updatedUser));

      // Puis revenir à AuthSuccess avec les nouvelles données utilisateur
      emit(AuthSuccess(user: updatedUser));
    } catch (e) {
      print('❌ AuthBloc - Erreur update profile: $e');
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

  // Méthode pour réinitialiser l'erreur
  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    print('🔄 AuthBloc._onClearAuthError() - Effacement erreur');
    if (state is AuthFailure) {
      emit(AuthInitial());
    }
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    print(
      '🔄 AuthBloc.onChange() - ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    print(
      '🔄 AuthBloc.onTransition() - ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
    );
  }
}
