part of 'receipt_bloc.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();

  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {}

class ReceiptLoading extends ReceiptState {}

class ReceiptLoaded extends ReceiptState {
  final List<Receipt> receipts;

  const ReceiptLoaded(this.receipts);

  @override
  List<Object?> get props => [receipts];
}

class ReceiptsByStoreLoaded extends ReceiptState {
  final List<StoreReceiptGroup> storeGroups;

  const ReceiptsByStoreLoaded(this.storeGroups);

  @override
  List<Object?> get props => [storeGroups];
}

class ReceiptStatsLoaded extends ReceiptState {
  final ReceiptStats stats;

  const ReceiptStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class ReceiptOperationSuccess extends ReceiptState {
  final String message;

  const ReceiptOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Un rafraichissement a echoue ALORS QUE des donnees sont deja affichees.
/// Volontairement absent des `buildWhen` de l'ecran : la liste visible n'est
/// pas remplacee par un ecran d'erreur. Le `BlocListener` en fait un message
/// passager, pour que l'echec soit VU au lieu d'etre avale en silence (la
/// page semblait alors figee : la facture ajoutee n'apparaissait pas et rien
/// n'expliquait pourquoi).
class ReceiptRefreshFailed extends ReceiptState {
  final String message;

  const ReceiptRefreshFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiptError extends ReceiptState {
  final String message;

  const ReceiptError(this.message);

  @override
  List<Object?> get props => [message];
}
