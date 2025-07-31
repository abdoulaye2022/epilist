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
  /// **'Partagée par {userName}'**
  String sharedBy(String userName);

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
  /// **'Information'**
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
  /// **'total'**
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

  /// No description provided for @similarItemDetected.
  ///
  /// In fr, this message translates to:
  /// **'Article similaire détecté'**
  String get similarItemDetected;

  /// No description provided for @itemToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Article à ajouter'**
  String get itemToAdd;

  /// No description provided for @product.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get product;

  /// No description provided for @store.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get store;

  /// No description provided for @similarItemsFound.
  ///
  /// In fr, this message translates to:
  /// **'Articles similaires trouvés'**
  String get similarItemsFound;

  /// No description provided for @identical.
  ///
  /// In fr, this message translates to:
  /// **'Identique'**
  String get identical;

  /// No description provided for @similar.
  ///
  /// In fr, this message translates to:
  /// **'Similaire'**
  String get similar;

  /// No description provided for @mergeWithExisting.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner avec l\'existant'**
  String get mergeWithExisting;

  /// No description provided for @addAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter quand même'**
  String get addAnyway;

  /// No description provided for @duplicateDetectedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons trouvé des articles similaires dans votre liste.'**
  String get duplicateDetectedMessage;

  /// No description provided for @noSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noSearchResults;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Essayez avec d\'autres mots-clés'**
  String get tryDifferentKeywords;

  /// No description provided for @suggestionsWillAppearAfterShopping.
  ///
  /// In fr, this message translates to:
  /// **'Les suggestions apparaîtront après vos achats'**
  String get suggestionsWillAppearAfterShopping;

  /// No description provided for @startShopping.
  ///
  /// In fr, this message translates to:
  /// **'Commencer mes achats'**
  String get startShopping;

  /// No description provided for @searchTips.
  ///
  /// In fr, this message translates to:
  /// **'Essayez des termes plus généraux ou vérifiez l\'orthographe'**
  String get searchTips;

  /// No description provided for @suggestionsBasedOnUsage.
  ///
  /// In fr, this message translates to:
  /// **'Les suggestions se basent sur vos habitudes d\'achat'**
  String get suggestionsBasedOnUsage;

  /// No description provided for @scheduleReminder.
  ///
  /// In fr, this message translates to:
  /// **'Programmer un rappel'**
  String get scheduleReminder;

  /// No description provided for @remindIn2Hours.
  ///
  /// In fr, this message translates to:
  /// **'Rappel dans 2h'**
  String get remindIn2Hours;

  /// No description provided for @remindTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Rappel demain'**
  String get remindTomorrow;

  /// No description provided for @viewReminders.
  ///
  /// In fr, this message translates to:
  /// **'Voir les rappels'**
  String get viewReminders;

  /// No description provided for @cancelReminders.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les rappels'**
  String get cancelReminders;

  /// No description provided for @scheduledReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels programmés'**
  String get scheduledReminders;

  /// No description provided for @noRemindersScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel programmé'**
  String get noRemindersScheduled;

  /// No description provided for @reminderScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Rappel programmé avec succès'**
  String get reminderScheduled;

  /// No description provided for @reminderScheduledFor.
  ///
  /// In fr, this message translates to:
  /// **'Rappel programmé pour'**
  String get reminderScheduledFor;

  /// No description provided for @reminderCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Rappel annulé'**
  String get reminderCancelled;

  /// No description provided for @allRemindersCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Tous les rappels annulés'**
  String get allRemindersCancelled;

  /// No description provided for @errorSchedulingReminder.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la programmation du rappel'**
  String get errorSchedulingReminder;

  /// No description provided for @errorLoadingReminders.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des rappels'**
  String get errorLoadingReminders;

  /// No description provided for @errorCancellingReminder.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'annulation du rappel'**
  String get errorCancellingReminder;

  /// No description provided for @errorCancellingReminders.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'annulation des rappels'**
  String get errorCancellingReminders;

  /// No description provided for @cancelAllReminders.
  ///
  /// In fr, this message translates to:
  /// **'Annuler tous les rappels'**
  String get cancelAllReminders;

  /// No description provided for @cancelAllRemindersConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment annuler tous les rappels pour cette liste ?'**
  String get cancelAllRemindersConfirm;

  /// No description provided for @cancelAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout annuler'**
  String get cancelAll;

  /// No description provided for @addReminder.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un rappel'**
  String get addReminder;

  /// No description provided for @quickOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options rapides'**
  String get quickOptions;

  /// No description provided for @customDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure personnalisées'**
  String get customDateTime;

  /// No description provided for @storeName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du magasin'**
  String get storeName;

  /// No description provided for @storeNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Provigo, IGA, Metro...'**
  String get storeNameHint;

  /// No description provided for @customMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message personnalisé'**
  String get customMessage;

  /// No description provided for @customMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Message personnalisé pour le rappel'**
  String get customMessageHint;

  /// No description provided for @selectDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner date et heure'**
  String get selectDateTime;

  /// No description provided for @in2Hours.
  ///
  /// In fr, this message translates to:
  /// **'Dans 2h'**
  String get in2Hours;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @thisWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Ce weekend'**
  String get thisWeekend;

  /// No description provided for @allOfAbove.
  ///
  /// In fr, this message translates to:
  /// **'Tous les ci-dessus'**
  String get allOfAbove;

  /// No description provided for @inHours.
  ///
  /// In fr, this message translates to:
  /// **'Dans {hours} heures'**
  String inHours(int hours);

  /// No description provided for @showingXOfY.
  ///
  /// In fr, this message translates to:
  /// **'Affichage de {x} sur {y} listes'**
  String showingXOfY(int x, int y);

  /// No description provided for @optionalFields.
  ///
  /// In fr, this message translates to:
  /// **'Champs optionnels'**
  String get optionalFields;

  /// No description provided for @aboutMission.
  ///
  /// In fr, this message translates to:
  /// **'Notre Mission'**
  String get aboutMission;

  /// No description provided for @aboutMissionText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList révolutionne la façon dont vous gérez vos courses. Créez des listes intelligentes, suivez vos dépenses en temps réel, partagez avec votre famille et ne manquez plus jamais un article important grâce à notre système de gestion collaborative.'**
  String get aboutMissionText;

  /// No description provided for @aboutFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalités principales'**
  String get aboutFeatures;

  /// No description provided for @aboutFeaturesText.
  ///
  /// In fr, this message translates to:
  /// **'• Création de compte sécurisée (prénom, nom, email)\n• Listes d\'épicerie personnalisées et intelligentes\n• Ajout d\'articles avec quantité, prix et magasin\n• Calcul automatique des totaux et pourcentages\n• Marquage en temps réel des articles achetés\n• Duplication rapide des listes existantes\n• Partage sécurisé via liens avec permissions\n• Gestion des droits (lecture, édition, administration)\n• Synchronisation sur tous vos appareils\n• Interface moderne et intuitive'**
  String get aboutFeaturesText;

  /// No description provided for @aboutCollaboration.
  ///
  /// In fr, this message translates to:
  /// **'Collaboration familiale'**
  String get aboutCollaboration;

  /// No description provided for @aboutCollaborationText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList facilite les courses en famille avec son système de partage avancé. Partagez vos listes d\'un simple lien, définissez qui peut voir, modifier ou administrer chaque liste. Tout le monde reste synchronisé en temps réel!'**
  String get aboutCollaborationText;

  /// No description provided for @aboutDevelopment.
  ///
  /// In fr, this message translates to:
  /// **'Développement'**
  String get aboutDevelopment;

  /// No description provided for @aboutDevelopmentText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList est développé avec passion par M2atech Solutions Inc. pour vous offrir la meilleure expérience de gestion d\'épicerie. Nous sommes constamment à l\'écoute de vos retours pour améliorer l\'app et ajouter de nouvelles fonctionnalités innovantes.'**
  String get aboutDevelopmentText;

  /// No description provided for @aboutContact.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get aboutContact;

  /// No description provided for @aboutRateApp.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer l\'app'**
  String get aboutRateApp;

  /// No description provided for @aboutShareApp.
  ///
  /// In fr, this message translates to:
  /// **'Partager EpiList'**
  String get aboutShareApp;

  /// No description provided for @aboutWebsite.
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get aboutWebsite;

  /// No description provided for @aboutRightsReserved.
  ///
  /// In fr, this message translates to:
  /// **'Tous droits réservés.'**
  String get aboutRightsReserved;

  /// No description provided for @aboutDevelopedWith.
  ///
  /// In fr, this message translates to:
  /// **'Développé avec'**
  String get aboutDevelopedWith;

  /// No description provided for @aboutByCompany.
  ///
  /// In fr, this message translates to:
  /// **'par M2atech Solutions Inc.'**
  String get aboutByCompany;

  /// No description provided for @aboutContactError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien de contact'**
  String get aboutContactError;

  /// No description provided for @aboutWebsiteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le site web'**
  String get aboutWebsiteError;

  /// No description provided for @aboutStoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Magasin indisponible. Évaluez EpiList sur votre magasin habituel!'**
  String get aboutStoreUnavailable;

  /// No description provided for @aboutStoreError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le magasin pour le moment'**
  String get aboutStoreError;

  /// No description provided for @aboutShareDescription.
  ///
  /// In fr, this message translates to:
  /// **'Organisez vos courses en famille avec EpiList! Listes partagées, calculs automatiques, synchronisation temps réel.'**
  String get aboutShareDescription;

  /// No description provided for @aboutDiscoverApp.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez l\'app'**
  String get aboutDiscoverApp;

  /// No description provided for @aboutShareSubject.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez EpiList - Votre assistant épicerie familial!'**
  String get aboutShareSubject;

  /// No description provided for @aboutShareError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de partager pour le moment'**
  String get aboutShareError;

  /// No description provided for @termsLastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 5 juillet 2025'**
  String get termsLastUpdated;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'1. Acceptation des conditions'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptanceText.
  ///
  /// In fr, this message translates to:
  /// **'En utilisant l\'application EpiList, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions dans leur intégralité, veuillez ne pas utiliser l\'application.'**
  String get termsAcceptanceText;

  /// No description provided for @termsServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'2. Description du service'**
  String get termsServiceTitle;

  /// No description provided for @termsServiceText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList est une application mobile de gestion de listes d\'épicerie qui permet :\n\n• Créer un compte avec prénom, nom, email et mot de passe\n• Créer, modifier et supprimer des listes d\'épicerie\n• Ajouter des articles avec nom, quantité, prix et magasin (optionnel)\n• Marquer les articles comme achetés ou les supprimer\n• Calculer automatiquement les totaux et pourcentages d\'achats\n• Dupliquer les listes existantes\n• Partager les listes avec des liens sécurisés\n• Gérer les permissions d\'accès (lecture, édition, administration)\n\nLe service est fourni \"en l\'état\" et \"selon disponibilité\".'**
  String get termsServiceText;

  /// No description provided for @termsAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'3. Compte utilisateur et sécurité'**
  String get termsAccountTitle;

  /// No description provided for @termsAccountText.
  ///
  /// In fr, this message translates to:
  /// **'Pour utiliser EpiList, vous devez :\n\n• Créer un compte avec des informations exactes (prénom, nom, email)\n• Choisir un mot de passe sécurisé et le garder confidentiel\n• Être responsable de toutes les activités effectuées sous votre compte\n• Nous notifier immédiatement de toute utilisation non autorisée\n• Mettre à jour vos informations personnelles si nécessaire\n\nVous êtes seul responsable de la sécurité de vos identifiants de connexion.'**
  String get termsAccountText;

  /// No description provided for @termsUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'4. Utilisation des listes et partage'**
  String get termsUsageTitle;

  /// No description provided for @termsUsageText.
  ///
  /// In fr, this message translates to:
  /// **'Concernant l\'utilisation des fonctionnalités de l\'application :\n\n• Vous pouvez créer des listes d\'épicerie illimitées\n• Les liens de partage sont de votre responsabilité\n• Vous contrôlez les permissions d\'accès que vous accordez\n• Les personnes invitées doivent respecter les permissions définies\n• Vous pouvez révoquer l\'accès à tout moment\n• Le contenu partagé doit rester approprié et légal\n\nVous êtes responsable de la gestion de vos listes partagées.'**
  String get termsUsageText;

  /// No description provided for @termsAcceptableTitle.
  ///
  /// In fr, this message translates to:
  /// **'5. Utilisation acceptable'**
  String get termsAcceptableTitle;

  /// No description provided for @termsAcceptableText.
  ///
  /// In fr, this message translates to:
  /// **'Vous acceptez de :\n\n• Utiliser l\'application uniquement pour la gestion de listes d\'épicerie\n• Ne pas tenter de perturber le fonctionnement du service\n• Ne pas accéder illégalement aux données d\'autres utilisateurs\n• Respecter les droits de propriété intellectuelle\n• Ne pas utiliser l\'application à des fins commerciales sans autorisation\n• Ne pas partager de contenu offensant ou illégal\n\nToute utilisation abusive peut entraîner une suspension immédiate du compte.'**
  String get termsAcceptableText;

  /// No description provided for @termsOwnershipTitle.
  ///
  /// In fr, this message translates to:
  /// **'6. Propriété du contenu'**
  String get termsOwnershipTitle;

  /// No description provided for @termsOwnershipText.
  ///
  /// In fr, this message translates to:
  /// **'Concernant le contenu que vous créez dans EpiList :\n\n• Vous conservez la propriété de vos listes et données personnelles\n• Vous nous accordez une licence limitée pour fournir le service\n• Vous êtes responsable de l\'exactitude de vos informations\n• Nous ne revendiquons aucun droit sur vos données personnelles\n• Vous pouvez exporter vos données à tout moment\n\nVos données vous appartiennent et restent sous votre contrôle.'**
  String get termsOwnershipText;

  /// No description provided for @termsCalculationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'7. Calculs et prix'**
  String get termsCalculationsTitle;

  /// No description provided for @termsCalculationsText.
  ///
  /// In fr, this message translates to:
  /// **'Concernant les fonctionnalités de calcul :\n\n• Les totaux et pourcentages sont calculés automatiquement\n• Nous ne garantissons pas l\'exactitude absolue des calculs\n• Les prix saisis sont de votre responsabilité\n• Vérifiez toujours les calculs pour vos achats importants\n• Nous ne sommes pas responsables des erreurs de prix\n\nUtilisez les calculs comme aide, pas comme référence absolue.'**
  String get termsCalculationsText;

  /// No description provided for @termsAvailabilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'8. Disponibilité du service'**
  String get termsAvailabilityTitle;

  /// No description provided for @termsAvailabilityText.
  ///
  /// In fr, this message translates to:
  /// **'Nous nous efforçons d\'assurer une disponibilité continue du service, mais nous ne garantissons pas :\n\n• Un accès ininterrompu 24h/24\n• L\'absence complète de bugs ou d\'erreurs\n• La compatibilité avec tous les appareils\n• La sauvegarde permanente de toutes les données\n\nDes maintenances programmées peuvent causer des interruptions temporaires.'**
  String get termsAvailabilityText;

  /// No description provided for @termsLiabilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'9. Limitation de responsabilité'**
  String get termsLiabilityTitle;

  /// No description provided for @termsLiabilityText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList et ses développeurs ne peuvent être tenus responsables de :\n\n• Dommages indirects ou consécutifs\n• Perte de données due à des problèmes techniques\n• Erreurs dans les calculs de prix ou totaux\n• Utilisation incorrecte des informations fournies\n• Problèmes liés au partage de listes\n• Achats effectués basés sur les listes créées\n\nVotre utilisation de l\'application se fait à vos propres risques.'**
  String get termsLiabilityText;

  /// No description provided for @termsTerminationTitle.
  ///
  /// In fr, this message translates to:
  /// **'10. Suspension et résiliation'**
  String get termsTerminationTitle;

  /// No description provided for @termsTerminationText.
  ///
  /// In fr, this message translates to:
  /// **'Nous nous réservons le droit de suspendre ou résilier votre accès :\n\n• En cas de violation de ces conditions d\'utilisation\n• Pour des raisons de sécurité ou de maintenance\n• Si le compte est inactif depuis plus de 24 mois\n• En cas d\'utilisation abusive des fonctionnalités de partage\n\nVous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.'**
  String get termsTerminationText;

  /// No description provided for @termsModificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'11. Modifications'**
  String get termsModificationsTitle;

  /// No description provided for @termsModificationsText.
  ///
  /// In fr, this message translates to:
  /// **'Nous nous réservons le droit de :\n\n• Modifier ou améliorer les fonctionnalités de l\'application\n• Mettre à jour ces conditions d\'utilisation\n• Suspendre temporairement le service pour maintenance\n• Discontinuer définitivement le service avec préavis de 60 jours\n\nLes changements importants vous seront notifiés par email ou dans l\'application.'**
  String get termsModificationsText;

  /// No description provided for @termsJurisdictionTitle.
  ///
  /// In fr, this message translates to:
  /// **'12. Loi applicable et juridiction'**
  String get termsJurisdictionTitle;

  /// No description provided for @termsJurisdictionText.
  ///
  /// In fr, this message translates to:
  /// **'Ces conditions d\'utilisation sont régies par la loi canadienne. Tout litige relatif à l\'utilisation d\'EpiList sera soumis à la juridiction des tribunaux compétents du Nouveau-Brunswick, Canada.'**
  String get termsJurisdictionText;

  /// No description provided for @termsContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'13. Contact et support'**
  String get termsContactTitle;

  /// No description provided for @termsContactText.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question concernant ces conditions d\'utilisation ou pour de l\'assistance, veuillez nous contacter via notre site web.\n\nNous nous engageons à répondre le plus rapidement possible.'**
  String get termsContactText;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : 5 juillet 2025'**
  String get privacyLastUpdated;

  /// No description provided for @privacyCollectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'1. Collecte d\'informations'**
  String get privacyCollectionTitle;

  /// No description provided for @privacyCollectionText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList collecte les informations suivantes pour son fonctionnement :\n\n• Informations de compte : prénom, nom, email, mot de passe (chiffré)\n• Données de listes d\'épicerie : noms de listes, articles, quantités, prix, magasins (optionnel)\n• Données de partage : liens de partage, permissions d\'accès (lecture, édition, administration)\n• Données d\'utilisation : statut d\'achat des articles, totaux et calculs de pourcentages\n• Données techniques : journaux d\'erreurs, performance de l\'application\n\nNous ne collectons aucune information personnelle sensible au-delà de ce qui est nécessaire au fonctionnement.'**
  String get privacyCollectionText;

  /// No description provided for @privacyUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'2. Utilisation des données'**
  String get privacyUsageTitle;

  /// No description provided for @privacyUsageText.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont utilisées exclusivement pour :\n\n• Créer et gérer votre compte utilisateur\n• Créer, modifier et supprimer vos listes d\'épicerie\n• Calculer les totaux et pourcentages d\'articles achetés\n• Dupliquer vos listes existantes\n• Partager vos listes avec des membres de la famille ou amis via des liens sécurisés\n• Gérer les permissions d\'accès (lecture, édition, administration)\n• Synchroniser vos données sur tous vos appareils\n• Fournir un support technique\n\nNous ne vendons ni ne louons vos données personnelles à des tiers.'**
  String get privacyUsageText;

  /// No description provided for @privacyStorageTitle.
  ///
  /// In fr, this message translates to:
  /// **'3. Stockage et sécurité'**
  String get privacyStorageTitle;

  /// No description provided for @privacyStorageText.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont protégées par :\n\n• Stockage sécurisé sur nos serveurs avec chiffrement\n• Chiffrement des mots de passe avec des algorithmes sécurisés\n• Protection des données en transit et au repos\n• Liens de partage sécurisés avec contrôle d\'accès\n• Sauvegarde régulière de vos listes et données\n• Mesures de sécurité conformes aux standards de l\'industrie\n\nNous appliquons les meilleures pratiques de sécurité pour protéger vos informations.'**
  String get privacyStorageText;

  /// No description provided for @privacySharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'4. Partage des données'**
  String get privacySharingTitle;

  /// No description provided for @privacySharingText.
  ///
  /// In fr, this message translates to:
  /// **'Vos données personnelles ne sont partagées que dans les cas suivants :\n\n• Avec les personnes que vous autorisez via les liens de partage de listes\n• Avec nos prestataires de services techniques (hébergement, support)\n• Avec les autorités légales si requis par la loi\n\nLe partage de listes se fait selon les permissions que vous définissez :\n• Lecture seule : consultation des listes sans modification\n• Édition : ajout, suppression et modification d\'articles\n• Administration : gestion complète incluant suppression de listes\n\nAucun partage commercial de vos données n\'est effectué.'**
  String get privacySharingText;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'5. Vos droits'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRightsText.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez le droit de :\n\n• Accéder à toutes vos données personnelles\n• Modifier vos informations de compte (prénom, nom, email)\n• Supprimer votre compte et toutes les données associées\n• Exporter vos listes d\'épicerie\n• Révoquer les liens de partage à tout moment\n• Modifier les permissions d\'accès pour les utilisateurs invités\n• Supprimer vos listes ou articles individuellement\n\nContactez-nous pour exercer ces droits.'**
  String get privacyRightsText;

  /// No description provided for @privacyFeaturesTitle.
  ///
  /// In fr, this message translates to:
  /// **'6. Fonctionnalités de l\'application'**
  String get privacyFeaturesTitle;

  /// No description provided for @privacyFeaturesText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList traite vos données pour offrir les fonctionnalités suivantes :\n\n• Création et gestion de comptes utilisateurs\n• Création, duplication, modification et suppression de listes\n• Ajout d\'articles avec nom, quantité, prix et magasin (optionnel)\n• Marquage d\'articles comme achetés ou suppression d\'articles\n• Calcul automatique des totaux et pourcentages d\'achats\n• Génération de liens de partage sécurisés\n• Gestion des permissions d\'accès collaboratif\n\nToutes ces données restent sous votre contrôle.'**
  String get privacyFeaturesText;

  /// No description provided for @privacyCookiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'7. Cookies et technologies similaires'**
  String get privacyCookiesTitle;

  /// No description provided for @privacyCookiesText.
  ///
  /// In fr, this message translates to:
  /// **'EpiList utilise des technologies de suivi pour :\n\n• Maintenir votre session active\n• Mémoriser vos préférences d\'utilisation\n• Analyser l\'usage de l\'application (données anonymes)\n• Optimiser les performances de l\'application\n\nVous pouvez désactiver ces fonctions dans les paramètres de l\'application.'**
  String get privacyCookiesText;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In fr, this message translates to:
  /// **'8. Modifications'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesText.
  ///
  /// In fr, this message translates to:
  /// **'Cette politique peut être mise à jour pour refléter les évolutions de l\'application. Nous vous informerons des changements importants par :\n\n• Email à l\'adresse associée à votre compte\n• Mise à jour de la date en haut de cette politique\n\nVotre utilisation continue de l\'application après les changements constitue votre acceptation.'**
  String get privacyChangesText;

  /// No description provided for @privacyContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'9. Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactText.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question concernant cette politique de confidentialité ou vos données, veuillez nous contacter via notre site web.\n\nNous nous engageons à répondre dans les 48 heures ouvrables.'**
  String get privacyContactText;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get currency;

  /// No description provided for @currencies.
  ///
  /// In fr, this message translates to:
  /// **'Devises'**
  String get currencies;

  /// No description provided for @selectCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la devise'**
  String get selectCurrency;

  /// No description provided for @changeCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Changer la devise'**
  String get changeCurrency;

  /// No description provided for @currencySettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de devise'**
  String get currencySettings;

  /// No description provided for @currencyCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de devise'**
  String get currencyCode;

  /// No description provided for @currencySymbol.
  ///
  /// In fr, this message translates to:
  /// **'Symbole de devise'**
  String get currencySymbol;

  /// No description provided for @exchangeRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change'**
  String get exchangeRate;

  /// No description provided for @defaultCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise par défaut'**
  String get defaultCurrency;

  /// No description provided for @preferredCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise préférée'**
  String get preferredCurrency;

  /// No description provided for @currentCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise actuelle'**
  String get currentCurrency;

  /// No description provided for @noCurrencySet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune devise définie'**
  String get noCurrencySet;

  /// No description provided for @chooseCurrencyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre devise d\'affichage préférée'**
  String get chooseCurrencyDescription;

  /// No description provided for @manageCurrencyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos préférences de devise'**
  String get manageCurrencyDescription;

  /// No description provided for @currencyConversionInfo.
  ///
  /// In fr, this message translates to:
  /// **'Les prix seront automatiquement convertis dans votre devise'**
  String get currencyConversionInfo;

  /// No description provided for @showPopularOnly.
  ///
  /// In fr, this message translates to:
  /// **'Afficher seulement les devises populaires'**
  String get showPopularOnly;

  /// No description provided for @convertPrices.
  ///
  /// In fr, this message translates to:
  /// **'Convertir les prix'**
  String get convertPrices;

  /// No description provided for @viewInLocalCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Voir en devise locale'**
  String get viewInLocalCurrency;

  /// No description provided for @formatUserAmount.
  ///
  /// In fr, this message translates to:
  /// **'Formater le montant'**
  String get formatUserAmount;

  /// No description provided for @updateCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la devise'**
  String get updateCurrency;

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @each.
  ///
  /// In fr, this message translates to:
  /// **'chacun'**
  String get each;

  /// No description provided for @unitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get unitPrice;

  /// No description provided for @totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix total'**
  String get totalPrice;

  /// No description provided for @formattedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix formaté'**
  String get formattedPrice;

  /// No description provided for @originalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant original'**
  String get originalAmount;

  /// No description provided for @convertedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant converti'**
  String get convertedAmount;

  /// No description provided for @exchangeRateToCAD.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change vers CAD'**
  String get exchangeRateToCAD;

  /// No description provided for @popularCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Devises populaires'**
  String get popularCurrencies;

  /// No description provided for @allCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les devises'**
  String get allCurrencies;

  /// No description provided for @supportedCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Devises supportées'**
  String get supportedCurrencies;

  /// No description provided for @currencyNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Devise non trouvée'**
  String get currencyNotFound;

  /// No description provided for @invalidCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise invalide'**
  String get invalidCurrency;

  /// No description provided for @currencyUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la mise à jour de la devise'**
  String get currencyUpdateFailed;

  /// No description provided for @conversionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la conversion de devise'**
  String get conversionFailed;

  /// No description provided for @exchangeRateNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change non disponible'**
  String get exchangeRateNotAvailable;

  /// No description provided for @currencyUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Devise mise à jour avec succès'**
  String get currencyUpdatedSuccessfully;

  /// No description provided for @currencySelectedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Devise sélectionnée avec succès'**
  String get currencySelectedSuccessfully;

  /// No description provided for @conversionSuccessful.
  ///
  /// In fr, this message translates to:
  /// **'Conversion réussie'**
  String get conversionSuccessful;

  /// No description provided for @currencyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de devise'**
  String get currencyInfo;

  /// No description provided for @rateLastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Taux mis à jour le'**
  String get rateLastUpdated;

  /// No description provided for @basedOnCAD.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur le Dollar Canadien (CAD)'**
  String get basedOnCAD;

  /// No description provided for @exchangeRateDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Les taux de change sont donnés à titre indicatif'**
  String get exchangeRateDisclaimer;

  /// No description provided for @priceInCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Prix en {currency}'**
  String priceInCurrency(String currency);

  /// No description provided for @amountInCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Montant en {currency}'**
  String amountInCurrency(String currency);

  /// No description provided for @convertTo.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en {currency}'**
  String convertTo(String currency);

  /// No description provided for @oneXEqualsYCAD.
  ///
  /// In fr, this message translates to:
  /// **'1 {currency} = {rate} CAD'**
  String oneXEqualsYCAD(String currency, String rate);

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @currencySelectionDialog.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue de sélection de devise'**
  String get currencySelectionDialog;

  /// No description provided for @chooseCurrencyPreference.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre préférence de devise'**
  String get chooseCurrencyPreference;

  /// No description provided for @currencyDisplayOnly.
  ///
  /// In fr, this message translates to:
  /// **'Cette devise sera utilisée pour l\'affichage uniquement. Les prix ne sont pas convertis.'**
  String get currencyDisplayOnly;

  /// No description provided for @pricesNotConverted.
  ///
  /// In fr, this message translates to:
  /// **'Les prix ne sont pas convertis automatiquement'**
  String get pricesNotConverted;

  /// No description provided for @currentSelectedCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise actuellement sélectionnée'**
  String get currentSelectedCurrency;

  /// No description provided for @loadingCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des devises...'**
  String get loadingCurrencies;

  /// No description provided for @noCurrenciesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune devise disponible'**
  String get noCurrenciesAvailable;

  /// No description provided for @cannotLoadCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les devises depuis le serveur'**
  String get cannotLoadCurrencies;

  /// No description provided for @currencyUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Votre devise a été mise à jour avec succès'**
  String get currencyUpdated;

  /// No description provided for @confirmCurrencyChange.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le changement de devise'**
  String get confirmCurrencyChange;

  /// No description provided for @currencySettingsTile.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de devise'**
  String get currencySettingsTile;

  /// No description provided for @manageCurrencySettings.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les paramètres de devise'**
  String get manageCurrencySettings;

  /// No description provided for @defaultCurrencyCAD.
  ///
  /// In fr, this message translates to:
  /// **'CAD (par défaut)'**
  String get defaultCurrencyCAD;

  /// No description provided for @selectPreferredCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la devise préférée'**
  String get selectPreferredCurrency;

  /// No description provided for @currencySettingsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de devise mis à jour'**
  String get currencySettingsUpdated;

  /// No description provided for @selectYourCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre devise'**
  String get selectYourCurrency;

  /// No description provided for @chooseDisplayCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre devise d\'affichage'**
  String get chooseDisplayCurrency;

  /// No description provided for @currencyForPrices.
  ///
  /// In fr, this message translates to:
  /// **'Cette devise sera utilisée pour afficher les prix'**
  String get currencyForPrices;

  /// No description provided for @noCurrencySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune devise sélectionnée'**
  String get noCurrencySelected;

  /// No description provided for @popularCurrenciesOnly.
  ///
  /// In fr, this message translates to:
  /// **'Devises populaires uniquement'**
  String get popularCurrenciesOnly;

  /// No description provided for @allAvailableCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les devises disponibles'**
  String get allAvailableCurrencies;

  /// No description provided for @currencySelectionComplete.
  ///
  /// In fr, this message translates to:
  /// **'Sélection de devise terminée'**
  String get currencySelectionComplete;

  /// No description provided for @applyChanges.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les modifications'**
  String get applyChanges;

  /// No description provided for @discardChanges.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications'**
  String get discardChanges;

  /// No description provided for @popular.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get popular;

  /// No description provided for @analytics.
  ///
  /// In fr, this message translates to:
  /// **'Analyses'**
  String get analytics;

  /// No description provided for @overview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get overview;

  /// No description provided for @trends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances'**
  String get trends;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @topProducts.
  ///
  /// In fr, this message translates to:
  /// **'Top produits'**
  String get topProducts;

  /// No description provided for @userCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Ma devise'**
  String get userCurrency;

  /// No description provided for @noAnalyticsData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée d\'analyse disponible'**
  String get noAnalyticsData;

  /// No description provided for @loadData.
  ///
  /// In fr, this message translates to:
  /// **'Charger les données'**
  String get loadData;

  /// No description provided for @noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noDataAvailable;

  /// No description provided for @monthlyOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble mensuelle'**
  String get monthlyOverview;

  /// No description provided for @totalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total dépensé'**
  String get totalSpent;

  /// No description provided for @itemsPurchased.
  ///
  /// In fr, this message translates to:
  /// **'Articles achetés'**
  String get itemsPurchased;

  /// No description provided for @uniqueProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits uniques'**
  String get uniqueProducts;

  /// No description provided for @shoppingSessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions d\'achat'**
  String get shoppingSessions;

  /// No description provided for @quickStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques rapides'**
  String get quickStats;

  /// No description provided for @averageDailySpending.
  ///
  /// In fr, this message translates to:
  /// **'Dépense quotidienne moyenne'**
  String get averageDailySpending;

  /// No description provided for @busiestDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour le plus actif'**
  String get busiestDay;

  /// No description provided for @comparisonWithLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison avec le mois dernier'**
  String get comparisonWithLastMonth;

  /// No description provided for @spendingIncreased.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses augmentées'**
  String get spendingIncreased;

  /// No description provided for @spendingDecreased.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses diminuées'**
  String get spendingDecreased;

  /// No description provided for @spendingStable.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses stables'**
  String get spendingStable;

  /// No description provided for @spendingByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses par catégorie'**
  String get spendingByCategory;

  /// No description provided for @noCategoriesData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de catégorie'**
  String get noCategoriesData;

  /// No description provided for @monthlyTrends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances mensuelles'**
  String get monthlyTrends;

  /// No description provided for @monthlyAverage.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne mensuelle'**
  String get monthlyAverage;

  /// No description provided for @totalProducts.
  ///
  /// In fr, this message translates to:
  /// **'Total produits'**
  String get totalProducts;

  /// No description provided for @showing.
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get showing;

  /// No description provided for @noProductsData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de produit'**
  String get noProductsData;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @viewSpendingReports.
  ///
  /// In fr, this message translates to:
  /// **'Voir les rapports de dépenses'**
  String get viewSpendingReports;

  /// No description provided for @manageAllLists.
  ///
  /// In fr, this message translates to:
  /// **'Gérer toutes les listes'**
  String get manageAllLists;

  /// No description provided for @recentLists.
  ///
  /// In fr, this message translates to:
  /// **'Listes récentes ({count})'**
  String recentLists(Object count);

  /// No description provided for @items.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get items;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'fini'**
  String get done;

  /// No description provided for @shared.
  ///
  /// In fr, this message translates to:
  /// **'Partagée'**
  String get shared;

  /// No description provided for @sharedWithYou.
  ///
  /// In fr, this message translates to:
  /// **'Partagée avec vous'**
  String get sharedWithYou;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @sortByAmount.
  ///
  /// In fr, this message translates to:
  /// **'Trier par montant'**
  String get sortByAmount;

  /// No description provided for @sortByQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Par quantité'**
  String get sortByQuantity;

  /// No description provided for @sortByFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Par fréquence'**
  String get sortByFrequency;

  /// No description provided for @unknownProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit inconnu'**
  String get unknownProduct;

  /// No description provided for @itemsCount.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get itemsCount;

  /// No description provided for @storesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Magasins'**
  String get storesLabel;

  /// No description provided for @averagePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix moyen'**
  String get averagePrice;

  /// No description provided for @stores.
  ///
  /// In fr, this message translates to:
  /// **'Magasins'**
  String get stores;

  /// No description provided for @averagePriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix moyen'**
  String get averagePriceLabel;

  /// No description provided for @amountSort.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amountSort;

  /// No description provided for @quantitySort.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantitySort;

  /// No description provided for @frequencySort.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get frequencySort;

  /// No description provided for @loadingAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des analyses...'**
  String get loadingAnalytics;

  /// No description provided for @errorLoadingAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des analyses'**
  String get errorLoadingAnalytics;

  /// No description provided for @analyticsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Analyses indisponibles'**
  String get analyticsUnavailable;

  /// No description provided for @refreshAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les analyses'**
  String get refreshAnalytics;

  /// No description provided for @rank.
  ///
  /// In fr, this message translates to:
  /// **'Rang'**
  String get rank;

  /// No description provided for @ranking.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get ranking;

  /// No description provided for @position.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @topRanked.
  ///
  /// In fr, this message translates to:
  /// **'Mieux classé'**
  String get topRanked;

  /// No description provided for @mostPurchased.
  ///
  /// In fr, this message translates to:
  /// **'Plus acheté'**
  String get mostPurchased;

  /// No description provided for @frequentlyBought.
  ///
  /// In fr, this message translates to:
  /// **'Fréquemment acheté'**
  String get frequentlyBought;

  /// No description provided for @times.
  ///
  /// In fr, this message translates to:
  /// **'fois'**
  String get times;

  /// No description provided for @timesSingular.
  ///
  /// In fr, this message translates to:
  /// **'fois'**
  String get timesSingular;

  /// No description provided for @timesPlural.
  ///
  /// In fr, this message translates to:
  /// **'fois'**
  String get timesPlural;

  /// No description provided for @purchases.
  ///
  /// In fr, this message translates to:
  /// **'achats'**
  String get purchases;

  /// No description provided for @purchase.
  ///
  /// In fr, this message translates to:
  /// **'achat'**
  String get purchase;

  /// No description provided for @analyticsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'analyse'**
  String get analyticsError;

  /// No description provided for @noAnalyticsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune analyse disponible'**
  String get noAnalyticsAvailable;

  /// No description provided for @analyticsLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours...'**
  String get analyticsLoading;

  /// No description provided for @dataNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Données non disponibles'**
  String get dataNotAvailable;

  /// No description provided for @selectPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la période'**
  String get selectPeriod;

  /// No description provided for @changePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Changer la période'**
  String get changePeriod;

  /// No description provided for @daily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get yearly;

  /// No description provided for @period.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get period;

  /// No description provided for @timeframe.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get timeframe;

  /// No description provided for @chooseCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la devise'**
  String get chooseCurrency;

  /// No description provided for @displayCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise d\'affichage'**
  String get displayCurrency;

  /// No description provided for @currencyFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format de devise'**
  String get currencyFormat;

  /// No description provided for @viewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get viewDetails;

  /// No description provided for @showMore.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In fr, this message translates to:
  /// **'Afficher moins'**
  String get showLess;

  /// No description provided for @expandChart.
  ///
  /// In fr, this message translates to:
  /// **'Développer le graphique'**
  String get expandChart;

  /// No description provided for @collapseChart.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le graphique'**
  String get collapseChart;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @dataRange.
  ///
  /// In fr, this message translates to:
  /// **'Plage de données'**
  String get dataRange;

  /// No description provided for @noDataFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée trouvée'**
  String get noDataFound;

  /// No description provided for @insufficientData.
  ///
  /// In fr, this message translates to:
  /// **'Données insuffisantes'**
  String get insufficientData;

  /// No description provided for @calculatingData.
  ///
  /// In fr, this message translates to:
  /// **'Calcul des données...'**
  String get calculatingData;

  /// No description provided for @networkErrorAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau lors du chargement des analyses'**
  String get networkErrorAnalytics;

  /// No description provided for @serverErrorAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur pour les analyses'**
  String get serverErrorAnalytics;

  /// No description provided for @timeoutErrorAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Délai d\'attente dépassé pour les analyses'**
  String get timeoutErrorAnalytics;

  /// No description provided for @noSpendingRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense enregistrée'**
  String get noSpendingRecorded;

  /// No description provided for @dailyTrends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances quotidiennes'**
  String get dailyTrends;

  /// No description provided for @weeklyTrends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances hebdomadaires'**
  String get weeklyTrends;

  /// No description provided for @yearlyTrends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances annuelles'**
  String get yearlyTrends;

  /// No description provided for @day.
  ///
  /// In fr, this message translates to:
  /// **'jour'**
  String get day;

  /// No description provided for @week.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get week;

  /// No description provided for @month.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get month;

  /// No description provided for @year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get year;

  /// No description provided for @dailyAverage.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne/jour'**
  String get dailyAverage;

  /// No description provided for @weeklyAverage.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne/semaine'**
  String get weeklyAverage;

  /// No description provided for @yearlyAverage.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne/année'**
  String get yearlyAverage;

  /// No description provided for @choosePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la période'**
  String get choosePeriod;

  /// No description provided for @updateChart.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le graphique'**
  String get updateChart;

  /// No description provided for @refreshChart.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser le graphique'**
  String get refreshChart;

  /// No description provided for @chartData.
  ///
  /// In fr, this message translates to:
  /// **'Données du graphique'**
  String get chartData;

  /// No description provided for @barChart.
  ///
  /// In fr, this message translates to:
  /// **'Graphique en barres'**
  String get barChart;

  /// No description provided for @lineChart.
  ///
  /// In fr, this message translates to:
  /// **'Graphique linéaire'**
  String get lineChart;

  /// No description provided for @noChartData.
  ///
  /// In fr, this message translates to:
  /// **'Pas de données pour le graphique'**
  String get noChartData;

  /// No description provided for @loadingChart.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du graphique...'**
  String get loadingChart;

  /// No description provided for @summaryData.
  ///
  /// In fr, this message translates to:
  /// **'Données de résumé'**
  String get summaryData;

  /// No description provided for @periodSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de la période'**
  String get periodSummary;

  /// No description provided for @averageSpending.
  ///
  /// In fr, this message translates to:
  /// **'Dépense moyenne'**
  String get averageSpending;

  /// No description provided for @totalForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Total pour la période'**
  String get totalForPeriod;

  /// No description provided for @previousPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période suivante'**
  String get nextPeriod;

  /// No description provided for @currentPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période actuelle'**
  String get currentPeriod;

  /// No description provided for @comparePeriods.
  ///
  /// In fr, this message translates to:
  /// **'Comparer les périodes'**
  String get comparePeriods;

  /// No description provided for @dataLoadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement des données'**
  String get dataLoadingError;

  /// No description provided for @chartError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du graphique'**
  String get chartError;

  /// No description provided for @noDataForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour cette période'**
  String get noDataForPeriod;

  /// No description provided for @selectDifferentPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une période différente'**
  String get selectDifferentPeriod;

  /// No description provided for @weekNumber.
  ///
  /// In fr, this message translates to:
  /// **'Semaine {number}'**
  String weekNumber(int number);

  /// No description provided for @weekLabel.
  ///
  /// In fr, this message translates to:
  /// **'S{number}'**
  String weekLabel(int number);

  /// No description provided for @receipts.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get receipts;

  /// No description provided for @allReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allReceipts;

  /// No description provided for @byStore.
  ///
  /// In fr, this message translates to:
  /// **'Par magasin'**
  String get byStore;

  /// No description provided for @addReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une facture'**
  String get addReceipt;

  /// No description provided for @editReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la facture'**
  String get editReceipt;

  /// No description provided for @deleteReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la facture'**
  String get deleteReceipt;

  /// No description provided for @deleteReceiptConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette facture ?'**
  String get deleteReceiptConfirm;

  /// No description provided for @noReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get noReceipts;

  /// No description provided for @addFirstReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre première facture pour suivre vos dépenses réelles'**
  String get addFirstReceipt;

  /// No description provided for @enterStoreName.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nom du magasin'**
  String get enterStoreName;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get totalAmount;

  /// No description provided for @enterAmount.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le montant'**
  String get enterAmount;

  /// No description provided for @purchaseDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'achat'**
  String get purchaseDate;

  /// No description provided for @selectDate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la date'**
  String get selectDate;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @optionalNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes optionnelles'**
  String get optionalNotes;

  /// No description provided for @storeNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du magasin est requis'**
  String get storeNameRequired;

  /// No description provided for @storeNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 2 caractères'**
  String get storeNameTooShort;

  /// No description provided for @amountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est requis'**
  String get amountRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get invalidAmount;

  /// No description provided for @amountMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif'**
  String get amountMustBePositive;

  /// No description provided for @amountTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Montant trop élevé (max 999 999,99)'**
  String get amountTooHigh;

  /// No description provided for @spendingSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé des dépenses'**
  String get spendingSummary;

  /// No description provided for @totalExpensesSummary.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de vos dépenses'**
  String get totalExpensesSummary;

  /// No description provided for @totalFromReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Total des factures'**
  String get totalFromReceipts;

  /// No description provided for @totalFromItems.
  ///
  /// In fr, this message translates to:
  /// **'Total des articles'**
  String get totalFromItems;

  /// No description provided for @bestEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure estimation'**
  String get bestEstimate;

  /// No description provided for @dataComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison des données'**
  String get dataComparison;

  /// No description provided for @receiptVsItemComparison.
  ///
  /// In fr, this message translates to:
  /// **'Factures vs prix des articles'**
  String get receiptVsItemComparison;

  /// No description provided for @dataQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité des données'**
  String get dataQuality;

  /// No description provided for @dataQualityExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellente'**
  String get dataQualityExcellent;

  /// No description provided for @dataQualityGood.
  ///
  /// In fr, this message translates to:
  /// **'Bonne'**
  String get dataQualityGood;

  /// No description provided for @dataQualityFair.
  ///
  /// In fr, this message translates to:
  /// **'Correcte'**
  String get dataQualityFair;

  /// No description provided for @dataQualityPoor.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get dataQualityPoor;

  /// No description provided for @dataQualityUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnue'**
  String get dataQualityUnknown;

  /// No description provided for @addReceiptsRecommendation.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des factures pour des données plus précises'**
  String get addReceiptsRecommendation;

  /// No description provided for @addItemPricesRecommendation.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des prix aux articles pour plus de détails'**
  String get addItemPricesRecommendation;

  /// No description provided for @significantVarianceDetected.
  ///
  /// In fr, this message translates to:
  /// **'Écart significatif détecté ({percentage}%)'**
  String significantVarianceDetected(String percentage);

  /// No description provided for @lastVisit.
  ///
  /// In fr, this message translates to:
  /// **'Dernière visite'**
  String get lastVisit;

  /// No description provided for @added.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté'**
  String get added;

  /// No description provided for @receiptAddedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Facture ajoutée avec succès'**
  String get receiptAddedSuccessfully;

  /// No description provided for @receiptUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Facture mise à jour avec succès'**
  String get receiptUpdatedSuccessfully;

  /// No description provided for @receiptDeletedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Facture supprimée avec succès'**
  String get receiptDeletedSuccessfully;

  /// No description provided for @receiptsLoadedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Factures chargées avec succès'**
  String get receiptsLoadedSuccessfully;

  /// No description provided for @errorLoadingReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des factures'**
  String get errorLoadingReceipts;

  /// No description provided for @errorAddingReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout de la facture'**
  String get errorAddingReceipt;

  /// No description provided for @errorUpdatingReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour de la facture'**
  String get errorUpdatingReceipt;

  /// No description provided for @errorDeletingReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression de la facture'**
  String get errorDeletingReceipt;

  /// No description provided for @receiptValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Données de facture invalides'**
  String get receiptValidationError;

  /// No description provided for @storeNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Nom de magasin invalide'**
  String get storeNameInvalid;

  /// No description provided for @amountTooLow.
  ///
  /// In fr, this message translates to:
  /// **'Montant trop faible'**
  String get amountTooLow;

  /// No description provided for @dateInFuture.
  ///
  /// In fr, this message translates to:
  /// **'La date ne peut pas être dans le futur'**
  String get dateInFuture;

  /// No description provided for @dateTooOld.
  ///
  /// In fr, this message translates to:
  /// **'La date ne peut pas être antérieure à 2 ans'**
  String get dateTooOld;

  /// No description provided for @notesTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Notes trop longues (max 1000 caractères)'**
  String get notesTooLong;

  /// No description provided for @receiptDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la facture'**
  String get receiptDetails;

  /// No description provided for @receiptInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la facture'**
  String get receiptInformation;

  /// No description provided for @manageReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les factures'**
  String get manageReceipts;

  /// No description provided for @viewReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Voir les factures'**
  String get viewReceipts;

  /// No description provided for @receiptHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des factures'**
  String get receiptHistory;

  /// No description provided for @totalReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Total des factures'**
  String get totalReceipts;

  /// No description provided for @averageReceiptAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant moyen par facture'**
  String get averageReceiptAmount;

  /// No description provided for @largestReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Plus grande facture'**
  String get largestReceipt;

  /// No description provided for @smallestReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Plus petite facture'**
  String get smallestReceipt;

  /// No description provided for @mostFrequentStore.
  ///
  /// In fr, this message translates to:
  /// **'Magasin le plus fréquenté'**
  String get mostFrequentStore;

  /// No description provided for @comparisonResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats de comparaison'**
  String get comparisonResults;

  /// No description provided for @dataAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision des données'**
  String get dataAccuracy;

  /// No description provided for @recommendationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get recommendationsTitle;

  /// No description provided for @improvementsNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Améliorations nécessaires'**
  String get improvementsNeeded;

  /// No description provided for @wellDoneMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bravo ! Vos données sont précises'**
  String get wellDoneMessage;

  /// No description provided for @addMoreReceiptsAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez plus de factures pour améliorer la précision'**
  String get addMoreReceiptsAdvice;

  /// No description provided for @priceItemsAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des prix à vos articles pour de meilleures estimations'**
  String get priceItemsAdvice;

  /// No description provided for @loadingReceiptStats.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des statistiques de factures...'**
  String get loadingReceiptStats;

  /// No description provided for @noReceiptStats.
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique de facture disponible'**
  String get noReceiptStats;

  /// No description provided for @receiptStatsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques de factures indisponibles'**
  String get receiptStatsUnavailable;

  /// No description provided for @refreshReceiptStats.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les statistiques'**
  String get refreshReceiptStats;

  /// No description provided for @receiptOperationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Opération de facture échouée'**
  String get receiptOperationFailed;

  /// No description provided for @backToReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux factures'**
  String get backToReceipts;

  /// No description provided for @addNewReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une nouvelle facture'**
  String get addNewReceipt;

  /// No description provided for @editReceiptInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les informations de la facture'**
  String get editReceiptInfo;

  /// No description provided for @duplicateReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer la facture'**
  String get duplicateReceipt;

  /// No description provided for @shareReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Partager la facture'**
  String get shareReceipt;

  /// No description provided for @exportReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les factures'**
  String get exportReceipts;

  /// No description provided for @importReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Importer les factures'**
  String get importReceipts;

  /// No description provided for @filterByStore.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par magasin'**
  String get filterByStore;

  /// No description provided for @filterByDate.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par date'**
  String get filterByDate;

  /// No description provided for @filterByAmount.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par montant'**
  String get filterByAmount;

  /// No description provided for @sortByDate.
  ///
  /// In fr, this message translates to:
  /// **'Trier par date'**
  String get sortByDate;

  /// No description provided for @sortByStore.
  ///
  /// In fr, this message translates to:
  /// **'Trier par magasin'**
  String get sortByStore;

  /// No description provided for @newestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Plus récent en premier'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Plus ancien en premier'**
  String get oldestFirst;

  /// No description provided for @highestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Montant le plus élevé en premier'**
  String get highestFirst;

  /// No description provided for @lowestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Montant le plus faible en premier'**
  String get lowestFirst;

  /// No description provided for @cannotAddReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter une facture'**
  String get cannotAddReceipt;

  /// No description provided for @cannotEditReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier la facture'**
  String get cannotEditReceipt;

  /// No description provided for @cannotDeleteReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer la facture'**
  String get cannotDeleteReceipt;

  /// No description provided for @receiptPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée pour les opérations de facture'**
  String get receiptPermissionDenied;

  /// No description provided for @receiptReadOnlyAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès en lecture seule aux factures'**
  String get receiptReadOnlyAccess;

  /// No description provided for @receiptDateFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format de date de facture'**
  String get receiptDateFormat;

  /// No description provided for @amountDisplayFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'affichage du montant'**
  String get amountDisplayFormat;

  /// No description provided for @receiptNumberFormat.
  ///
  /// In fr, this message translates to:
  /// **'Facture n°{number}'**
  String receiptNumberFormat(int number);

  /// No description provided for @receiptSavedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Facture sauvegardée avec succès'**
  String get receiptSavedSuccessfully;

  /// No description provided for @receiptDeletedPermanently.
  ///
  /// In fr, this message translates to:
  /// **'Facture supprimée définitivement'**
  String get receiptDeletedPermanently;

  /// No description provided for @allReceiptsCleared.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les factures supprimées'**
  String get allReceiptsCleared;

  /// No description provided for @receiptDataExported.
  ///
  /// In fr, this message translates to:
  /// **'Données de factures exportées'**
  String get receiptDataExported;

  /// No description provided for @receiptDataImported.
  ///
  /// In fr, this message translates to:
  /// **'Données de factures importées'**
  String get receiptDataImported;

  /// No description provided for @receiptHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos des factures'**
  String get receiptHelpTitle;

  /// No description provided for @receiptHelpDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos vraies factures d\'achat pour suivre les dépenses réelles versus les coûts estimés'**
  String get receiptHelpDescription;

  /// No description provided for @receiptBenefits.
  ///
  /// In fr, this message translates to:
  /// **'Avantages d\'ajouter des factures'**
  String get receiptBenefits;

  /// No description provided for @accurateSpendingData.
  ///
  /// In fr, this message translates to:
  /// **'• Données de dépenses précises'**
  String get accurateSpendingData;

  /// No description provided for @betterBudgetTracking.
  ///
  /// In fr, this message translates to:
  /// **'• Meilleur suivi du budget'**
  String get betterBudgetTracking;

  /// No description provided for @spendingComparisons.
  ///
  /// In fr, this message translates to:
  /// **'• Comparer estimations vs coûts réels'**
  String get spendingComparisons;

  /// No description provided for @storeSpendingAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'• Analyser les dépenses par magasin'**
  String get storeSpendingAnalysis;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @budgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @createBudget.
  ///
  /// In fr, this message translates to:
  /// **'Créer un budget'**
  String get createBudget;

  /// No description provided for @editBudget.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le budget'**
  String get editBudget;

  /// No description provided for @deleteBudget.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le budget'**
  String get deleteBudget;

  /// No description provided for @quickBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget rapide'**
  String get quickBudget;

  /// No description provided for @budgetName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du budget'**
  String get budgetName;

  /// No description provided for @budgetNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Courses du mois'**
  String get budgetNameHint;

  /// No description provided for @budgetAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant du budget'**
  String get budgetAmount;

  /// No description provided for @budgetAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant du budget est requis'**
  String get budgetAmountRequired;

  /// No description provided for @budgetAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant de budget invalide'**
  String get budgetAmountInvalid;

  /// No description provided for @budgetAmountTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Montant de budget trop élevé'**
  String get budgetAmountTooHigh;

  /// No description provided for @budgetNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du budget est requis'**
  String get budgetNameRequired;

  /// No description provided for @budgetNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du budget est trop court'**
  String get budgetNameTooShort;

  /// No description provided for @periodType.
  ///
  /// In fr, this message translates to:
  /// **'Type de période'**
  String get periodType;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get endDate;

  /// No description provided for @alertThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get alertThreshold;

  /// No description provided for @alertThresholdDescription.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir une alerte quand ce pourcentage du budget est atteint'**
  String get alertThresholdDescription;

  /// No description provided for @associatedList.
  ///
  /// In fr, this message translates to:
  /// **'Liste associée'**
  String get associatedList;

  /// No description provided for @generalBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget général'**
  String get generalBudget;

  /// No description provided for @budgetCreatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Budget créé avec succès'**
  String get budgetCreatedSuccessfully;

  /// No description provided for @budgetUpdatedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Budget modifié avec succès'**
  String get budgetUpdatedSuccessfully;

  /// No description provided for @budgetDeletedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Budget supprimé avec succès'**
  String get budgetDeletedSuccessfully;

  /// No description provided for @errorLoadingBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des budgets'**
  String get errorLoadingBudgets;

  /// No description provided for @budgetSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé des budgets'**
  String get budgetSummary;

  /// No description provided for @overviewOfYourBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de vos budgets'**
  String get overviewOfYourBudgets;

  /// No description provided for @totalBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Total budgets'**
  String get totalBudgets;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get active;

  /// No description provided for @warnings.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get warnings;

  /// No description provided for @exceeded.
  ///
  /// In fr, this message translates to:
  /// **'Dépassés'**
  String get exceeded;

  /// No description provided for @noBudgetsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget pour le moment'**
  String get noBudgetsYet;

  /// No description provided for @createFirstBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier budget pour gérer vos dépenses'**
  String get createFirstBudgetDescription;

  /// No description provided for @noActiveBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget actif'**
  String get noActiveBudgets;

  /// No description provided for @createActiveBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Créez un budget actif pour commencer le suivi'**
  String get createActiveBudgetDescription;

  /// No description provided for @noBudgetAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte de budget'**
  String get noBudgetAlerts;

  /// No description provided for @allBudgetsOnTrack.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos budgets sont sous contrôle'**
  String get allBudgetsOnTrack;

  /// No description provided for @budgeted.
  ///
  /// In fr, this message translates to:
  /// **'Budgétisé'**
  String get budgeted;

  /// No description provided for @spent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In fr, this message translates to:
  /// **'Restant'**
  String get remaining;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @activate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activate;

  /// No description provided for @custom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get custom;

  /// No description provided for @alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// No description provided for @createQuickBudget.
  ///
  /// In fr, this message translates to:
  /// **'Créer un budget rapide'**
  String get createQuickBudget;

  /// No description provided for @createMonthlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Créer un budget mensuel'**
  String get createMonthlyBudget;

  /// No description provided for @quickBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Créez un budget rapidement avec des modèles prédéfinis'**
  String get quickBudgetDescription;

  /// No description provided for @monthlyBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Budget pour le mois en cours'**
  String get monthlyBudgetDescription;

  /// No description provided for @yearlyBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Budget pour l\'année en cours'**
  String get yearlyBudgetDescription;

  /// No description provided for @weeklyBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'Budget pour la semaine en cours'**
  String get weeklyBudgetDescription;

  /// No description provided for @selectBudgetType.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez le type de budget'**
  String get selectBudgetType;

  /// No description provided for @createBudgetQuickly.
  ///
  /// In fr, this message translates to:
  /// **'Créez un budget rapidement'**
  String get createBudgetQuickly;

  /// No description provided for @weeklyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget hebdomadaire'**
  String get weeklyBudget;

  /// No description provided for @monthlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget mensuel'**
  String get monthlyBudget;

  /// No description provided for @yearlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget annuel'**
  String get yearlyBudget;

  /// No description provided for @recentBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets récents'**
  String get recentBudgets;

  /// No description provided for @deleteBudgetConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer le budget \"{budgetName}\" ?'**
  String deleteBudgetConfirmation(String budgetName);

  /// No description provided for @setBudgetForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Définir un budget pour une période'**
  String get setBudgetForPeriod;

  /// No description provided for @modifyBudgetDetails.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les détails du budget'**
  String get modifyBudgetDetails;

  /// No description provided for @expired.
  ///
  /// In fr, this message translates to:
  /// **'Expirés'**
  String get expired;

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @sortByName.
  ///
  /// In fr, this message translates to:
  /// **'Trier par nom'**
  String get sortByName;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @scope.
  ///
  /// In fr, this message translates to:
  /// **'Portée'**
  String get scope;

  /// No description provided for @general.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get general;

  /// No description provided for @specific.
  ///
  /// In fr, this message translates to:
  /// **'Spécifique'**
  String get specific;

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get clearFilters;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get update;

  /// No description provided for @filtersAndSort.
  ///
  /// In fr, this message translates to:
  /// **'Filtres et tri'**
  String get filtersAndSort;

  /// No description provided for @spendingProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression des dépenses'**
  String get spendingProgress;

  /// No description provided for @specificList.
  ///
  /// In fr, this message translates to:
  /// **'Liste spécifique'**
  String get specificList;

  /// No description provided for @budgetPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période du budget'**
  String get budgetPeriod;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le montant'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un montant valide'**
  String get pleaseEnterValidAmount;

  /// No description provided for @budgetScope.
  ///
  /// In fr, this message translates to:
  /// **'Portée du budget'**
  String get budgetScope;

  /// No description provided for @enterBudgetName.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nom du budget'**
  String get enterBudgetName;

  /// No description provided for @pleaseEnterBudgetName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le nom du budget'**
  String get pleaseEnterBudgetName;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @generalBudgetDescription.
  ///
  /// In fr, this message translates to:
  /// **'S\'applique à toutes vos listes de courses'**
  String get generalBudgetDescription;

  /// No description provided for @orSelectSpecificList.
  ///
  /// In fr, this message translates to:
  /// **'Ou sélectionnez une liste spécifique'**
  String get orSelectSpecificList;

  /// No description provided for @unknownList.
  ///
  /// In fr, this message translates to:
  /// **'Liste inconnue'**
  String get unknownList;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get days;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @availableLists.
  ///
  /// In fr, this message translates to:
  /// **'Listes disponibles'**
  String get availableLists;

  /// No description provided for @noListsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste disponible'**
  String get noListsAvailable;

  /// No description provided for @selectList.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une liste'**
  String get selectList;

  /// No description provided for @budgetDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du budget'**
  String get budgetDetails;

  /// No description provided for @budgetProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression du budget'**
  String get budgetProgress;

  /// No description provided for @spentAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant dépensé'**
  String get spentAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant restant'**
  String get remainingAmount;

  /// No description provided for @budgetStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut du budget'**
  String get budgetStatus;

  /// No description provided for @budgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Budget dépassé'**
  String get budgetExceeded;

  /// No description provided for @budgetWarning.
  ///
  /// In fr, this message translates to:
  /// **'Alerte budget'**
  String get budgetWarning;

  /// No description provided for @budgetOnTrack.
  ///
  /// In fr, this message translates to:
  /// **'Budget sous contrôle'**
  String get budgetOnTrack;

  /// No description provided for @budgetCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création du budget'**
  String get budgetCreateError;

  /// No description provided for @budgetUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour du budget'**
  String get budgetUpdateError;

  /// No description provided for @budgetDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression du budget'**
  String get budgetDeleteError;

  /// No description provided for @budgetLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement du budget'**
  String get budgetLoadError;

  /// No description provided for @pauseBudget.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause le budget'**
  String get pauseBudget;

  /// No description provided for @resumeBudget.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le budget'**
  String get resumeBudget;

  /// No description provided for @toggleBudgetStatus.
  ///
  /// In fr, this message translates to:
  /// **'Basculer le statut du budget'**
  String get toggleBudgetStatus;

  /// No description provided for @viewBudgetDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails du budget'**
  String get viewBudgetDetails;

  /// No description provided for @editBudgetDetails.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les détails du budget'**
  String get editBudgetDetails;

  /// No description provided for @budgetPeriodTypeWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get budgetPeriodTypeWeekly;

  /// No description provided for @budgetPeriodTypeMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get budgetPeriodTypeMonthly;

  /// No description provided for @budgetPeriodTypeYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get budgetPeriodTypeYearly;

  /// No description provided for @budgetPeriodTypeCustom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get budgetPeriodTypeCustom;

  /// No description provided for @budgetFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get budgetFilterAll;

  /// No description provided for @budgetFilterActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get budgetFilterActive;

  /// No description provided for @budgetFilterInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactifs'**
  String get budgetFilterInactive;

  /// No description provided for @budgetFilterExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirés'**
  String get budgetFilterExpired;

  /// No description provided for @budgetFilterUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get budgetFilterUpcoming;

  /// No description provided for @budgetFilterWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get budgetFilterWarning;

  /// No description provided for @budgetFilterExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Dépassés'**
  String get budgetFilterExceeded;

  /// No description provided for @budgetScopeGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get budgetScopeGeneral;

  /// No description provided for @budgetScopeSpecific.
  ///
  /// In fr, this message translates to:
  /// **'Spécifique à une liste'**
  String get budgetScopeSpecific;

  /// No description provided for @budgetValidationNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du budget est requis'**
  String get budgetValidationNameRequired;

  /// No description provided for @budgetValidationNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du budget doit contenir au moins 3 caractères'**
  String get budgetValidationNameTooShort;

  /// No description provided for @budgetValidationNameTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du budget ne peut pas dépasser 50 caractères'**
  String get budgetValidationNameTooLong;

  /// No description provided for @budgetValidationAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant du budget est requis'**
  String get budgetValidationAmountRequired;

  /// No description provided for @budgetValidationAmountMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant du budget doit être positif'**
  String get budgetValidationAmountMustBePositive;

  /// No description provided for @budgetValidationAmountTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Le montant du budget ne peut pas dépasser 999 999,99'**
  String get budgetValidationAmountTooHigh;

  /// No description provided for @budgetValidationStartDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date de début est requise'**
  String get budgetValidationStartDateRequired;

  /// No description provided for @budgetValidationEndDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin est requise'**
  String get budgetValidationEndDateRequired;

  /// No description provided for @budgetValidationEndDateAfterStart.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin doit être après la date de début'**
  String get budgetValidationEndDateAfterStart;

  /// No description provided for @budgetValidationAlertThresholdInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le seuil d\'alerte doit être entre 1 et 100'**
  String get budgetValidationAlertThresholdInvalid;

  /// No description provided for @hideFilters.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les filtres'**
  String get hideFilters;

  /// No description provided for @showFilters.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les filtres'**
  String get showFilters;

  /// No description provided for @moreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get moreOptions;

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResultsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In fr, this message translates to:
  /// **'Essayez d\'ajuster vos filtres ou d\'effacer les filtres actuels'**
  String get tryAdjustingFilters;

  /// No description provided for @daysRemaining.
  ///
  /// In fr, this message translates to:
  /// **'jours restants'**
  String get daysRemaining;

  /// No description provided for @dayRemaining.
  ///
  /// In fr, this message translates to:
  /// **'jour restant'**
  String get dayRemaining;

  /// No description provided for @epilistUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur EpiList'**
  String get epilistUser;

  /// No description provided for @refreshTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshTooltip;

  /// No description provided for @appLogoError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement du logo'**
  String get appLogoError;

  /// No description provided for @userMenuHeader.
  ///
  /// In fr, this message translates to:
  /// **'Menu utilisateur'**
  String get userMenuHeader;

  /// No description provided for @userRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle utilisateur'**
  String get userRole;

  /// No description provided for @accessLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'accès'**
  String get accessLevel;

  /// No description provided for @confirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'action'**
  String get confirmAction;

  /// No description provided for @menuOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options du menu'**
  String get menuOptions;

  /// No description provided for @userActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions utilisateur'**
  String get userActions;

  /// No description provided for @appReady.
  ///
  /// In fr, this message translates to:
  /// **'Application prête'**
  String get appReady;

  /// No description provided for @loadingUser.
  ///
  /// In fr, this message translates to:
  /// **'Chargement utilisateur'**
  String get loadingUser;

  /// No description provided for @welcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour'**
  String get welcomeBack;

  /// No description provided for @goodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get goodEvening;

  /// No description provided for @readOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get readOnly;

  /// No description provided for @addItems.
  ///
  /// In fr, this message translates to:
  /// **'ajouter des articles'**
  String get addItems;

  /// No description provided for @deleteItems.
  ///
  /// In fr, this message translates to:
  /// **'supprimer des articles'**
  String get deleteItems;

  /// No description provided for @modifyItemStatus.
  ///
  /// In fr, this message translates to:
  /// **'modifier le statut des articles'**
  String get modifyItemStatus;

  /// No description provided for @cannotPerformActionReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas {action} car cette liste est en mode lecture seule.\n\nVotre permission actuelle : {permission}'**
  String cannotPerformActionReadOnly(String action, String permission);

  /// No description provided for @cannotPerformAction.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas la permission de {action}.\n\nVotre permission actuelle : {permission}'**
  String cannotPerformAction(String action, String permission);
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
