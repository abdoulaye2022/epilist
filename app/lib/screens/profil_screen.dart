import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/screens/terms_of_service.dart';
import 'package:flutter/material.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Si l'utilisateur n'est pas connecté, rediriger vers la page de connexion
        if (state is! AuthSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final User user = state.user;
        final String userName = '${user.firstName} ${user.lastName}';

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Mon Profil',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            foregroundColor: Colors.black87,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // En-tête profil avec données réelles
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar avec initiales réelles
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green[100],
                        child: Text(
                          '${user.firstName[0]}${user.lastName[0]}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _editProfile(user),
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Modifier le profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Mes listes
                _buildSection('Mes données', [
                  _buildActionTile(Icons.list_alt, 'Mes listes de courses', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShoppingListScreen(),
                      ),
                    );
                  }),
                ]),

                SizedBox(height: 16),

                // Paramètres
                _buildSection('Paramètres', [
                  _buildActionTile(
                    Icons.notifications_outlined,
                    'Notifications',
                    () {
                      _showNotificationsSettings();
                    },
                  ),
                  _buildActionTile(Icons.security_outlined, 'Sécurité', () {
                    _showSecuritySettings();
                  }),
                ]),

                SizedBox(height: 16),

                // Informations légales
                _buildSection('Informations', [
                  _buildActionTile(
                    Icons.info_outline,
                    'À propos d\'EpiList',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      );
                    },
                  ),
                  _buildActionTile(
                    Icons.privacy_tip_outlined,
                    'Politique de confidentialité',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    Icons.article_outlined,
                    'Conditions d\'utilisation',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TermsOfServicePage(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(Icons.help_outline, 'Aide & Support', () {
                    _showHelpDialog();
                  }),
                ]),

                SizedBox(height: 24),

                // Bouton de déconnexion avec BLoC
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.logout),
                    label: Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[600],
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red[200]!),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.green[600], size: 22),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _editProfile(User currentUser) {
    final firstNameController = TextEditingController(
      text: currentUser.firstName,
    );
    final lastNameController = TextEditingController(
      text: currentUser.lastName,
    );
    final emailController = TextEditingController(text: currentUser.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifier le profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implémenter la mise à jour du profil via l'API
                  // context.read<AuthBloc>().add(UpdateProfileRequested(
                  //   firstName: firstNameController.text.trim(),
                  //   lastName: lastNameController.text.trim(),
                  //   email: emailController.text.trim(),
                  // ));

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mise à jour du profil à implémenter'),
                      backgroundColor: Colors.orange[600],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: Text('Sauvegarder'),
              ),
            ],
          ),
    );
  }

  void _showNotificationsSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Notifications'),
            content: Text(
              'Paramètres de notifications à venir dans une prochaine version.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sécurité'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Options de sécurité :'),
                SizedBox(height: 12),
                Text('• Changer le mot de passe'),
                Text('• Authentification à deux facteurs'),
                Text('• Supprimer le compte'),
                SizedBox(height: 12),
                Text('Ces fonctionnalités seront disponibles prochainement.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Aide & Support'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Besoin d\'aide ? Contactez-nous :'),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('support@epilist.app'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('01 23 45 67 89'),
                  ],
                ),
                SizedBox(height: 12),
                Text('Nous répondons sous 24h.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Déconnexion'),
            content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              Navigator.pop(context); // Fermer le dialog
                              // Utiliser le BLoC pour la déconnexion
                              context.read<AuthBloc>().add(LogoutRequested());
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                    child:
                        isLoading
                            ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Se déconnecter'),
                  );
                },
              ),
            ],
          ),
    );
  }
}
