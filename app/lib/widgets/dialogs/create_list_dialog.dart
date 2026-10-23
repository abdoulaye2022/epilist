// widgets/dialogs/create_list_dialog.dart - Nouvelle liste : un en-tête
// compact, un champ, deux boutons. Les styles viennent du thème.
//
// Le dialogue se refermait dès l'appui sur « Créer », et l'utilisatrice
// restait sur le tableau de bord avec un « Liste créée avec succès »,
// à chercher où se trouve sa liste. Il attend maintenant la réponse :
// si le nom est déjà pris, il le dit SANS se fermer ; si la liste est
// créée, il se ferme et [onCreated] mène à la page des listes.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key, this.onCreated});

  /// Appelé après la création, une fois le dialogue refermé. Le
  /// tableau de bord s'en sert pour ouvrir la page des listes ; la
  /// page des listes n'en a pas besoin, elle y est déjà.
  final void Function(ShoppingList list)? onCreated;

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final nameController = TextEditingController();

  /// L'erreur du serveur ou du contrôle local, SOUS le champ : un
  /// message qui passe en bas de l'écran pendant qu'un dialogue est
  /// ouvert ne se lit pas.
  String? _erreur;
  bool _envoye = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _createList() {
    if (nameController.text.trim().isEmpty) return;
    setState(() {
      _erreur = null;
      _envoye = true;
    });
    context.read<ShoppingListBloc>().add(
      CreateShoppingList(nameController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<ShoppingListBloc, ShoppingListState>(
      listenWhen: (_, _) => _envoye,
      listener: (context, state) {
        if (state is ShoppingListCreated) {
          Navigator.pop(context);
          widget.onCreated?.call(state.list);
        } else if (state is ShoppingListError) {
          setState(() {
            _erreur = state.message;
            _envoye = false;
          });
        }
      },
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.playlist_add_rounded,
                title: l10n.newList,
              ),
              const SizedBox(height: AppSpacing.md + 4),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.listName,
                  hintText: l10n.listNameHint,
                ),
                onSubmitted: (_) => _createList(),
                onChanged: (_) {
                  if (_erreur != null) setState(() => _erreur = null);
                },
              ),
              if (_erreur != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _erreur!,
                  style: TextStyle(fontSize: 17, color: AppColors.errorInk),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<ShoppingListBloc, ShoppingListState>(
                builder:
                    (context, state) => AppDialogActions(
                      cancelLabel: l10n.cancel,
                      submitLabel: l10n.create,
                      loading: _envoye || state is ShoppingListLoading,
                      onSubmit: _createList,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
