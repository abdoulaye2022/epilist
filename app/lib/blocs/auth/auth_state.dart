// blocs/auth/auth_state.dart
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
