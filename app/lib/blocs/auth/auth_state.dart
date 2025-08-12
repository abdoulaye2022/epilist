// blocs/auth/auth_state.dart - VERSION AVEC SSO
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

// ✅ NOUVEAUX ÉTATS SSO
class SSOLoading extends AuthState {
  final String provider; // 'google' ou 'apple'
  final String action; // 'login' ou 'register'

  const SSOLoading({required this.provider, required this.action});

  @override
  List<Object> get props => [provider, action];
}

class SSOError extends AuthState {
  final String provider;
  final String error;
  final String? details;

  const SSOError({required this.provider, required this.error, this.details});

  @override
  List<Object> get props => [provider, error, details ?? ''];
}

class AuthSuccess extends AuthState {
  final User user;
  final String? message;
  final String? authMethod; // 'email', 'google', 'apple'

  const AuthSuccess({required this.user, this.message, this.authMethod});

  @override
  List<Object> get props => [user, authMethod ?? ''];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class Unauthenticated extends AuthState {}

class RegistrationSuccess extends AuthState {}

// ✅ NOUVEL ÉTAT pour inscription SSO réussie
class SSORegistrationSuccess extends AuthState {
  final String provider;
  final User user;

  const SSORegistrationSuccess({required this.provider, required this.user});

  @override
  List<Object> get props => [provider, user];
}

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

// État spécifique pour email non vérifié lors du login
class EmailVerificationRequired extends AuthState {
  final String email;

  const EmailVerificationRequired(this.email);

  @override
  List<Object> get props => [email];
}

class EmailConfirmationSuccess extends AuthState {}

class VerificationCodeResent extends AuthState {
  final String email;

  const VerificationCodeResent(this.email);

  @override
  List<Object> get props => [email];
}

// États pour la suppression de compte
class AccountDeletionCodeSent extends AuthState {
  final String email;
  final int codeExpiresInMinutes;

  const AccountDeletionCodeSent({
    required this.email,
    required this.codeExpiresInMinutes,
  });

  @override
  List<Object> get props => [email, codeExpiresInMinutes];
}

class AccountDeletionConfirmed extends AuthState {
  final DateTime deletionEffectiveDate;
  final DateTime canCancelUntil;

  const AccountDeletionConfirmed({
    required this.deletionEffectiveDate,
    required this.canCancelUntil,
  });

  @override
  List<Object> get props => [deletionEffectiveDate, canCancelUntil];
}

class AccountDeletionCancelled extends AuthState {}

class AccountDeletionStatusLoaded extends AuthState {
  final AccountDeletionStatus status;

  const AccountDeletionStatusLoaded(this.status);

  @override
  List<Object> get props => [status];
}

// ✅ NOUVEAUX ÉTATS pour la gestion des comptes SSO
class SSOAccountLinked extends AuthState {
  final String provider;
  final String message;

  const SSOAccountLinked({required this.provider, required this.message});

  @override
  List<Object> get props => [provider, message];
}

class SSOAccountUnlinked extends AuthState {
  final String provider;
  final String message;

  const SSOAccountUnlinked({required this.provider, required this.message});

  @override
  List<Object> get props => [provider, message];
}

class SSOAccountLinkError extends AuthState {
  final String provider;
  final String error;

  const SSOAccountLinkError({required this.provider, required this.error});

  @override
  List<Object> get props => [provider, error];
}
