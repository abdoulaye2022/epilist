// widgets/dialogs/no_internet_dialog.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/connectivity_service.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetDialog({super.key, this.onRetry});

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog>
    with TickerProviderStateMixin {
  bool _isChecking = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false, // Empêche de fermer le dialog avec le bouton retour
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                    maxWidth: 500,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contenu scrollable
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIcon(),
                              const SizedBox(height: 20),
                              _buildTitle(l10n),
                              const SizedBox(height: 12),
                              _buildDescription(l10n),
                              const SizedBox(height: 24),
                              _buildTipsCard(l10n),
                              const SizedBox(height: 24),
                              _buildRetryButton(l10n),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.red.shade100, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.wifi, size: 40, color: Colors.red[300]),
          Positioned(
            right: 15,
            top: 15,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.noInternetConnection ?? 'Aucune connexion Internet',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.noInternetMessage ??
          'Vous devez être connecté à Internet pour utiliser cette application. '
              'Veuillez vérifier votre connexion et réessayer.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildTipsCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.connectionTips ?? 'Conseils :',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            Icons.wifi,
            l10n.checkWifiConnection ?? "Vérifiez votre connexion Wi-Fi",
            Colors.blue[700]!,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            Icons.signal_cellular_alt,
            l10n.checkMobileData ?? "Activez vos données mobiles",
            Colors.green[700]!,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            Icons.router,
            l10n.restartRouter ?? "Redémarrez votre routeur si nécessaire",
            Colors.orange[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isChecking ? null : () => _checkConnection(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.red[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            _isChecking
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.retry ?? 'Réessayer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isConnected = await ConnectivityService().checkConnectivity();

      if (isConnected) {
        if (mounted) {
          // Animation de fermeture
          await _animationController.reverse();
          Navigator.of(context).pop();
          widget.onRetry?.call();
        }
      } else {
        // Attendre un peu avant de permettre un nouvel essai
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }
}
