// widgets/common/network_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:epilist/services/connectivity_service.dart';

/// Widget affichant le statut de la connexion réseau
class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator({super.key});

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  final _connectivityService = ConnectivityService();
  bool _isConnected = true;
  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;

    // Écouter les changements de connectivité
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          // Toujours afficher quand hors ligne
          if (!isConnected) {
            _showIndicator = true;
          } else {
            // Afficher brièvement quand la connexion revient
            _showIndicator = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showIndicator = false;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showIndicator) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green[600] : Colors.orange[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected
                  ? 'Connexion rétablie'
                  : 'Mode hors ligne - Les modifications seront synchronisées plus tard',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget badge compact pour l'AppBar
class NetworkStatusBadge extends StatefulWidget {
  const NetworkStatusBadge({super.key});

  @override
  State<NetworkStatusBadge> createState() => _NetworkStatusBadgeState();
}

class _NetworkStatusBadgeState extends State<NetworkStatusBadge> {
  final _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;

    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          const Text(
            'Hors ligne',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
