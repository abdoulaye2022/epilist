// widgets/invitation/invitation_code_dialog.dart — « J'ai un code
// d'invitation ».
//
// C'est le chemin de retour de la boucle de partage, et le seul qui
// marche à coup sûr. Un lien de partage ne survit pas au passage par le
// magasin d'applications : on clique, on installe, on ouvre, et le
// jeton a disparu. Sur Android, le referrer de Google Play le rattrape
// parfois ; sur iOS, rien. Reste ce que la personne a sous les yeux :
// six caractères, qu'elle recopie.
//
// La saisie est volontairement tolérante — minuscules, espaces, tirets
// — parce qu'on recopie ce qu'on voit, pas ce que le code attend.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/invitation_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ouvre la saisie du code. Rend le jeton trouvé, ou null.
Future<String?> ouvrirSaisieCodeInvitation(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _DialogueCodeInvitation(),
  );
}

/// Le bouton, tel qu'il apparaît sur l'écran de bienvenue et juste
/// après l'inscription.
class BoutonCodeInvitation extends StatelessWidget {
  const BoutonCodeInvitation({super.key, this.onJetonTrouve});

  /// Appelé avec le jeton quand un code valide a été saisi.
  final ValueChanged<String>? onJetonTrouve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
      onPressed: () async {
        final jeton = await ouvrirSaisieCodeInvitation(context);
        if (jeton != null) {
          onJetonTrouve?.call(jeton);
        }
      },
      icon: Icon(Icons.confirmation_number_outlined, size: 18),
      label: Text(l10n.inviteCodeButton),
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
    );
  }
}

class _DialogueCodeInvitation extends StatefulWidget {
  const _DialogueCodeInvitation();

  @override
  State<_DialogueCodeInvitation> createState() =>
      _EtatDialogueCodeInvitation();
}

class _EtatDialogueCodeInvitation extends State<_DialogueCodeInvitation> {
  final _controleur = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final l10n = AppLocalizations.of(context)!;
    final saisi = _controleur.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    if (saisi.length != 6) {
      setState(() => _erreur = l10n.inviteCodeTooShort);
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });

    final service = context.read<InvitationService>();
    final jeton = await service.resoudreCode(saisi);

    if (!mounted) return;

    if (jeton == null) {
      setState(() {
        _enCours = false;
        _erreur = l10n.inviteCodeInvalid;
      });
      return;
    }

    // Le jeton est déjà gardé sur le disque par le service : même si
    // la personne ferme l'application avant de se connecter,
    // l'invitation l'attendra au retour.
    final connecte = await context.read<AuthService>().isAuthenticated();

    if (!mounted) return;

    Navigator.of(context).pop(jeton);

    if (connecte) {
      // Déjà connectée : on l'amène directement à l'invitation.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShareInvitationScreen(shareToken: jeton),
        ),
      );
    } else {
      SmartSnackBarManager.showMessage(
        context,
        l10n.inviteCodeSignInFirst,
        type: SnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.inviteCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inviteCodeExplain,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controleur,
            autofocus: true,
            enabled: !_enCours,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8, // 6 caractères, plus un tiret ou deux espaces
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 6,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              // On accepte ce que la personne voit sur son écran, y
              // compris les séparateurs : le nettoyage vient après.
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
              TextInputFormatter.withFunction(
                (avant, apres) => apres.copyWith(
                  text: apres.text.toUpperCase(),
                ),
              ),
            ],
            decoration: InputDecoration(
              hintText: l10n.inviteCodeHint,
              counterText: '',
              errorText: _erreur,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _enCours ? null : _valider(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _enCours ? null : _valider,
          child:
              _enCours
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.inviteCodeSubmit),
        ),
      ],
    );
  }
}
