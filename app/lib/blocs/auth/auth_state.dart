// auth_state.dart - VERSION CORRIGÉE
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class Unauthenticated extends AuthState {}

class RegistrationSuccess extends AuthState {}

class TokensRefreshed extends AuthState {
  final String accessToken;
  final String refreshToken;

  const TokensRefreshed(this.accessToken, this.refreshToken);

  @override
  List<Object> get props => [accessToken, refreshToken];
}

class ProfileUpdated extends AuthState {
  final User user;

  const ProfileUpdated(this.user);

  @override
  List<Object> get props => [user];
}

class PasswordChangeCodeSent extends AuthState {
  final String email;

  const PasswordChangeCodeSent(this.email);

  @override
  List<Object> get props => [email];
}

class PasswordChanged extends AuthState {}

class EmailConfirmationRequired extends AuthState {
  final String email;

  const EmailConfirmationRequired(this.email);

  @override
  List<Object> get props => [email];
}

// CORRIGÉ: EmailConfirmationSuccess ne devrait pas avoir d'utilisateur
// car la vérification d'email ne retourne pas de tokens
class EmailConfirmationSuccess extends AuthState {}

class VerificationCodeResent extends AuthState {
  final String email;

  const VerificationCodeResent(this.email);

  @override
  List<Object> get props => [email];
}
