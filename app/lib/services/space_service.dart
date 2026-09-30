// services/space_service.dart - Espaces (Phase 1) : appels API,
// espace actif persisté, et en-tête X-Space-Id injecté sur chaque
// requête. Le serveur revérifie l'appartenance à CHAQUE appel : cet
// en-tête n'est qu'une déclaration d'intention, jamais une preuve.
import 'package:dio/dio.dart';
import 'package:epilist/models/space.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Espace actif de la session : persisté, observable (le sélecteur du
/// drawer s'y abonne). null = espace personnel (comportement historique).
class ActiveSpaceStore {
  static const _idKey = 'active_space_id';
  static const _nameKey = 'active_space_name';
  static const _typeKey = 'active_space_type';

  /// (id, name, type) — null tant que l'espace personnel est actif.
  static final ValueNotifier<Space?> current = ValueNotifier<Space?>(null);

  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_idKey);
      if (id == null) return;
      current.value = Space(
        id: id,
        name: prefs.getString(_nameKey) ?? '',
        type: prefs.getString(_typeKey) ?? 'household',
        ownerUserId: 0,
      );
    } catch (_) {}
  }

  static Future<void> set(Space? space) async {
    current.value = (space == null || space.isPersonal) ? null : space;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (current.value == null) {
        await prefs.remove(_idKey);
        await prefs.remove(_nameKey);
        await prefs.remove(_typeKey);
      } else {
        await prefs.setInt(_idKey, current.value!.id);
        await prefs.setString(_nameKey, current.value!.name);
        await prefs.setString(_typeKey, current.value!.type);
      }
    } catch (_) {}
  }

  /// À la déconnexion : retour à l'espace personnel.
  static Future<void> clear() => set(null);
}

/// Ajoute X-Space-Id à toutes les requêtes quand un espace non
/// personnel est actif. Sans en-tête, le serveur sert le personnel.
class SpaceHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final space = ActiveSpaceStore.current.value;
    if (space != null) {
      options.headers['X-Space-Id'] = space.id.toString();
    }
    handler.next(options);
  }
}

class SpaceService {
  final Dio dio;

  SpaceService({required this.dio});

  Future<List<Space>> getSpaces() async {
    final res = await dio.get('/spaces');
    final list = (res.data['data']['spaces'] as List? ?? []);
    return list.map((e) => Space.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Space> createSpace({
    required String type,
    required String name,
    String? country,
    String? region,
    String? city,
    String? postalCode,
  }) async {
    final res = await dio.post('/spaces', data: {
      'type': type,
      'name': name,
      if (country != null && country.isNotEmpty) 'country': country,
      if (region != null && region.isNotEmpty) 'region': region,
      if (city != null && city.isNotEmpty) 'city': city,
      if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
    });
    return Space.fromJson(res.data['data']['space'] as Map<String, dynamic>);
  }

  Future<List<SpaceMemberInfo>> getMembers(int spaceId) async {
    final res = await dio.get('/spaces/$spaceId/members');
    final list = (res.data['data']['members'] as List? ?? []);
    return list
        .map((e) => SpaceMemberInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> invite(int spaceId, String email, String role) async {
    await dio.post('/spaces/$spaceId/invitations',
        data: {'email': email, 'role': role});
  }

  Future<List<Map<String, dynamic>>> pendingInvitations(int spaceId) async {
    final res = await dio.get('/spaces/$spaceId/invitations');
    return ((res.data['data']['invitations'] as List? ?? []))
        .cast<Map<String, dynamic>>();
  }

  Future<void> revokeInvitation(int spaceId, int invitationId) async {
    await dio.delete('/spaces/$spaceId/invitations/$invitationId');
  }

  Future<List<SpaceInvitationInfo>> myInvitations() async {
    final res = await dio.get('/space-invitations');
    final list = (res.data['data']['invitations'] as List? ?? []);
    return list
        .map((e) => SpaceInvitationInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Répond à une invitation reçue (le jeton n'est fourni qu'au
  /// destinataire par GET /space-invitations).
  Future<Space?> answerInvitation(SpaceInvitationInfo inv, bool accept) async {
    final token = inv.token;
    if (token == null) return null;
    final res = await dio.post(
        '/space-invitations/$token/${accept ? 'accept' : 'decline'}');
    if (accept && res.data['data']?['space'] != null) {
      return Space.fromJson(res.data['data']['space'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> leave(int spaceId) async {
    await dio.post('/spaces/$spaceId/leave');
  }

  Future<void> updateMemberRole(int spaceId, int userId, String role) async {
    await dio.put('/spaces/$spaceId/members/$userId', data: {'role': role});
  }

  Future<void> removeMember(int spaceId, int userId) async {
    await dio.delete('/spaces/$spaceId/members/$userId');
  }
}
