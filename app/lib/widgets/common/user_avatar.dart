// widgets/common/user_avatar.dart
// Avatar unifié : la vraie photo (GCS, mise en cache) quand elle existe,
// sinon les initiales sur fond vert doux. Utilisé partout (drawer, profil,
// activité...) pour un rendu cohérent.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final User? user;

  /// URL prioritaire (ex. après un upload, avant le rafraîchissement du bloc).
  final String? overrideUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.overrideUrl,
    this.radius = 26,
  });

  String get _initials {
    final u = user;
    if (u == null) return 'E';
    final f = u.firstName.isNotEmpty ? u.firstName[0] : '';
    final l = u.lastName.isNotEmpty ? u.lastName[0] : '';
    final ini = '$f$l'.toUpperCase();
    return ini.isEmpty ? 'E' : ini;
  }

  @override
  Widget build(BuildContext context) {
    final url = overrideUrl ?? user?.avatarUrl;

    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      // foregroundImage : si le chargement échoue, le child (initiales)
      // reste visible — plus jamais de rond vide.
      foregroundImage: CachedNetworkImageProvider(url),
      onForegroundImageError: (_, __) {},
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
