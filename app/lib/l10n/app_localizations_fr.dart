// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'EpiList';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get hello => 'Bonjour ! 👋';

  @override
  String get manageGroceryLists => 'Gérez vos listes d\'épicerie facilement';

  @override
  String get myGroceryLists => 'Mes Listes d\'Épicerie';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get newList => 'Nouvelle Liste';

  @override
  String get createList => 'Créer une liste';

  @override
  String get noGroceryLists => 'Aucune liste d\'épicerie';

  @override
  String get createFirstList => 'Créez votre première liste';

  @override
  String get loadingError => 'Erreur de chargement';

  @override
  String get retry => 'Réessayer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get allLists => 'Toutes les listes';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get articles => 'articles';

  @override
  String get budget => 'Budget';

  @override
  String get sharedList => 'Liste partagée';

  @override
  String get collaborators => 'collaborateur(s)';

  @override
  String get sharedBy => 'Partagée par';

  @override
  String get completed => '✅ Terminée';

  @override
  String get inProgress => '🛒 En cours';

  @override
  String get created => 'Créée';

  @override
  String get edit => 'Modifier';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get share => 'Partager';

  @override
  String get manageShares => 'Gérer les partages';

  @override
  String get leave => 'Quitter';

  @override
  String get delete => 'Supprimer';

  @override
  String get cannotEditPermission =>
      'Vous n\'avez pas la permission de modifier cette liste';

  @override
  String get cannotSharePermission =>
      'Vous n\'avez pas la permission de partager cette liste';

  @override
  String get onlyOwnerManageShares =>
      'Seul le propriétaire peut gérer les partages';

  @override
  String get cannotLeaveOwnList => 'Impossible de quitter votre propre liste';

  @override
  String get cannotDeletePermission =>
      'Vous n\'avez pas la permission de supprimer cette liste';

  @override
  String get readOnlyAccess => 'Lecture seule';

  @override
  String get editAccess => 'Édition';

  @override
  String get adminAccess => 'Admin';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get languageSelection => 'Sélection de la langue';

  @override
  String get choosePreferredLanguage => 'Choisissez votre langue préférée';

  @override
  String get continueButton => 'Continuer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get login => 'Se connecter';

  @override
  String get register => 'S\'inscrire';

  @override
  String get welcomeToEpiList => 'Bienvenue sur EpiList';

  @override
  String get groceryListApp => 'Votre application de listes d\'épicerie';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ?';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get initialization => 'Initialisation...';

  @override
  String get checkingAuthentication => 'Vérification de l\'authentification...';

  @override
  String get invalidCredentials => 'Email ou mot de passe incorrect';

  @override
  String get userNotFound => 'Aucun compte trouvé avec cet email';

  @override
  String get emailNotVerified => 'Email non vérifié';

  @override
  String get sessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get emailConfirmedSuccess =>
      'Email confirmé avec succès ! Bienvenue !';

  @override
  String get networkError => 'Erreur de réseau';

  @override
  String get unknownError => 'Une erreur inattendue est survenue';

  @override
  String get initializationError => 'Erreur d\'initialisation';

  @override
  String get cannotStartApp => 'Impossible de démarrer l\'application';

  @override
  String get myProfile => 'Mon Profil';

  @override
  String get myData => 'Mes données';

  @override
  String get myShoppingLists => 'Mes listes de courses';

  @override
  String get settings => 'Paramètres';

  @override
  String get appSettings => 'Paramètres de l\'application';

  @override
  String get security => 'Sécurité';

  @override
  String get information => 'Informations';

  @override
  String get aboutEpiList => 'À propos d\'EpiList';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get emailVerified => 'Email vérifié';

  @override
  String get emailNotVerifiedStatus => 'Email non vérifié';

  @override
  String get loadingProfile => 'Chargement du profil...';

  @override
  String get cannotLoadProfile => 'Impossible de charger le profil';

  @override
  String get accountDeletionScheduled => 'Suppression de compte programmée';

  @override
  String accountWillBeDeleted(String date) {
    return 'Votre compte sera définitivement supprimé le $date';
  }

  @override
  String timeRemaining(int days, String plural) {
    return 'Temps restant : $days jour$plural';
  }

  @override
  String reason(String reason) {
    return 'Raison : $reason';
  }

  @override
  String get cancelDeletion => 'Annuler la suppression';

  @override
  String get cancellationPeriodExpired =>
      'La période d\'annulation de 30 jours est écoulée';

  @override
  String get deletionCodeSent =>
      'Code de suppression envoyé ! Vérifiez votre email.';

  @override
  String get accountDeletionCancelled =>
      'Suppression de compte annulée avec succès !';

  @override
  String get accountWillBeDeletedIn30Days =>
      'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action.';

  @override
  String get confirmCancelDeletion => 'Annuler la suppression';

  @override
  String get confirmCancelDeletionText =>
      'Êtes-vous sûr de vouloir annuler la suppression de votre compte ? Votre compte redeviendra actif immédiatement.';

  @override
  String get noKeepDeletion => 'Non, garder la suppression';

  @override
  String get yesCancelDeletion => 'Oui, annuler';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get enterYourCode => 'Entrez votre code';

  @override
  String get enterCodeAndNewPassword =>
      'Entrez le code et votre nouveau mot de passe';

  @override
  String get enterEmailForVerificationCode =>
      'Entrez votre email pour recevoir un code de vérification';

  @override
  String verificationCodeSentTo(Object email) {
    return 'Code de vérification envoyé à $email';
  }

  @override
  String get passwordChangedSuccessfully =>
      'Mot de passe modifié avec succès !';

  @override
  String get pleaseEnterEmail => 'Veuillez saisir votre email';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get verificationCode => 'Code de vérification';

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres';

  @override
  String get pleaseEnterVerificationCode =>
      'Veuillez saisir le code de vérification';

  @override
  String get codeMustBeSixDigits => 'Le code doit contenir 6 chiffres';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get pleaseEnterNewPassword =>
      'Veuillez saisir votre nouveau mot de passe';

  @override
  String get passwordMinSixCharacters =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe *';

  @override
  String get pleaseConfirmNewPassword =>
      'Veuillez confirmer votre nouveau mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get codeExpiresInTwoHours => 'Le code expire dans 2 heures';

  @override
  String get verificationCodeWillBeSent =>
      'Un code de vérification sera envoyé par email';

  @override
  String get changingPassword => 'Changement en cours...';

  @override
  String get sendingCode => 'Envoi du code...';

  @override
  String get invalidVerificationCode => 'Le code de vérification est invalide';

  @override
  String get verificationCodeExpired =>
      'Le code de vérification a expiré. Demandez un nouveau code.';

  @override
  String get noAccountFoundWithEmail => 'Aucun compte trouvé avec cet email';

  @override
  String get emailNotVerifiedYet => 'Votre email n\'est pas encore vérifié';

  @override
  String get errorChangingPassword =>
      'Erreur lors du changement de mot de passe';

  @override
  String get connectionProblemCheckNetwork =>
      'Problème de connexion. Vérifiez votre réseau.';

  @override
  String get enteredDataNotValid => 'Les données saisies ne sont pas valides';

  @override
  String get unexpectedErrorOccurred => 'Une erreur inattendue est survenue';

  @override
  String get manageGroceryListsEasily => 'Gérez vos courses facilement';

  @override
  String get createListsBeforeShopping =>
      'Créez vos listes avant d\'aller faire vos courses';

  @override
  String get checkPurchasesRealTime => 'Cochez vos achats en temps réel';

  @override
  String get trackGroceryExpenses => 'Suivez vos dépenses d\'épicerie en CAD\$';

  @override
  String get loggingIn => 'Connexion en cours...';

  @override
  String get pleaseEnterPassword => 'Veuillez saisir votre mot de passe';

  @override
  String get passwordMinThreeCharacters =>
      'Le mot de passe doit contenir au moins 3 caractères';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get or => 'OU';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get simplifyShoppingControlBudget =>
      'Simplifiez vos courses et maîtrisez votre budget !';

  @override
  String get pleaseFixFormErrors =>
      'Veuillez corriger les erreurs dans le formulaire';

  @override
  String get emailMustBeVerified =>
      'Votre email doit être vérifié avant de continuer.';

  @override
  String get resetPasswordSecurely =>
      'Réinitialiser votre mot de passe en toute sécurité.';

  @override
  String get cancel => 'Annuler';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get joinEpiListToManage =>
      'Rejoignez EpiList pour gérer vos courses facilement';

  @override
  String get creatingAccount => 'Création du compte en cours...';

  @override
  String get firstNameRequired => 'Prénom requis';

  @override
  String get lastNameRequired => 'Nom requis';

  @override
  String get tooShort => 'Trop court';

  @override
  String get atLeastSixCharacters => 'Au moins 6 caractères';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get passwordsDifferent => 'Mots de passe différents';

  @override
  String get iAcceptThe => 'J\'accepte les ';

  @override
  String get andThe => ' et la ';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get afterRegistrationEmailVerification =>
      'Après inscription, vous recevrez un code de vérification par email';

  @override
  String accountCreatedSuccessfully(String firstName, String lastName) {
    return 'Compte créé avec succès ! $firstName $lastName\nVérifiez votre email pour activer votre compte.';
  }

  @override
  String get emailAlreadyExists => 'Cette adresse email est déjà utilisée';

  @override
  String get passwordTooWeak => 'Le mot de passe est trop faible';

  @override
  String get validationError => 'Les données saisies ne sont pas valides';

  @override
  String get noShoppingLists => 'Aucune liste de courses';

  @override
  String get createFirstListToStart =>
      'Créez votre première liste pour commencer';

  @override
  String get leaveList => 'Quitter la liste';

  @override
  String sureToLeave(String listName) {
    return 'Êtes-vous sûr de vouloir quitter \"$listName\" ?';
  }

  @override
  String get loseAccessWarning =>
      'Vous perdrez l\'accès à cette liste et à tous ses éléments.';

  @override
  String get list => 'Liste';

  @override
  String get noActiveShares => 'Aucun partage actif';

  @override
  String get user => 'Utilisateur';

  @override
  String get modifyPermissions => 'Modifier permissions';

  @override
  String get revoke => 'Révoquer';

  @override
  String get createNewShare => 'Créer un nouveau partage';

  @override
  String get close => 'Fermer';

  @override
  String get today => 'aujourd\'hui';

  @override
  String get yesterday => 'hier';

  @override
  String daysAgo(int days) {
    return 'il y a $days jours';
  }

  @override
  String get on => 'le';

  @override
  String get cad => ' \$CAD';

  @override
  String createShareLinkFor(String listName) {
    return 'Créez un lien de partage pour \"$listName\"';
  }

  @override
  String get permissions => 'Permissions';

  @override
  String get linkExpiration => 'Expiration du lien';

  @override
  String daysCount(int count) {
    return '$count jours';
  }

  @override
  String get creating => 'Création...';

  @override
  String get generateShareLink => 'Générer le lien de partage';

  @override
  String get linkCreatedSuccessfully => 'Lien créé avec succès';

  @override
  String get copy => 'Copier';

  @override
  String get newLink => 'Nouveau lien';

  @override
  String linkExpirationInfo(int days) {
    return 'Le lien expire après $days jours. Vous pouvez révoquer l\'accès à tout moment.';
  }

  @override
  String get shareLinkCreatedSuccessfully =>
      'Lien de partage créé avec succès !';

  @override
  String get linkCopiedToClipboard => 'Lien copié dans le presse-papiers !';

  @override
  String get you => 'Vous';

  @override
  String epilistInvitation(String listName) {
    return 'Invitation EpiList - $listName';
  }

  @override
  String get shareError => 'Erreur lors du partage';

  @override
  String get readOnlyDescription => 'Peut voir la liste mais pas la modifier';

  @override
  String get editDescription =>
      'Peut ajouter, modifier et marquer des articles';

  @override
  String get adminDescription =>
      'Peut tout faire, y compris partager et supprimer';

  @override
  String get total => 'Total';

  @override
  String get progress => 'Progression';

  @override
  String get editList => 'Modifier la liste';

  @override
  String get thisListIsEmpty => 'Cette liste est vide';

  @override
  String get yourListIsEmpty => 'Votre liste est vide';

  @override
  String get noItemsReadOnlyDescription =>
      'Il n\'y a pas encore d\'articles dans cette liste.\nVous pouvez seulement consulter son contenu.';

  @override
  String get noItemsNoPermissionDescription =>
      'Il n\'y a pas encore d\'articles dans cette liste.\nVous n\'avez pas la permission d\'ajouter des articles.';

  @override
  String get noItemsAddFirstDescription =>
      'Commencez par ajouter votre premier article\npour organiser vos courses.';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get readOnlyMode => 'Mode lecture seule';

  @override
  String get permissionRequiredToAdd => 'Permission requise pour ajouter';

  @override
  String get addItemTooltip => 'Ajouter un article';

  @override
  String get insufficientPermission => 'Permission insuffisante';

  @override
  String get readOnlyAccessMode =>
      'Mode lecture seule - Vous ne pouvez pas modifier cette liste';

  @override
  String get sharedListCanEdit =>
      'Liste partagée - Vous pouvez modifier les articles';

  @override
  String get limitedAccess => 'Accès limité à cette liste';

  @override
  String get by => 'Par';

  @override
  String get quantity => 'Quantité';

  @override
  String get deleteItem => 'Supprimer';

  @override
  String get editItem => 'Modifier l\'article';

  @override
  String get listInformation => 'Informations de la liste';

  @override
  String detailsAndPermissions(String listName) {
    return 'Détails et permissions de \"$listName\"';
  }

  @override
  String get name => 'Nom';

  @override
  String get status => 'Statut';

  @override
  String get private => 'Privée';

  @override
  String get yourRole => 'Votre rôle';

  @override
  String get owner => 'Propriétaire';

  @override
  String get collaborator => 'Collaborateur';

  @override
  String get understood => 'Compris';

  @override
  String get moreInfo => 'Plus d\'infos';

  @override
  String get contactOwnerForPermissions =>
      'Contactez le propriétaire pour obtenir plus de permissions';

  @override
  String deleteItemConfirm(String itemName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$itemName\" de la liste ?';
  }

  @override
  String leaveListConfirm(String listName) {
    return 'Êtes-vous sûr de vouloir quitter \"$listName\" ?\n\nVous perdrez l\'accès à cette liste et ne pourrez plus voir son contenu.';
  }

  @override
  String leftList(String listName) {
    return 'Vous avez quitté la liste \"$listName\"';
  }

  @override
  String listDeleted(String listName) {
    return 'Liste \"$listName\" supprimée';
  }

  @override
  String get editItems => 'Modifier les articles';

  @override
  String get shareList => 'Partager la liste';

  @override
  String get deleteList => 'Supprimer la liste';

  @override
  String get readOnlyShort => 'Lecture';

  @override
  String get quantityShort => 'Qté';

  @override
  String get modification => 'Modification';

  @override
  String get consultation => 'Consultation';

  @override
  String get modifyThisList => 'modifier cette liste';

  @override
  String get modifyThisItem => 'modifier cet article';

  @override
  String get deleteThisItem => 'supprimer cet article';

  @override
  String get limited => 'Limitée';

  @override
  String cannotActionReadOnly(String action, String permission) {
    return 'Vous ne pouvez pas $action car cette liste est en mode lecture seule.\n\nVotre permission actuelle : $permission';
  }

  @override
  String cannotActionPermission(String action, String permission) {
    return 'Vous n\'avez pas la permission de $action.\n\nVotre permission actuelle : $permission';
  }

  @override
  String sharedByUser(String userName) {
    return 'Partagée par $userName';
  }

  @override
  String get deleteItemTitle => 'Supprimer l\'article';

  @override
  String deleteQuickConfirm(String itemName) {
    return 'Supprimer \"$itemName\" ?';
  }

  @override
  String get newItem => 'Nouvel Article';

  @override
  String get addNewItemToList =>
      'Ajoutez un nouvel article à votre liste d\'épicerie';

  @override
  String get productNameRequired => 'Nom du produit*';

  @override
  String get productNameRequiredMessage => 'Le nom du produit est obligatoire';

  @override
  String get productNameHint => 'Ex: Bananes, Pain, Lait...';

  @override
  String get priceCAD => 'Prix (\$CAD)';

  @override
  String get storeOptional => 'Magasin (optionnel)';

  @override
  String get storeHint => 'Ex: IGA, Metro, Provigo...';

  @override
  String get add => 'Ajouter';

  @override
  String get giveNameToNewList =>
      'Donnez un nom à votre nouvelle liste d\'épicerie';

  @override
  String get listName => 'Nom de la liste';

  @override
  String get listNameHint => 'Ex: Courses de la semaine';

  @override
  String get create => 'Créer';

  @override
  String get processingInProgress => 'Traitement en cours...';

  @override
  String get emailAddressRequired => 'Adresse email *';

  @override
  String get emailHint => 'votre@email.com';

  @override
  String get emailRequired => 'L\'email est requis';

  @override
  String get invalidEmailFormat => 'Format d\'email invalide';

  @override
  String get verificationCodeSent => 'Code de vérification envoyé !';

  @override
  String get checkEmailAndEnterCode =>
      'Vérifiez votre boîte email et entrez le code ci-dessous';

  @override
  String get verificationCodeRequired => 'Code de vérification *';

  @override
  String get sixDigitCodeHint => 'Code à 6 chiffres';

  @override
  String get codeRequired => 'Le code est requis';

  @override
  String get newPasswordRequired => 'Nouveau mot de passe *';

  @override
  String get minimumSixCharacters => 'Minimum 6 caractères';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordMinSixChars =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get retypePassword => 'Retapez le mot de passe';

  @override
  String get confirmationRequired => 'La confirmation est requise';

  @override
  String get changePasswordButton => 'Changer le mot de passe';

  @override
  String get verificationCodeSentCheckEmail =>
      'Code de vérification envoyé ! Vérifiez votre email.';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get attention => '⚠️ ATTENTION';

  @override
  String get actionDefinitiveIrreversible =>
      'Cette action est définitive et irréversible !';

  @override
  String get whatWillBeDeleted => 'Ce qui sera supprimé :';

  @override
  String get profileAndPersonalInfo =>
      '• Votre profil et informations personnelles';

  @override
  String get allPrivateGroceryLists =>
      '• Toutes vos listes d\'épicerie privées';

  @override
  String get preferencesAndSettings => '• Vos préférences et paramètres';

  @override
  String get purchaseHistory => '• Votre historique d\'achats';

  @override
  String get whatWillBePreserved => 'Ce qui sera préservé :';

  @override
  String get sharedListsAnonymized =>
      '• Les listes partagées avec d\'autres utilisateurs (anonymisées)';

  @override
  String get reasonOptional => 'Raison (optionnelle)';

  @override
  String get whyDeleteAccount => 'Pourquoi supprimez-vous votre compte ?';

  @override
  String get understandIrreversible =>
      'Je comprends que cette action est irréversible';

  @override
  String get allDataWillBeDeleted =>
      'Toutes mes données seront définitivement supprimées';

  @override
  String verificationCodeSentToEmail(String email) {
    return 'Un code de vérification a été envoyé à $email';
  }

  @override
  String get requestDeletion => 'Demander la suppression';

  @override
  String get confirmDeletionWithCode => 'Confirmer la suppression';

  @override
  String accountWillBeDeletedOn(String date) {
    return 'Votre compte sera supprimé le $date. Vous avez 30 jours pour annuler cette action.';
  }

  @override
  String get deleteListTitle => 'Supprimer la liste';

  @override
  String get sureToDeleteItem => 'Êtes-vous sûr de vouloir supprimer';

  @override
  String get sureToDeleteList => 'Êtes-vous sûr de vouloir supprimer la liste';

  @override
  String get actionIrreversible => 'Cette action est irréversible.';

  @override
  String get actionIrreversibleDeletesAllItems =>
      'Cette action est irréversible et supprimera tous les articles.';

  @override
  String get confirm => 'Confirmer';

  @override
  String sureToDeleteItemFromList(String itemName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$itemName\" de votre liste ?';
  }

  @override
  String get sureToLeaveQuestion => 'Êtes-vous sûr de vouloir quitter';

  @override
  String get modifyItemInformation =>
      'Modifiez les informations de votre article';

  @override
  String get save => 'Enregistrer';

  @override
  String get modify => 'Modifier';

  @override
  String get fromYourList => 'de votre liste';

  @override
  String get processing => 'Traitement en cours...';

  @override
  String get verificationCodeSentTitle => 'Code de vérification envoyé';

  @override
  String get enterCodeReceived => 'Entrez le code reçu';

  @override
  String get codeExpiresIn => 'Le code expire dans';

  @override
  String get hours => 'heures';

  @override
  String get checkEmailsAndSpam => 'Vérifiez vos emails et vos spams';

  @override
  String get areYouSure => 'Êtes-vous sûr';

  @override
  String get wantToDelete => 'de vouloir supprimer';

  @override
  String get wantToLeave => 'de vouloir quitter';

  @override
  String get thisAction => 'Cette action';

  @override
  String get isIrreversible => 'est irréversible';

  @override
  String get andWillDelete => 'et supprimera';

  @override
  String get allItems => 'tous les articles';

  @override
  String get codeIsRequired => 'Le code est requis';

  @override
  String get invalidCode => 'Code invalide';

  @override
  String get codeExpired => 'Code expiré';

  @override
  String get editListName => 'Modifier le nom';

  @override
  String get modifyListName => 'Modifiez le nom de votre liste d\'épicerie';

  @override
  String get modifyPersonalInformation =>
      'Modifiez vos informations personnelles';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès';

  @override
  String get emailCannotBeModified => 'L\'email ne peut pas être modifié';

  @override
  String get firstNameAndLastNameRequired =>
      'Le prénom et le nom sont obligatoires';

  @override
  String get confirmLogoutMessage =>
      'Voulez-vous vraiment vous déconnecter de votre compte ?';

  @override
  String get manageAccountSecurity => 'Gérez la sécurité de votre compte';

  @override
  String get changePasswordTitle => 'Changer le mot de passe';

  @override
  String get changePasswordDescription => 'Modifiez votre mot de passe actuel';

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountDescription =>
      'Supprimez définitivement votre compte';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get emailAddress => 'Adresse email';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get passwordMustBeSixCharacters =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get youWillReceiveVerificationCode =>
      'Vous recevrez un code de vérification à 6 chiffres';

  @override
  String get send => 'Envoyer';

  @override
  String get allFieldsRequired => 'Tous les champs sont obligatoires';

  @override
  String get emailFormatInvalid => 'Format d\'email invalide';

  @override
  String get confirmDeletionTitle => 'Confirmer la suppression';

  @override
  String get enterCodeToConfirm =>
      'Entrez le code reçu par email pour confirmer';

  @override
  String get actionIrreversibleAllDataDeleted =>
      'Cette action est irréversible. Toutes vos données seront supprimées.';

  @override
  String get reasonForDeletion => 'Raison de la suppression (optionnel)';

  @override
  String get codeSentCheckEmail => 'Code envoyé ! Vérifiez votre boîte email.';

  @override
  String get deletionCode => 'Code de suppression';

  @override
  String get actionDefinitiveAccountDeleted30Days =>
      'Cette action est définitive. Votre compte sera supprimé dans 30 jours.';

  @override
  String get accountDeletedIn30DaysCanCancel =>
      'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action pendant cette période.';

  @override
  String get accountDeletionCodeSent =>
      'Code de suppression envoyé ! Vérifiez votre email.';
}
