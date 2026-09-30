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
///
/// [syncOverride] : pendant le REJEU d'une action hors ligne, l'espace
/// capturé à l'enqueue prime sur l'espace actif (l'utilisateur a pu
/// changer d'espace entre-temps). 0 = forcer le personnel.
class SpaceHeaderInterceptor extends Interceptor {
  static int? syncOverride;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final override = syncOverride;
    if (override != null) {
      if (override > 0) {
        options.headers['X-Space-Id'] = override.toString();
      }
      handler.next(options);
      return;
    }
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

/// Extension Phase 3 : fournisseurs et demandes d'achat (restaurant).
extension SpaceServicePhase3 on SpaceService {
  Future<List<SupplierInfo>> getSuppliers() async {
    final res = await dio.get('/suppliers');
    return ((res.data['data']['suppliers'] as List? ?? []))
        .map((e) => SupplierInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSupplier({
    int? id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? notes,
    bool? isActive,
  }) async {
    final body = {
      'name': name,
      if (contactName != null) 'contact_name': contactName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
    };
    if (id == null) {
      await dio.post('/suppliers', data: body);
    } else {
      await dio.put('/suppliers/$id', data: body);
    }
  }

  Future<(List<PurchaseRequestInfo>, int)> getPurchaseRequests(
      {String? status}) async {
    final res = await dio.get('/purchase-requests',
        queryParameters: status == null ? null : {'status': status});
    final list = ((res.data['data']['requests'] as List? ?? []))
        .map((e) => PurchaseRequestInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    return (list, res.data['data']['pending_count'] as int? ?? 0);
  }

  Future<void> createPurchaseRequest({
    required String productName,
    double? quantity,
    String? unit,
    String? note,
  }) async {
    await dio.post('/purchase-requests', data: {
      'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null && unit.isNotEmpty) 'unit': unit,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> actOnPurchaseRequest(int id, String action,
      {String? comment}) async {
    await dio.post('/purchase-requests/$id/$action',
        data: comment == null ? null : {'comment': comment});
  }
}

/// Phase 4 — intelligence prix : prix cible et alertes de baisse.
/// L'espace actif est porté par l'en-tête X-Space-Id (intercepteur).
extension SpaceServicePhase4 on SpaceService {
  Future<List<PriceAlertInfo>> getPriceAlerts() async {
    final res = await dio.get('/price-alerts');
    return ((res.data['data']['alerts'] as List? ?? []))
        .map((e) => PriceAlertInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PriceTargetSuggestion> suggestPriceTarget(String product) async {
    final res = await dio
        .get('/price-alerts/suggest', queryParameters: {'product': product});
    return PriceTargetSuggestion.fromJson(
        (res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<void> createPriceAlert({
    required String productName,
    required double targetPrice,
  }) async {
    await dio.post('/price-alerts', data: {
      'product_name': productName,
      'target_price': targetPrice,
    });
  }

  Future<void> updatePriceAlert(int id,
      {double? targetPrice, bool? isActive}) async {
    await dio.put('/price-alerts/$id', data: {
      if (targetPrice != null) 'target_price': targetPrice,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<void> deletePriceAlert(int id) async {
    await dio.delete('/price-alerts/$id');
  }
}

/// Phase 5 — assistant intelligent : brief avant les courses (§28),
/// économies estimées documentées (§30), « est-ce un bon prix » (§29).
/// Réponses laissées en Map : composition d'affichage, pas de logique.
extension SpaceServicePhase5 on SpaceService {
  Future<Map<String, dynamic>> getPreShopping() async {
    final res = await dio.get('/assistant/pre-shopping');
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getSavings({int days = 30}) async {
    final res =
        await dio.get('/assistant/savings', queryParameters: {'days': days});
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> checkPrice(String product, double price) async {
    final res = await dio.get('/prices/check',
        queryParameters: {'product': product, 'price': price});
    return (res.data['data'] as Map).cast<String, dynamic>();
  }
}
