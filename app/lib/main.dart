// main.dart - VERSION CORRIGÉE AVEC SYNC AUTH + CURRENCY
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/config/token_refresh_interceptor.dart';
import 'package:epilist/notifications/notification_service.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/screens/welcome_screen.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/services/currency_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/product_suggestion_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/utils/snackbar_manager.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
// IMPORTS POUR I18N
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:epilist/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final sharedPreferences = await SharedPreferences.getInstance();

    // ✅ Initialiser le service de connectivité dès le démarrage
    await ConnectivityService().initialize();

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

    final authService = AuthService(
      dio: dio,
      sharedPreferences: sharedPreferences,
    );

    final accountDeletionService = AccountDeletionService(
      dio: dio,
      authService: authService,
    );

    final currencyService = CurrencyService(dio: dio, authService: authService);

    final analyticsService = AnalyticsService(
      dio: dio,
      authService: authService,
    );

    final localizationBloc = LocalizationBloc(
      sharedPreferences: sharedPreferences,
    );

    final authBloc = AuthBloc(
      authService: authService,
      accountDeletionService: accountDeletionService,
      localizationBloc: localizationBloc,
    );

    // Ajouter l'interceptor de refresh token
    dio.interceptors.add(
      TokenRefreshInterceptor(
        authService: authService,
        authBloc: authBloc,
        dio: dio,
      ),
    );

    // Ajouter les interceptors de logging en mode debug
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }

    await NotificationService.initialize();

    runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthService>.value(value: authService),
          RepositoryProvider<AccountDeletionService>.value(
            value: accountDeletionService,
          ),
          RepositoryProvider<ConnectivityService>.value(
            value: ConnectivityService(),
          ),
          RepositoryProvider<CurrencyService>.value(value: currencyService),
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
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
          RepositoryProvider<ProductSuggestionService>(
            create:
                (context) => ProductSuggestionService(
                  dio: dio,
                  authService: context.read<AuthService>(),
                ),
          ),
          RepositoryProvider<ReceiptService>(
            create:
                (context) => ReceiptService(
                  dio: dio,
                  authService: context.read<AuthService>(),
                ),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            // 1. LocalizationBloc en premier (pas de dépendances)
            BlocProvider<LocalizationBloc>.value(
              value: localizationBloc..add(LoadLanguage()),
            ),

            // 2. AuthBloc (dépend de LocalizationBloc)
            BlocProvider<AuthBloc>.value(
              value: authBloc..add(CheckAuthentication()),
            ),

            // 3. ✅ CORRECTION CRITIQUE: CurrencyBloc avec AuthBloc
            BlocProvider(
              create:
                  (context) => CurrencyBloc(
                    currencyService: context.read<CurrencyService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                    authBloc: context.read<AuthBloc>(), // ✅ AJOUT CRUCIAL
                  ),
            ),
            BlocProvider(
              create:
                  (context) => CurrencyBloc(
                    currencyService: context.read<CurrencyService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                    authBloc: context.read<AuthBloc>(), // ✅ AJOUT CRUCIAL
                  ),
            ),

            // 4. Autres BLoCs
            BlocProvider(
              create:
                  (context) => ShoppingListBloc(
                    shoppingListService: context.read<ShoppingListService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => SharedListBloc(
                    sharedListService: context.read<SharedListService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider<ProductSuggestionBloc>(
              create:
                  (context) => ProductSuggestionBloc(
                    suggestionService: context.read<ProductSuggestionService>(),
                  ),
            ),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e) {
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        Locale currentLocale = const Locale('fr'); // Par défaut

        if (localizationState is LocalizationLoaded) {
          currentLocale = localizationState.locale;
        }

        return MaterialApp(
          title: 'EpiList',
          debugShowCheckedModeBanner: false,

          // CONFIGURATION I18N
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', ''), Locale('en', '')],

          theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),

          routes: {
            '/register': (context) => _wrapWithConnectivity(const SignUpPage()),
            '/login': (context) => _wrapWithConnectivity(const LoginScreen()),
            '/home':
                (context) => _wrapWithConnectivity(
                  const HomeScreen(),
                  showBanner: false,
                ),
            '/profil':
                (context) => _wrapWithConnectivity(const ProfileScreen()),
            '/welcome': (context) => const WelcomeScreen(),
            '/email-verification': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return _wrapWithConnectivity(
                EmailVerificationScreen(
                  email: args['email'],
                  fromRegistration: args['fromRegistration'] ?? false,
                ),
              );
            },
            '/share': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              final shareToken = args?['token'] as String?;
              if (shareToken != null) {
                return _wrapWithConnectivity(
                  BlocProvider(
                    create:
                        (context) => SharedListBloc(
                          sharedListService: context.read<SharedListService>(),
                          localizationBloc: context.read<LocalizationBloc>(),
                        ),
                    child: ShareInvitationScreen(shareToken: shareToken),
                  ),
                );
              }
              return _wrapWithConnectivity(
                const HomeScreen(),
                showBanner: false,
              );
            },
          },
          home: const AuthWrapper(),
        );
      },
    );
  }

  Widget _wrapWithConnectivity(Widget child, {bool showBanner = true}) {
    return ConnectivityWrapper(
      showOfflineBanner: showBanner,
      blockActionsWhenOffline: true,
      child: child,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _redirecting = false;
  bool _deepLinkInitialized = false;
  bool _hasCheckedAuth = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDeepLinksWithDelay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService().dispose();
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _deepLinkInitialized) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          DeepLinkHandler.updateContext(context);
        }
      });
    }
  }

  Future<void> _initializeDeepLinksWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted && !_deepLinkInitialized) {
      print('🚀 Initialisation des deep links depuis AuthWrapper');
      DeepLinkHandler.initialize(context);
      setState(() {
        _deepLinkInitialized = true;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!_hasCheckedAuth &&
            state is! AuthInitial &&
            state is! AuthLoading) {
          setState(() {
            _hasCheckedAuth = true;
          });
        }

        // Ignorer les états de suppression de compte pour éviter les conflits
        if (state is AccountDeletionStatusLoaded ||
            state is AccountDeletionCodeSent ||
            state is AccountDeletionConfirmed ||
            state is AccountDeletionCancelled) {
          return;
        }

        // Gérer la redirection vers la vérification d'email
        if (state is EmailVerificationRequired && !_redirecting) {
          setState(() => _redirecting = true);

          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ConnectivityWrapper(
                        showOfflineBanner: false,
                        child: EmailVerificationScreen(
                          email: state.email,
                          fromRegistration: false,
                        ),
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

        // Gérer la confirmation d'email réussie
        if (state is EmailConfirmationSuccess) {
          if (mounted) {
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.emailConfirmedSuccess,
              duration: const Duration(seconds: 3),
            );
          }
        }

        // ✅ NOUVEAU: Charger la devise utilisateur après authentification réussie
        if (state is AuthSuccess) {
          // Charger la devise utilisateur après connexion
          context.read<CurrencyBloc>().add(const LoadUserCurrency());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          if (current is AccountDeletionStatusLoaded ||
              current is AccountDeletionCodeSent ||
              current is AccountDeletionConfirmed ||
              current is AccountDeletionCancelled) {
            return false;
          }

          if (current is EmailVerificationRequired && _redirecting) {
            return false;
          }

          if (current is TokensRefreshed) {
            return false;
          }

          return true;
        },
        builder: (context, state) {
          if (_isInitializing ||
              !_deepLinkInitialized ||
              state is AuthInitial ||
              state is AuthLoading) {
            String message = l10n.initialization;
            if (state is AuthLoading) {
              message = l10n.checkingAuthentication;
            }

            return LoadingScreen(message: message);
          }

          if (state is EmailConfirmationRequired) {
            return ConnectivityWrapper(
              showOfflineBanner: false,
              child: EmailVerificationScreen(
                email: state.email,
                fromRegistration: true,
              ),
            );
          }

          if (state is AuthSuccess || state is EmailConfirmationSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_deepLinkInitialized) {
                DeepLinkHandler.processPendingTokenAfterLogin();
              }
            });

            return ConnectivityWrapper(
              showOfflineBanner: false,
              blockActionsWhenOffline: true,
              child: const HomeScreen(),
            );
          }

          if (state is Unauthenticated ||
              state is AuthFailure ||
              state is PasswordChanged) {
            return const WelcomeScreen();
          }

          return const WelcomeScreen();
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.appTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.initialization,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
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
