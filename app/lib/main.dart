// main.dart - VERSION OPTIMISÉE AVEC FIREBASE

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/budget/budget_bloc.dart';
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/blocs/contact/contact_bloc.dart';
import 'package:epilist/blocs/contact/contact_event.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/blocs/suggestion/suggestion_bloc.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/config/token_refresh_interceptor.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/signup_screen.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/screens/welcome_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/services/budget_service.dart';
import 'package:epilist/services/category_service.dart';
import 'package:epilist/services/contact_service.dart';
import 'package:epilist/services/currency_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/product_suggestion_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/services/suggestion_service.dart';
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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:epilist/l10n/app_localizations.dart';

// ✅ CORRECTION: Import Firebase avec options par défaut
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:epilist/services/notification_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/offline_sync_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📱 Message reçu en arrière-plan: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ ÉTAPE 1: Initialiser Firebase avec options
    print('🚀 Initialisation de Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');

    // ✅ ÉTAPE 2: Configurer les notifications en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ ÉTAPE 3: Initialisation simple des notifications (sans demander permissions)
    print('🔔 Initialisation basique des notifications...');
    await NotificationService.initializeBasic();

    final sharedPreferences = await SharedPreferences.getInstance();
    await ConnectivityService().initialize();

    // ETAPE 4: Initialiser le nouveau systeme de cache
    print('[OfflineMode] Initialisation du cache hors ligne...');
    await OfflineStorageService.initialize();
    print('[OfflineMode] Cache hors ligne initialise');

    // ETAPE 5: Initialiser la queue d'actions
    print('[OfflineMode] Initialisation de la queue...');
    await OfflineQueueService.initialize();
    print('[OfflineMode] Queue initialisee');

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 120), // TEMPORARY: Very high for debugging slow server
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
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

    final categoryService = CategoryService(authService);

    final analyticsService = AnalyticsService(
      dio: dio,
      authService: authService,
    );

    // ✅ ÉTAPE 5: Créer les services pour les listes et items (nécessaires pour le sync)
    final shoppingListService = ShoppingListService(
      dio: dio,
      authService: authService,
    );

    final listItemService = ListItemService(
      dio: dio,
      authService: authService,
    );

    // ✅ ÉTAPE 6: Initialiser le service de synchronisation hors ligne
    print('🔄 Initialisation du service de synchronisation...');
    await OfflineSyncService().initialize(
      shoppingListService: shoppingListService,
      listItemService: listItemService,
    );
    print('✅ Service de synchronisation initialisé');

    final localizationBloc = LocalizationBloc(
      sharedPreferences: sharedPreferences,
    );

    final authBloc = AuthBloc(
      authService: authService,
      accountDeletionService: accountDeletionService,
      localizationBloc: localizationBloc,
    );

    dio.interceptors.add(
      TokenRefreshInterceptor(
        authService: authService,
        authBloc: authBloc,
        dio: dio,
      ),
    );

    // Désactivé pour réduire les logs HTTP
    // if (kDebugMode) {
    //   dio.interceptors.add(
    //     LogInterceptor(
    //       requestBody: true,
    //       responseBody: true,
    //       error: true,
    //       requestHeader: true,
    //       responseHeader: false,
    //     ),
    //   );
    // }

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
          RepositoryProvider<CategoryService>.value(value: categoryService),
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
          RepositoryProvider<ShoppingListService>.value(
            value: shoppingListService,
          ),
          RepositoryProvider<ListItemService>.value(
            value: listItemService,
          ),
          RepositoryProvider<OfflineSyncService>.value(
            value: OfflineSyncService(),
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
          RepositoryProvider<BudgetService>(
            create:
                (context) => BudgetService(
                  dio: dio,
                  authService: context.read<AuthService>(),
                ),
          ),
          RepositoryProvider<ContactService>(
            create:
                (context) => ContactService(
                  dio: dio,
                  authService: context.read<AuthService>(),
                ),
          ),
          RepositoryProvider<SuggestionService>(
            create: (context) => SuggestionService(dio: dio),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<LocalizationBloc>.value(
              value: localizationBloc..add(LoadLanguage()),
            ),
            BlocProvider<AuthBloc>.value(
              value: authBloc..add(CheckAuthentication()),
            ),
            BlocProvider(
              create:
                  (context) => CurrencyBloc(
                    currencyService: context.read<CurrencyService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                    authBloc: context.read<AuthBloc>(),
                  ),
            ),
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
            BlocProvider<ReceiptBloc>(
              create:
                  (context) => ReceiptBloc(
                    receiptService: context.read<ReceiptService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => BudgetBloc(
                    budgetService: context.read<BudgetService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => AnalyticsBloc(
                    analyticsService: context.read<AnalyticsService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => ContactBloc(
                    contactService: context.read<ContactService>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => CategoryBloc(
                    categoryService: context.read<CategoryService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
            ),
            BlocProvider(
              create:
                  (context) => SuggestionBloc(
                    suggestionService: context.read<SuggestionService>(),
                  ),
            ),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

// ✅ Le reste de votre code reste identique
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        Locale currentLocale = const Locale('fr');

        if (localizationState is LocalizationLoaded) {
          currentLocale = localizationState.locale;
        }

        return MaterialApp(
          title: 'EpiList',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', ''), Locale('en', '')],
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              primary: Colors.green[600]!,
              secondary: Colors.green[600]!,
            ),
          ),
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
            '/budget': (context) => _wrapWithConnectivity(const BudgetScreen()),
            '/list/details': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              final listId = args?['list_id'] as String?;

              if (listId != null) {
                return _wrapWithConnectivity(ListDetailsScreen(listId: listId));
              }
              return _wrapWithConnectivity(const HomeScreen());
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
      blockActionsWhenOffline: false, // 🔓 Permettre le fonctionnement hors ligne
      child: child,
    );
  }
}

// ✅ Le reste des classes reste identique (AuthWrapper, LoadingScreen, etc.)
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.updateContext(context);
    });
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
          NotificationService.updateContext(context);
        }
      });
    }
  }

  Future<void> _initializeDeepLinksWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted && !_deepLinkInitialized) {
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

        if (state is AccountDeletionStatusLoaded ||
            state is AccountDeletionCodeSent ||
            state is AccountDeletionConfirmed ||
            state is AccountDeletionCancelled) {
          return;
        }

        if (state is Unauthenticated && _hasCheckedAuth && !_redirecting) {
          NotificationService.clearDeviceData();

          setState(() {
            _redirecting = true;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _redirecting = false;
              });
            }
          });
          return;
        }

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

        if (state is EmailConfirmationSuccess) {
          if (mounted) {
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              l10n.emailConfirmedSuccess,
              duration: const Duration(seconds: 3),
            );
          }
        }

        // ✅ OPTIMISATION: Initialisation complète des notifications SEULEMENT lors de la connexion
        if (state is AuthSuccess) {
          context.read<CurrencyBloc>().add(const LoadUserCurrency());

          // ✅ NOUVEAU: Initialisation complète des notifications après connexion
          Future.delayed(const Duration(milliseconds: 500), () async {
            try {
              print(
                '🔔 Initialisation complète des notifications après connexion...',
              );
              await NotificationService.initializeAfterLogin();
              print('✅ Notifications initialisées avec succès après connexion');
            } catch (e) {
              print(
                '⚠️ Erreur lors de l\'initialisation des notifications: $e',
              );
            }
          });

          NotificationService.updateContext(context);
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
              blockActionsWhenOffline: false, // 🔓 Permettre le fonctionnement hors ligne
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
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
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
  final String? error;

  const ErrorApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Impossible de démarrer l\'application',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (error != null && kDebugMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Détails: $error',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart functionality could be implemented here
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListDetailsScreen extends StatelessWidget {
  final String listId;

  const ListDetailsScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Liste')),
      body: Center(child: Text('Liste ID: $listId')),
    );
  }
}
