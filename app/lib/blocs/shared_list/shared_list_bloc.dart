// blocs/shared_list/shared_list_bloc.dart - VERSION BRANCH.IO
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/branch_links_service.dart';

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
      // 🌿 Étape 1: Créer le token côté serveur
      final shareData = await _sharedListService.createShareLink(
        listId: event.listId,
        permission: event.permission,
        expirationDays: event.expirationDays,
      );
      
      // 🌿 Étape 2: Créer le lien Branch.io avec les données reçues
      final branchLink = await BranchLinksService.createShareLink(
        shareToken: shareData['share_token'],
        listName: shareData['list_name'],
        ownerName: shareData['owner_name'],
      );
      
      // 🌿 Étape 3: Tracker l'événement de création de lien
      await BranchLinksService.trackCustomEvent(
        eventName: 'share_link_created',
        customData: {
          'list_id': event.listId.toString(),
          'permission': event.permission.toString(),
          'expiration_days': (event.expirationDays ?? 30).toString(),
        },
      );
      
      emit(ShareLinkCreated(branchLink));
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
      
      // 🌿 Tracker l'ouverture d'une invitation
      await BranchLinksService.trackCustomEvent(
        eventName: 'invitation_viewed',
        customData: {
          'share_token': event.shareToken,
          'list_name': invitation.listName,
        },
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
      
      // 🌿 Tracker l'acceptation d'une invitation
      await BranchLinksService.trackCustomEvent(
        eventName: 'invitation_accepted',
        customData: {
          'share_token': event.shareToken,
          'list_id': shoppingList.id.toString(),
          'list_name': shoppingList.name,
        },
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
      
      // 🌿 Tracker le refus d'une invitation
      await BranchLinksService.trackCustomEvent(
        eventName: 'invitation_declined',
        customData: {
          'share_token': event.shareToken,
        },
      );
      
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
      
      // 🌿 Tracker la modification de permissions
      await BranchLinksService.trackCustomEvent(
        eventName: 'permission_updated',
        customData: {
          'share_id': event.shareId.toString(),
          'new_permission': event.permission.toString(),
        },
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
      
      // 🌿 Tracker la révocation de partage
      await BranchLinksService.trackCustomEvent(
        eventName: 'share_revoked',
        customData: {
          'share_id': event.shareId.toString(),
        },
      );
      
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
      
      // 🌿 Tracker la sortie d'une liste partagée
      await BranchLinksService.trackCustomEvent(
        eventName: 'shared_list_left',
        customData: {
          'list_id': event.listId.toString(),
        },
      );
      
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
      
      // 🌿 Tracker la révocation de tous les liens
      await BranchLinksService.trackCustomEvent(
        eventName: 'all_share_links_revoked',
        customData: {
          'list_id': event.listId.toString(),
        },
      );
      
      emit(ShareOperationSuccess('Tous les liens de partage ont été révoqués'));
    } catch (e) {
      print("Error revoking all share links: $e");
      emit(SharedListError('Erreur lors de la révocation des liens'));
    }
  }
}