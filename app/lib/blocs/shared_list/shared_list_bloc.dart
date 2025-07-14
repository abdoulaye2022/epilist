// blocs/shared_list/shared_list_bloc.dart - VERSION AVEC TRADUCTIONS CORRIGÉES
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart'; // ✅ NOUVEAU
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/share_invitation.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:flutter/foundation.dart';

class SharedListBloc extends Bloc<SharedListEvent, SharedListState> {
  final SharedListService _sharedListService;
  final LocalizationBloc
  _localizationBloc; // ✅ NOUVEAU: Injection du LocalizationBloc

  SharedListBloc({
    required SharedListService sharedListService,
    required LocalizationBloc localizationBloc, // ✅ NOUVEAU
  }) : _sharedListService = sharedListService,
       _localizationBloc = localizationBloc, // ✅ NOUVEAU
       super(SharedListInitial()) {
    on<LoadSharedLists>(_onLoadSharedLists);
    on<LoadListShares>(_onLoadListShares);
    on<CreateShareLink>(_onCreateShareLink);
    on<LoadShareInvitation>(_onLoadShareInvitation);
    on<AcceptShareInvitation>(_onAcceptShareInvitation);
    on<DeclineShareInvitation>(_onDeclineShareInvitation);
    on<UpdateSharePermission>(_onUpdateSharePermission);
    on<RevokeShare>(_onRevokeShare);
    on<LeaveSharedList>(_onLeaveSharedList);
    on<RevokeAllShareLinks>(_onRevokeAllShareLinks);
  }

  /// ✅ NOUVEAU: Méthode pour les messages de succès
  String _getTranslatedSuccessMessage(String operation) {
    // Fallbacks français par défaut
    const Map<String, String> frenchMessages = {
      'load_shared': 'Listes partagées chargées avec succès',
      'load_shares': 'Partages chargés avec succès',
      'create_link': 'Lien de partage créé avec succès',
      'load_invitation': 'Invitation chargée avec succès',
      'accept_invitation': 'Invitation acceptée avec succès',
      'decline_invitation': 'Invitation refusée avec succès',
      'update_permission': 'Permissions mises à jour avec succès',
      'revoke_share': 'Partage révoqué avec succès',
      'leave_list': 'Vous avez quitté la liste partagée',
      'revoke_all_links': 'Tous les liens de partage ont été révoqués',
    };

    const Map<String, String> englishMessages = {
      'load_shared': 'Shared lists loaded successfully',
      'load_shares': 'Shares loaded successfully',
      'create_link': 'Share link created successfully',
      'load_invitation': 'Invitation loaded successfully',
      'accept_invitation': 'Invitation accepted successfully',
      'decline_invitation': 'Invitation declined successfully',
      'update_permission': 'Permissions updated successfully',
      'revoke_share': 'Share revoked successfully',
      'leave_list': 'You left the shared list',
      'revoke_all_links': 'All share links have been revoked',
    };

    // Déterminer la langue depuis LocalizationBloc
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

  /// ✅ NOUVEAU: Méthode pour les messages d'erreur
  String _getTranslatedErrorMessage(String operation, dynamic error) {
    // Fallbacks français par défaut
    const Map<String, String> frenchErrors = {
      'load_shared': 'Erreur lors du chargement des listes partagées',
      'load_shares': 'Erreur lors du chargement des partages',
      'create_link': 'Erreur lors de la création du lien de partage',
      'load_invitation': 'Invitation invalide ou expirée',
      'accept_invitation': 'Erreur lors de l\'acceptation de l\'invitation',
      'decline_invitation': 'Erreur lors du refus de l\'invitation',
      'update_permission': 'Erreur lors de la mise à jour des permissions',
      'revoke_share': 'Erreur lors de la révocation du partage',
      'leave_list': 'Erreur lors de la sortie de la liste',
      'revoke_all_links': 'Erreur lors de la révocation des liens',
    };

    const Map<String, String> englishErrors = {
      'load_shared': 'Error loading shared lists',
      'load_shares': 'Error loading shares',
      'create_link': 'Error creating share link',
      'load_invitation': 'Invalid or expired invitation',
      'accept_invitation': 'Error accepting invitation',
      'decline_invitation': 'Error declining invitation',
      'update_permission': 'Error updating permissions',
      'revoke_share': 'Error revoking share',
      'leave_list': 'Error leaving list',
      'revoke_all_links': 'Error revoking links',
    };

    // Déterminer la langue depuis LocalizationBloc
    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishErrors[operation] ?? 'An error occurred';
    } else {
      return frenchErrors[operation] ?? 'Une erreur est survenue';
    }
  }

