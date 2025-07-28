// blocs/receipt/receipt_event.dart
part of 'receipt_bloc.dart';

abstract class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object?> get props => [];
}

class LoadReceipts extends ReceiptEvent {
  final int listId;

  const LoadReceipts(this.listId);

  @override
  List<Object?> get props => [listId];
}

class CreateReceipt extends ReceiptEvent {
  final int listId;
  final String storeName;
  final double totalAmount;
  final DateTime purchaseDate;
  final String? notes;

  const CreateReceipt({
    required this.listId,
    required this.storeName,
    required this.totalAmount,
    required this.purchaseDate,
    this.notes,
  });

  @override
  List<Object?> get props => [
    listId,
    storeName,
    totalAmount,
    purchaseDate,
    notes,
  ];
}

class UpdateReceipt extends ReceiptEvent {
  final int listId;
  final int receiptId;
  final String? storeName;
  final double? totalAmount;
  final DateTime? purchaseDate;
  final String? notes;

  const UpdateReceipt({
    required this.listId,
    required this.receiptId,
    this.storeName,
    this.totalAmount,
    this.purchaseDate,
    this.notes,
  });

  @override
  List<Object?> get props => [
    listId,
    receiptId,
    storeName,
    totalAmount,
    purchaseDate,
    notes,
  ];
}

class DeleteReceipt extends ReceiptEvent {
  final int listId;
  final int receiptId;

  const DeleteReceipt({required this.listId, required this.receiptId});

  @override
  List<Object?> get props => [listId, receiptId];
}

class LoadReceiptsByStore extends ReceiptEvent {
  final int listId;

  const LoadReceiptsByStore(this.listId);

  @override
  List<Object?> get props => [listId];
}

class LoadReceiptStats extends ReceiptEvent {
  final int listId;

  const LoadReceiptStats(this.listId);

  @override
  List<Object?> get props => [listId];
}
