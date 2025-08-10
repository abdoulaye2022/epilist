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
  String get newList => 'Nouvelle';

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
      'Saisissez le code reçu par email et votre nouveau mot de passe';

  @override
  String get enterEmailForVerificationCode =>
      'Entrez votre email pour recevoir un code de vérification';

  @override
  String verificationCodeSentTo(Object email) {
    return 'Code de vérification envoyé à $email';
  }

  @override
  String get passwordChangedSuccessfully => 'Mot de passe changé avec succès !';

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
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

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
  String get codeExpiresInTwoHours =>
      'Le code expire dans 2 heures. Vérifiez vos emails et vos spams.';

  @override
  String get verificationCodeWillBeSent =>
      'Vous recevrez un code de vérification par email pour changer votre mot de passe.';

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
  String get total => 'total';

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
  String get quantity => 'Qté';

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

  @override
  String get listCreatedSuccessfully => 'Liste créée avec succès';

  @override
  String get listUpdatedSuccessfully => 'Liste modifiée avec succès';

  @override
  String get listDeletedSuccessfully => 'Liste supprimée avec succès';

  @override
  String get listDuplicatedSuccessfully => 'Liste dupliquée avec succès';

  @override
  String get listsLoadedSuccessfully => 'Listes chargées avec succès';

  @override
  String get operationSuccess => 'Opération réussie';

  @override
  String get listNotFound => 'Liste non trouvée';

  @override
  String get serverError => 'Erreur du serveur';

  @override
  String get itemAddedSuccessfully => 'Article ajouté avec succès';

  @override
  String get itemUpdatedSuccessfully => 'Article mis à jour avec succès';

  @override
  String get itemDeletedSuccessfully => 'Article supprimé avec succès';

  @override
  String get itemStatusUpdatedSuccessfully => 'Statut mis à jour avec succès';

  @override
  String get itemsLoadedSuccessfully => 'Articles chargés avec succès';

  @override
  String get errorLoadingItems => 'Erreur lors du chargement des articles';

  @override
  String get errorAddingItem => 'Erreur lors de l\'ajout de l\'article';

  @override
  String get errorUpdatingItem => 'Erreur lors de la mise à jour de l\'article';

  @override
  String get errorDeletingItem => 'Erreur lors de la suppression de l\'article';

  @override
  String get errorUpdatingStatus => 'Erreur lors de la mise à jour du statut';

  @override
  String get invitationReceived => 'Invitation reçue !';

  @override
  String get loginRequiredForInvitation =>
      'Connexion requise pour accéder à l\'invitation';

  @override
  String get invalidShareLink => 'Lien de partage invalide';

  @override
  String get errorOpeningInvitation =>
      'Erreur lors de l\'ouverture de l\'invitation';

  @override
  String get cannotOpenInvitation => 'Impossible d\'ouvrir l\'invitation';

  @override
  String get authSuccessNavigation =>
      'Authentification réussie, navigation vers l\'invitation';

  @override
  String get invitationEpiList => 'Invitation EpiList';

  @override
  String get invitationSubject =>
      'Invitation à partager une liste d\'épicerie - EpiList';

  @override
  String invitationMessage(String owner, String listName) {
    return '$owner vous invite sur \"$listName\"';
  }

  @override
  String get directLinkRecommended => 'Lien direct EpiList (recommandé)';

  @override
  String get orViaBrowser => 'Ou via navigateur';

  @override
  String get directLinkAutoOpen =>
      'Le lien direct ouvrira automatiquement l\'app !';

  @override
  String get clickToOpenEpiList => 'Cliquez pour ouvrir EpiList';

  @override
  String get appWillOpenAutomatically => 'L\'app s\'ouvrira automatiquement !';

  @override
  String get sharedListsLoadedSuccessfully =>
      'Listes partagées chargées avec succès';

  @override
  String get sharesLoadedSuccessfully => 'Partages chargés avec succès';

  @override
  String get invitationLoadedSuccessfully => 'Invitation chargée avec succès';

  @override
  String get invitationAcceptedSuccessfully =>
      'Invitation acceptée avec succès';

  @override
  String get invitationDeclinedSuccessfully => 'Invitation refusée avec succès';

  @override
  String get permissionsUpdatedSuccessfully =>
      'Permissions mises à jour avec succès';

  @override
  String get shareRevokedSuccessfully => 'Partage révoqué avec succès';

  @override
  String get leftSharedListSuccessfully => 'Vous avez quitté la liste partagée';

  @override
  String get allShareLinksRevokedSuccessfully =>
      'Tous les liens de partage ont été révoqués';

  @override
  String get errorLoadingSharedLists =>
      'Erreur lors du chargement des listes partagées';

  @override
  String get errorLoadingShares => 'Erreur lors du chargement des partages';

  @override
  String get errorCreatingShareLink =>
      'Erreur lors de la création du lien de partage';

  @override
  String get invalidOrExpiredInvitation => 'Invitation invalide ou expirée';

  @override
  String get errorAcceptingInvitation =>
      'Erreur lors de l\'acceptation de l\'invitation';

  @override
  String get errorDecliningInvitation =>
      'Erreur lors du refus de l\'invitation';

  @override
  String get errorUpdatingPermissions =>
      'Erreur lors de la mise à jour des permissions';

  @override
  String get errorRevokingShare => 'Erreur lors de la révocation du partage';

  @override
  String get errorLeavingList => 'Erreur lors de la sortie de la liste';

  @override
  String get errorRevokingLinks => 'Erreur lors de la révocation des liens';

  @override
  String get operationSuccessful => 'Opération réussie';

  @override
  String get anErrorOccurred => 'Une erreur est survenue';

  @override
  String get noInternetConnection => 'Aucune connexion Internet';

  @override
  String get noInternetMessage =>
      'Vous devez être connecté à Internet pour utiliser cette application. Veuillez vérifier votre connexion et réessayer.';

  @override
  String get connectionTips => 'Conseils :';

  @override
  String get checkWifiConnection => 'Vérifiez votre connexion Wi-Fi';

  @override
  String get checkMobileData => 'Activez vos données mobiles';

  @override
  String get restartRouter => 'Redémarrez votre routeur si nécessaire';

  @override
  String get offlineMode => 'Mode hors ligne - Connexion requise';

  @override
  String get backOnline => 'Connexion rétablie !';

  @override
  String get connectionRequired => 'Connexion Internet requise';

  @override
  String get connectionRequiredForInvitation =>
      'Connexion Internet requise pour ouvrir l\'invitation';

  @override
  String get productSuggestions => 'Suggestions de produits';

  @override
  String get noSuggestionsFound => 'Aucune suggestion trouvée';

  @override
  String get searchingSuggestions => 'Recherche de suggestions...';

  @override
  String get usedOnce => 'Utilisé 1 fois';

  @override
  String usedXTimes(int count) {
    return 'Utilisé $count fois';
  }

  @override
  String weeksAgo(int weeks, String plural) {
    return 'Il y a $weeks semaine$plural';
  }

  @override
  String monthsAgo(int months, Object plural) {
    return 'Il y a $months mois';
  }

  @override
  String suggestionWithDate(String usage, String date) {
    return '$usage • $date';
  }

  @override
  String get suggestionSelected => 'Suggestion sélectionnée';

  @override
  String get clearSuggestion => 'Effacer la suggestion';

  @override
  String get popularSuggestions => 'Suggestions populaires';

  @override
  String get recentSuggestions => 'Suggestions récentes';

  @override
  String get manageSuggestions => 'Gérer les suggestions';

  @override
  String get deleteSuggestion => 'Supprimer la suggestion';

  @override
  String get deleteSuggestionConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette suggestion ?';

  @override
  String get clearAllSuggestions => 'Supprimer toutes les suggestions';

  @override
  String get clearAllSuggestionsConfirm =>
      'Êtes-vous sûr de vouloir supprimer toutes vos suggestions ? Cette action est irréversible.';

  @override
  String get suggestionsCleared => 'Toutes les suggestions ont été supprimées';

  @override
  String get errorLoadingSuggestions =>
      'Erreur lors du chargement des suggestions';

  @override
  String get errorSavingSuggestion =>
      'Erreur lors de la sauvegarde de la suggestion';

  @override
  String get suggestionSaved => 'Suggestion sauvegardée';

  @override
  String get noSuggestionsYet => 'Aucune suggestion pour le moment';

  @override
  String get startTypingForSuggestions =>
      'Commencez à taper pour voir vos suggestions';

  @override
  String get basedOnHistory => 'Basé sur votre historique';

  @override
  String get autoComplete => 'Saisie automatique';

  @override
  String get suggestionHelper => 'Vos produits fréquents apparaîtront ici';

  @override
  String get lastUsed => 'Dernière utilisation';

  @override
  String get suggestionDeleted => 'Suggestion supprimée';

  @override
  String get totalSuggestions => 'Total des suggestions';

  @override
  String get mostUsedSuggestion => 'Suggestion la plus utilisée';

  @override
  String get recentlyAdded => 'Récemment ajouté';

  @override
  String get neverUsed => 'Jamais utilisé';

  @override
  String get usageStatistics => 'Statistiques d\'utilisation';

  @override
  String get averageUsage => 'Utilisation moyenne';

  @override
  String get oldestSuggestion => 'Suggestion la plus ancienne';

  @override
  String get newestSuggestion => 'Suggestion la plus récente';

  @override
  String get exportSuggestions => 'Exporter les suggestions';

  @override
  String get importSuggestions => 'Importer les suggestions';

  @override
  String get suggestionSettings => 'Paramètres des suggestions';

  @override
  String get enableAutoSuggestions => 'Activer les suggestions automatiques';

  @override
  String get suggestionThreshold => 'Seuil de suggestions';

  @override
  String get maxSuggestions => 'Nombre maximum de suggestions';

  @override
  String get clearOldSuggestions => 'Nettoyer les anciennes suggestions';

  @override
  String get suggestionsOlderThan => 'Suggestions plus anciennes que';

  @override
  String get oneMonth => '1 mois';

  @override
  String get threeMonths => '3 mois';

  @override
  String get sixMonths => '6 mois';

  @override
  String get oneYear => '1 an';

  @override
  String get cleanupCompleted => 'Nettoyage terminé';

  @override
  String get suggestionsOptimized => 'Suggestions optimisées';

  @override
  String get backupSuggestions => 'Sauvegarder les suggestions';

  @override
  String get restoreSuggestions => 'Restaurer les suggestions';

  @override
  String get suggestionBackupCreated => 'Sauvegarde créée avec succès';

  @override
  String get suggestionBackupRestored => 'Suggestions restaurées avec succès';

  @override
  String get noBackupFound => 'Aucune sauvegarde trouvée';

  @override
  String get suggestionTips => 'Conseils pour les suggestions';

  @override
  String get tipMoreUsage =>
      'Plus vous utilisez l\'app, meilleures sont les suggestions';

  @override
  String get tipRegularUpdates =>
      'Les suggestions se mettent à jour automatiquement';

  @override
  String get tipPersonalized =>
      'Vos suggestions sont uniques et personnalisées';

  @override
  String priceFormat(String price) {
    return '$price \$CAD';
  }

  @override
  String get noStoreSpecified => 'Aucun magasin spécifié';

  @override
  String get noPriceSet => 'Prix non défini';

  @override
  String suggestionDescription(
    String name,
    String usage,
    String price,
    String store,
  ) {
    return '$name - $usage - $price - $store';
  }

  @override
  String get similarItemDetected => 'Article similaire détecté';

  @override
  String get itemToAdd => 'Article à ajouter';

  @override
  String get product => 'Produit';

  @override
  String get store => 'Magasin';

  @override
  String get similarItemsFound => 'Articles similaires trouvés';

  @override
  String get identical => 'Identique';

  @override
  String get similar => 'Similaire';

  @override
  String get mergeWithExisting => 'Fusionner avec l\'existant';

  @override
  String get addAnyway => 'Ajouter quand même';

  @override
  String get duplicateDetectedMessage =>
      'Nous avons trouvé des articles similaires dans votre liste.';

  @override
  String get noSearchResults => 'Aucun résultat trouvé';

  @override
  String get tryDifferentKeywords => 'Essayez avec d\'autres mots-clés';

  @override
  String get suggestionsWillAppearAfterShopping =>
      'Les suggestions apparaîtront après vos achats';

  @override
  String get startShopping => 'Commencer mes achats';

  @override
  String get searchTips =>
      'Essayez des termes plus généraux ou vérifiez l\'orthographe';

  @override
  String get suggestionsBasedOnUsage =>
      'Les suggestions se basent sur vos habitudes d\'achat';

  @override
  String get scheduleReminder => 'Programmer un rappel';

  @override
  String get remindIn2Hours => 'Rappel dans 2h';

  @override
  String get remindTomorrow => 'Rappel demain';

  @override
  String get viewReminders => 'Voir les rappels';

  @override
  String get cancelReminders => 'Annuler les rappels';

  @override
  String get scheduledReminders => 'Rappels programmés';

  @override
  String get noRemindersScheduled => 'Aucun rappel programmé';

  @override
  String get reminderScheduled => 'Rappel programmé avec succès';

  @override
  String get reminderScheduledFor => 'Rappel programmé pour';

  @override
  String get reminderCancelled => 'Rappel annulé';

  @override
  String get allRemindersCancelled => 'Tous les rappels annulés';

  @override
  String get errorSchedulingReminder =>
      'Erreur lors de la programmation du rappel';

  @override
  String get errorLoadingReminders => 'Erreur lors du chargement des rappels';

  @override
  String get errorCancellingReminder =>
      'Erreur lors de l\'annulation du rappel';

  @override
  String get errorCancellingReminders =>
      'Erreur lors de l\'annulation des rappels';

  @override
  String get cancelAllReminders => 'Annuler tous les rappels';

  @override
  String get cancelAllRemindersConfirm =>
      'Voulez-vous vraiment annuler tous les rappels pour cette liste ?';

  @override
  String get cancelAll => 'Tout annuler';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get quickOptions => 'Options rapides';

  @override
  String get customDateTime => 'Date et heure personnalisées';

  @override
  String get storeName => 'Nom du magasin';

  @override
  String get storeNameHint => 'Ex: Provigo, IGA, Metro...';

  @override
  String get customMessage => 'Message personnalisé';

  @override
  String get customMessageHint => 'Message personnalisé pour le rappel';

  @override
  String get selectDateTime => 'Sélectionner date et heure';

  @override
  String get in2Hours => 'Dans 2h';

  @override
  String get tomorrow => 'Demain';

  @override
  String get thisWeekend => 'Ce weekend';

  @override
  String get allOfAbove => 'Tous les ci-dessus';

  @override
  String inHours(int hours) {
    return 'Dans $hours heures';
  }

  @override
  String showingXOfY(int x, int y) {
    return 'Affichage de $x sur $y listes';
  }

  @override
  String get optionalFields => 'Champs optionnels';

  @override
  String get aboutMission => 'Notre Mission';

  @override
  String get aboutMissionText =>
      'EpiList révolutionne la façon dont vous gérez vos courses. Créez des listes intelligentes, suivez vos dépenses en temps réel, partagez avec votre famille et ne manquez plus jamais un article important grâce à notre système de gestion collaborative.';

  @override
  String get aboutFeatures => 'Fonctionnalités principales';

  @override
  String get aboutFeaturesText =>
      '• Création de compte sécurisée (prénom, nom, email)\n• Listes d\'épicerie personnalisées et intelligentes\n• Ajout d\'articles avec quantité, prix et magasin\n• Calcul automatique des totaux et pourcentages\n• Marquage en temps réel des articles achetés\n• Duplication rapide des listes existantes\n• Partage sécurisé via liens avec permissions\n• Gestion des droits (lecture, édition, administration)\n• Synchronisation sur tous vos appareils\n• Interface moderne et intuitive';

  @override
  String get aboutCollaboration => 'Collaboration familiale';

  @override
  String get aboutCollaborationText =>
      'EpiList facilite les courses en famille avec son système de partage avancé. Partagez vos listes d\'un simple lien, définissez qui peut voir, modifier ou administrer chaque liste. Tout le monde reste synchronisé en temps réel!';

  @override
  String get aboutDevelopment => 'Développement';

  @override
  String get aboutDevelopmentText =>
      'EpiList est développé avec passion par M2atech Solutions Inc. pour vous offrir la meilleure expérience de gestion d\'épicerie. Nous sommes constamment à l\'écoute de vos retours pour améliorer l\'app et ajouter de nouvelles fonctionnalités innovantes.';

  @override
  String get aboutContact => 'Nous contacter';

  @override
  String get aboutRateApp => 'Évaluer l\'app';

  @override
  String get aboutShareApp => 'Partager EpiList';

  @override
  String get aboutWebsite => 'Site web';

  @override
  String get aboutRightsReserved => 'Tous droits réservés.';

  @override
  String get aboutDevelopedWith => 'Développé avec';

  @override
  String get aboutByCompany => 'par M2atech Solutions Inc.';

  @override
  String get aboutContactError => 'Impossible d\'ouvrir le lien de contact';

  @override
  String get aboutWebsiteError => 'Impossible d\'ouvrir le site web';

  @override
  String get aboutStoreUnavailable =>
      'Magasin indisponible. Évaluez EpiList sur votre magasin habituel!';

  @override
  String get aboutStoreError =>
      'Impossible d\'ouvrir le magasin pour le moment';

  @override
  String get aboutShareDescription =>
      'Organisez vos courses en famille avec EpiList! Listes partagées, calculs automatiques, synchronisation temps réel.';

  @override
  String get aboutDiscoverApp => 'Découvrez l\'app';

  @override
  String get aboutShareSubject =>
      'Découvrez EpiList - Votre assistant épicerie familial!';

  @override
  String get aboutShareError => 'Impossible de partager pour le moment';

  @override
  String get termsLastUpdated => 'Dernière mise à jour : 5 juillet 2025';

  @override
  String get termsAcceptanceTitle => '1. Acceptation des conditions';

  @override
  String get termsAcceptanceText =>
      'En utilisant l\'application EpiList, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions dans leur intégralité, veuillez ne pas utiliser l\'application.';

  @override
  String get termsServiceTitle => '2. Description du service';

  @override
  String get termsServiceText =>
      'EpiList est une application mobile de gestion de listes d\'épicerie qui permet :\n\n• Créer un compte avec prénom, nom, email et mot de passe\n• Créer, modifier et supprimer des listes d\'épicerie\n• Ajouter des articles avec nom, quantité, prix et magasin (optionnel)\n• Marquer les articles comme achetés ou les supprimer\n• Calculer automatiquement les totaux et pourcentages d\'achats\n• Dupliquer les listes existantes\n• Partager les listes avec des liens sécurisés\n• Gérer les permissions d\'accès (lecture, édition, administration)\n\nLe service est fourni \"en l\'état\" et \"selon disponibilité\".';

  @override
  String get termsAccountTitle => '3. Compte utilisateur et sécurité';

  @override
  String get termsAccountText =>
      'Pour utiliser EpiList, vous devez :\n\n• Créer un compte avec des informations exactes (prénom, nom, email)\n• Choisir un mot de passe sécurisé et le garder confidentiel\n• Être responsable de toutes les activités effectuées sous votre compte\n• Nous notifier immédiatement de toute utilisation non autorisée\n• Mettre à jour vos informations personnelles si nécessaire\n\nVous êtes seul responsable de la sécurité de vos identifiants de connexion.';

  @override
  String get termsUsageTitle => '4. Utilisation des listes et partage';

  @override
  String get termsUsageText =>
      'Concernant l\'utilisation des fonctionnalités de l\'application :\n\n• Vous pouvez créer des listes d\'épicerie illimitées\n• Les liens de partage sont de votre responsabilité\n• Vous contrôlez les permissions d\'accès que vous accordez\n• Les personnes invitées doivent respecter les permissions définies\n• Vous pouvez révoquer l\'accès à tout moment\n• Le contenu partagé doit rester approprié et légal\n\nVous êtes responsable de la gestion de vos listes partagées.';

  @override
  String get termsAcceptableTitle => '5. Utilisation acceptable';

  @override
  String get termsAcceptableText =>
      'Vous acceptez de :\n\n• Utiliser l\'application uniquement pour la gestion de listes d\'épicerie\n• Ne pas tenter de perturber le fonctionnement du service\n• Ne pas accéder illégalement aux données d\'autres utilisateurs\n• Respecter les droits de propriété intellectuelle\n• Ne pas utiliser l\'application à des fins commerciales sans autorisation\n• Ne pas partager de contenu offensant ou illégal\n\nToute utilisation abusive peut entraîner une suspension immédiate du compte.';

  @override
  String get termsOwnershipTitle => '6. Propriété du contenu';

  @override
  String get termsOwnershipText =>
      'Concernant le contenu que vous créez dans EpiList :\n\n• Vous conservez la propriété de vos listes et données personnelles\n• Vous nous accordez une licence limitée pour fournir le service\n• Vous êtes responsable de l\'exactitude de vos informations\n• Nous ne revendiquons aucun droit sur vos données personnelles\n• Vous pouvez exporter vos données à tout moment\n\nVos données vous appartiennent et restent sous votre contrôle.';

  @override
  String get termsCalculationsTitle => '7. Calculs et prix';

  @override
  String get termsCalculationsText =>
      'Concernant les fonctionnalités de calcul :\n\n• Les totaux et pourcentages sont calculés automatiquement\n• Nous ne garantissons pas l\'exactitude absolue des calculs\n• Les prix saisis sont de votre responsabilité\n• Vérifiez toujours les calculs pour vos achats importants\n• Nous ne sommes pas responsables des erreurs de prix\n\nUtilisez les calculs comme aide, pas comme référence absolue.';

  @override
  String get termsAvailabilityTitle => '8. Disponibilité du service';

  @override
  String get termsAvailabilityText =>
      'Nous nous efforçons d\'assurer une disponibilité continue du service, mais nous ne garantissons pas :\n\n• Un accès ininterrompu 24h/24\n• L\'absence complète de bugs ou d\'erreurs\n• La compatibilité avec tous les appareils\n• La sauvegarde permanente de toutes les données\n\nDes maintenances programmées peuvent causer des interruptions temporaires.';

  @override
  String get termsLiabilityTitle => '9. Limitation de responsabilité';

  @override
  String get termsLiabilityText =>
      'EpiList et ses développeurs ne peuvent être tenus responsables de :\n\n• Dommages indirects ou consécutifs\n• Perte de données due à des problèmes techniques\n• Erreurs dans les calculs de prix ou totaux\n• Utilisation incorrecte des informations fournies\n• Problèmes liés au partage de listes\n• Achats effectués basés sur les listes créées\n\nVotre utilisation de l\'application se fait à vos propres risques.';

  @override
  String get termsTerminationTitle => '10. Suspension et résiliation';

  @override
  String get termsTerminationText =>
      'Nous nous réservons le droit de suspendre ou résilier votre accès :\n\n• En cas de violation de ces conditions d\'utilisation\n• Pour des raisons de sécurité ou de maintenance\n• Si le compte est inactif depuis plus de 24 mois\n• En cas d\'utilisation abusive des fonctionnalités de partage\n\nVous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.';

  @override
  String get termsModificationsTitle => '11. Modifications';

  @override
  String get termsModificationsText =>
      'Nous nous réservons le droit de :\n\n• Modifier ou améliorer les fonctionnalités de l\'application\n• Mettre à jour ces conditions d\'utilisation\n• Suspendre temporairement le service pour maintenance\n• Discontinuer définitivement le service avec préavis de 60 jours\n\nLes changements importants vous seront notifiés par email ou dans l\'application.';

  @override
  String get termsJurisdictionTitle => '12. Loi applicable et juridiction';

  @override
  String get termsJurisdictionText =>
      'Ces conditions d\'utilisation sont régies par la loi canadienne. Tout litige relatif à l\'utilisation d\'EpiList sera soumis à la juridiction des tribunaux compétents du Nouveau-Brunswick, Canada.';

  @override
  String get termsContactTitle => '13. Contact et support';

  @override
  String get termsContactText =>
      'Pour toute question concernant ces conditions d\'utilisation ou pour de l\'assistance, veuillez nous contacter via notre site web.\n\nNous nous engageons à répondre le plus rapidement possible.';

  @override
  String get privacyLastUpdated => 'Dernière mise à jour : 5 juillet 2025';

  @override
  String get privacyCollectionTitle => '1. Collecte d\'informations';

  @override
  String get privacyCollectionText =>
      'EpiList collecte les informations suivantes pour son fonctionnement :\n\n• Informations de compte : prénom, nom, email, mot de passe (chiffré)\n• Données de listes d\'épicerie : noms de listes, articles, quantités, prix, magasins (optionnel)\n• Données de partage : liens de partage, permissions d\'accès (lecture, édition, administration)\n• Données d\'utilisation : statut d\'achat des articles, totaux et calculs de pourcentages\n• Données techniques : journaux d\'erreurs, performance de l\'application\n\nNous ne collectons aucune information personnelle sensible au-delà de ce qui est nécessaire au fonctionnement.';

  @override
  String get privacyUsageTitle => '2. Utilisation des données';

  @override
  String get privacyUsageText =>
      'Vos données sont utilisées exclusivement pour :\n\n• Créer et gérer votre compte utilisateur\n• Créer, modifier et supprimer vos listes d\'épicerie\n• Calculer les totaux et pourcentages d\'articles achetés\n• Dupliquer vos listes existantes\n• Partager vos listes avec des membres de la famille ou amis via des liens sécurisés\n• Gérer les permissions d\'accès (lecture, édition, administration)\n• Synchroniser vos données sur tous vos appareils\n• Fournir un support technique\n\nNous ne vendons ni ne louons vos données personnelles à des tiers.';

  @override
  String get privacyStorageTitle => '3. Stockage et sécurité';

  @override
  String get privacyStorageText =>
      'Vos données sont protégées par :\n\n• Stockage sécurisé sur nos serveurs avec chiffrement\n• Chiffrement des mots de passe avec des algorithmes sécurisés\n• Protection des données en transit et au repos\n• Liens de partage sécurisés avec contrôle d\'accès\n• Sauvegarde régulière de vos listes et données\n• Mesures de sécurité conformes aux standards de l\'industrie\n\nNous appliquons les meilleures pratiques de sécurité pour protéger vos informations.';

  @override
  String get privacySharingTitle => '4. Partage des données';

  @override
  String get privacySharingText =>
      'Vos données personnelles ne sont partagées que dans les cas suivants :\n\n• Avec les personnes que vous autorisez via les liens de partage de listes\n• Avec nos prestataires de services techniques (hébergement, support)\n• Avec les autorités légales si requis par la loi\n\nLe partage de listes se fait selon les permissions que vous définissez :\n• Lecture seule : consultation des listes sans modification\n• Édition : ajout, suppression et modification d\'articles\n• Administration : gestion complète incluant suppression de listes\n\nAucun partage commercial de vos données n\'est effectué.';

  @override
  String get privacyRightsTitle => '5. Vos droits';

  @override
  String get privacyRightsText =>
      'Vous avez le droit de :\n\n• Accéder à toutes vos données personnelles\n• Modifier vos informations de compte (prénom, nom, email)\n• Supprimer votre compte et toutes les données associées\n• Exporter vos listes d\'épicerie\n• Révoquer les liens de partage à tout moment\n• Modifier les permissions d\'accès pour les utilisateurs invités\n• Supprimer vos listes ou articles individuellement\n\nContactez-nous pour exercer ces droits.';

  @override
  String get privacyFeaturesTitle => '6. Fonctionnalités de l\'application';

  @override
  String get privacyFeaturesText =>
      'EpiList traite vos données pour offrir les fonctionnalités suivantes :\n\n• Création et gestion de comptes utilisateurs\n• Création, duplication, modification et suppression de listes\n• Ajout d\'articles avec nom, quantité, prix et magasin (optionnel)\n• Marquage d\'articles comme achetés ou suppression d\'articles\n• Calcul automatique des totaux et pourcentages d\'achats\n• Génération de liens de partage sécurisés\n• Gestion des permissions d\'accès collaboratif\n\nToutes ces données restent sous votre contrôle.';

  @override
  String get privacyCookiesTitle => '7. Cookies et technologies similaires';

  @override
  String get privacyCookiesText =>
      'EpiList utilise des technologies de suivi pour :\n\n• Maintenir votre session active\n• Mémoriser vos préférences d\'utilisation\n• Analyser l\'usage de l\'application (données anonymes)\n• Optimiser les performances de l\'application\n\nVous pouvez désactiver ces fonctions dans les paramètres de l\'application.';

  @override
  String get privacyChangesTitle => '8. Modifications';

  @override
  String get privacyChangesText =>
      'Cette politique peut être mise à jour pour refléter les évolutions de l\'application. Nous vous informerons des changements importants par :\n\n• Email à l\'adresse associée à votre compte\n• Mise à jour de la date en haut de cette politique\n\nVotre utilisation continue de l\'application après les changements constitue votre acceptation.';

  @override
  String get privacyContactTitle => '9. Contact';

  @override
  String get privacyContactText =>
      'Pour toute question concernant cette politique de confidentialité ou vos données, veuillez nous contacter via notre site web.\n\nNous nous engageons à répondre dans les 48 heures ouvrables.';

  @override
  String get currency => 'Devise';

  @override
  String get currencies => 'Devises';

  @override
  String get selectCurrency => 'Sélectionner la devise';

  @override
  String get changeCurrency => 'Changer la devise';

  @override
  String get currencySettings => 'Paramètres de devise';

  @override
  String get currencyCode => 'Code de devise';

  @override
  String get currencySymbol => 'Symbole de devise';

  @override
  String get exchangeRate => 'Taux de change';

  @override
  String get defaultCurrency => 'Devise par défaut';

  @override
  String get preferredCurrency => 'Devise préférée';

  @override
  String get currentCurrency => 'Devise actuelle';

  @override
  String get noCurrencySet => 'Aucune devise définie';

  @override
  String get chooseCurrencyDescription =>
      'Choisissez votre devise préférée pour les prix';

  @override
  String get manageCurrencyDescription => 'Gérez vos préférences de devise';

  @override
  String get currencyConversionInfo =>
      'Les prix seront automatiquement convertis dans votre devise';

  @override
  String get showPopularOnly => 'Afficher seulement les devises populaires';

  @override
  String get convertPrices => 'Convertir les prix';

  @override
  String get viewInLocalCurrency => 'Voir en devise locale';

  @override
  String get formatUserAmount => 'Formater le montant';

  @override
  String get updateCurrency => 'Mettre à jour la devise';

  @override
  String get select => 'Sélectionner';

  @override
  String get each => 'chacun';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get totalPrice => 'Prix total';

  @override
  String get formattedPrice => 'Prix formaté';

  @override
  String get originalAmount => 'Montant original';

  @override
  String get convertedAmount => 'Montant converti';

  @override
  String get exchangeRateToCAD => 'Taux de change vers CAD';

  @override
  String get popularCurrencies => 'Devises populaires';

  @override
  String get allCurrencies => 'Toutes les devises';

  @override
  String get supportedCurrencies => 'Devises supportées';

  @override
  String get currencyNotFound => 'Devise non trouvée';

  @override
  String get invalidCurrency => 'Devise invalide';

  @override
  String get currencyUpdateFailed => 'Échec de la mise à jour de la devise';

  @override
  String get conversionFailed => 'Échec de la conversion de devise';

  @override
  String get exchangeRateNotAvailable => 'Taux de change non disponible';

  @override
  String get currencyUpdatedSuccessfully => 'Devise mise à jour avec succès';

  @override
  String get currencySelectedSuccessfully => 'Devise sélectionnée avec succès';

  @override
  String get conversionSuccessful => 'Conversion réussie';

  @override
  String get currencyInfo => 'Informations de devise';

  @override
  String get rateLastUpdated => 'Taux mis à jour le';

  @override
  String get basedOnCAD => 'Basé sur le Dollar Canadien (CAD)';

  @override
  String get exchangeRateDisclaimer =>
      'Les taux de change sont donnés à titre indicatif';

  @override
  String priceInCurrency(String currency) {
    return 'Prix en $currency';
  }

  @override
  String amountInCurrency(String currency) {
    return 'Montant en $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Convertir en $currency';
  }

  @override
  String oneXEqualsYCAD(String currency, String rate) {
    return '1 $currency = $rate CAD';
  }

  @override
  String get price => 'Prix';

  @override
  String get currencySelectionDialog => 'Dialogue de sélection de devise';

  @override
  String get chooseCurrencyPreference =>
      'Choisissez votre préférence de devise';

  @override
  String get currencyDisplayOnly => 'Affichage uniquement';

  @override
  String get pricesNotConverted =>
      'Les prix ne sont pas convertis automatiquement';

  @override
  String get currentSelectedCurrency => 'Devise actuellement sélectionnée';

  @override
  String get loadingCurrencies => 'Chargement des devises disponibles...';

  @override
  String get noCurrenciesAvailable => 'Aucune devise disponible pour le moment';

  @override
  String get cannotLoadCurrencies =>
      'Impossible de charger la liste des devises';

  @override
  String get currencyUpdated => 'Votre devise a été mise à jour avec succès';

  @override
  String get confirmCurrencyChange => 'Confirmer le changement de devise';

  @override
  String get currencySettingsTile => 'Paramètres de devise';

  @override
  String get manageCurrencySettings => 'Gérer les paramètres de devise';

  @override
  String get defaultCurrencyCAD => 'CAD (par défaut)';

  @override
  String get selectPreferredCurrency => 'Sélectionner la devise préférée';

  @override
  String get currencySettingsUpdated => 'Paramètres de devise mis à jour';

  @override
  String get selectYourCurrency => 'Sélectionnez votre devise';

  @override
  String get chooseDisplayCurrency => 'Choisissez votre devise d\'affichage';

  @override
  String get currencyForPrices =>
      'Cette devise sera utilisée pour afficher les prix';

  @override
  String get noCurrencySelected => 'Aucune devise sélectionnée';

  @override
  String get popularCurrenciesOnly => 'Devises populaires uniquement';

  @override
  String get allAvailableCurrencies => 'Toutes les devises disponibles';

  @override
  String get currencySelectionComplete => 'Sélection de devise terminée';

  @override
  String get applyChanges => 'Appliquer les modifications';

  @override
  String get discardChanges => 'Annuler les modifications';

  @override
  String get popular => 'Populaire';

  @override
  String get analytics => 'Analyses';

  @override
  String get overview => 'Vue d\'ensemble';

  @override
  String get trends => 'Tendances';

  @override
  String get categories => 'Catégories';

  @override
  String get topProducts => 'Top produits';

  @override
  String get userCurrency => 'Ma devise';

  @override
  String get noAnalyticsData => 'Aucune donnée d\'analyse disponible';

  @override
  String get loadData => 'Charger les données';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get monthlyOverview => 'Vue d\'ensemble mensuelle';

  @override
  String get totalSpent => 'Total dépensé';

  @override
  String get itemsPurchased => 'Articles achetés';

  @override
  String get uniqueProducts => 'Produits uniques';

  @override
  String get shoppingSessions => 'Sessions d\'achat';

  @override
  String get quickStats => 'Statistiques rapides';

  @override
  String get averageDailySpending => 'Dépense quotidienne moyenne';

  @override
  String get busiestDay => 'Jour le plus actif';

  @override
  String get comparisonWithLastMonth => 'Comparaison avec le mois dernier';

  @override
  String get spendingIncreased => 'Dépenses augmentées';

  @override
  String get spendingDecreased => 'Dépenses diminuées';

  @override
  String get spendingStable => 'Dépenses stables';

  @override
  String get spendingByCategory => 'Dépenses par catégorie';

  @override
  String get noCategoriesData => 'Aucune donnée de catégorie';

  @override
  String get monthlyTrends => 'Tendances mensuelles';

  @override
  String get monthlyAverage => 'Moyenne mensuelle';

  @override
  String get totalProducts => 'Total produits';

  @override
  String get showing => 'Affichage';

  @override
  String get noProductsData => 'Aucune donnée de produit';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get viewSpendingReports => 'Voir les rapports de dépenses';

  @override
  String get manageAllLists => 'Gérer toutes les listes';

  @override
  String recentLists(Object count) {
    return 'Listes récentes ($count)';
  }

  @override
  String get items => 'articles';

  @override
  String get done => 'fini';

  @override
  String get shared => 'Partagée';

  @override
  String get sharedWithYou => 'Partagée avec vous';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortByAmount => 'Trier par montant';

  @override
  String get sortByQuantity => 'Par quantité';

  @override
  String get sortByFrequency => 'Par fréquence';

  @override
  String get unknownProduct => 'Produit inconnu';

  @override
  String get itemsCount => 'articles';

  @override
  String get storesLabel => 'Magasins';

  @override
  String get averagePrice => 'Prix moyen';

  @override
  String get stores => 'Magasins';

  @override
  String get averagePriceLabel => 'Prix moyen';

  @override
  String get amountSort => 'Montant';

  @override
  String get quantitySort => 'Quantité';

  @override
  String get frequencySort => 'Fréquence';

  @override
  String get loadingAnalytics => 'Chargement des analyses...';

  @override
  String get errorLoadingAnalytics => 'Erreur lors du chargement des analyses';

  @override
  String get analyticsUnavailable => 'Analyses indisponibles';

  @override
  String get refreshAnalytics => 'Actualiser les analyses';

  @override
  String get rank => 'Rang';

  @override
  String get ranking => 'Classement';

  @override
  String get position => 'Position';

  @override
  String get topRanked => 'Mieux classé';

  @override
  String get mostPurchased => 'Plus acheté';

  @override
  String get frequentlyBought => 'Fréquemment acheté';

  @override
  String get times => 'fois';

  @override
  String get timesSingular => 'fois';

  @override
  String get timesPlural => 'fois';

  @override
  String get purchases => 'achats';

  @override
  String get purchase => 'achat';

  @override
  String get analyticsError => 'Erreur d\'analyse';

  @override
  String get noAnalyticsAvailable => 'Aucune analyse disponible';

  @override
  String get analyticsLoading => 'Chargement en cours...';

  @override
  String get dataNotAvailable => 'Données non disponibles';

  @override
  String get selectPeriod => 'Sélectionner la période';

  @override
  String get changePeriod => 'Changer la période';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String get period => 'Période';

  @override
  String get timeframe => 'Période';

  @override
  String get chooseCurrency => 'Choisir la devise';

  @override
  String get displayCurrency => 'Devise d\'affichage';

  @override
  String get currencyFormat => 'Format de devise';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get expandChart => 'Développer le graphique';

  @override
  String get collapseChart => 'Réduire le graphique';

  @override
  String get statistics => 'Statistiques';

  @override
  String get dataRange => 'Plage de données';

  @override
  String get noDataFound => 'Aucune donnée trouvée';

  @override
  String get insufficientData => 'Données insuffisantes';

  @override
  String get calculatingData => 'Calcul des données...';

  @override
  String get networkErrorAnalytics =>
      'Erreur réseau lors du chargement des analyses';

  @override
  String get serverErrorAnalytics => 'Erreur serveur pour les analyses';

  @override
  String get timeoutErrorAnalytics =>
      'Délai d\'attente dépassé pour les analyses';

  @override
  String get noSpendingRecorded => 'Aucune dépense enregistrée';

  @override
  String get dailyTrends => 'Tendances quotidiennes';

  @override
  String get weeklyTrends => 'Tendances hebdomadaires';

  @override
  String get yearlyTrends => 'Tendances annuelles';

  @override
  String get day => 'jour';

  @override
  String get week => 'Semaine';

  @override
  String get month => 'Mois';

  @override
  String get year => 'Année';

  @override
  String get dailyAverage => 'Moyenne/jour';

  @override
  String get weeklyAverage => 'Moyenne/semaine';

  @override
  String get yearlyAverage => 'Moyenne/année';

  @override
  String get choosePeriod => 'Choisir la période';

  @override
  String get updateChart => 'Mettre à jour le graphique';

  @override
  String get refreshChart => 'Actualiser le graphique';

  @override
  String get chartData => 'Données du graphique';

  @override
  String get barChart => 'Graphique en barres';

  @override
  String get lineChart => 'Graphique linéaire';

  @override
  String get noChartData => 'Pas de données pour le graphique';

  @override
  String get loadingChart => 'Chargement du graphique...';

  @override
  String get summaryData => 'Données de résumé';

  @override
  String get periodSummary => 'Résumé de la période';

  @override
  String get averageSpending => 'Dépense moyenne';

  @override
  String get totalForPeriod => 'Total pour la période';

  @override
  String get previousPeriod => 'Période précédente';

  @override
  String get nextPeriod => 'Période suivante';

  @override
  String get currentPeriod => 'Période actuelle';

  @override
  String get comparePeriods => 'Comparer les périodes';

  @override
  String get dataLoadingError => 'Erreur de chargement des données';

  @override
  String get chartError => 'Erreur du graphique';

  @override
  String get noDataForPeriod => 'Aucune donnée pour cette période';

  @override
  String get selectDifferentPeriod => 'Sélectionnez une période différente';

  @override
  String weekNumber(int number) {
    return 'Semaine $number';
  }

  @override
  String weekLabel(int number) {
    return 'S$number';
  }

  @override
  String get receipts => 'Factures';

  @override
  String get allReceipts => 'Toutes';

  @override
  String get byStore => 'Par magasin';

  @override
  String get addReceipt => 'Ajouter une facture';

  @override
  String get editReceipt => 'Modifier la facture';

  @override
  String get deleteReceipt => 'Supprimer la facture';

  @override
  String get deleteReceiptConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette facture ?';

  @override
  String get noReceipts => 'Aucune facture';

  @override
  String get addFirstReceipt =>
      'Ajoutez votre première facture pour suivre vos dépenses réelles';

  @override
  String get enterStoreName => 'Entrez le nom du magasin';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get enterAmount => 'Entrez le montant';

  @override
  String get purchaseDate => 'Date d\'achat';

  @override
  String get selectDate => 'Sélectionner la date';

  @override
  String get notes => 'Notes';

  @override
  String get optionalNotes => 'Notes optionnelles';

  @override
  String get storeNameRequired => 'Le nom du magasin est requis';

  @override
  String get storeNameTooShort => 'Le nom doit contenir au moins 2 caractères';

  @override
  String get amountRequired => 'Le montant est requis';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get amountMustBePositive => 'Le montant doit être positif';

  @override
  String get amountTooHigh => 'Montant trop élevé (max 999 999,99)';

  @override
  String get spendingSummary => 'Résumé des dépenses';

  @override
  String get totalExpensesSummary => 'Vue d\'ensemble de vos dépenses';

  @override
  String get totalFromReceipts => 'Total des factures';

  @override
  String get totalFromItems => 'Total des articles';

  @override
  String get bestEstimate => 'Meilleure estimation';

  @override
  String get dataComparison => 'Comparaison des données';

  @override
  String get receiptVsItemComparison => 'Factures vs prix des articles';

  @override
  String get dataQuality => 'Qualité des données';

  @override
  String get dataQualityExcellent => 'Excellente';

  @override
  String get dataQualityGood => 'Bonne';

  @override
  String get dataQualityFair => 'Correcte';

  @override
  String get dataQualityPoor => 'Faible';

  @override
  String get dataQualityUnknown => 'Inconnue';

  @override
  String get addReceiptsRecommendation =>
      'Ajoutez des factures pour des données plus précises';

  @override
  String get addItemPricesRecommendation =>
      'Ajoutez des prix aux articles pour plus de détails';

  @override
  String significantVarianceDetected(String percentage) {
    return 'Écart significatif détecté ($percentage%)';
  }

  @override
  String get lastVisit => 'Dernière visite';

  @override
  String get added => 'Ajouté';

  @override
  String get receiptAddedSuccessfully => 'Facture ajoutée avec succès';

  @override
  String get receiptUpdatedSuccessfully => 'Facture mise à jour avec succès';

  @override
  String get receiptDeletedSuccessfully => 'Facture supprimée avec succès';

  @override
  String get receiptsLoadedSuccessfully => 'Factures chargées avec succès';

  @override
  String get errorLoadingReceipts => 'Erreur lors du chargement des factures';

  @override
  String get errorAddingReceipt => 'Erreur lors de l\'ajout de la facture';

  @override
  String get errorUpdatingReceipt =>
      'Erreur lors de la mise à jour de la facture';

  @override
  String get errorDeletingReceipt =>
      'Erreur lors de la suppression de la facture';

  @override
  String get receiptValidationError => 'Données de facture invalides';

  @override
  String get storeNameInvalid => 'Nom de magasin invalide';

  @override
  String get amountTooLow => 'Montant trop faible';

  @override
  String get dateInFuture => 'La date ne peut pas être dans le futur';

  @override
  String get dateTooOld => 'La date ne peut pas être antérieure à 2 ans';

  @override
  String get notesTooLong => 'Notes trop longues (max 1000 caractères)';

  @override
  String get receiptDetails => 'Détails de la facture';

  @override
  String get receiptInformation => 'Informations de la facture';

  @override
  String get manageReceipts => 'Gérer les factures';

  @override
  String get viewReceipts => 'Voir les factures';

  @override
  String get receiptHistory => 'Historique des factures';

  @override
  String get totalReceipts => 'Total des factures';

  @override
  String get averageReceiptAmount => 'Montant moyen par facture';

  @override
  String get largestReceipt => 'Plus grande facture';

  @override
  String get smallestReceipt => 'Plus petite facture';

  @override
  String get mostFrequentStore => 'Magasin le plus fréquenté';

  @override
  String get comparisonResults => 'Résultats de comparaison';

  @override
  String get dataAccuracy => 'Précision des données';

  @override
  String get recommendationsTitle => 'Recommandations';

  @override
  String get improvementsNeeded => 'Améliorations nécessaires';

  @override
  String get wellDoneMessage => 'Bravo ! Vos données sont précises';

  @override
  String get addMoreReceiptsAdvice =>
      'Ajoutez plus de factures pour améliorer la précision';

  @override
  String get priceItemsAdvice =>
      'Ajoutez des prix à vos articles pour de meilleures estimations';

  @override
  String get loadingReceiptStats =>
      'Chargement des statistiques de factures...';

  @override
  String get noReceiptStats => 'Aucune statistique de facture disponible';

  @override
  String get receiptStatsUnavailable =>
      'Statistiques de factures indisponibles';

  @override
  String get refreshReceiptStats => 'Actualiser les statistiques';

  @override
  String get receiptOperationFailed => 'Opération de facture échouée';

  @override
  String get backToReceipts => 'Retour aux factures';

  @override
  String get addNewReceipt => 'Ajouter une nouvelle facture';

  @override
  String get editReceiptInfo => 'Modifier les informations de la facture';

  @override
  String get duplicateReceipt => 'Dupliquer la facture';

  @override
  String get shareReceipt => 'Partager la facture';

  @override
  String get exportReceipts => 'Exporter les factures';

  @override
  String get importReceipts => 'Importer les factures';

  @override
  String get filterByStore => 'Filtrer par magasin';

  @override
  String get filterByDate => 'Filtrer par date';

  @override
  String get filterByAmount => 'Filtrer par montant';

  @override
  String get sortByDate => 'Trier par date';

  @override
  String get sortByStore => 'Trier par magasin';

  @override
  String get newestFirst => 'Plus récent en premier';

  @override
  String get oldestFirst => 'Plus ancien en premier';

  @override
  String get highestFirst => 'Montant le plus élevé en premier';

  @override
  String get lowestFirst => 'Montant le plus faible en premier';

  @override
  String get cannotAddReceipt => 'Impossible d\'ajouter une facture';

  @override
  String get cannotEditReceipt => 'Impossible de modifier la facture';

  @override
  String get cannotDeleteReceipt => 'Impossible de supprimer la facture';

  @override
  String get receiptPermissionDenied =>
      'Permission refusée pour les opérations de facture';

  @override
  String get receiptReadOnlyAccess => 'Accès en lecture seule aux factures';

  @override
  String get receiptDateFormat => 'Format de date de facture';

  @override
  String get amountDisplayFormat => 'Format d\'affichage du montant';

  @override
  String receiptNumberFormat(int number) {
    return 'Facture n°$number';
  }

  @override
  String get receiptSavedSuccessfully => 'Facture sauvegardée avec succès';

  @override
  String get receiptDeletedPermanently => 'Facture supprimée définitivement';

  @override
  String get allReceiptsCleared => 'Toutes les factures supprimées';

  @override
  String get receiptDataExported => 'Données de factures exportées';

  @override
  String get receiptDataImported => 'Données de factures importées';

  @override
  String get receiptHelpTitle => 'À propos des factures';

  @override
  String get receiptHelpDescription =>
      'Ajoutez vos vraies factures d\'achat pour suivre les dépenses réelles versus les coûts estimés';

  @override
  String get receiptBenefits => 'Avantages d\'ajouter des factures';

  @override
  String get accurateSpendingData => '• Données de dépenses précises';

  @override
  String get betterBudgetTracking => '• Meilleur suivi du budget';

  @override
  String get spendingComparisons => '• Comparer estimations vs coûts réels';

  @override
  String get storeSpendingAnalysis => '• Analyser les dépenses par magasin';

  @override
  String get error => 'Erreur';

  @override
  String get budgets => 'Budgets';

  @override
  String get createBudget => 'Créer un budget';

  @override
  String get editBudget => 'Modifier le budget';

  @override
  String get deleteBudget => 'Supprimer le budget';

  @override
  String get quickBudget => 'Budget rapide';

  @override
  String get budgetName => 'Nom du budget';

  @override
  String get budgetNameHint => 'Ex: Courses du mois';

  @override
  String get budgetAmount => 'Montant du budget';

  @override
  String get budgetAmountRequired => 'Le montant du budget est requis';

  @override
  String get budgetAmountInvalid => 'Montant de budget invalide';

  @override
  String get budgetAmountTooHigh => 'Montant de budget trop élevé';

  @override
  String get budgetNameRequired => 'Le nom du budget est requis';

  @override
  String get budgetNameTooShort => 'Le nom du budget est trop court';

  @override
  String get periodType => 'Type de période';

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get alertThreshold => 'Seuil d\'alerte';

  @override
  String get alertThresholdDescription =>
      'Recevoir une alerte quand ce pourcentage du budget est atteint';

  @override
  String get associatedList => 'Liste associée';

  @override
  String get generalBudget => 'Budget général';

  @override
  String get budgetCreatedSuccessfully => 'Budget créé avec succès';

  @override
  String get budgetUpdatedSuccessfully => 'Budget modifié avec succès';

  @override
  String get budgetDeletedSuccessfully => 'Budget supprimé avec succès';

  @override
  String get errorLoadingBudgets => 'Erreur lors du chargement des budgets';

  @override
  String get budgetSummary => 'Résumé des budgets';

  @override
  String get overviewOfYourBudgets => 'Vue d\'ensemble de vos budgets';

  @override
  String get totalBudgets => 'Total budgets';

  @override
  String get active => 'Actifs';

  @override
  String get warnings => 'Alertes';

  @override
  String get exceeded => 'Dépassés';

  @override
  String get noBudgetsYet => 'Aucun budget pour le moment';

  @override
  String get createFirstBudgetDescription =>
      'Créez votre premier budget pour gérer vos dépenses';

  @override
  String get noActiveBudgets => 'Aucun budget actif';

  @override
  String get createActiveBudgetDescription =>
      'Créez un budget actif pour commencer le suivi';

  @override
  String get noBudgetAlerts => 'Aucune alerte de budget';

  @override
  String get allBudgetsOnTrack => 'Tous vos budgets sont sous contrôle';

  @override
  String get budgeted => 'Budgétisé';

  @override
  String get spent => 'Dépensé';

  @override
  String get remaining => 'Restant';

  @override
  String get pause => 'Pause';

  @override
  String get activate => 'Activer';

  @override
  String get custom => 'Personnalisé';

  @override
  String get alerts => 'Alertes';

  @override
  String get createQuickBudget => 'Créer un budget rapide';

  @override
  String get createMonthlyBudget => 'Créer un budget mensuel';

  @override
  String get quickBudgetDescription =>
      'Créez un budget rapidement avec des modèles prédéfinis';

  @override
  String get monthlyBudgetDescription => 'Budget pour le mois en cours';

  @override
  String get yearlyBudgetDescription => 'Budget pour l\'année en cours';

  @override
  String get weeklyBudgetDescription => 'Budget pour la semaine en cours';

  @override
  String get selectBudgetType => 'Sélectionnez le type de budget';

  @override
  String get createBudgetQuickly => 'Créez un budget rapidement';

  @override
  String get weeklyBudget => 'Budget hebdomadaire';

  @override
  String get monthlyBudget => 'Budget mensuel';

  @override
  String get yearlyBudget => 'Budget annuel';

  @override
  String get recentBudgets => 'Budgets récents';

  @override
  String deleteBudgetConfirmation(String budgetName) {
    return 'Êtes-vous sûr de vouloir supprimer le budget \"$budgetName\" ?';
  }

  @override
  String get setBudgetForPeriod => 'Définir un budget pour une période';

  @override
  String get modifyBudgetDetails => 'Modifier les détails du budget';

  @override
  String get expired => 'Expirés';

  @override
  String get upcoming => 'À venir';

  @override
  String get warning => 'Attention';

  @override
  String get sortByName => 'Trier par nom';

  @override
  String get filters => 'Filtres';

  @override
  String get scope => 'Portée';

  @override
  String get general => 'Général';

  @override
  String get specific => 'Spécifique';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get update => 'Mettre à jour';

  @override
  String get filtersAndSort => 'Filtres et tri';

  @override
  String get spendingProgress => 'Progression des dépenses';

  @override
  String get specificList => 'Liste spécifique';

  @override
  String get budgetPeriod => 'Période du budget';

  @override
  String get pleaseEnterAmount => 'Veuillez entrer le montant';

  @override
  String get pleaseEnterValidAmount => 'Veuillez entrer un montant valide';

  @override
  String get budgetScope => 'Portée du budget';

  @override
  String get enterBudgetName => 'Entrez le nom du budget';

  @override
  String get pleaseEnterBudgetName => 'Veuillez entrer le nom du budget';

  @override
  String get preview => 'Aperçu';

  @override
  String get type => 'Type';

  @override
  String get amount => 'Montant';

  @override
  String get generalBudgetDescription =>
      'S\'applique à toutes vos listes de courses';

  @override
  String get orSelectSpecificList => 'Ou sélectionnez une liste spécifique';

  @override
  String get unknownList => 'Liste inconnue';

  @override
  String get date => 'Date';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get days => 'jours';

  @override
  String get all => 'Tous';

  @override
  String get budgetPeriodTypeWeekly => 'Hebdomadaire';

  @override
  String get budgetPeriodTypeMonthly => 'Mensuel';

  @override
  String get budgetPeriodTypeYearly => 'Annuel';

  @override
  String get budgetPeriodTypeCustom => 'Personnalisé';

  @override
  String get budgetFilterAll => 'Tous';

  @override
  String get budgetFilterActive => 'Actifs';

  @override
  String get budgetFilterInactive => 'Inactifs';

  @override
  String get budgetFilterExpired => 'Expirés';

  @override
  String get budgetFilterUpcoming => 'À venir';

  @override
  String get budgetFilterWarning => 'Attention';

  @override
  String get budgetFilterExceeded => 'Dépassés';

  @override
  String get budgetScopeGeneral => 'Général';

  @override
  String get budgetScopeSpecific => 'Spécifique à une liste';

  @override
  String get budgetValidationNameRequired => 'Le nom du budget est requis';

  @override
  String get budgetValidationNameTooShort =>
      'Le nom du budget doit contenir au moins 3 caractères';

  @override
  String get budgetValidationNameTooLong =>
      'Le nom du budget ne peut pas dépasser 50 caractères';

  @override
  String get budgetValidationAmountRequired =>
      'Le montant du budget est requis';

  @override
  String get budgetValidationAmountMustBePositive =>
      'Le montant du budget doit être positif';

  @override
  String get budgetValidationAmountTooHigh =>
      'Le montant du budget ne peut pas dépasser 999 999,99';

  @override
  String get budgetValidationStartDateRequired =>
      'La date de début est requise';

  @override
  String get budgetValidationEndDateRequired => 'La date de fin est requise';

  @override
  String get budgetValidationEndDateAfterStart =>
      'La date de fin doit être après la date de début';

  @override
  String get budgetValidationAlertThresholdInvalid =>
      'Le seuil d\'alerte doit être entre 1 et 100';

  @override
  String get hideFilters => 'Masquer les filtres';

  @override
  String get showFilters => 'Afficher les filtres';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get toggleBudgetStatus => 'Basculer le statut du budget';

  @override
  String get viewBudgetDetails => 'Voir les détails du budget';

  @override
  String get pauseBudget => 'Mettre en pause le budget';

  @override
  String get resumeBudget => 'Reprendre le budget';

  @override
  String get budgetOnTrack => 'Budget sous contrôle';

  @override
  String get budgetWarning => 'Alerte budget';

  @override
  String get budgetExceeded => 'Budget dépassé';

  @override
  String get budgetDetails => 'Détails du budget';

  @override
  String get budgetProgress => 'Progression du budget';

  @override
  String get spentAmount => 'Montant dépensé';

  @override
  String get remainingAmount => 'Montant restant';

  @override
  String get budgetStatus => 'Statut du budget';

  @override
  String get budgetCreateError => 'Erreur lors de la création du budget';

  @override
  String get budgetUpdateError => 'Erreur lors de la mise à jour du budget';

  @override
  String get budgetDeleteError => 'Erreur lors de la suppression du budget';

  @override
  String get budgetLoadError => 'Erreur lors du chargement du budget';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get tryAdjustingFilters =>
      'Essayez d\'ajuster vos filtres ou d\'effacer les filtres actuels';

  @override
  String get daysRemaining => 'jours restants';

  @override
  String get dayRemaining => 'jour restant';

  @override
  String get epilistUser => 'Utilisateur EpiList';

  @override
  String get refreshTooltip => 'Actualiser';

  @override
  String get appLogoError => 'Erreur de chargement du logo';

  @override
  String get userMenuHeader => 'Menu utilisateur';

  @override
  String get userRole => 'Rôle utilisateur';

  @override
  String get accessLevel => 'Niveau d\'accès';

  @override
  String get confirmAction => 'Confirmer l\'action';

  @override
  String get menuOptions => 'Options du menu';

  @override
  String get userActions => 'Actions utilisateur';

  @override
  String get appReady => 'Application prête';

  @override
  String get loadingUser => 'Chargement utilisateur';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get addItems => 'ajouter des articles';

  @override
  String get deleteItems => 'supprimer des articles';

  @override
  String get modifyItemStatus => 'modifier le statut des articles';

  @override
  String cannotPerformActionReadOnly(String action, String permission) {
    return 'Vous ne pouvez pas $action car cette liste est en mode lecture seule.\n\nVotre permission actuelle : $permission';
  }

  @override
  String cannotPerformAction(String action, String permission) {
    return 'Vous n\'avez pas la permission de $action.\n\nVotre permission actuelle : $permission';
  }

  @override
  String get codePastedSuccessfully => 'Code collé avec succès !';

  @override
  String get codePartiallyPasted => 'Code partiellement collé';

  @override
  String get noCodeFoundInClipboard =>
      'Aucun code trouvé dans le presse-papiers';

  @override
  String get errorPastingCode => 'Erreur lors du collage du code';

  @override
  String get pasteCode => 'Coller le code';

  @override
  String get clear => 'Effacer';

  @override
  String get refreshing => 'Actualisation...';

  @override
  String get export => 'Exporter';

  @override
  String get exportReceiptsDescription =>
      'Exportez vos factures au format PDF ou CSV';

  @override
  String get exportToPDF => 'Exporter en PDF';

  @override
  String get exportToCSV => 'Exporter en CSV';

  @override
  String get exportPDFInProgress => 'Export PDF en cours...';

  @override
  String get exportCSVInProgress => 'Export CSV en cours...';

  @override
  String get addFirstReceiptToStart =>
      'Ajoutez votre première facture pour commencer à suivre vos dépenses réelles';

  @override
  String get createReceiptNow => 'Créer une facture maintenant';

  @override
  String get errorExportingReceipts => 'Erreur lors de l\'export des factures';

  @override
  String get exportCompletedSuccessfully => 'Export terminé avec succès';

  @override
  String get exportFailed => 'Échec de l\'export';

  @override
  String get refreshingData => 'Actualisation des données...';

  @override
  String get dataRefreshedSuccessfully => 'Données actualisées avec succès';

  @override
  String get exportOptions => 'Options d\'export';

  @override
  String get selectExportFormat => 'Sélectionnez le format d\'export';

  @override
  String get exportToPDFFile => 'Exporter vers fichier PDF';

  @override
  String get exportToCSVFile => 'Exporter vers fichier CSV';

  @override
  String get exportStarted => 'Export démarré';

  @override
  String get checkDownloadsFolder =>
      'Vérifiez votre dossier de téléchargements';

  @override
  String get pdfExportError => 'Erreur d\'export PDF';

  @override
  String get csvExportError => 'Erreur d\'export CSV';

  @override
  String get fileCreationError => 'Erreur de création de fichier';

  @override
  String get permissionDeniedError =>
      'Permission refusée pour la création de fichier';

  @override
  String get overBudget => 'Dépassement budget';

  @override
  String get highestPurchase => 'Plus gros achat';

  @override
  String get topCategory => 'Catégorie principale';

  @override
  String get mostFrequentCategory => 'Catégorie la plus fréquente';

  @override
  String get weeklyActivity => 'Activité hebdomadaire';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get includeSharedLists => 'Inclure les listes partagées';

  @override
  String get showingOnlyOwnLists =>
      'Affichage uniquement de vos propres listes';

  @override
  String get spendingBreakdown => 'Répartition des dépenses';

  @override
  String get myLists => 'Mes listes';

  @override
  String get sharedLists => 'Listes partagées';

  @override
  String get ownListsOnly => 'Mes listes uniquement';

  @override
  String get dataSourceBreakdown => 'Répartition des sources de données';

  @override
  String get andXMore => 'Et';

  @override
  String get moreCategories => 'autres catégories';

  @override
  String get january => 'Janvier';

  @override
  String get february => 'Février';

  @override
  String get march => 'Mars';

  @override
  String get april => 'Avril';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Juin';

  @override
  String get july => 'Juillet';

  @override
  String get august => 'Août';

  @override
  String get september => 'Septembre';

  @override
  String get october => 'Octobre';

  @override
  String get november => 'Novembre';

  @override
  String get december => 'Décembre';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Fév';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Avr';

  @override
  String get mayShort => 'Mai';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aoû';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Déc';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get mondayShort => 'Lun';

  @override
  String get tuesdayShort => 'Mar';

  @override
  String get wednesdayShort => 'Mer';

  @override
  String get thursdayShort => 'Jeu';

  @override
  String get fridayShort => 'Ven';

  @override
  String get saturdayShort => 'Sam';

  @override
  String get sundayShort => 'Dim';
}
