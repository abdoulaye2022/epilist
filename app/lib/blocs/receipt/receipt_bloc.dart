// blocs/receipt/receipt_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:equatable/equatable.dart';

part 'receipt_event.dart';
part 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  final ReceiptService _receiptService;
  final LocalizationBloc _localizationBloc;

  ReceiptBloc({
    required ReceiptService receiptService,
    required LocalizationBloc localizationBloc,
  }) : _receiptService = receiptService,
       _localizationBloc = localizationBloc,
       super(ReceiptInitial()) {
    on<LoadReceipts>(_onLoadReceipts);
    on<CreateReceipt>(_onCreateReceipt);
    on<UpdateReceipt>(_onUpdateReceipt);
    on<DeleteReceipt>(_onDeleteReceipt);
    on<LoadReceiptsByStore>(_onLoadReceiptsByStore);
    on<LoadReceiptStats>(_onLoadReceiptStats);
  }

  /// Messages de succès traduits
  String _getTranslatedSuccessMessage(String operation) {
    const Map<String, String> frenchMessages = {
      'create': 'Facture ajoutée avec succès',
      'update': 'Facture modifiée avec succès',
      'delete': 'Facture supprimée avec succès',
      'load': 'Factures chargées avec succès',
    };

    const Map<String, String> englishMessages = {
      'create': 'Receipt added successfully',
      'update': 'Receipt updated successfully',
      'delete': 'Receipt deleted successfully',
      'load': 'Receipts loaded successfully',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishMessages[operation] ?? 'Operation successful';
    } else {
      return frenchMessages[operation] ?? 'Opération réussie';
    }
  }

  /// Messages d'erreur traduits
  String _getTranslatedErrorMessage(dynamic error) {
    const Map<String, String> frenchErrors = {
      'network': 'Erreur de réseau',
      'permission': 'Permission insuffisante',
      'not_found': 'Facture non trouvée',
      'validation': 'Données invalides',
      'server': 'Erreur du serveur',
      'general': 'Une erreur est survenue',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'permission': 'Insufficient permission',
      'not_found': 'Receipt not found',
      'validation': 'Invalid data',
      'server': 'Server error',
      'general': 'An error occurred',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    String errorString = error.toString().toLowerCase();
    String errorType = 'general';

    if (errorString.contains('network') ||
        errorString.contains('réseau') ||
        errorString.contains('connection') ||
        errorString.contains('connexion')) {
      errorType = 'network';
    } else if (errorString.contains('permission') ||
        errorString.contains('autorisé') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      errorType = 'permission';
    } else if (errorString.contains('not found') ||
        errorString.contains('non trouvé') ||
        errorString.contains('404')) {
      errorType = 'not_found';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('invalide')) {
      errorType = 'validation';
    } else if (errorString.contains('server') ||
        errorString.contains('serveur') ||
        errorString.contains('500')) {
      errorType = 'server';
    }

    if (isEnglish) {
      return englishErrors[errorType]!;
    } else {
      return frenchErrors[errorType]!;
    }
  }

  Future<void> _onLoadReceipts(
    LoadReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(ReceiptLoading());
    try {
      final receipts = await _receiptService.getListReceipts(event.listId);
      emit(ReceiptLoaded(receipts));
    } catch (e) {
      print("Error loading receipts: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }

  Future<void> _onCreateReceipt(
    CreateReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    try {
      final newReceipt = await _receiptService.createReceipt(
        listId: event.listId,
        storeName: event.storeName,
        totalAmount: event.totalAmount,
        purchaseDate: event.purchaseDate,
        notes: event.notes,
      );

      final successMessage = _getTranslatedSuccessMessage('create');
      emit(ReceiptOperationSuccess(successMessage));

      // ✅ CORRECTION: Recharger toutes les données après création
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadReceipts(event.listId));
    } catch (e) {
      print("Error creating receipt: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }

  Future<void> _onUpdateReceipt(
    UpdateReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    try {
      print("🔄 Début de la mise à jour de la facture ${event.receiptId}");

      // ✅ CORRECTION: Construire les données correctement
      final Map<String, dynamic> updateData = {};

      if (event.storeName != null) {
        updateData['store_name'] = event.storeName!;
      }
      if (event.totalAmount != null) {
        updateData['total_amount'] = event.totalAmount!;
      }
      if (event.purchaseDate != null) {
        updateData['purchase_date'] =
            event.purchaseDate!.toIso8601String().split('T')[0];
      }
      if (event.notes != null) {
        updateData['notes'] = event.notes!;
      }

      print("📤 Données à envoyer: $updateData");

      final updatedReceipt = await _receiptService.updateReceipt(
        listId: event.listId,
        receiptId: event.receiptId,
        storeName: event.storeName,
        totalAmount: event.totalAmount,
        purchaseDate: event.purchaseDate,
        notes: event.notes,
      );

      print("✅ Facture mise à jour avec succès: ${updatedReceipt.id}");

      final successMessage = _getTranslatedSuccessMessage('update');
      emit(ReceiptOperationSuccess(successMessage));

      // ✅ CORRECTION: Recharger les données après mise à jour
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadReceipts(event.listId));
    } catch (e) {
      print("❌ Erreur lors de la mise à jour: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }

  Future<void> _onDeleteReceipt(
    DeleteReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    try {
      await _receiptService.deleteReceipt(event.listId, event.receiptId);

      final successMessage = _getTranslatedSuccessMessage('delete');
      emit(ReceiptOperationSuccess(successMessage));

      // ✅ CORRECTION: Recharger les données après suppression
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadReceipts(event.listId));
    } catch (e) {
      print("Error deleting receipt: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }

  Future<void> _onLoadReceiptsByStore(
    LoadReceiptsByStore event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(ReceiptLoading());
    try {
      final storeGroups = await _receiptService.getReceiptsByStore(
        event.listId,
      );
      emit(ReceiptsByStoreLoaded(storeGroups));
    } catch (e) {
      print("Error loading receipts by store: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }

  Future<void> _onLoadReceiptStats(
    LoadReceiptStats event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(ReceiptLoading());
    try {
      final stats = await _receiptService.getReceiptStats(event.listId);
      emit(ReceiptStatsLoaded(stats));
    } catch (e) {
      print("Error loading receipt stats: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ReceiptError(errorMessage));
    }
  }
}
