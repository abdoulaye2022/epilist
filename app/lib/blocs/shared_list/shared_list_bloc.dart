// blocs/shared_list/shared_list_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/deep_link_handler.dart';

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
      print("Error loading shared lists: $e");
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
      print("Error loading list shares: $e");
      emit(SharedListError('Erreur lors du chargement des partages'));
    }
  }

  Future<void> _onCreateShareLink(
    CreateShareLink event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      // Créer le lien de partage côté serveur
      final shareToken = await _sharedListService.createShareLink(
        listId: event.listId,
        permission: event.permission,
        expirationDays: event.expirationDays,
      );

      // 🆕 Générer l'URL avec le nouveau domaine
      final shareUrl = DeepLinkHandler.generateUniversalShareUrl(shareToken);

      emit(ShareLinkCreated(shareUrl));
    } catch (e) {
      print("Error creating share link: $e");
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
      emit(ShareInvitationLoaded(invitation));
    } catch (e) {
      print("Error loading share invitation: $e");
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
      emit(ShareInvitationAccepted(shoppingList));
    } catch (e) {
      print("Error accepting share invitation: $e");
      emit(SharedListError('Erreur lors de l\'acceptation de l\'invitation'));
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
      print("Error declining share invitation: $e");
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
      emit(ShareOperationSuccess('Permissions mises à jour avec succès'));
    } catch (e) {
      print("Error updating share permission: $e");
      emit(SharedListError('Erreur lors de la mise à jour des permissions'));
    }
  }

  Future<void> _onRevokeShare(
    RevokeShare event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeShare(event.shareId);
      emit(ShareOperationSuccess('Partage révoqué avec succès'));
    } catch (e) {
      print("Error revoking share: $e");
      emit(SharedListError('Erreur lors de la révocation du partage'));
    }
  }

  Future<void> _onLeaveSharedList(
    LeaveSharedList event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.leaveSharedList(event.listId);
      emit(ShareOperationSuccess('Vous avez quitté la liste partagée'));
    } catch (e) {
      print("Error leaving shared list: $e");
      emit(SharedListError('Erreur lors de la sortie de la liste'));
    }
  }

  Future<void> _onRevokeAllShareLinks(
    RevokeAllShareLinks event,
    Emitter<SharedListState> emit,
  ) async {
    try {
      await _sharedListService.revokeAllShareLinks(event.listId);
      emit(ShareOperationSuccess('Tous les liens de partage ont été révoqués'));
    } catch (e) {
      print("Error revoking all share links: $e");
      emit(SharedListError('Erreur lors de la révocation des liens'));
    }
  }
}
