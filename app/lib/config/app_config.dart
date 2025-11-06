// config/app_config.dart
class AppConfig {
  // Production URLs
  static const String baseUrl = 'https://m2atodev.com/api.epilist/public';
  // static const String baseUrl = 'https://m2acode.com/api.epilist/public';

  // Development - ngrok (SLOW - use only for real device)
  // static const String baseUrl = 'https://a0f4e7436d3e.ngrok-free.app';

  // Development - local server (FAST - for simulator/emulator)
  // Pour iOS Simulator: 'http://localhost:8080'
  // Pour Android Emulator: 'http://10.0.2.2:8080'
  // static const String baseUrl = 'http://localhost:8080';
}
// Commande pour voir l'adresse IP
//  ifconfig | grep "inet " | grep -v 127.0.0.1
// curl https://https://a39e35968fe0.ngrok-free.app/auth/login