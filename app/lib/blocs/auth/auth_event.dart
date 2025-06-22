// auth_event.dart - VERSION CORRIGÉE
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;

  const LoginButtonPressed({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthentication extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const RegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [firstName, lastName, email, password];
}

class RefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const RefreshTokenRequested(this.refreshToken);

  @override
  List<Object> get props => [refreshToken];
}

class GetCurrentUser extends AuthEvent {}

class UpdateProfile extends AuthEvent {
  final String firstName;
  final String lastName;

  const UpdateProfile({required this.firstName, required this.lastName});

  @override
  List<Object> get props => [firstName, lastName];
}

class ClearAuthError extends AuthEvent {}

class RequestPasswordChangeCode extends AuthEvent {
  final String email;

  const RequestPasswordChangeCode(this.email);

  @override
  List<Object> get props => [email];
}

class VerifyPasswordChangeCode extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;

  const VerifyPasswordChangeCode({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, code, newPassword];
}

// AJOUT: Événements manquants pour la confirmation d'email
class ConfirmEmailRequested extends AuthEvent {
  final String email;
  final String code;

  const ConfirmEmailRequested({required this.email, required this.code});

  @override
  List<Object> get props => [email, code];
}

class ResendVerificationCode extends AuthEvent {
  final String email;

  const ResendVerificationCode(this.email);

  @override
  List<Object> get props => [email];
}
