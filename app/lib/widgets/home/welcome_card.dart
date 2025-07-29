// widgets/home/welcome_card.dart - VERSION AVEC FERMETURE PERSISTANTE
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/l10n/app_localizations.dart';

class WelcomeCard extends StatefulWidget {
  const WelcomeCard({super.key});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  // Clé pour le stockage persistant
  static const String _welcomeCardDismissedKey = 'welcome_card_dismissed';

  bool _isDismissed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  // Charger l'état de fermeture depuis SharedPreferences
  Future<void> _loadDismissedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(_welcomeCardDismissedKey) ?? false;

      if (mounted) {
        setState(() {
          _isDismissed = isDismissed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'état WelcomeCard: $e');
      if (mounted) {
        setState(() {
          _isDismissed = false;
          _isLoading = false;
        });
      }
    }
  }

  // Sauvegarder l'état de fermeture
  Future<void> _dismissCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeCardDismissedKey, true);

      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'état WelcomeCard: $e');
    }
  }

  // Méthode publique pour réinitialiser la carte (optionnel - pour debugging ou settings)
  static Future<void> resetWelcomeCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_welcomeCardDismissedKey);
    } catch (e) {
      print('Erreur lors de la réinitialisation WelcomeCard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Pendant le chargement, afficher un placeholder minimal
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Si la carte a été fermée, ne rien afficher
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et bouton de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.hello,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              // Bouton de fermeture
              InkWell(
                onTap: _dismissCard,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: Colors.blue[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manageGroceryLists,
            style: TextStyle(fontSize: 16, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}
