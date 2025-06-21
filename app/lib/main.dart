import 'package:dio/dio.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisez SharedPreferences avant runApp
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialisez Dio avec la configuration de base
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create:
              (context) =>
                  AuthService(dio: dio, sharedPreferences: sharedPreferences),
        ),
        RepositoryProvider(
          create:
              (context) => ShoppingListService(
                dio: dio,
                authService: context.read<AuthService>(),
              ),
        ),
        RepositoryProvider(
          create:
              (context) => ListItemService(
                dio: dio,
                authService: context.read<AuthService>(),
              ),
        ),
      ],
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
