// widgets/home/home_app_bar.dart - VERSION CORRIGÉE AVEC PERSISTENCE DES DONNÉES
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/user.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAllLists;
  final VoidCallback? onProfile;
  final VoidCallback? onLogout;

  const HomeAppBar({
    super.key,
    this.onRefresh,
    this.onViewAllLists,
    this.onProfile,
    this.onLogout,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  // ✅ Variables pour persister les données utilisateur
  String? _cachedFirstName;
  String? _cachedLastName;

  @override
  void initState() {
    super.initState();
    // ✅ Récupérer les données utilisateur au démarrage
    _loadInitialUserData();
  }

  void _loadInitialUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        _updateUserDataFromState(authState);
      }
    });
  }

  void _updateUserDataFromState(AuthState state) {
    User? user;

    if (state is AuthSuccess) {
      user = state.user;
    } else if (state is ProfileUpdated) {
      user = state.user;
    }

    if (user != null) {
      setState(() {
        _cachedFirstName = user?.firstName;
        _cachedLastName = user?.lastName;
      });
    }
  }

  String _getGreeting(l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      // ✅ Écouter les changements d'état pour mettre à jour les données
      listener: (context, state) {
        _updateUserDataFromState(state);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String? firstName = _cachedFirstName;
          String? lastName = _cachedLastName;

          // ✅ Mettre à jour depuis l'état actuel si disponible
          if (authState is AuthSuccess) {
            firstName = authState.user?.firstName ?? _cachedFirstName;
            lastName = authState.user?.lastName ?? _cachedLastName;
          } else if (authState is ProfileUpdated) {
            firstName = authState.user?.firstName ?? _cachedFirstName;
            lastName = authState.user?.lastName ?? _cachedLastName;
          }

          return AppBar(
            // ✅ Background blanc pour l'AppBar
            backgroundColor: Colors.white,

            // ✅ Enlève l'ombre sous l'AppBar
            elevation: 0,

            // ✅ Couleur des icônes (noir sur fond blanc)
            iconTheme: const IconThemeData(color: Colors.black),

            // ✅ Logo à gauche
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        size: 28,
                        color: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ✅ Nom de l'application au centre avec couleur verte
            title: Text(
              'EpiList',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            // ✅ Centrer le titre
            centerTitle: true,

            // ✅ Avatar et actions à droite
            actions: [
              // Bouton refresh (optionnel)
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: widget.onRefresh,
                  tooltip: l10n.refreshTooltip, // Au lieu de 'Actualiser'
                ),

              // Avatar utilisateur avec initiales
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                icon: _buildAvatarWithInitials(firstName, lastName),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      widget.onProfile?.call();
                      break;
                    case 'view_all':
                      widget.onViewAllLists?.call();
                      break;
                    case 'logout':
                      widget.onLogout?.call();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      // En-tête du menu avec nom utilisateur
                      if ((firstName != null && firstName.isNotEmpty) ||
                          (lastName != null && lastName.isNotEmpty))
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting(l10n)}, ${firstName ?? ''} ${lastName ?? ''}'
                                    .trim(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.epilistUser, // Au lieu de 'Utilisateur EpiList'
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const Divider(height: 16),
                            ],
                          ),
                        ),

                      // Menu Profil
                      if (widget.onProfile != null)
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.profile ?? 'Profil',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Divider
                      if (widget.onProfile != null &&
                          widget.onViewAllLists != null)
                        const PopupMenuDivider(),

                      // Menu Toutes les listes
                      if (widget.onViewAllLists != null)
                        PopupMenuItem<String>(
                          value: 'view_all',
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt, color: Colors.black87),
                              const SizedBox(width: 12),
                              Text(l10n.allLists ?? 'Toutes les listes'),
                            ],
                          ),
                        ),

                      // Divider avant logout
                      if (widget.onLogout != null) const PopupMenuDivider(),

                      // Menu Déconnexion
                      if (widget.onLogout != null)
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                l10n.logout ?? 'Déconnexion',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
              ),

              const SizedBox(width: 8), // Petit espacement à droite
            ],

            // ✅ Pas de bouton retour automatique
            automaticallyImplyLeading: false,
          );
        },
      ),
    );
  }

  // ✅ Méthode pour construire l'avatar avec initiales
  Widget _buildAvatarWithInitials(String? firstName, String? lastName) {
    String initials = _getInitials(firstName, lastName);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.green[100],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ Méthode pour extraire les initiales
  String _getInitials(String? firstName, String? lastName) {
    String firstInitial = '';
    String lastInitial = '';

    if (firstName != null && firstName.isNotEmpty) {
      firstInitial = firstName[0].toUpperCase();
    }

    if (lastName != null && lastName.isNotEmpty) {
      lastInitial = lastName[0].toUpperCase();
    }

    // Si on a les deux initiales
    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    }

    // Si on a seulement le prénom
    if (firstInitial.isNotEmpty) {
      return firstInitial;
    }

    // Si on a seulement le nom
    if (lastInitial.isNotEmpty) {
      return lastInitial;
    }

    // Par défaut si aucun nom n'est fourni
    return 'U';
  }
}

