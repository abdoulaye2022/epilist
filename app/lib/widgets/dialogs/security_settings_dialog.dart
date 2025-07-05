// widgets/dialogs/security_settings_dialog.dart - VERSION AVEC SUPPRESSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/widgets/dialogs/delete_account_dialog.dart';
import 'package:epilist/widgets/dialogs/change_password_dialog.dart';

class SecuritySettingsDialog extends StatelessWidget {
  const SecuritySettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              SizedBox(width: 12),
              Text('Sécurité & Confidentialité'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSecurityTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  subtitle: 'Modifier votre mot de passe actuel',
                  onTap: () => _showChangePasswordDialog(context),
                ),

                const Divider(height: 24),

                _buildSecurityTile(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Authentification à deux facteurs',
                  subtitle: 'Sécurisez votre compte avec 2FA',
                  onTap: () => _show2FADialog(context),
                  isComingSoon: true,
                ),

                const Divider(height: 24),

                _buildSecurityTile(
                  context,
                  icon: Icons.devices_outlined,
                  title: 'Sessions actives',
                  subtitle: 'Gérer les appareils connectés',
                  onTap: () => _showActiveSessionsDialog(context),
                  isComingSoon: true,
                ),

                const Divider(height: 24),

                _buildSecurityTile(
                  context,
                  icon: Icons.download_outlined,
                  title: 'Exporter mes données',
                  subtitle: 'Télécharger une copie de vos données',
                  onTap: () => _showExportDataDialog(context),
                  isComingSoon: true,
                ),

                const Divider(height: 24, color: Colors.red),

                // ✅ NOUVEAU: Option de suppression de compte
                _buildDangerousSecurityTile(
                  context,
                  icon: Icons.delete_forever_outlined,
                  title: 'Supprimer le compte',
                  subtitle: 'Supprimer définitivement votre compte EpiList',
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[600], size: 24),
      ),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (isComingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Bientôt',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing:
          isComingSoon
              ? Icon(Icons.lock_outline, color: Colors.grey[400], size: 16)
              : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: isComingSoon ? null : onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // ✅ NOUVEAU: Widget spécial pour les actions dangereuses
  Widget _buildDangerousSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red[600], size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.red[600]),
        ),
        trailing: Icon(
          Icons.warning_amber_rounded,
          color: Colors.red[600],
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const ChangePasswordDialog(),
          ),
    );
  }

  // ✅ NOUVEAU: Afficher le dialog de suppression de compte
  void _showDeleteAccountDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const DeleteAccountDialog(),
          ),
    );
  }

  void _show2FADialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Authentification à deux facteurs'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Cette fonctionnalité arrive bientôt !'),
                SizedBox(height: 8),
                Text(
                  'Nous travaillons pour vous offrir une sécurité renforcée avec l\'authentification à deux facteurs.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sessions actives'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.devices, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text('Fonctionnalité en développement'),
                SizedBox(height: 8),
                Text(
                  'Bientôt, vous pourrez voir et gérer tous les appareils connectés à votre compte.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exporter mes données'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Export de données disponible bientôt'),
                SizedBox(height: 8),
                Text(
                  'Nous préparons un outil pour vous permettre de télécharger toutes vos données (listes, items, préférences).',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
