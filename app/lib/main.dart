// main.dart - VERSION CLEAN SANS BRANCH.IO
import 'package:dio/dio.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/config/token_refresh_interceptor.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final sharedPreferences = await SharedPreferences.getInstance();

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Ajouter les interceptors de logging en mode debug
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    final authService = AuthService(
      dio: dio,
      sharedPreferences: sharedPreferences,
    );

    final authBloc = AuthBloc(authService: authService);

    // Ajouter l'interceptor de refresh token
    dio.interceptors.add(
      TokenRefreshInterceptor(
        authService: authService,
        authBloc: authBloc,
        dio: dio,
      ),
    );

    runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthService>.value(value: authService),
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
          RepositoryProvider(
            create:
                (context) => SharedListService(
                  dio: dio,
                  authService: context.read<AuthService>(),
                ),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(
              value: authBloc..add(CheckAuthentication()),
            ),
            BlocProvider(
              create:
                  (context) => ShoppingListBloc(
                    shoppingListService: context.read<ShoppingListService>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => SharedListBloc(
                    sharedListService: context.read<SharedListService>(),
                  ),
            ),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpiList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      routes: {
        '/register': (context) => const SignUpPage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profil': (context) => const ProfileScreen(),
        '/email-verification': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EmailVerificationScreen(
            email: args['email'],
            fromRegistration: args['fromRegistration'] ?? false,
          );
        },
        // Route pour les liens de partage
        '/share': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          final shareToken = args?['token'] as String?;
          if (shareToken != null) {
            return BlocProvider(
              create:
                  (context) => SharedListBloc(
                    sharedListService: context.read<SharedListService>(),
                  ),
              child: ShareInvitationScreen(shareToken: shareToken),
            );
          }
          return const HomeScreen();
        },
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _redirecting = false;
  bool _deepLinkInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  /// Initialiser les deep links
  Future<void> _initializeDeepLinks() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && !_deepLinkInitialized) {
          debugPrint('🔄 Initialisation des deep links...');

          DeepLinkHandler.initialize(context);

          setState(() {
            _deepLinkInitialized = true;
          });

          debugPrint('✅ Deep links initialisés avec succès');
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des deep links: $e');
      if (mounted) {
        setState(() {
          _deepLinkInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Nettoyer les deep links
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('🎧 AuthWrapper Listener - État: ${state.runtimeType}');

        // Gérer la redirection vers la vérification d'email
        if (state is EmailVerificationRequired && !_redirecting) {
          setState(() => _redirecting = true);

          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EmailVerificationScreen(
                        email: state.email,
                        fromRegistration: false,
                      ),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() => _redirecting = false);
                }
              });
            }
          });
        }

        // Gérer les tokens rafraîchis
        if (state is TokensRefreshed) {
          debugPrint('✅ Tokens rafraîchis dans AuthWrapper');
        }

        // Gérer les erreurs d'authentification
        if (state is AuthFailure) {
          debugPrint('❌ Erreur d\'authentification: ${state.error}');
          if (mounted && state.error.contains('Session expirée')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          // Ne pas reconstruire pour EmailVerificationRequired si on redirige déjà
          if (current is EmailVerificationRequired && _redirecting) {
            return false;
          }

          // Ne pas reconstruire pour TokensRefreshed
          if (current is TokensRefreshed) {
            return false;
          }

          return true;
        },
        builder: (context, state) {
          debugPrint('🔍 AuthWrapper Builder - État: ${state.runtimeType}');

          // Afficher l'écran de chargement jusqu'à l'initialisation
          if (!_deepLinkInitialized ||
              state is AuthInitial ||
              state is AuthLoading) {
            String message = 'Initialisation...';
            if (state is AuthLoading) {
              message = 'Vérification de l\'authentification...';
            }

            return LoadingScreen(message: message);
          }

          // Confirmation d'email requise (après inscription)
          if (state is EmailConfirmationRequired) {
            return EmailVerificationScreen(
              email: state.email,
              fromRegistration: true,
            );
          }

          // Utilisateur authentifié avec succès
          if (state is AuthSuccess) {
            debugPrint('✅ Utilisateur connecté: ${state.user.email}');
            return const HomeScreen();
          }

          // États nécessitant une redirection vers login
          if (state is Unauthenticated ||
              state is AuthFailure ||
              state is PasswordChanged ||
              state is EmailConfirmationSuccess) {
            return const LoginScreen();
          }

          // État par défaut
          return const LoginScreen();
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou icône de l'app
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Indicateur de chargement
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),

            // Nom de l'app
            const Text(
              'EpiList',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Message de chargement personnalisé
            Text(
              message ?? 'Initialisation...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Animation de points
            const LoadingDots(),
          ],
        ),
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity = (0.5 +
                    0.5 *
                        (((_controller.value + delay) % 1.0) < 0.5
                            ? ((_controller.value + delay) % 1.0) * 2
                            : 2 - ((_controller.value + delay) % 1.0) * 2))
                .clamp(0.3, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'initialisation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Impossible de démarrer l\'application',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Redémarrer l'app
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
