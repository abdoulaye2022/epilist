import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'EpiList'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! 👋'**
  String get hello;

  /// No description provided for @manageGroceryLists.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos listes d\'épicerie facilement'**
  String get manageGroceryLists;

  /// No description provided for @myGroceryLists.
  ///
  /// In fr, this message translates to:
  /// **'Mes Listes d\'Épicerie'**
  String get myGroceryLists;

  /// No description provided for @viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAll;

  /// No description provided for @newList.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Liste'**
  String get newList;

  /// No description provided for @createList.
  ///
  /// In fr, this message translates to:
  /// **'Créer une liste'**
  String get createList;

  /// No description provided for @noGroceryLists.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste d\'épicerie'**
  String get noGroceryLists;

  /// No description provided for @createFirstList.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première liste'**
  String get createFirstList;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @allLists.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les listes'**
  String get allLists;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @articles.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get articles;

  /// No description provided for @budget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @sharedList.
  ///
  /// In fr, this message translates to:
  /// **'Liste partagée'**
  String get sharedList;

  /// No description provided for @collaborators.
  ///
  /// In fr, this message translates to:
  /// **'collaborateur(s)'**
  String get collaborators;

  /// No description provided for @sharedBy.
  ///
  /// In fr, this message translates to:
  /// **'Partagée par'**
  String get sharedBy;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'✅ Terminée'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'🛒 En cours'**
  String get inProgress;

  /// No description provided for @created.
  ///
  /// In fr, this message translates to:
  /// **'Créée'**
  String get created;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @duplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get duplicate;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @manageShares.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les partages'**
  String get manageShares;

  /// No description provided for @leave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get leave;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @cannotEditPermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas la permission de modifier cette liste'**
  String get cannotEditPermission;

  /// No description provided for @cannotSharePermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas la permission de partager cette liste'**
  String get cannotSharePermission;

  /// No description provided for @onlyOwnerManageShares.
  ///
  /// In fr, this message translates to:
  /// **'Seul le propriétaire peut gérer les partages'**
  String get onlyOwnerManageShares;

  /// No description provided for @cannotLeaveOwnList.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter votre propre liste'**
  String get cannotLeaveOwnList;

  /// No description provided for @cannotDeletePermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas la permission de supprimer cette liste'**
  String get cannotDeletePermission;

  /// No description provided for @readOnlyAccess.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get readOnlyAccess;

  /// No description provided for @editAccess.
  ///
  /// In fr, this message translates to:
  /// **'Édition'**
  String get editAccess;

  /// No description provided for @adminAccess.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get adminAccess;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la langue'**
  String get selectLanguage;

  /// No description provided for @languageSelection.
  ///
  /// In fr, this message translates to:
  /// **'Sélection de la langue'**
  String get languageSelection;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre langue préférée'**
  String get choosePreferredLanguage;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get registerTitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register;

  /// No description provided for @welcomeToEpiList.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur EpiList'**
  String get welcomeToEpiList;

  /// No description provided for @groceryListApp.
  ///
  /// In fr, this message translates to:
  /// **'Votre application de listes d\'épicerie'**
  String get groceryListApp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ?'**
  String get noAccount;

  /// No description provided for @initialization.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation...'**
  String get initialization;

  /// No description provided for @checkingAuthentication.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de l\'authentification...'**
  String get checkingAuthentication;

  /// No description provided for @invalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get invalidCredentials;

  /// No description provided for @userNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte trouvé avec cet email'**
  String get userNotFound;

  /// No description provided for @emailNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email non vérifié'**
  String get emailNotVerified;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Veuillez vous reconnecter.'**
  String get sessionExpired;

  /// No description provided for @emailConfirmedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Email confirmé avec succès ! Bienvenue !'**
  String get emailConfirmedSuccess;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de réseau'**
  String get networkError;

  /// No description provided for @unknownError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue'**
  String get unknownError;

  /// No description provided for @initializationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'initialisation'**
  String get initializationError;

  /// No description provided for @cannotStartApp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer l\'application'**
  String get cannotStartApp;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get myProfile;

  /// No description provided for @myData.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get myData;

  /// No description provided for @myShoppingLists.
  ///
  /// In fr, this message translates to:
  /// **'Mes listes de courses'**
  String get myShoppingLists;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @appSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de l\'application'**
  String get appSettings;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @aboutEpiList.
  ///
  /// In fr, this message translates to:
  /// **'À propos d\'EpiList'**
  String get aboutEpiList;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfService;

  /// No description provided for @logoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutButton;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @emailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié'**
  String get emailVerified;

  /// No description provided for @emailNotVerifiedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Email non vérifié'**
  String get emailNotVerifiedStatus;

  /// No description provided for @loadingProfile.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du profil...'**
  String get loadingProfile;

  /// No description provided for @cannotLoadProfile.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le profil'**
  String get cannotLoadProfile;

  /// No description provided for @accountDeletionScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression de compte programmée'**
  String get accountDeletionScheduled;

  /// No description provided for @accountWillBeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera définitivement supprimé le {date}'**
  String accountWillBeDeleted(String date);

  /// No description provided for @timeRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Temps restant : {days} jour{plural}'**
  String timeRemaining(int days, String plural);

  /// No description provided for @reason.
  ///
  /// In fr, this message translates to:
  /// **'Raison : {reason}'**
  String reason(String reason);

  /// No description provided for @cancelDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get cancelDeletion;

  /// No description provided for @cancellationPeriodExpired.
  ///
  /// In fr, this message translates to:
  /// **'La période d\'annulation de 30 jours est écoulée'**
  String get cancellationPeriodExpired;

  /// No description provided for @deletionCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code de suppression envoyé ! Vérifiez votre email.'**
  String get deletionCodeSent;

  /// No description provided for @accountDeletionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression de compte annulée avec succès !'**
  String get accountDeletionCancelled;

  /// No description provided for @accountWillBeDeletedIn30Days.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action.'**
  String get accountWillBeDeletedIn30Days;

  /// No description provided for @confirmCancelDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get confirmCancelDeletion;

  /// No description provided for @confirmCancelDeletionText.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler la suppression de votre compte ? Votre compte redeviendra actif immédiatement.'**
  String get confirmCancelDeletionText;

  /// No description provided for @noKeepDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Non, garder la suppression'**
  String get noKeepDeletion;

  /// No description provided for @yesCancelDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get yesCancelDeletion;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @enterYourCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code'**
  String get enterYourCode;

  /// No description provided for @enterCodeAndNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu par email et votre nouveau mot de passe'**
  String get enterCodeAndNewPassword;

  /// No description provided for @enterEmailForVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email pour recevoir un code de vérification'**
  String get enterEmailForVerificationCode;

  /// No description provided for @verificationCodeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification envoyé à {email}'**
  String verificationCodeSentTo(Object email);

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé avec succès !'**
  String get passwordChangedSuccessfully;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre email'**
  String get pleaseEnterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @verificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get verificationCode;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code à 6 chiffres'**
  String get enterSixDigitCode;

  /// No description provided for @pleaseEnterVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir le code de vérification'**
  String get pleaseEnterVerificationCode;

  /// No description provided for @codeMustBeSixDigits.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir 6 chiffres'**
  String get codeMustBeSixDigits;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre nouveau mot de passe'**
  String get pleaseEnterNewPassword;

  /// No description provided for @passwordMinSixCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordMinSixCharacters;

  /// No description provided for @confirmNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmNewPassword;

  /// No description provided for @pleaseConfirmNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre nouveau mot de passe'**
  String get pleaseConfirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @codeExpiresInTwoHours.
  ///
  /// In fr, this message translates to:
  /// **'Le code expire dans 2 heures. Vérifiez vos emails et vos spams.'**
  String get codeExpiresInTwoHours;

  /// No description provided for @verificationCodeWillBeSent.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez un code de vérification par email pour changer votre mot de passe.'**
  String get verificationCodeWillBeSent;

  /// No description provided for @changingPassword.
  ///
  /// In fr, this message translates to:
  /// **'Changement en cours...'**
  String get changingPassword;

  /// No description provided for @sendingCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoi du code...'**
  String get sendingCode;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Le code de vérification est invalide'**
  String get invalidVerificationCode;

  /// No description provided for @verificationCodeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Le code de vérification a expiré. Demandez un nouveau code.'**
  String get verificationCodeExpired;

  /// No description provided for @noAccountFoundWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte trouvé avec cet email'**
  String get noAccountFoundWithEmail;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In fr, this message translates to:
  /// **'Votre email n\'est pas encore vérifié'**
  String get emailNotVerifiedYet;

  /// No description provided for @errorChangingPassword.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du changement de mot de passe'**
  String get errorChangingPassword;

  /// No description provided for @connectionProblemCheckNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion. Vérifiez votre réseau.'**
  String get connectionProblemCheckNetwork;

  /// No description provided for @enteredDataNotValid.
  ///
  /// In fr, this message translates to:
  /// **'Les données saisies ne sont pas valides'**
  String get enteredDataNotValid;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue'**
  String get unexpectedErrorOccurred;

  /// No description provided for @manageGroceryListsEasily.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos courses facilement'**
  String get manageGroceryListsEasily;

  /// No description provided for @createListsBeforeShopping.
  ///
  /// In fr, this message translates to:
  /// **'Créez vos listes avant d\'aller faire vos courses'**
  String get createListsBeforeShopping;

  /// No description provided for @checkPurchasesRealTime.
  ///
  /// In fr, this message translates to:
  /// **'Cochez vos achats en temps réel'**
  String get checkPurchasesRealTime;

  /// No description provided for @trackGroceryExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos dépenses d\'épicerie en CAD\$'**
  String get trackGroceryExpenses;

  /// No description provided for @loggingIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get loggingIn;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre mot de passe'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinThreeCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 3 caractères'**
  String get passwordMinThreeCharacters;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get or;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @simplifyShoppingControlBudget.
  ///
  /// In fr, this message translates to:
  /// **'Simplifiez vos courses et maîtrisez votre budget !'**
  String get simplifyShoppingControlBudget;

  /// No description provided for @pleaseFixFormErrors.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez corriger les erreurs dans le formulaire'**
  String get pleaseFixFormErrors;

  /// No description provided for @emailMustBeVerified.
  ///
  /// In fr, this message translates to:
  /// **'Votre email doit être vérifié avant de continuer.'**
  String get emailMustBeVerified;

  /// No description provided for @resetPasswordSecurely.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser votre mot de passe en toute sécurité.'**
  String get resetPasswordSecurely;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @joinEpiListToManage.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez EpiList pour gérer vos courses facilement'**
  String get joinEpiListToManage;

  /// No description provided for @creatingAccount.
  ///
  /// In fr, this message translates to:
  /// **'Création du compte en cours...'**
  String get creatingAccount;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom requis'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get lastNameRequired;

  /// No description provided for @tooShort.
  ///
  /// In fr, this message translates to:
  /// **'Trop court'**
  String get tooShort;

  /// No description provided for @atLeastSixCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères'**
  String get atLeastSixCharacters;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre mot de passe'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDifferent.
  ///
  /// In fr, this message translates to:
  /// **'Mots de passe différents'**
  String get passwordsDifferent;

  /// No description provided for @iAcceptThe.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les '**
  String get iAcceptThe;

  /// No description provided for @andThe.
  ///
  /// In fr, this message translates to:
  /// **' et la '**
  String get andThe;

  /// No description provided for @createMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createMyAccount;

  /// No description provided for @afterRegistrationEmailVerification.
  ///
  /// In fr, this message translates to:
  /// **'Après inscription, vous recevrez un code de vérification par email'**
  String get afterRegistrationEmailVerification;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé avec succès ! {firstName} {lastName}\nVérifiez votre email pour activer votre compte.'**
  String accountCreatedSuccessfully(String firstName, String lastName);

  /// No description provided for @emailAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse email est déjà utilisée'**
  String get emailAlreadyExists;

  /// No description provided for @passwordTooWeak.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible'**
  String get passwordTooWeak;

  /// No description provided for @validationError.
  ///
  /// In fr, this message translates to:
  /// **'Les données saisies ne sont pas valides'**
  String get validationError;

  /// No description provided for @noShoppingLists.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste de courses'**
  String get noShoppingLists;

  /// No description provided for @createFirstListToStart.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première liste pour commencer'**
  String get createFirstListToStart;

  /// No description provided for @leaveList.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la liste'**
  String get leaveList;

  /// No description provided for @sureToLeave.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter \"{listName}\" ?'**
  String sureToLeave(String listName);

  /// No description provided for @loseAccessWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous perdrez l\'accès à cette liste et à tous ses éléments.'**
  String get loseAccessWarning;

  /// No description provided for @list.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @noActiveShares.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partage actif'**
  String get noActiveShares;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @modifyPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Modifier permissions'**
  String get modifyPermissions;

  /// No description provided for @revoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get revoke;

  /// No description provided for @createNewShare.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau partage'**
  String get createNewShare;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {days} jours'**
  String daysAgo(int days);

  /// No description provided for @on.
  ///
  /// In fr, this message translates to:
  /// **'le'**
  String get on;

  /// No description provided for @cad.
  ///
  /// In fr, this message translates to:
  /// **' \$CAD'**
  String get cad;

  /// No description provided for @createShareLinkFor.
  ///
  /// In fr, this message translates to:
  /// **'Créez un lien de partage pour \"{listName}\"'**
  String createShareLinkFor(String listName);

  /// No description provided for @permissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @linkExpiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration du lien'**
  String get linkExpiration;

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String daysCount(int count);

  /// No description provided for @creating.
  ///
  /// In fr, this message translates to:
  /// **'Création...'**
  String get creating;

  /// No description provided for @generateShareLink.
  ///
  /// In fr, this message translates to:
  /// **'Générer le lien de partage'**
  String get generateShareLink;

  /// No description provided for @linkCreatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Lien créé avec succès'**
  String get linkCreatedSuccessfully;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @newLink.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau lien'**
  String get newLink;

  /// No description provided for @linkExpirationInfo.
  ///
  /// In fr, this message translates to:
  /// **'Le lien expire après {days} jours. Vous pouvez révoquer l\'accès à tout moment.'**
  String linkExpirationInfo(int days);

  /// No description provided for @shareLinkCreatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage créé avec succès'**
  String get shareLinkCreatedSuccessfully;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié dans le presse-papiers !'**
  String get linkCopiedToClipboard;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get you;

  /// No description provided for @epilistInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Invitation EpiList - {listName}'**
  String epilistInvitation(String listName);

  /// No description provided for @shareError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du partage'**
  String get shareError;

  /// No description provided for @readOnlyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Peut voir la liste mais pas la modifier'**
  String get readOnlyDescription;

  /// No description provided for @editDescription.
  ///
  /// In fr, this message translates to:
  /// **'Peut ajouter, modifier et marquer des articles'**
  String get editDescription;

  /// No description provided for @adminDescription.
  ///
  /// In fr, this message translates to:
  /// **'Peut tout faire, y compris partager et supprimer'**
  String get adminDescription;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progress;

  /// No description provided for @editList.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la liste'**
  String get editList;

  /// No description provided for @thisListIsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Cette liste est vide'**
  String get thisListIsEmpty;

  /// No description provided for @yourListIsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre liste est vide'**
  String get yourListIsEmpty;

  /// No description provided for @noItemsReadOnlyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a pas encore d\'articles dans cette liste.\nVous pouvez seulement consulter son contenu.'**
  String get noItemsReadOnlyDescription;

  /// No description provided for @noItemsNoPermissionDescription.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a pas encore d\'articles dans cette liste.\nVous n\'avez pas la permission d\'ajouter des articles.'**
  String get noItemsNoPermissionDescription;

  /// No description provided for @noItemsAddFirstDescription.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par ajouter votre premier article\npour organiser vos courses.'**
  String get noItemsAddFirstDescription;

  /// No description provided for @addItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get addItem;

  /// No description provided for @readOnlyMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode lecture seule'**
  String get readOnlyMode;

  /// No description provided for @permissionRequiredToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Permission requise pour ajouter'**
  String get permissionRequiredToAdd;

  /// No description provided for @addItemTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get addItemTooltip;

  /// No description provided for @insufficientPermission.
  ///
  /// In fr, this message translates to:
  /// **'Permission insuffisante'**
  String get insufficientPermission;

  /// No description provided for @readOnlyAccessMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode lecture seule - Vous ne pouvez pas modifier cette liste'**
  String get readOnlyAccessMode;

  /// No description provided for @sharedListCanEdit.
  ///
  /// In fr, this message translates to:
  /// **'Liste partagée - Vous pouvez modifier les articles'**
  String get sharedListCanEdit;

  /// No description provided for @limitedAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès limité à cette liste'**
  String get limitedAccess;

  /// No description provided for @by.
  ///
  /// In fr, this message translates to:
  /// **'Par'**
  String get by;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get quantity;

  /// No description provided for @deleteItem.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteItem;

  /// No description provided for @editItem.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'article'**
  String get editItem;

  /// No description provided for @listInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la liste'**
  String get listInformation;

  /// No description provided for @detailsAndPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Détails et permissions de \"{listName}\"'**
  String detailsAndPermissions(String listName);

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @private.
  ///
  /// In fr, this message translates to:
  /// **'Privée'**
  String get private;

  /// No description provided for @yourRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle'**
  String get yourRole;

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get owner;

  /// No description provided for @collaborator.
  ///
  /// In fr, this message translates to:
  /// **'Collaborateur'**
  String get collaborator;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understood;

  /// No description provided for @moreInfo.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'infos'**
  String get moreInfo;

  /// No description provided for @contactOwnerForPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Contactez le propriétaire pour obtenir plus de permissions'**
  String get contactOwnerForPermissions;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer \"{itemName}\" de la liste ?'**
  String deleteItemConfirm(String itemName);

  /// No description provided for @leaveListConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter \"{listName}\" ?\n\nVous perdrez l\'accès à cette liste et ne pourrez plus voir son contenu.'**
  String leaveListConfirm(String listName);

  /// No description provided for @leftList.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté la liste \"{listName}\"'**
  String leftList(String listName);

  /// No description provided for @listDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Liste \"{listName}\" supprimée'**
  String listDeleted(String listName);

  /// No description provided for @editItems.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les articles'**
  String get editItems;

  /// No description provided for @shareList.
  ///
  /// In fr, this message translates to:
  /// **'Partager la liste'**
  String get shareList;

  /// No description provided for @deleteList.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liste'**
  String get deleteList;

  /// No description provided for @readOnlyShort.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get readOnlyShort;

  /// No description provided for @quantityShort.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get quantityShort;

  /// No description provided for @modification.
  ///
  /// In fr, this message translates to:
  /// **'Modification'**
  String get modification;

  /// No description provided for @consultation.
  ///
  /// In fr, this message translates to:
  /// **'Consultation'**
  String get consultation;

  /// No description provided for @modifyThisList.
  ///
  /// In fr, this message translates to:
  /// **'modifier cette liste'**
  String get modifyThisList;

  /// No description provided for @modifyThisItem.
  ///
  /// In fr, this message translates to:
  /// **'modifier cet article'**
  String get modifyThisItem;

  /// No description provided for @deleteThisItem.
  ///
  /// In fr, this message translates to:
  /// **'supprimer cet article'**
  String get deleteThisItem;

  /// No description provided for @limited.
  ///
  /// In fr, this message translates to:
  /// **'Limitée'**
  String get limited;

  /// No description provided for @cannotActionReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas {action} car cette liste est en mode lecture seule.\n\nVotre permission actuelle : {permission}'**
  String cannotActionReadOnly(String action, String permission);

  /// No description provided for @cannotActionPermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas la permission de {action}.\n\nVotre permission actuelle : {permission}'**
  String cannotActionPermission(String action, String permission);

  /// No description provided for @sharedByUser.
  ///
  /// In fr, this message translates to:
  /// **'Partagée par {userName}'**
  String sharedByUser(String userName);

  /// No description provided for @deleteItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'article'**
  String get deleteItemTitle;

  /// No description provided for @deleteQuickConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer \"{itemName}\" ?'**
  String deleteQuickConfirm(String itemName);

  /// No description provided for @newItem.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel Article'**
  String get newItem;

  /// No description provided for @addNewItemToList.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un nouvel article à votre liste d\'épicerie'**
  String get addNewItemToList;

  /// No description provided for @productNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit*'**
  String get productNameRequired;

  /// No description provided for @productNameRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du produit est obligatoire'**
  String get productNameRequiredMessage;

  /// No description provided for @productNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Bananes, Pain, Lait...'**
  String get productNameHint;

  /// No description provided for @priceCAD.
  ///
  /// In fr, this message translates to:
  /// **'Prix (\$CAD)'**
  String get priceCAD;

  /// No description provided for @storeOptional.
  ///
  /// In fr, this message translates to:
  /// **'Magasin (optionnel)'**
  String get storeOptional;

  /// No description provided for @storeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: IGA, Metro, Provigo...'**
  String get storeHint;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @giveNameToNewList.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom à votre nouvelle liste d\'épicerie'**
  String get giveNameToNewList;

  /// No description provided for @listName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la liste'**
  String get listName;

  /// No description provided for @listNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Courses de la semaine'**
  String get listNameHint;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @processingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours...'**
  String get processingInProgress;

  /// No description provided for @emailAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email *'**
  String get emailAddressRequired;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'email invalide'**
  String get invalidEmailFormat;

  /// No description provided for @verificationCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification envoyé !'**
  String get verificationCodeSent;

  /// No description provided for @checkEmailAndEnterCode.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre boîte email et entrez le code ci-dessous'**
  String get checkEmailAndEnterCode;

  /// No description provided for @verificationCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification *'**
  String get verificationCodeRequired;

  /// No description provided for @sixDigitCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get sixDigitCodeHint;

  /// No description provided for @codeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le code est requis'**
  String get codeRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe *'**
  String get newPasswordRequired;

  /// No description provided for @minimumSixCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get minimumSixCharacters;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @passwordMinSixChars.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordMinSixChars;

  /// No description provided for @retypePassword.
  ///
  /// In fr, this message translates to:
  /// **'Retapez le mot de passe'**
  String get retypePassword;

  /// No description provided for @confirmationRequired.
  ///
  /// In fr, this message translates to:
  /// **'La confirmation est requise'**
  String get confirmationRequired;

  /// No description provided for @changePasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePasswordButton;

  /// No description provided for @verificationCodeSentCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification envoyé ! Vérifiez votre email.'**
  String get verificationCodeSentCheckEmail;

  /// No description provided for @confirmDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletion;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccount;

  /// No description provided for @attention.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ ATTENTION'**
  String get attention;

  /// No description provided for @actionDefinitiveIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive et irréversible !'**
  String get actionDefinitiveIrreversible;

  /// No description provided for @whatWillBeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui sera supprimé :'**
  String get whatWillBeDeleted;

  /// No description provided for @profileAndPersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'• Votre profil et informations personnelles'**
  String get profileAndPersonalInfo;

  /// No description provided for @allPrivateGroceryLists.
  ///
  /// In fr, this message translates to:
  /// **'• Toutes vos listes d\'épicerie privées'**
  String get allPrivateGroceryLists;

  /// No description provided for @preferencesAndSettings.
  ///
  /// In fr, this message translates to:
  /// **'• Vos préférences et paramètres'**
  String get preferencesAndSettings;

  /// No description provided for @purchaseHistory.
  ///
  /// In fr, this message translates to:
  /// **'• Votre historique d\'achats'**
  String get purchaseHistory;

  /// No description provided for @whatWillBePreserved.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui sera préservé :'**
  String get whatWillBePreserved;

  /// No description provided for @sharedListsAnonymized.
  ///
  /// In fr, this message translates to:
  /// **'• Les listes partagées avec d\'autres utilisateurs (anonymisées)'**
  String get sharedListsAnonymized;

  /// No description provided for @reasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Raison (optionnelle)'**
  String get reasonOptional;

  /// No description provided for @whyDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi supprimez-vous votre compte ?'**
  String get whyDeleteAccount;

  /// No description provided for @understandIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends que cette action est irréversible'**
  String get understandIrreversible;

  /// No description provided for @allDataWillBeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Toutes mes données seront définitivement supprimées'**
  String get allDataWillBeDeleted;

  /// No description provided for @verificationCodeSentToEmail.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification a été envoyé à {email}'**
  String verificationCodeSentToEmail(String email);

  /// No description provided for @requestDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Demander la suppression'**
  String get requestDeletion;

  /// No description provided for @confirmDeletionWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletionWithCode;

  /// No description provided for @accountWillBeDeletedOn.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera supprimé le {date}. Vous avez 30 jours pour annuler cette action.'**
  String accountWillBeDeletedOn(String date);

  /// No description provided for @deleteListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liste'**
  String get deleteListTitle;

  /// No description provided for @sureToDeleteItem.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer'**
  String get sureToDeleteItem;

  /// No description provided for @sureToDeleteList.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer la liste'**
  String get sureToDeleteList;

  /// No description provided for @actionIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get actionIrreversible;

  /// No description provided for @actionIrreversibleDeletesAllItems.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible et supprimera tous les articles.'**
  String get actionIrreversibleDeletesAllItems;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @sureToDeleteItemFromList.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer \"{itemName}\" de votre liste ?'**
  String sureToDeleteItemFromList(String itemName);

  /// No description provided for @sureToLeaveQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter'**
  String get sureToLeaveQuestion;

  /// No description provided for @modifyItemInformation.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez les informations de votre article'**
  String get modifyItemInformation;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @modify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// No description provided for @fromYourList.
  ///
  /// In fr, this message translates to:
  /// **'de votre liste'**
  String get fromYourList;

  /// No description provided for @processing.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours...'**
  String get processing;

  /// No description provided for @verificationCodeSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification envoyé'**
  String get verificationCodeSentTitle;

  /// No description provided for @enterCodeReceived.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu'**
  String get enterCodeReceived;

  /// No description provided for @codeExpiresIn.
  ///
  /// In fr, this message translates to:
  /// **'Le code expire dans'**
  String get codeExpiresIn;

  /// No description provided for @hours.
  ///
  /// In fr, this message translates to:
  /// **'heures'**
  String get hours;

  /// No description provided for @checkEmailsAndSpam.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez vos emails et vos spams'**
  String get checkEmailsAndSpam;

  /// No description provided for @areYouSure.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr'**
  String get areYouSure;

  /// No description provided for @wantToDelete.
  ///
  /// In fr, this message translates to:
  /// **'de vouloir supprimer'**
  String get wantToDelete;

  /// No description provided for @wantToLeave.
  ///
  /// In fr, this message translates to:
  /// **'de vouloir quitter'**
  String get wantToLeave;

  /// No description provided for @thisAction.
  ///
  /// In fr, this message translates to:
  /// **'Cette action'**
  String get thisAction;

  /// No description provided for @isIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'est irréversible'**
  String get isIrreversible;

  /// No description provided for @andWillDelete.
  ///
  /// In fr, this message translates to:
  /// **'et supprimera'**
  String get andWillDelete;

  /// No description provided for @allItems.
  ///
  /// In fr, this message translates to:
  /// **'tous les articles'**
  String get allItems;

  /// No description provided for @codeIsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le code est requis'**
  String get codeIsRequired;

  /// No description provided for @invalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get invalidCode;

  /// No description provided for @codeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré'**
  String get codeExpired;

  /// No description provided for @editListName.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom'**
  String get editListName;

  /// No description provided for @modifyListName.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez le nom de votre liste d\'épicerie'**
  String get modifyListName;

  /// No description provided for @modifyPersonalInformation.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez vos informations personnelles'**
  String get modifyPersonalInformation;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @emailCannotBeModified.
  ///
  /// In fr, this message translates to:
  /// **'L\'email ne peut pas être modifié'**
  String get emailCannotBeModified;

  /// No description provided for @firstNameAndLastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom et le nom sont obligatoires'**
  String get firstNameAndLastNameRequired;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter de votre compte ?'**
  String get confirmLogoutMessage;

  /// No description provided for @manageAccountSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Gérez la sécurité de votre compte'**
  String get manageAccountSecurity;

  /// No description provided for @changePasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordDescription.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez votre mot de passe actuel'**
  String get changePasswordDescription;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In fr, this message translates to:
  /// **'Supprimez définitivement votre compte'**
  String get deleteAccountDescription;

  /// No description provided for @newPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordTitle;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailAddress;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordMustBeSixCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordMustBeSixCharacters;

  /// No description provided for @youWillReceiveVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez un code de vérification à 6 chiffres'**
  String get youWillReceiveVerificationCode;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @allFieldsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Tous les champs sont obligatoires'**
  String get allFieldsRequired;

  /// No description provided for @emailFormatInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'email invalide'**
  String get emailFormatInvalid;

  /// No description provided for @confirmDeletionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletionTitle;

  /// No description provided for @enterCodeToConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu par email pour confirmer'**
  String get enterCodeToConfirm;

  /// No description provided for @actionIrreversibleAllDataDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront supprimées.'**
  String get actionIrreversibleAllDataDeleted;

  /// No description provided for @reasonForDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Raison de la suppression (optionnel)'**
  String get reasonForDeletion;

  /// No description provided for @codeSentCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé ! Vérifiez votre boîte email.'**
  String get codeSentCheckEmail;

  /// No description provided for @deletionCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de suppression'**
  String get deletionCode;

  /// No description provided for @actionDefinitiveAccountDeleted30Days.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Votre compte sera supprimé dans 30 jours.'**
  String get actionDefinitiveAccountDeleted30Days;

  /// No description provided for @accountDeletedIn30DaysCanCancel.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action pendant cette période.'**
  String get accountDeletedIn30DaysCanCancel;

  /// No description provided for @accountDeletionCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code de suppression envoyé ! Vérifiez votre email.'**
  String get accountDeletionCodeSent;

  /// No description provided for @listCreatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Liste créée avec succès'**
  String get listCreatedSuccessfully;

  /// No description provided for @listUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Liste modifiée avec succès'**
  String get listUpdatedSuccessfully;

  /// No description provided for @listDeletedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Liste supprimée avec succès'**
  String get listDeletedSuccessfully;

  /// No description provided for @listDuplicatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Liste dupliquée avec succès'**
  String get listDuplicatedSuccessfully;

  /// No description provided for @listsLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Listes chargées avec succès'**
  String get listsLoadedSuccessfully;

  /// No description provided for @operationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Opération réussie'**
  String get operationSuccess;

  /// No description provided for @listNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Liste non trouvée'**
  String get listNotFound;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur'**
  String get serverError;

  /// No description provided for @itemAddedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Article ajouté avec succès'**
  String get itemAddedSuccessfully;

  /// No description provided for @itemUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Article mis à jour avec succès'**
  String get itemUpdatedSuccessfully;

  /// No description provided for @itemDeletedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Article supprimé avec succès'**
  String get itemDeletedSuccessfully;

  /// No description provided for @itemStatusUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Statut mis à jour avec succès'**
  String get itemStatusUpdatedSuccessfully;

  /// No description provided for @itemsLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Articles chargés avec succès'**
  String get itemsLoadedSuccessfully;

  /// No description provided for @errorLoadingItems.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des articles'**
  String get errorLoadingItems;

  /// No description provided for @errorAddingItem.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout de l\'article'**
  String get errorAddingItem;

  /// No description provided for @errorUpdatingItem.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour de l\'article'**
  String get errorUpdatingItem;

  /// No description provided for @errorDeletingItem.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression de l\'article'**
  String get errorDeletingItem;

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour du statut'**
  String get errorUpdatingStatus;

  /// No description provided for @invitationReceived.
  ///
  /// In fr, this message translates to:
  /// **'Invitation reçue !'**
  String get invitationReceived;

  /// No description provided for @loginRequiredForInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise pour accéder à l\'invitation'**
  String get loginRequiredForInvitation;

  /// No description provided for @invalidShareLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage invalide'**
  String get invalidShareLink;

  /// No description provided for @errorOpeningInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ouverture de l\'invitation'**
  String get errorOpeningInvitation;

  /// No description provided for @cannotOpenInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'invitation'**
  String get cannotOpenInvitation;

  /// No description provided for @authSuccessNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Authentification réussie, navigation vers l\'invitation'**
  String get authSuccessNavigation;

  /// No description provided for @invitationEpiList.
  ///
  /// In fr, this message translates to:
  /// **'Invitation EpiList'**
  String get invitationEpiList;

  /// No description provided for @invitationSubject.
  ///
  /// In fr, this message translates to:
  /// **'Invitation à partager une liste d\'épicerie - EpiList'**
  String get invitationSubject;

  /// No description provided for @invitationMessage.
  ///
  /// In fr, this message translates to:
  /// **'{owner} vous invite sur \"{listName}\"'**
  String invitationMessage(String owner, String listName);

  /// No description provided for @directLinkRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Lien direct EpiList (recommandé)'**
  String get directLinkRecommended;

  /// No description provided for @orViaBrowser.
  ///
  /// In fr, this message translates to:
  /// **'Ou via navigateur'**
  String get orViaBrowser;

  /// No description provided for @directLinkAutoOpen.
  ///
  /// In fr, this message translates to:
  /// **'Le lien direct ouvrira automatiquement l\'app !'**
  String get directLinkAutoOpen;

  /// No description provided for @clickToOpenEpiList.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez pour ouvrir EpiList'**
  String get clickToOpenEpiList;

  /// No description provided for @appWillOpenAutomatically.
  ///
  /// In fr, this message translates to:
  /// **'L\'app s\'ouvrira automatiquement !'**
  String get appWillOpenAutomatically;

  /// No description provided for @sharedListsLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Listes partagées chargées avec succès'**
  String get sharedListsLoadedSuccessfully;

  /// No description provided for @sharesLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Partages chargés avec succès'**
  String get sharesLoadedSuccessfully;

  /// No description provided for @invitationLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Invitation chargée avec succès'**
  String get invitationLoadedSuccessfully;

  /// No description provided for @invitationAcceptedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Invitation acceptée avec succès'**
  String get invitationAcceptedSuccessfully;

  /// No description provided for @invitationDeclinedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Invitation refusée avec succès'**
  String get invitationDeclinedSuccessfully;

  /// No description provided for @permissionsUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Permissions mises à jour avec succès'**
  String get permissionsUpdatedSuccessfully;

  /// No description provided for @shareRevokedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Partage révoqué avec succès'**
  String get shareRevokedSuccessfully;

  /// No description provided for @leftSharedListSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté la liste partagée'**
  String get leftSharedListSuccessfully;

  /// No description provided for @allShareLinksRevokedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Tous les liens de partage ont été révoqués'**
  String get allShareLinksRevokedSuccessfully;

  /// No description provided for @errorLoadingSharedLists.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des listes partagées'**
  String get errorLoadingSharedLists;

  /// No description provided for @errorLoadingShares.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des partages'**
  String get errorLoadingShares;

  /// No description provided for @errorCreatingShareLink.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création du lien de partage'**
  String get errorCreatingShareLink;

  /// No description provided for @invalidOrExpiredInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Invitation invalide ou expirée'**
  String get invalidOrExpiredInvitation;

  /// No description provided for @errorAcceptingInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'acceptation de l\'invitation'**
  String get errorAcceptingInvitation;

  /// No description provided for @errorDecliningInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du refus de l\'invitation'**
  String get errorDecliningInvitation;

  /// No description provided for @errorUpdatingPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour des permissions'**
  String get errorUpdatingPermissions;

  /// No description provided for @errorRevokingShare.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la révocation du partage'**
  String get errorRevokingShare;

  /// No description provided for @errorLeavingList.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sortie de la liste'**
  String get errorLeavingList;

  /// No description provided for @errorRevokingLinks.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la révocation des liens'**
  String get errorRevokingLinks;

  /// No description provided for @operationSuccessful.
  ///
  /// In fr, this message translates to:
  /// **'Opération réussie'**
  String get operationSuccessful;

  /// No description provided for @anErrorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get anErrorOccurred;

  /// No description provided for @noInternetConnection.
  ///
  /// In fr, this message translates to:
  /// **'Aucune connexion Internet'**
  String get noInternetConnection;

  /// No description provided for @noInternetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté à Internet pour utiliser cette application. Veuillez vérifier votre connexion et réessayer.'**
  String get noInternetMessage;

  /// No description provided for @connectionTips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils :'**
  String get connectionTips;

  /// No description provided for @checkWifiConnection.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion Wi-Fi'**
  String get checkWifiConnection;

  /// No description provided for @checkMobileData.
  ///
  /// In fr, this message translates to:
  /// **'Activez vos données mobiles'**
  String get checkMobileData;

  /// No description provided for @restartRouter.
  ///
  /// In fr, this message translates to:
  /// **'Redémarrez votre routeur si nécessaire'**
  String get restartRouter;

  /// No description provided for @offlineMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne - Connexion requise'**
  String get offlineMode;

  /// No description provided for @backOnline.
  ///
  /// In fr, this message translates to:
  /// **'Connexion rétablie !'**
  String get backOnline;

  /// No description provided for @connectionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Internet requise'**
  String get connectionRequired;

  /// No description provided for @connectionRequiredForInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Internet requise pour ouvrir l\'invitation'**
  String get connectionRequiredForInvitation;

  /// No description provided for @productSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions de produits'**
  String get productSuggestions;

  /// No description provided for @noSuggestionsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion trouvée'**
  String get noSuggestionsFound;

  /// No description provided for @searchingSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de suggestions...'**
  String get searchingSuggestions;

  /// No description provided for @usedOnce.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé 1 fois'**
  String get usedOnce;

  /// No description provided for @usedXTimes.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé {count} fois'**
  String usedXTimes(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {weeks} semaine{plural}'**
  String weeksAgo(int weeks, String plural);

  /// No description provided for @monthsAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {months} mois'**
  String monthsAgo(int months, Object plural);

  /// No description provided for @suggestionWithDate.
  ///
  /// In fr, this message translates to:
  /// **'{usage} • {date}'**
  String suggestionWithDate(String usage, String date);

  /// No description provided for @suggestionSelected.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion sélectionnée'**
  String get suggestionSelected;

  /// No description provided for @clearSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la suggestion'**
  String get clearSuggestion;

  /// No description provided for @popularSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions populaires'**
  String get popularSuggestions;

  /// No description provided for @recentSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions récentes'**
  String get recentSuggestions;

  /// No description provided for @manageSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les suggestions'**
  String get manageSuggestions;

  /// No description provided for @deleteSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la suggestion'**
  String get deleteSuggestion;

  /// No description provided for @deleteSuggestionConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette suggestion ?'**
  String get deleteSuggestionConfirm;

  /// No description provided for @clearAllSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer toutes les suggestions'**
  String get clearAllSuggestions;

  /// No description provided for @clearAllSuggestionsConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer toutes vos suggestions ? Cette action est irréversible.'**
  String get clearAllSuggestionsConfirm;

  /// No description provided for @suggestionsCleared.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les suggestions ont été supprimées'**
  String get suggestionsCleared;

  /// No description provided for @errorLoadingSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des suggestions'**
  String get errorLoadingSuggestions;

  /// No description provided for @errorSavingSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde de la suggestion'**
  String get errorSavingSuggestion;

  /// No description provided for @suggestionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion sauvegardée'**
  String get suggestionSaved;

  /// No description provided for @noSuggestionsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion pour le moment'**
  String get noSuggestionsYet;

  /// No description provided for @startTypingForSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Commencez à taper pour voir vos suggestions'**
  String get startTypingForSuggestions;

  /// No description provided for @basedOnHistory.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur votre historique'**
  String get basedOnHistory;

  /// No description provided for @autoComplete.
  ///
  /// In fr, this message translates to:
  /// **'Saisie automatique'**
  String get autoComplete;

  /// No description provided for @suggestionHelper.
  ///
  /// In fr, this message translates to:
  /// **'Vos produits fréquents apparaîtront ici'**
  String get suggestionHelper;

  /// No description provided for @lastUsed.
  ///
  /// In fr, this message translates to:
  /// **'Dernière utilisation'**
  String get lastUsed;

  /// No description provided for @suggestionDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion supprimée'**
  String get suggestionDeleted;

  /// No description provided for @totalSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Total des suggestions'**
  String get totalSuggestions;

  /// No description provided for @mostUsedSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion la plus utilisée'**
  String get mostUsedSuggestion;

  /// No description provided for @recentlyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Récemment ajouté'**
  String get recentlyAdded;

  /// No description provided for @neverUsed.
  ///
  /// In fr, this message translates to:
  /// **'Jamais utilisé'**
  String get neverUsed;

  /// No description provided for @usageStatistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques d\'utilisation'**
  String get usageStatistics;

  /// No description provided for @averageUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation moyenne'**
  String get averageUsage;

  /// No description provided for @oldestSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion la plus ancienne'**
  String get oldestSuggestion;

  /// No description provided for @newestSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion la plus récente'**
  String get newestSuggestion;

  /// No description provided for @exportSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les suggestions'**
  String get exportSuggestions;

  /// No description provided for @importSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Importer les suggestions'**
  String get importSuggestions;

  /// No description provided for @suggestionSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres des suggestions'**
  String get suggestionSettings;

  /// No description provided for @enableAutoSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Activer les suggestions automatiques'**
  String get enableAutoSuggestions;

  /// No description provided for @suggestionThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil de suggestions'**
  String get suggestionThreshold;

  /// No description provided for @maxSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximum de suggestions'**
  String get maxSuggestions;

  /// No description provided for @clearOldSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer les anciennes suggestions'**
  String get clearOldSuggestions;

  /// No description provided for @suggestionsOlderThan.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions plus anciennes que'**
  String get suggestionsOlderThan;

  /// No description provided for @oneMonth.
  ///
  /// In fr, this message translates to:
  /// **'1 mois'**
  String get oneMonth;

  /// No description provided for @threeMonths.
  ///
  /// In fr, this message translates to:
  /// **'3 mois'**
  String get threeMonths;

  /// No description provided for @sixMonths.
  ///
  /// In fr, this message translates to:
  /// **'6 mois'**
  String get sixMonths;

  /// No description provided for @oneYear.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get oneYear;

  /// No description provided for @cleanupCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage terminé'**
  String get cleanupCompleted;

  /// No description provided for @suggestionsOptimized.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions optimisées'**
  String get suggestionsOptimized;

  /// No description provided for @backupSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder les suggestions'**
  String get backupSuggestions;

  /// No description provided for @restoreSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer les suggestions'**
  String get restoreSuggestions;

  /// No description provided for @suggestionBackupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée avec succès'**
  String get suggestionBackupCreated;

  /// No description provided for @suggestionBackupRestored.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions restaurées avec succès'**
  String get suggestionBackupRestored;

  /// No description provided for @noBackupFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde trouvée'**
  String get noBackupFound;

  /// No description provided for @suggestionTips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour les suggestions'**
  String get suggestionTips;

  /// No description provided for @tipMoreUsage.
  ///
  /// In fr, this message translates to:
  /// **'Plus vous utilisez l\'app, meilleures sont les suggestions'**
  String get tipMoreUsage;

  /// No description provided for @tipRegularUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Les suggestions se mettent à jour automatiquement'**
  String get tipRegularUpdates;

  /// No description provided for @tipPersonalized.
  ///
  /// In fr, this message translates to:
  /// **'Vos suggestions sont uniques et personnalisées'**
  String get tipPersonalized;

  /// Format d'affichage du prix
  ///
  /// In fr, this message translates to:
  /// **'{price} \$CAD'**
  String priceFormat(String price);

  /// Texte affiché quand aucun magasin n'est spécifié
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin spécifié'**
  String get noStoreSpecified;

  /// Texte affiché quand aucun prix n'est défini
  ///
  /// In fr, this message translates to:
  /// **'Prix non défini'**
  String get noPriceSet;

  /// Description complète d'une suggestion
  ///
  /// In fr, this message translates to:
  /// **'{name} - {usage} - {price} - {store}'**
  String suggestionDescription(
    String name,
    String usage,
    String price,
    String store,
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
