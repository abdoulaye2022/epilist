// widgets/home/home_app_bar.dart - VERSION SIMPLIFIÉE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/user.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final VoidCallback onViewAllLists;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const HomeAppBar({
    super.key,
    required this.onRefresh,
    required this.onViewAllLists,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      title: _buildLogo(),
      actions: [_buildUserAvatar(context), const SizedBox(width: 16)],
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si l'image n'est pas trouvée
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'EpiList',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        return current is AuthSuccess ||
            current is ProfileUpdated ||
            current is AuthLoading ||
            current is Unauthenticated;
      },
      builder: (context, state) {
        User? user;

        if (state is AuthSuccess) {
          user = state.user;
        } else if (state is ProfileUpdated) {
          user = state.user;
        }

        if (user != null) {
          return _buildUserAvatarWidget(user);
        }

        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildUserAvatarWidget(User user) {
    return GestureDetector(
      onTap: onProfile,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green[300]!, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green[600],
          child: Text(
            _getUserInitials(user),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return GestureDetector(
      onTap: onProfile,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2.5),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[400],
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  /// Génère les initiales de l'utilisateur (prénom + nom)
  String _getUserInitials(User user) {
    String initials = '';

    // Première lettre du prénom
    if (user.firstName.isNotEmpty) {
      initials += user.firstName[0].toUpperCase();
    }

    // Première lettre du nom
    if (user.lastName.isNotEmpty) {
      initials += user.lastName[0].toUpperCase();
    }

    // Si on n'a aucun nom, utiliser la première lettre de l'email
    if (initials.isEmpty && user.email.isNotEmpty) {
      initials = user.email[0].toUpperCase();
    }

    // Limiter à 2 caractères maximum
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
