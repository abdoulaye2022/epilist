// config/app_navigator.dart - Accès au navigateur racine depuis
// l'extérieur de l'arbre de widgets.
//
// Nécessaire pour ouvrir un écran à la suite d'un clic sur une
// notification : à ce moment-là, aucun BuildContext d'écran n'est
// disponible (l'application peut même être en train de démarrer).
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
