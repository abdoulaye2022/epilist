// Un rafraichissement rate ne doit JAMAIS etre avale en silence.
//
// Avant : quand des factures etaient deja affichees, un rechargement en
// echec n'emettait rien du tout. La page gardait un etat perime sans un mot
// d'explication — typiquement apres l'ajout d'une facture scannee, qui
// n'apparaissait alors jamais dans la liste. C'est le « la page facture ne
// fonctionne pas » vu de l'interieur.
//
// Maintenant : la liste visible est conservee (on ne la remplace pas par un
// ecran d'erreur) MAIS l'echec remonte sous la forme d'un ReceiptRefreshFailed,
// dont l'ecran fait un message passager.

import 'package:dio/dio.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de facade : repond ce que le test lui dicte, sans reseau.
class _ServiceSimule extends ReceiptService {
  _ServiceSimule({required super.dio, required super.authService});

  /// Quand c'est non nul, getListReceipts leve cette erreur.
  Object? erreur;
  List<Receipt> factures = const [];

  @override
  Future<List<Receipt>> getListReceipts(int listId) async {
    if (erreur != null) throw erreur!;
    return factures;
  }
}

void main() {
  late _ServiceSimule service;
  late ReceiptBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();
    service = _ServiceSimule(
      dio: dio,
      authService: AuthService(dio: dio, sharedPreferences: prefs),
    );
    bloc = ReceiptBloc(
      receiptService: service,
      localizationBloc: LocalizationBloc(sharedPreferences: prefs),
    );
  });

  tearDown(() => bloc.close());

  test('premier chargement en echec : chargement puis erreur plein ecran', () async {
    service.erreur = Exception('connexion perdue');

    final vus = <ReceiptState>[];
    final abonnement = bloc.stream.listen(vus.add);
    bloc.add(const LoadReceipts(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await abonnement.cancel();

    expect(vus.map((e) => e.runtimeType), [ReceiptLoading, ReceiptError]);
    // Rien n'est affiche : l'erreur a toute la place, avec un bouton Reessayer.
    expect((vus.last as ReceiptError).message, isNotEmpty);
  });

  test('rechargement en echec alors que la liste est affichee : signale, pas avale', () async {
    // 1er chargement reussi.
    bloc.add(const LoadReceipts(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<ReceiptLoaded>());

    // 2e chargement en echec (celui qui suit l'ajout d'une facture, par ex.).
    service.erreur = Exception('connexion perdue');
    final vus = <ReceiptState>[];
    final abonnement = bloc.stream.listen(vus.add);
    bloc.add(const LoadReceipts(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await abonnement.cancel();

    // Le silence d'avant : vus serait vide.
    expect(vus, isNotEmpty, reason: 'l\'echec doit etre signale');
    expect(vus.single, isA<ReceiptRefreshFailed>());
    expect((vus.single as ReceiptRefreshFailed).message, isNotEmpty);
    // Et surtout : pas de ReceiptError, qui effacerait la liste visible.
    expect(vus.whereType<ReceiptError>(), isEmpty);
  });
}
