// screens/main_shell.dart - Coquille principale avec onglets en bas :
// Accueil | Listes | (+) | Statistiques | Budget.
// Le bouton central vert crée une nouvelle liste (remplace l'ancien FAB
// et le bouton « Nouvelle liste » du tableau de bord).
//
// Les onglets sont construits paresseusement (au premier affichage) pour
// ne pas déclencher quatre chargements API à l'ouverture de l'app, puis
// gardés vivants dans un IndexedStack.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Onglets déjà visités : seuls ceux-là sont réellement construits.
  final List<bool> _visited = [true, false, false, false];

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited[index] = true;
    });
  }

  void _createList() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ShoppingListBloc>(),
        child: const CreateListDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          _visited[1] ? const ShoppingListScreen() : const SizedBox.shrink(),
          _visited[2] ? const AnalyticsScreen() : const SizedBox.shrink(),
          _visited[3] ? const BudgetScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(l10n),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tabItem(0, Icons.home_outlined, Icons.home_rounded,
                  l10n.tabHome),
              _tabItem(1, Icons.list_alt_outlined, Icons.list_alt_rounded,
                  l10n.tabLists),
              _centerButton(l10n),
              _tabItem(2, Icons.bar_chart_outlined, Icons.bar_chart_rounded,
                  l10n.statistics),
              _tabItem(3, Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet_rounded, l10n.budget),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _select(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton central vert : créer une nouvelle liste.
  Widget _centerButton(AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: l10n.createList,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _createList,
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
