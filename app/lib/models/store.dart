// models/store.dart - Magasin de l'utilisateur, avec son ordre de rayons
import 'package:equatable/equatable.dart';

/// Les jours de la semaine, dans l'ordre, tels que l'API les nomme.
///
/// `DateTime.weekday` vaut 1 pour lundi et 7 pour dimanche : l'index
/// dans cette liste est donc `weekday - 1`.
const List<String> kJoursApi = [
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun',
];

/// Une plage d'ouverture : « 08:00 » à « 21:00 ».
class StoreHours extends Equatable {
  const StoreHours({required this.open, required this.close});

  final String open;
  final String close;

  /// `null` si la journée est fermée (plage absente ou nulle), ce qui
  /// est le cas le plus fréquent du dimanche.
  static StoreHours? fromJson(dynamic brut) {
    if (brut is! List || brut.length != 2) return null;
    return StoreHours(open: brut[0].toString(), close: brut[1].toString());
  }

  List<String> toJson() => [open, close];

  @override
  List<Object?> get props => [open, close];
}

class Store extends Equatable {
  final int id;
  final String name;
  final String slug;

  /// Ordre des rayons : liste de kinds de catégories
  /// (ex. ["fruits_vegetables", "bakery", "dairy"...]).
  /// Vide = pas encore configuré pour ce magasin.
  final List<String> categoryOrder;

  /// Où il se trouve. La planche montre l'adresse sur la carte d'un
  /// magasin ; elle était introuvable, faute de colonne, jusqu'à la
  /// migration 012.
  final String? address;
  final String? city;
  final String? postalCode;

  /// Les coordonnées servent à calculer une DISTANCE, le jour où
  /// l'application saura où est le téléphone. Elles ne portent aucune
  /// distance elles-mêmes : une distance enregistrée serait une
  /// distance depuis un point qui n'a pas de sens.
  final double? latitude;
  final double? longitude;

  /// Les heures d'ouverture par jour. Une clé absente ou nulle vaut
  /// « fermé ».
  final Map<String, StoreHours?> openingHours;

  /// Le favori appartient au MEMBRE, pas au magasin : dans un espace
  /// partagé, le magasin de quartier de l'un n'est pas celui de l'autre.
  /// Il vivait auparavant dans les préférences de l'appareil — perdu au
  /// changement de téléphone, invisible pour les autres membres.
  final bool isFavorite;

  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryOrder = const [],
    this.address,
    this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.openingHours = const {},
    this.isFavorite = false,
  });

  bool get hasAisleOrder => categoryOrder.isNotEmpty;

  /// L'adresse en une ligne, ou `null` si rien n'est renseigné.
  String? get addressLine {
    final morceaux = [
      address,
      city,
      postalCode,
    ].where((m) => m != null && m.trim().isNotEmpty).map((m) => m!.trim());
    return morceaux.isEmpty ? null : morceaux.join(', ');
  }

  bool get hasOpeningHours => openingHours.values.any((h) => h != null);

  /// Les heures d'un jour donné (1 = lundi … 7 = dimanche).
  StoreHours? hoursFor(int weekday) {
    if (weekday < 1 || weekday > 7) return null;
    return openingHours[kJoursApi[weekday - 1]];
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    final heures = <String, StoreHours?>{};
    final brut = json['opening_hours'];
    if (brut is Map) {
      for (final entree in brut.entries) {
        final jour = entree.key.toString();
        if (kJoursApi.contains(jour)) {
          heures[jour] = StoreHours.fromJson(entree.value);
        }
      }
    }

    double? nombre(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

    return Store(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryOrder:
          (json['category_order'] is List)
              ? (json['category_order'] as List)
                  .map((e) => e.toString())
                  .toList()
              : const [],
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: nombre(json['latitude']),
      longitude: nombre(json['longitude']),
      openingHours: heures,
      isFavorite: json['is_favorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category_order': categoryOrder,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours.map((j, h) => MapEntry(j, h?.toJson())),
      'is_favorite': isFavorite,
    };
  }

  Store copyWith({
    int? id,
    String? name,
    String? slug,
    List<String>? categoryOrder,
    String? address,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    Map<String, StoreHours?>? openingHours,
    bool? isFavorite,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingHours: openingHours ?? this.openingHours,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    categoryOrder,
    address,
    city,
    postalCode,
    latitude,
    longitude,
    openingHours,
    isFavorite,
  ];
}
