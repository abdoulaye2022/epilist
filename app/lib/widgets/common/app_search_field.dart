// widgets/common/app_search_field.dart - Champ de recherche commun.
// Un seul gabarit : l'app n'avait AUCUNE recherche (ni SearchDelegate,
// ni showSearch, ni SearchBar dans 103 000 lignes).
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: controller == null || controller!.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: MaterialLocalizations.of(context)
                    .deleteButtonTooltip,
                onPressed: () {
                  controller!.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}
