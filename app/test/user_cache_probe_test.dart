import 'package:flutter_test/flutter_test.dart';
import 'package:epilist/models/user.dart';

void main() {
  final apiMe = {
    "success": true,
    "data": {
      "id": 10,
      "first_name": "Abdoulaye",
      "last_name": "Mohamed Ahmed",
      "email": "m2atodev@gmail.com",
      "avatar_url": "https://storage.googleapis.com/epilist-storage/dev/avatars/x.jpg",
      "email_verified": true,
      "currency": {"id": 1, "code": "CAD", "name": "Dollar canadien", "symbol": "\$"},
      "is_active": true,
    }
  };

  test('chaîne complète /auth/me -> cache -> relecture garde l avatar', () {
    final u1 = User.fromMap(apiMe);
    expect(u1.avatarUrl, isNotNull);
    final cached = u1.toJsonString();
    final u2 = User.fromJsonString(cached);
    expect(u2.avatarUrl, u1.avatarUrl);
    expect(u2.firstName, 'Abdoulaye');
  });

  test('fromLoginResponse (payload plat) garde l avatar', () {
    final u = User.fromLoginResponse({
      'access_token': 'a', 'refresh_token': 'r',
      'data': (apiMe['data'] as Map<String, dynamic>),
    });
    expect(u.avatarUrl, isNotNull);
    final u2 = User.fromJsonString(u.toJsonString());
    expect(u2.avatarUrl, isNotNull);
  });
}
