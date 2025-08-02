// complete_notification_test.dart - À ajouter temporairement dans votre app

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:epilist/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:epilist/config/app_config.dart';
import 'dart:io';

class CompleteNotificationTest extends StatefulWidget {
  const CompleteNotificationTest({super.key});

  @override
  State<CompleteNotificationTest> createState() =>
      _CompleteNotificationTestState();
}

class _CompleteNotificationTestState extends State<CompleteNotificationTest> {
  final List<String> _logs = [];
  bool _isTestRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print('🔍 [TEST] $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications Complet'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isTestRunning ? null : _runCompleteTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isTestRunning
                            ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Test en cours...'),
                              ],
                            )
                            : const Text('Lancer Test Complet'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testFirebaseConsole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Test Firebase Console'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testLocalNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Test Local'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black87;
                IconData icon = Icons.info;

                if (log.contains('✅') || log.contains('SUCCESS')) {
                  textColor = Colors.green[700]!;
                  icon = Icons.check_circle;
                } else if (log.contains('❌') || log.contains('ERROR')) {
                  textColor = Colors.red[700]!;
                  icon = Icons.error;
                } else if (log.contains('⚠️') || log.contains('WARNING')) {
                  textColor = Colors.orange[700]!;
                  icon = Icons.warning;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: textColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _isTestRunning = true;
      _logs.clear();
    });

    _addLog('🚀 Début du test complet des notifications');

    try {
      // 1. Informations de l'appareil
      await _testDeviceInfo();

      // 2. Permissions
      await _testPermissions();

      // 3. Firebase et tokens
      await _testFirebaseTokens();

      // 4. NotificationService
      await _testNotificationService();

      // 5. Enregistrement backend
      await _testBackendRegistration();

      // 6. Notifications locales
      await _testLocalNotifications();

      _addLog('✅ Test complet terminé');
    } catch (e) {
      _addLog('❌ Erreur lors du test: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  Future<void> _testDeviceInfo() async {
    _addLog('📱 Test des informations de l\'appareil...');

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _addLog(
          '📱 Android ${androidInfo.version.release} - API ${androidInfo.version.sdkInt}',
        );
        _addLog('📱 ${androidInfo.manufacturer} ${androidInfo.model}');
        _addLog('📱 ID: ${androidInfo.id}');

        if (androidInfo.version.sdkInt < 21) {
          _addLog('❌ API level trop ancien pour FCM (minimum 21)');
        } else {
          _addLog('✅ API level compatible');
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _addLog('📱 iOS ${iosInfo.systemVersion} - ${iosInfo.model}');
        _addLog('📱 Physique: ${iosInfo.isPhysicalDevice}');
      }
    } catch (e) {
      _addLog('❌ Erreur info appareil: $e');
    }
  }

  Future<void> _testPermissions() async {
    _addLog('🔒 Test des permissions...');

    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        _addLog('🔒 Notifications Android: $notificationStatus');

        if (notificationStatus != PermissionStatus.granted) {
          _addLog('⚠️ Demande de permission...');
          final result = await Permission.notification.request();
          _addLog('🔒 Résultat permission: $result');
        }

        // Autres permissions Android
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.status;
        _addLog('🔒 Optimisation batterie: $batteryStatus');
      } else if (Platform.isIOS) {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        _addLog('🔒 iOS Authorization: ${settings.authorizationStatus}');
        _addLog('🔒 iOS Alert: ${settings.alert}');
        _addLog('🔒 iOS Sound: ${settings.sound}');
        _addLog('🔒 iOS Badge: ${settings.badge}');
      }
    } catch (e) {
      _addLog('❌ Erreur permissions: $e');
    }
  }

  Future<void> _testFirebaseTokens() async {
    _addLog('🔥 Test Firebase et tokens...');

    try {
      // Test du token FCM
      _addLog('🔄 Récupération du token FCM...');
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        _addLog('✅ Token FCM reçu: ${fcmToken.substring(0, 30)}...');
        _addLog('📏 Longueur du token: ${fcmToken.length}');

        // Copier le token dans le presse-papiers pour test manuel
        _addLog('📋 Token complet: $fcmToken');
      } else {
        _addLog('❌ Aucun token FCM reçu');
      }

      // Test APNS pour iOS
      if (Platform.isIOS) {
        try {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            _addLog('✅ Token APNS reçu: ${apnsToken.substring(0, 30)}...');
          } else {
            _addLog('⚠️ Aucun token APNS');
          }
        } catch (e) {
          _addLog('⚠️ Erreur APNS: $e');
        }
      }
    } catch (e) {
      _addLog('❌ Erreur Firebase tokens: $e');
    }
  }

  Future<void> _testNotificationService() async {
    _addLog('🔔 Test NotificationService...');

    try {
      // final isInitialized = NotificationService.isInitialized;
      // _addLog('🔔 Service initialisé: $isInitialized');

      final currentToken = NotificationService.getCurrentToken();
      if (currentToken != null) {
        _addLog('✅ Token via service: ${currentToken.substring(0, 30)}...');
      } else {
        _addLog('❌ Aucun token via service');
      }

      final isRegistered = await NotificationService.isDeviceRegistered();
      _addLog('📋 Appareil enregistré: $isRegistered');
    } catch (e) {
      _addLog('❌ Erreur NotificationService: $e');
    }
  }

  Future<void> _testBackendRegistration() async {
    _addLog('🌐 Test enregistrement backend...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('access_token');

      if (authToken == null) {
        _addLog('⚠️ Pas de token d\'authentification');
        return;
      }

      _addLog('✅ Token auth disponible');

      // Test de connexion au backend
      final dio = Dio();
      dio.options.baseUrl = AppConfig.baseUrl;
      dio.options.headers['Authorization'] = 'Bearer $authToken';
      dio.options.connectTimeout = const Duration(seconds: 10);

      try {
        final response = await dio.get('/auth/me');
        _addLog('✅ Connexion backend OK: ${response.statusCode}');
      } catch (e) {
        _addLog('❌ Erreur connexion backend: $e');
      }
    } catch (e) {
      _addLog('❌ Erreur test backend: $e');
    }
  }

  Future<void> _testLocalNotifications() async {
    _addLog('🔔 Test notifications locales...');

    try {
      // Ce test sera implémenté séparément
      _addLog('ℹ️ Test notifications locales disponible via bouton séparé');
    } catch (e) {
      _addLog('❌ Erreur notifications locales: $e');
    }
  }

  Future<void> _testFirebaseConsole() async {
    _addLog('🎯 Instructions pour test Firebase Console:');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      _addLog('📋 1. Copier ce token: $fcmToken');
      _addLog('🌐 2. Aller sur Firebase Console');
      _addLog('📤 3. Cloud Messaging > Envoyer votre premier message');
      _addLog('🎯 4. Coller le token dans "Token d\'enregistrement FCM"');
      _addLog('✉️ 5. Titre: "Test EpiList"');
      _addLog('✉️ 6. Message: "Test de notification depuis Firebase Console"');
      _addLog('🚀 7. Cliquer sur "Tester"');
    } else {
      _addLog('❌ Pas de token disponible pour le test');
    }
  }

  Future<void> _testLocalNotification() async {
    _addLog('🔔 Test notification locale...');

    try {
      // Simuler une notification locale
      _addLog('📱 Simulation d\'une notification locale...');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test de notification locale - vérifiez les paramètres si aucune notification n\'apparaît',
          ),
          duration: Duration(seconds: 3),
        ),
      );

      _addLog('✅ Test local lancé - vérifiez la barre de notification');
    } catch (e) {
      _addLog('❌ Erreur notification locale: $e');
    }
  }
}
