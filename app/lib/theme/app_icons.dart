// theme/app_icons.dart - Un seul jeu d'icônes pour les dix sections.
//
// Elles étaient choisies écran par écran : la même section portait un
// dessin dans la barre du bas, un autre dans le menu, un troisième sur
// sa tuile. Trois disaient autre chose que leur section — un reçu pour
// « Avant les courses », alors que le tableau de bord a déjà « Scanner
// un reçu » ; une fourchette et un couteau pour « Planifier mes
// repas », qui disent « restaurant » ; un réfrigérateur pour « À la
// maison », qui n'est qu'une zone sur quatre, à côté du garde-manger et
// de l'entretien.
//
// Elles vivent ici, et nulle part ailleurs : changer une icône se fait
// une fois, et la barre du bas, le menu, les tuiles et les écrans vides
// changent ensemble.
//
// Un seul style de trait pour toutes — les contours de Material. Les
// glyphes pleins et multicolores de la planche disaient leur couleur
// avant de dire leur section, et ne se rangeaient dans aucune famille.
import 'package:flutter/material.dart';

/// Les dix destinations, et les quelques gestes qui les accompagnent.
abstract final class AppIcons {
  /// Quatre carrés : la convention, et elle est juste.
  static const IconData dashboard = Icons.space_dashboard_outlined;

  /// Une liste à coches. Juste aussi.
  static const IconData lists = Icons.checklist_rounded;

  /// Un portefeuille, pas un cochon-tirelire : le cochon dit
  /// « épargne », quand la section parle de ce qu'on dépense ce mois-ci.
  static const IconData budgets = Icons.account_balance_wallet_outlined;

  /// Des barres, sans étincelle : l'étincelle de `insights` évoque
  /// l'intelligence artificielle, pas une dépense comparée au mois
  /// dernier.
  static const IconData analytics = Icons.bar_chart_rounded;

  /// Un bloc-notes avec une coche : cinq étapes à vérifier avant de
  /// partir. Ni un reçu (c'est une facture, et le tableau de bord en a
  /// déjà un), ni une baguette magique.
  static const IconData preShopping = Icons.fact_check_outlined;

  /// Une étiquette de prix avec sa flèche : une cloche ne dit que
  /// « notification », ce que fait déjà la moitié de l'application.
  static const IconData priceAlerts = Icons.price_change_outlined;

  /// Des étagères : ce que la section montre vraiment, quatre zones de
  /// rangement, dont une seule est le réfrigérateur.
  static const IconData inventory = Icons.shelves;

  /// Un calendrier et ses flèches de répétition. Clair.
  static const IconData recurring = Icons.event_repeat_outlined;

  /// Un calendrier : la section planifie une semaine. Le couvert disait
  /// « aller au restaurant ».
  static const IconData mealPlanner = Icons.calendar_month_rounded;

  /// Une devanture, comme sur la fiche d'un magasin.
  static const IconData stores = Icons.storefront_outlined;

  /// L'épingle de carte, pour la distance et l'itinéraire : elle
  /// accompagne la devanture, elle ne la remplace pas.
  static const IconData storePin = Icons.place_outlined;
}
