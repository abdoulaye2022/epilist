// config/app_config.dart
class AppConfig {
  // ACTIF — PRODUCTION. C'est la valeur que doit porter le depot : une
  // build de release partie avec une URL de dev ne joindrait rien, et
  // l'application ne le dirait pas. Garde-fou : scripts/check_release_config.sh
  static const String baseUrl = 'https://m2atodev.com/api.epilist/public';

  // Development — API locale (port 8001, voir launch.sh). Fonctionne sur
  // le simulateur iOS tel quel, et sur un appareil Android branche en USB
  // grace au pont « adb reverse tcp:8001 tcp:8001 » que launch.sh pose
  // automatiquement. Le HTTP en clair n'est autorise qu'en build DEBUG
  // (android/app/src/debug/res/xml/network_security_config.xml).
  // static const String baseUrl = 'http://localhost:8001';

  // Development - emulateur Android (l'hote vu depuis l'emulateur)
  // static const String baseUrl = 'http://10.0.2.2:8001';

  // Development via ngrok. Le tunnel doit pointer sur le port 8001
  // (launch.sh s'en charge). ATTENTION : le domaine reserve
  // m2atech.ngrok.app est partage avec un AUTRE projet. S'il est deja pris
  // par celui-la, l'app tape sur SON API (symptome : « utilisateur
  // inexistant »). Verifier d'abord :
  //   curl -s http://127.0.0.1:4041/api/tunnels
  // static const String baseUrl = 'https://m2atech.ngrok.app';

  // Development - IP locale (appareil reel sur le meme Wi-Fi)
  // static const String baseUrl = 'http://192.168.1.100:8001';

  // Logs de debug (debugPrint) dans la console.
  // false = silence total, meme en `flutter run`.
  // Passer a true UNIQUEMENT le temps de deboguer ; sans effet en release
  // (toujours silencieux, voir main.dart).
  static const bool enableDebugLogs = false;
}
// Commande pour voir l'adresse IP
//  ifconfig | grep "inet " | grep -v 127.0.0.1
// curl https://https://a39e35968fe0.ngrok-free.app/auth/login