  Future<void> _onLoadSharedLists(
    LoadSharedLists event,
    Emitter<SharedListState> emit,
  ) async {
    emit(SharedListLoading());
    try {
      final sharedLists = await _sharedListService.getSharedLists();
      emit(SharedListsLoaded(sharedLists));
    } catch (e) {
      debugPrint("❌ Error loading shared lists: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('load_shared', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onLoadListShares(
    LoadListShares event,
    Emitter<SharedListState> emit,
  ) async {
    emit(SharedListLoading());
    try {
      final shares = await _sharedListService.getListShares(event.listId);
      emit(ListSharesLoaded(listId: event.listId, shares: shares));
    } catch (e) {
      debugPrint("❌ Error loading list shares: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('load_shares', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onCreateShareLink(
    CreateShareLink event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      debugPrint('🔄 Création du lien de partage...');

      final shareData = await _sharedListService.createShareLink(
        listId: event.listId,
        permission: event.permission,
        expirationDays: event.expirationDays,
      );

      debugPrint('✅ Lien de partage créé: ${shareData['share_url']}');

      emit(ShareLinkCreated(shareData['share_url']));
    } catch (e) {
      debugPrint("❌ Error creating share link: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('create_link', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onLoadShareInvitation(
    LoadShareInvitation event,
    Emitter<SharedListState> emit,
  ) async {
    emit(SharedListLoading());
    try {
      final invitation = await _sharedListService.getShareInvitation(
        event.shareToken,
      );

      debugPrint('✅ Invitation chargée: ${invitation.listName}');

      emit(ShareInvitationLoaded(invitation));
    } catch (e) {
      debugPrint("❌ Error loading share invitation: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('load_invitation', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onAcceptShareInvitation(
    AcceptShareInvitation event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      final shoppingList = await _sharedListService.acceptShareInvitation(
        event.shareToken,
      );

      debugPrint('✅ Invitation acceptée: ${shoppingList.name}');

      emit(ShareInvitationAccepted(shoppingList));
    } catch (e) {
      debugPrint("❌ Error accepting share invitation: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('accept_invitation', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onDeclineShareInvitation(
    DeclineShareInvitation event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.declineShareInvitation(event.shareToken);

      emit(ShareInvitationDeclined());
    } catch (e) {
      debugPrint("❌ Error declining share invitation: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('decline_invitation', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onUpdateSharePermission(
    UpdateSharePermission event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.updateSharePermission(
        shareId: event.shareId,
        permission: event.permission,
      );

      debugPrint('✅ Permissions mises à jour');

      // ✅ UTILISER la nouvelle méthode de traduction
      final successMessage = _getTranslatedSuccessMessage('update_permission');
      emit(ShareOperationSuccess(successMessage));
    } catch (e) {
      debugPrint("❌ Error updating share permission: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('update_permission', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onRevokeShare(
    RevokeShare event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeShare(event.shareId);

      debugPrint('✅ Partage révoqué');

      // ✅ UTILISER la nouvelle méthode de traduction
      final successMessage = _getTranslatedSuccessMessage('revoke_share');
      emit(ShareOperationSuccess(successMessage));
    } catch (e) {
      debugPrint("❌ Error revoking share: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('revoke_share', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onLeaveSharedList(
    LeaveSharedList event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.leaveSharedList(event.listId);

      debugPrint('✅ Liste quittée');

      // ✅ UTILISER la nouvelle méthode de traduction
      final successMessage = _getTranslatedSuccessMessage('leave_list');
      emit(ShareOperationSuccess(successMessage));
    } catch (e) {
      debugPrint("❌ Error leaving shared list: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('leave_list', e);
      emit(SharedListError(errorMessage));
    }
  }

  Future<void> _onRevokeAllShareLinks(
    RevokeAllShareLinks event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeAllShareLinks(event.listId);

      debugPrint('✅ Tous les liens révoqués');

      // ✅ UTILISER la nouvelle méthode de traduction
      final successMessage = _getTranslatedSuccessMessage('revoke_all_links');
      emit(ShareOperationSuccess(successMessage));
    } catch (e) {
      debugPrint("❌ Error revoking all share links: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedErrorMessage('revoke_all_links', e);
      emit(SharedListError(errorMessage));
    }
  }
}
