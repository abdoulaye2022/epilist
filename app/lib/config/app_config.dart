// config/app_config.dart
class AppConfig {
  // Production
  static const String baseUrl = 'https://m2atodev.com/api.epilist/public';

  // L'API locale tourne sur le port 8001 (voir launch.sh)

  // Development - local server (FAST - simulateur / emulateur uniquement)
  // Pour iOS Simulator:   'http://localhost:8001'
  // Pour Android Emulator: 'http://10.0.2.2:8001'
  // static const String baseUrl = 'http://localhost:8001';

  // Development - IP locale (FAST - appareil reel sur le meme Wi-Fi)
  // static const String baseUrl = 'http://192.168.1.100:8001';

  // Development - ngrok (appareil reel) : domaine reserve permanent,
  // l'URL ne change pas d'un demarrage a l'autre (voir launch.sh).
  // static const String baseUrl = 'https://m2atech.ngrok.app';

  // Logs de debug (debugPrint) dans la console.
  // false = silence total, meme en `flutter run`.
  // Passer a true UNIQUEMENT le temps de deboguer ; sans effet en release
  // (toujours silencieux, voir main.dart).
  static const bool enableDebugLogs = false;
}
// Commande pour voir l'adresse IP
//  ifconfig | grep "inet " | grep -v 127.0.0.1
// curl https://https://a39e35968fe0.ngrok-free.app/auth/login