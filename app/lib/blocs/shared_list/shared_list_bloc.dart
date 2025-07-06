// blocs/shared_list/shared_list_bloc.dart - VERSION AVEC IMPORTS CORRIGÉS
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/share_invitation.dart'; // ✅ Import ajouté
import 'package:epilist/services/shared_list_service.dart';
import 'package:flutter/foundation.dart';

class SharedListBloc extends Bloc<SharedListEvent, SharedListState> {
  final SharedListService _sharedListService;

  SharedListBloc({required SharedListService sharedListService})
    : _sharedListService = sharedListService,
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
      emit(SharedListError('Erreur lors du chargement des listes partagées'));
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
      emit(SharedListError('Erreur lors du chargement des partages'));
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
      emit(SharedListError('Erreur lors de la création du lien de partage'));
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
      emit(SharedListError('Invitation invalide ou expirée'));
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
      emit(SharedListError('Erreur lors de l\'acceptation de l\'invitation'));
    }
  }

  Future<void> _onDeclineShareInvitation(
    DeclineShareInvitation event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.declineShareInvitation(event.shareToken);

      // debugPrint('✅ Invitation refusée');

      emit(ShareInvitationDeclined());
    } catch (e) {
      debugPrint("❌ Error declining share invitation: $e");
      emit(SharedListError('Erreur lors du refus de l\'invitation'));
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

      emit(ShareOperationSuccess('Permissions mises à jour avec succès'));
    } catch (e) {
      debugPrint("❌ Error updating share permission: $e");
      emit(SharedListError('Erreur lors de la mise à jour des permissions'));
    }
  }

  Future<void> _onRevokeShare(
    RevokeShare event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeShare(event.shareId);

      debugPrint('✅ Partage révoqué');

      emit(ShareOperationSuccess('Partage révoqué avec succès'));
    } catch (e) {
      debugPrint("❌ Error revoking share: $e");
      emit(SharedListError('Erreur lors de la révocation du partage'));
    }
  }

  Future<void> _onLeaveSharedList(
    LeaveSharedList event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.leaveSharedList(event.listId);

      debugPrint('✅ Liste quittée');

      emit(ShareOperationSuccess('Vous avez quitté la liste partagée'));
    } catch (e) {
      debugPrint("❌ Error leaving shared list: $e");
      emit(SharedListError('Erreur lors de la sortie de la liste'));
    }
  }

  Future<void> _onRevokeAllShareLinks(
    RevokeAllShareLinks event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeAllShareLinks(event.listId);

      debugPrint('✅ Tous les liens révoqués');

      emit(ShareOperationSuccess('Tous les liens de partage ont été révoqués'));
    } catch (e) {
      debugPrint("❌ Error revoking all share links: $e");
      emit(SharedListError('Erreur lors de la révocation des liens'));
    }
  }
}
