part of 'auth_bloc.dart';

abstract class AuthEvent {}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;

  LoginButtonPressed({required this.email, required this.password});
}

class LogoutRequested extends AuthEvent {}

class CheckAuthentication extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  // Vérifiez l'orthographe ici aussi
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  RegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });
}

class RefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  RefreshTokenRequested(this.refreshToken);

  @override
  List<Object> get props => [refreshToken];
}

class GetCurrentUser extends AuthEvent {}

class UpdateProfile extends AuthEvent {
  final String firstName;
  final String lastName;

  UpdateProfile({required this.firstName, required this.lastName});

  @override
  List<Object> get props => [firstName, lastName];
}