// ✅ Version alternative avec avatar image ET initiales (également corrigée)
class HomeAppBarWithUserImage extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAllLists;
  final VoidCallback? onProfile;
  final VoidCallback? onLogout;
  final String? userImageUrl;

  const HomeAppBarWithUserImage({
    super.key,
    this.onRefresh,
    this.onViewAllLists,
    this.onProfile,
    this.onLogout,
    this.userImageUrl,
  });

  @override
  State<HomeAppBarWithUserImage> createState() =>
      _HomeAppBarWithUserImageState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarWithUserImageState extends State<HomeAppBarWithUserImage> {
  String? _cachedFirstName;
  String? _cachedLastName;

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  void _loadInitialUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        _updateUserDataFromState(authState);
      }
    });
  }

  void _updateUserDataFromState(AuthState state) {
    User? user;

    if (state is AuthSuccess) {
      user = state.user;
    } else if (state is ProfileUpdated) {
      user = state.user;
    }

    if (user != null) {
      setState(() {
        _cachedFirstName = user?.firstName;
        _cachedLastName = user?.lastName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _updateUserDataFromState(state);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String? firstName = _cachedFirstName;
          String? lastName = _cachedLastName;

          if (authState is AuthSuccess) {
            firstName = authState.user?.firstName ?? _cachedFirstName;
            lastName = authState.user?.lastName ?? _cachedLastName;
          } else if (authState is ProfileUpdated) {
            firstName = authState.user?.firstName ?? _cachedFirstName;
            lastName = authState.user?.lastName ?? _cachedLastName;
          }

          return AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),

            // Logo à gauche
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shopping_cart_rounded,
                      size: 28,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ),

            // Nom de l'application au centre
            title: Text(
              'EpiList',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,

            // Avatar personnalisé à droite
            actions: [
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: widget.onRefresh,
                  tooltip: 'Actualiser',
                ),

              // Avatar avec image utilisateur ou initiales
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green[300]!, width: 2),
                  ),
                  child: ClipOval(
                    child:
                        widget.userImageUrl != null &&
                                widget.userImageUrl!.isNotEmpty
                            ? Image.network(
                              widget.userImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarWithInitials(
                                  firstName,
                                  lastName,
                                );
                              },
                            )
                            : _buildAvatarWithInitials(firstName, lastName),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      widget.onProfile?.call();
                      break;
                    case 'view_all':
                      widget.onViewAllLists?.call();
                      break;
                    case 'logout':
                      widget.onLogout?.call();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      // En-tête du menu avec nom utilisateur
                      if ((firstName != null && firstName.isNotEmpty) ||
                          (lastName != null && lastName.isNotEmpty))
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${firstName ?? ''} ${lastName ?? ''}'.trim(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Utilisateur EpiList',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const Divider(height: 16),
                            ],
                          ),
                        ),

                      // Menu Profil
                      if (widget.onProfile != null)
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.profile ?? 'Profil',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (widget.onProfile != null &&
                          widget.onViewAllLists != null)
                        const PopupMenuDivider(),

                      // Menu Toutes les listes
                      if (widget.onViewAllLists != null)
                        PopupMenuItem<String>(
                          value: 'view_all',
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt, color: Colors.black87),
                              const SizedBox(width: 12),
                              Text(l10n.allLists ?? 'Toutes les listes'),
                            ],
                          ),
                        ),

                      if (widget.onLogout != null) const PopupMenuDivider(),

                      // Menu Déconnexion
                      if (widget.onLogout != null)
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                l10n.logout ?? 'Déconnexion',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
              ),

              const SizedBox(width: 8),
            ],

            automaticallyImplyLeading: false,
          );
        },
      ),
    );
  }

  // ✅ Méthode pour construire l'avatar avec initiales
  Widget _buildAvatarWithInitials(String? firstName, String? lastName) {
    String initials = _getInitials(firstName, lastName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.green[100],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ Méthode pour extraire les initiales
  String _getInitials(String? firstName, String? lastName) {
    String firstInitial = '';
    String lastInitial = '';

    if (firstName != null && firstName.isNotEmpty) {
      firstInitial = firstName[0].toUpperCase();
    }

    if (lastName != null && lastName.isNotEmpty) {
      lastInitial = lastName[0].toUpperCase();
    }

    // Si on a les deux initiales
    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    }

    // Si on a seulement le prénom
    if (firstInitial.isNotEmpty) {
      return firstInitial;
    }

    // Si on a seulement le nom
    if (lastInitial.isNotEmpty) {
      return lastInitial;
    }

    // Par défaut si aucun nom n'est fourni
    return 'U';
  }
}
