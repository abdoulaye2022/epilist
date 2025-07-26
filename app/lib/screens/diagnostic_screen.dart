// diagnostic_screen.dart - VERSION AMÉLIORÉE ET COMPLÈTE
import 'package:flutter/material.dart';
import 'package:epilist/notifications/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  Map<String, dynamic> _diagnosticResults = {};
  bool _isLoading = false;
  String _lastTest = '';
  List<String> _testHistory = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnostic Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showAdvancedDiagnostic,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Diagnostic en cours...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statut général
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    // Permissions
                    _buildPermissionsCard(),
                    const SizedBox(height: 16),

                    // Notifications en attente
                    _buildPendingNotificationsCard(),
                    const SizedBox(height: 16),

                    // Capacités du service
                    _buildCapabilityCard(),
                    const SizedBox(height: 16),

                    // Tests rapides
                    _buildTestsCard(),
                    const SizedBox(height: 16),

                    // Historique des tests
                    if (_testHistory.isNotEmpty) _buildTestHistoryCard(),
                    const SizedBox(height: 16),

                    // Conseils et solutions
                    _buildAdviceCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusCard() {
    final status = _diagnosticResults['service_status'] ?? {};
    final platform = _diagnosticResults['platform'] ?? 'unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Statut général',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Service initialisé',
              status['service_initialized'] ?? false,
            ),
            _buildStatusRow('Plateforme', platform),
            _buildStatusRow('Timers actifs', '${status['active_timers'] ?? 0}'),
            _buildStatusRow(
              'Dernier ID notification',
              '${status['last_notification_id'] ?? 0}',
            ),
            if (_lastTest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Dernier test: $_lastTest',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final permissions =
        _diagnosticResults['permissions'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _requestMissingPermissions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Redemander les permissions',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (permissions.isEmpty)
              const Text('Aucune donnée de permission...')
            else
              ...permissions.entries.map(
                (entry) => _buildStatusRow(entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNotificationsCard() {
    final pendingCount =
        _diagnosticResults['pending_notifications'] as int? ?? 0;
    final pendingDetails = _diagnosticResults['pending_details'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Notifications programmées',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      pendingCount > 0 ? _clearPendingNotifications : null,
                  child: const Text('Effacer tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Notifications en attente', '$pendingCount'),
            if (pendingDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Détails:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...pendingDetails
                  .take(3)
                  .map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '• ID ${notification['id']}: ${notification['title']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              if (pendingDetails.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    '... et ${pendingDetails.length - 3} autres',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityCard() {
    final capability =
        _diagnosticResults['service_capability'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Capacités du service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (capability.isEmpty)
              const Text('Test de capacités en cours...')
            else
              ...capability.entries.map(
                (entry) => _buildStatusRow(
                  _formatCapabilityName(entry.key),
                  entry.value,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Tests rapides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testImmediate,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Immédiat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _test10Seconds,
                    icon: const Icon(Icons.timer_10),
                    label: const Text('10s'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _test2Minutes,
                    icon: const Icon(Icons.timer),
                    label: const Text('2 minutes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testWithTimer,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Timer Dart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Historique des tests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _testHistory.clear();
                    });
                  },
                  child: const Text('Effacer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._testHistory.reversed
                .take(5)
                .map(
                  (test) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $test',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    final permissions =
        _diagnosticResults['permissions'] as Map<String, dynamic>? ?? {};
    final capability =
        _diagnosticResults['service_capability'] as Map<String, dynamic>? ?? {};

    final hasPermissionIssues = permissions.values.any(
      (granted) => granted != true,
    );
    final hasCapabilityIssues = capability.values.any(
      (capable) => capable != true,
    );
    final hasIssues = hasPermissionIssues || hasCapabilityIssues;

    return Card(
      color: hasIssues ? Colors.red[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning : Icons.check_circle,
                  color: hasIssues ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  hasIssues ? 'Actions requises' : 'Configuration OK',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasIssues) ...[
              if (!(permissions['Batterie'] ?? true))
                _buildAdviceItem(
                  '🔋 Optimisation batterie',
                  'Paramètres > Apps > EpiList > Batterie > Non optimisée',
                ),
              if (!(permissions['Alarme exacte'] ?? true))
                _buildAdviceItem(
                  '⏰ Alarmes exactes',
                  'Paramètres > Apps > Applications spéciales > Alarmes et rappels',
                ),
              if (!(permissions['Notification'] ?? true))
                _buildAdviceItem(
                  '🔔 Notifications',
                  'Paramètres > Apps > EpiList > Notifications > Activées',
                ),
              if (Platform.isIOS && hasPermissionIssues)
                _buildAdviceItem(
                  '📱 iOS',
                  'Les notifications ne fonctionnent pas sur l\'émulateur iOS',
                ),
            ] else
              const Text(
                '✅ Toutes les permissions sont accordées ! Les notifications devraient fonctionner parfaitement.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    final isBoolean = value is bool;
    final displayValue = isBoolean ? (value ? '✅' : '❌') : value.toString();
    final color =
        isBoolean ? (value ? Colors.green : Colors.red) : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceItem(String title, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            instruction,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatCapabilityName(String key) {
    return switch (key) {
      'plugin_accessible' => 'Plugin accessible',
      'can_create_notifications' => 'Peut créer notifications',
      'has_permissions' => 'Permissions suffisantes',
      'can_schedule' => 'Peut programmer',
      _ => key,
    };
  }

  Future<void> _runDiagnostic() async {
    setState(() => _isLoading = true);

    try {
      // Obtenir le diagnostic complet du service
      final diagnostic = await NotificationService.runDiagnostic();

      setState(() {
        _diagnosticResults = {
          'service_status': NotificationService.getStatus(),
          'platform': Platform.operatingSystem,
          ...diagnostic,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticResults = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _requestMissingPermissions() async {
    try {
      await NotificationService.initialize();
      await _runDiagnostic();
      _showSnackBar('🔄 Permissions mises à jour', Colors.blue);
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _clearPendingNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
      await _runDiagnostic();
      _showSnackBar('✅ Notifications effacées', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _testImmediate() async {
    try {
      await NotificationService.testImmediateNotification();
      final timestamp = DateTime.now().toString().substring(11, 19);

      setState(() {
        _lastTest = 'Immédiat - $timestamp';
        _testHistory.add('✅ Immédiat à $timestamp');
      });

      _showSnackBar('✅ Notification immédiate envoyée !', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _test10Seconds() async {
    try {
      await NotificationService.scheduleNotification(
        id: 1010,
        title: '⏰ Test 10 secondes',
        body: 'Cette notification était programmée il y a 10 secondes',
        scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
        payload: 'test_10s',
      );

      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _lastTest = '10 secondes - $timestamp';
        _testHistory.add('⏰ Programmé 10s à $timestamp');
      });

      _showSnackBar('⏰ Test 10s programmé ! Attendez...', Colors.orange);
      await _runDiagnostic();
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _test2Minutes() async {
    try {
      await NotificationService.scheduleNotification(
        id: 2020,
        title: '🎯 Test 2 minutes',
        body:
            'Test critique : cette notification était programmée il y a 2 minutes',
        scheduledTime: DateTime.now().add(const Duration(minutes: 2)),
        payload: 'test_2min',
      );

      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _lastTest = '2 minutes - $timestamp';
        _testHistory.add('🎯 Programmé 2min à $timestamp');
      });

      _showSnackBar(
        '🎯 Test 2min programmé ! C\'est le test critique.',
        Colors.red,
      );
      await _runDiagnostic();
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _testWithTimer() async {
    try {
      await NotificationService.scheduleWithTimer(
        id: 3030,
        title: '⏱️ Test Timer Dart',
        body: 'Notification via Timer Dart (15 secondes)',
        delay: const Duration(seconds: 15),
        payload: 'test_timer',
      );

      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _lastTest = 'Timer Dart - $timestamp';
        _testHistory.add('⏱️ Timer Dart 15s à $timestamp');
      });

      _showSnackBar('⏱️ Timer Dart créé (15s) !', Colors.purple);
      await _runDiagnostic();
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _showAdvancedDiagnostic() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🔧 Diagnostic avancé'),
            content: SingleChildScrollView(
              child: Text(
                'Diagnostic complet:\n\n${_diagnosticResults.toString()}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
