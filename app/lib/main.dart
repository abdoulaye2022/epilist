import 'package:epilist/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [RepositoryProvider(create: (context) => AuthService())],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => AuthBloc(authService: context.read<AuthService>())
                  ..add(CheckAuthentication()), // Maintenant géré correctement
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => SignUpPage(),
        '/login': (context) => LoginScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AuthSuccess) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
