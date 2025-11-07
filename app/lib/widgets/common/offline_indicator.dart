// widgets/common/offline_indicator.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/services/offline_sync_service.dart';
import 'package:flutter/material.dart';

/// Widget d'indicateur de mode hors ligne
///
/// Affiche un badge en haut de l'écran lorsque:
/// - L'application est hors ligne
/// - Des actions sont en attente de synchronisation
/// - Une synchronisation est en cours
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final _connectivityService = ConnectivityService();
  final _syncService = OfflineSyncService();

  // Commencer par supposer hors ligne pour afficher la bannière si nécessaire
  bool _isOnline = false;
  int _pendingCount = 0;
  bool _isSyncing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    // Vérifier immédiatement le statut
    final isOnline = _connectivityService.isConnected;
    final pendingCount = await _syncService.getPendingActionsCount();

    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _pendingCount = pendingCount;
        _initialized = true;
      });
    }

    // Écouter les changements de connectivité
    _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
        _updatePendingCount();
      }
    });

    // Écouter les changements de synchronisation
    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isSyncing = status == SyncStatus.syncing;
        });
        _updatePendingCount();
      }
    });
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncService.getPendingActionsCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Ne rien afficher si tout est normal (en ligne et pas d'actions en attente)
    if (_isOnline && _pendingCount == 0 && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: _getBackgroundColor(),
        elevation: 4,
        child: InkWell(
          onTap: _showDetailsDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getStatusTitle(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_getStatusSubtitle(l10n) != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getStatusSubtitle(l10n)!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (!_isOnline) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.white,
        size: 20,
      );
    }

    if (_pendingCount > 0) {
      return const Icon(
        Icons.sync,
        color: Colors.white,
        size: 20,
      );
    }

    return const Icon(
      Icons.check_circle,
      color: Colors.white,
      size: 20,
    );
  }

  Color _getBackgroundColor() {
    if (_isSyncing) {
      return Colors.blue[700]!;
    }

    if (!_isOnline && _pendingCount > 0) {
      return Colors.orange[700]!;
    }

    if (!_isOnline) {
      return Colors.grey[600]!;
    }

    if (_pendingCount > 0) {
      return Colors.blue[600]!;
    }

    return Colors.green[600]!;
  }

  String _getStatusTitle(AppLocalizations l10n) {
    if (_isSyncing) {
      return l10n.synchronizing;
    }

    if (!_isOnline && _pendingCount > 0) {
      return l10n.offlineWithPendingActions;
    }

    if (!_isOnline) {
      return l10n.offlineMode;
    }

    if (_pendingCount > 0) {
      return l10n.pendingActions;
    }

    return l10n.allSynced;
  }

  String? _getStatusSubtitle(AppLocalizations l10n) {
    if (_isSyncing) {
      return l10n.syncInProgress;
    }

    if (!_isOnline && _pendingCount > 0) {
      return l10n.willSyncWhenOnline;
    }

    if (_pendingCount > 0) {
      return l10n.tapToViewDetails;
    }

    return null;
  }

  void _showDetailsDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => _OfflineDetailsDialog(
        isOnline: _isOnline,
        pendingCount: _pendingCount,
        isSyncing: _isSyncing,
        l10n: l10n,
        onForceSync: () async {
          Navigator.pop(context);
          await _syncService.forceSyncNow();
        },
      ),
    );
  }
}

// ============================================================================
// DIALOG DE DÉTAILS
// ============================================================================

class _OfflineDetailsDialog extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final AppLocalizations l10n;
  final VoidCallback onForceSync;

  const _OfflineDetailsDialog({
    required this.isOnline,
    required this.pendingCount,
    required this.isSyncing,
    required this.l10n,
    required this.onForceSync,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(l10n.syncStatus),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(
            l10n.connectionStatus,
            isOnline ? l10n.online : l10n.offline,
            isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            l10n.pendingActions,
            '$pendingCount',
            pendingCount > 0 ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            l10n.syncState,
            isSyncing ? l10n.syncing : l10n.idle,
            isSyncing ? Colors.blue : Colors.grey,
          ),
          if (!isOnline && pendingCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.offlineDataWillSync,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isOnline && pendingCount > 0 && !isSyncing)
          TextButton.icon(
            onPressed: onForceSync,
            icon: const Icon(Icons.sync),
            label: Text(l10n.syncNow),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
