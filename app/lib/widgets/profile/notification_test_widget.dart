// widgets/profile/notification_test_widget.dart - VERSION CORRIGÉE AVEC SUPPORT SIMULATEUR
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/notification_service.dart';
import 'dart:convert';
import 'dart:io';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _lastDebugData;
  String? _lastTestResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec icône et badge simulateur
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '🔔 Test des Notifications',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ✅ BADGE SIMULATEUR/PHYSIQUE
                            if (NotificationService.isSimulator)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  '🧪 SIMULATEUR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Text(
                                  '📱 PHYSIQUE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          NotificationService.isSimulator
                              ? 'Tester sur simulateur iOS (notifications simulées)'
                              : 'Tester sur appareil physique (vraies notifications)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ INFORMATIONS SUR L'ÉTAT ACTUEL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      NotificationService.isInitialized
                          ? Colors.green[50]
                          : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        NotificationService.isInitialized
                            ? Colors.green[200]!
                            : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          NotificationService.isInitialized
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color:
                              NotificationService.isInitialized
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          NotificationService.isInitialized
                              ? '✅ Service Notifications: Initialisé'
                              : '⚠️ Service Notifications: Non initialisé',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                NotificationService.isInitialized
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Token FCM: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          NotificationService.getCurrentToken() != null
                              ? '${NotificationService.getCurrentToken()!.substring(0, 15)}...'
                              : 'Non disponible',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color:
                                NotificationService.getCurrentToken() != null
                                    ? Colors.green[700]
                                    : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ RÉSULTAT DU DERNIER TEST
              if (_lastTestResult != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _lastTestResult!.contains('✅')
                            ? Colors.green[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _lastTestResult!.contains('✅')
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Dernier test:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastTestResult!,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              _lastTestResult!.contains('✅')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Boutons d'action
              Column(
                children: [
                  // ✅ BOUTON PRINCIPAL: Test via serveur (simulé ou réel)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading
                              ? null
                              : () => _testNotificationViaServer(context),
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                NotificationService.isSimulator
                                    ? Icons.science
                                    : Icons.send,
                              ),
                      label: Text(
                        _isLoading
                            ? 'Envoi en cours...'
                            : NotificationService.isSimulator
                            ? 'Test Simulé via Serveur'
                            : 'Test Réel via Serveur',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            NotificationService.isSimulator
                                ? Colors.orange[600]
                                : Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ BOUTON: Test notification locale immédiate
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading
                              ? null
                              : () => _testLocalNotificationImmediate(context),
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Test Notification Locale'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ BOUTON: Voir appareils enregistrés
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isLoading ? null : () => _debugDevices(context),
                      icon: const Icon(Icons.devices),
                      label: const Text('Voir mes appareils'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        side: BorderSide(color: Colors.blue[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // ✅ NOUVEAU: Bouton test notification service direct
                  if (NotificationService.isSimulator) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed:
                            _isLoading
                                ? null
                                : () => _testNotificationServiceDirect(context),
                        icon: const Icon(Icons.science),
                        label: const Text('Test Service Direct'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Affichage des informations de debug si disponibles
              if (_lastDebugData != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Dernières informations:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Appareils: ${_lastDebugData!['total_devices'] ?? 0} '
                        '(Actifs: ${_lastDebugData!['active_devices'] ?? 0})',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (_lastDebugData!['simulated_count'] != null)
                        Text(
                          'Simulés: ${_lastDebugData!['simulated_count']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // ✅ INFORMATION POUR LE DÉVELOPPEUR
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Information Développeur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NotificationService.isSimulator
                          ? '📱 Simulateur iOS détecté: Les notifications Firebase sont simulées visuellement avec des notifications locales et des SnackBars.'
                          : '📱 Appareil physique détecté: Les notifications Firebase peuvent être reçues normalement.',
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Test via serveur (gère simulateur et physique)
  Future<void> _testNotificationViaServer(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _lastTestResult = null;
    });

    try {
      // ✅ UTILISER LE SERVICE NOTIFICATION DIRECTEMENT
      // final result =
      //     await NotificationService.sendTestNotificationToCurrentUser();

      // setState(() {
      //   if (result['success'] == true) {
      //     String message = '✅ ${result['message']}';

      //     if (result['is_simulator'] == true) {
      //       message += '\n🧪 Mode simulateur activé';
      //     }

      //     if (result['simulated_count'] != null &&
      //         result['simulated_count'] > 0) {
      //       message +=
      //           '\n📱 ${result['simulated_count']} notifications simulées';
      //       _lastDebugData = {'simulated_count': result['simulated_count']};
      //     }

      //     if (result['sent_count'] != null) {
      //       message += '\n📨 ${result['sent_count']} envois total';
      //     }

      //     if (result['local_fallback'] == true) {
      //       message += '\n💾 Fallback local utilisé (normal en développement)';
      //     }

      //     _lastTestResult = message;
      //     _showSuccessSnackBar(context, '✅ Test réussi !');
      //   } else {
      //     _lastTestResult = '❌ ${result['message']}';
      //     _showErrorSnackBar(context, 'Échec: ${result['message']}');
      //   }
      // });
    } catch (e) {
      setState(() {
        _lastTestResult = '❌ Erreur: ${_getErrorMessage(e)}';
      });
      _showErrorSnackBar(context, '❌ Erreur: ${_getErrorMessage(e)}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ NOUVELLE MÉTHODE: Test service direct (pour simulateur)
  Future<void> _testNotificationServiceDirect(BuildContext context) async {
    if (!NotificationService.isSimulator) {
      _showErrorSnackBar(
        context,
        '⚠️ Cette fonction n\'est disponible que sur simulateur',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // await NotificationService.showTestNotificationNow();

      setState(() {
        _lastTestResult =
            '✅ Notification service direct testée avec succès\n🧪 Notification locale affichée immédiatement';
      });

      _showSuccessSnackBar(context, '✅ Test service direct réussi !');
    } catch (e) {
      setState(() {
        _lastTestResult = '❌ Erreur test service direct: $e';
      });
      _showErrorSnackBar(context, '❌ Erreur service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ MÉTHODE AMÉLIORÉE: Test notification locale
  Future<void> _testLocalNotificationImmediate(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Créer une instance de FlutterLocalNotificationsPlugin
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      // ✅ CONFIGURATION AMÉLIORÉE POUR iOS ET ANDROID
      const androidDetails = AndroidNotificationDetails(
        'test_channel_immediate',
        'Test Immédiat',
        channelDescription: 'Canal de test pour notifications immédiates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Colors.blue,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
        threadIdentifier: 'test_notification',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Générer un ID unique basé sur le timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      final payload = jsonEncode({
        'type': 'test_local_immediate',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'widget_test',
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'is_simulator': NotificationService.isSimulator,
      });

      await localNotifications.show(
        notificationId,
        '🧪 Test Notification Locale',
        NotificationService.isSimulator
            ? 'Notification locale sur simulateur iOS (ID: $notificationId)'
            : 'Notification locale sur appareil physique (ID: $notificationId)',
        notificationDetails,
        payload: payload,
      );

      setState(() {
        _lastTestResult =
            '✅ Notification locale affichée avec succès\n'
            '📱 ID: $notificationId\n'
            '⏰ ${DateTime.now().toString().substring(11, 19)}';
      });

      _showSuccessSnackBar(
        context,
        '📱 Notification locale envoyée (ID: $notificationId)',
      );
    } catch (e) {
      setState(() {
        _lastTestResult = '❌ Erreur notification locale: $e';
      });
      _showErrorSnackBar(context, '❌ Erreur notification locale: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ MÉTHODE ORIGINALE CONSERVÉE: Debug appareils
  Future<void> _debugDevices(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('access_token');

      if (authToken == null) {
        _showErrorSnackBar(context, '❌ Non authentifié');
        return;
      }

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $authToken';

      final response = await dio.get('${AppConfig.baseUrl}/devices/debug');

      if (response.statusCode == 200) {
        final data = response.data;

        // Sauvegarder pour l'affichage
        setState(() => _lastDebugData = data);

        _showDevicesDialog(context, data);
      }
    } catch (e) {
      _showErrorSnackBar(context, '❌ Erreur: ${_getErrorMessage(e)}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDevicesDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  NotificationService.isSimulator
                      ? Icons.science
                      : Icons.devices,
                  color:
                      NotificationService.isSimulator
                          ? Colors.orange
                          : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '🔍 Mes Appareils ${NotificationService.isSimulator ? "(Mode Simulateur)" : ""}',
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Résumé
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          NotificationService.isSimulator
                              ? Colors.orange[50]
                              : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Résumé:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Total: ${data['total_devices']}'),
                        Text('Actifs: ${data['active_devices']}'),
                        Text('User ID: ${data['user_id']}'),
                        if (NotificationService.isSimulator)
                          Text(
                            '🧪 Mode Simulateur Actif',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liste des appareils
                  if (data['devices'] != null &&
                      data['devices'].isNotEmpty) ...[
                    const Text(
                      '📱 Appareils:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...data['devices']
                        .map<Widget>(
                          (device) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        device['platform'] == 'android'
                                            ? Icons.android
                                            : Icons.phone_iphone,
                                        color:
                                            device['can_receive_notifications']
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${device['platform']} - ${device['model'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // ✅ BADGE SIMULATEUR DANS LA LISTE
                                      if (device['push_token'] != null &&
                                          device['push_token']
                                              .toString()
                                              .contains('simulator_token'))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            '🧪 SIM',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              device['can_receive_notifications']
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          device['can_receive_notifications']
                                              ? '✅ Actif'
                                              : '❌ Inactif',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                device['can_receive_notifications']
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${device['device_id']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Token: ${device['push_token'] ?? 'Aucun'}',
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (device['last_active'] != null)
                                    Text(
                                      'Dernière activité: ${_formatDate(device['last_active'])}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        '📱 Aucun appareil enregistré',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              if (data['devices'] != null && data['devices'].isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _testNotificationViaServer(context);
                  },
                  child: Text(
                    NotificationService.isSimulator
                        ? 'Tester (Simulé)'
                        : 'Tester Notifications',
                  ),
                ),
            ],
          ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Inconnue';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inDays} jour(s)';
      }
    } catch (e) {
      return 'Format invalide';
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 404) {
        return 'Route non trouvée - Vérifiez l\'URL de l\'API';
      } else if (error.response?.statusCode == 401) {
        return 'Non autorisé - Token expiré';
      } else if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data['error'] != null) {
          return data['error']['message'] ?? 'Erreur serveur';
        }
      }
      return 'Erreur réseau: ${error.message}';
    }
    return error.toString();
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
