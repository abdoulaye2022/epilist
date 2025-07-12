// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EpiList';

  @override
  String get welcome => 'Welcome';

  @override
  String get hello => 'Hello! 👋';

  @override
  String get manageGroceryLists => 'Manage your grocery lists easily';

  @override
  String get myGroceryLists => 'My Grocery Lists';

  @override
  String get viewAll => 'View all';

  @override
  String get newList => 'New List';

  @override
  String get createList => 'Create list';

  @override
  String get noGroceryLists => 'No grocery lists';

  @override
  String get createFirstList => 'Create your first list';

  @override
  String get loadingError => 'Loading error';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get allLists => 'All lists';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get articles => 'items';

  @override
  String get budget => 'Budget';

  @override
  String get sharedList => 'Shared list';

  @override
  String get collaborators => 'collaborator(s)';

  @override
  String get sharedBy => 'Shared by';

  @override
  String get completed => '✅ Completed';

  @override
  String get inProgress => '🛒 In progress';

  @override
  String get created => 'Created';

  @override
  String get edit => 'Edit';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get share => 'Share';

  @override
  String get manageShares => 'Manage shares';

  @override
  String get leave => 'Leave';

  @override
  String get delete => 'Delete';

  @override
  String get cannotEditPermission =>
      'You don\'t have permission to edit this list';

  @override
  String get cannotSharePermission =>
      'You don\'t have permission to share this list';

  @override
  String get onlyOwnerManageShares => 'Only the owner can manage shares';

  @override
  String get cannotLeaveOwnList => 'Cannot leave your own list';

  @override
  String get cannotDeletePermission =>
      'You don\'t have permission to delete this list';

  @override
  String get readOnlyAccess => 'Read-only access';

  @override
  String get editAccess => 'Edit';

  @override
  String get adminAccess => 'Admin';

  @override
  String get language => 'Language';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get languageSelection => 'Language Selection';

  @override
  String get choosePreferredLanguage => 'Choose your preferred language';

  @override
  String get continueButton => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get loginTitle => 'Login';

  @override
  String get registerTitle => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get welcomeToEpiList => 'Welcome to EpiList';

  @override
  String get groceryListApp => 'Your grocery list application';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get noAccount => 'No account?';

  @override
  String get initialization => 'Initialization...';

  @override
  String get checkingAuthentication => 'Checking authentication...';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get userNotFound => 'No account found with this email';

  @override
  String get emailNotVerified => 'Email not verified';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get emailConfirmedSuccess => 'Email confirmed successfully! Welcome!';

  @override
  String get networkError => 'Network error. Check your connection.';

  @override
  String get unknownError => 'An unexpected error occurred';

  @override
  String get initializationError => 'Initialization error';

  @override
  String get cannotStartApp => 'Cannot start the application';

  @override
  String get myProfile => 'My Profile';

  @override
  String get myData => 'My Data';

  @override
  String get myShoppingLists => 'My Shopping Lists';

  @override
  String get settings => 'Settings';

  @override
  String get appSettings => 'App Settings';

  @override
  String get security => 'Security';

  @override
  String get information => 'Information';

  @override
  String get aboutEpiList => 'About EpiList';

  @override
  String get privacyPolicy => 'privacy policy';

  @override
  String get termsOfService => 'terms of service';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get emailNotVerifiedStatus => 'Email not verified';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get cannotLoadProfile => 'Cannot load profile';

  @override
  String get accountDeletionScheduled => 'Account deletion scheduled';

  @override
  String accountWillBeDeleted(String date) {
    return 'Your account will be permanently deleted on $date';
  }

  @override
  String timeRemaining(int days, String plural) {
    return 'Time remaining: $days day$plural';
  }

  @override
  String reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String get cancellationPeriodExpired =>
      'The 30-day cancellation period has expired';

  @override
  String get deletionCodeSent => 'Deletion code sent! Check your email.';

  @override
  String get accountDeletionCancelled =>
      'Account deletion cancelled successfully!';

  @override
  String get accountWillBeDeletedIn30Days =>
      'Your account will be deleted in 30 days. You can cancel this action.';

  @override
  String get confirmCancelDeletion => 'Cancel deletion';

  @override
  String get confirmCancelDeletionText =>
      'Are you sure you want to cancel the deletion of your account? Your account will become active immediately.';

  @override
  String get noKeepDeletion => 'No, keep deletion';

  @override
  String get yesCancelDeletion => 'Yes, cancel';

  @override
  String get changePassword => 'Change password';

  @override
  String get enterYourCode => 'Enter your code';

  @override
  String get enterCodeAndNewPassword => 'Enter the code and your new password';

  @override
  String get enterEmailForVerificationCode =>
      'Enter your email to receive a verification code';

  @override
  String verificationCodeSentTo(Object email) {
    return 'Verification code sent to $email';
  }

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully!';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get pleaseEnterVerificationCode =>
      'Please enter the verification code';

  @override
  String get codeMustBeSixDigits => 'Code must contain 6 digits';

  @override
  String get newPassword => 'New password';

  @override
  String get pleaseEnterNewPassword => 'Please enter your new password';

  @override
  String get passwordMinSixCharacters =>
      'Password must contain at least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm new password *';

  @override
  String get pleaseConfirmNewPassword => 'Please confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get sendCode => 'Send code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get codeExpiresInTwoHours => 'Code expires in 2 hours';

  @override
  String get verificationCodeWillBeSent =>
      'A verification code will be sent by email';

  @override
  String get changingPassword => 'Changing password...';

  @override
  String get sendingCode => 'Sending code...';

  @override
  String get invalidVerificationCode => 'The verification code is invalid';

  @override
  String get verificationCodeExpired =>
      'The verification code has expired. Request a new code.';

  @override
  String get noAccountFoundWithEmail => 'No account found with this email';

  @override
  String get emailNotVerifiedYet => 'Your email is not yet verified';

  @override
  String get errorChangingPassword => 'Error changing password';

  @override
  String get connectionProblemCheckNetwork =>
      'Connection problem. Check your network.';

  @override
  String get enteredDataNotValid => 'The entered data is not valid';

  @override
  String get unexpectedErrorOccurred => 'An unexpected error occurred';

  @override
  String get manageGroceryListsEasily => 'Manage your grocery lists easily';

  @override
  String get createListsBeforeShopping =>
      'Create your lists before going shopping';

  @override
  String get checkPurchasesRealTime => 'Check your purchases in real-time';

  @override
  String get trackGroceryExpenses => 'Track your grocery expenses in CAD\$';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinThreeCharacters =>
      'Password must contain at least 3 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get or => 'OR';

  @override
  String get createAccount => 'Create Account';

  @override
  String get simplifyShoppingControlBudget =>
      'Simplify your shopping and control your budget!';

  @override
  String get pleaseFixFormErrors => 'Please fix the errors in the form';

  @override
  String get emailMustBeVerified =>
      'Your email must be verified before continuing.';

  @override
  String get resetPasswordSecurely => 'Reset your password securely.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get joinEpiListToManage =>
      'Join EpiList to manage your groceries easily';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get firstNameRequired => 'First name required';

  @override
  String get lastNameRequired => 'Last name required';

  @override
  String get tooShort => 'Too short';

  @override
  String get atLeastSixCharacters => 'At least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDifferent => 'Passwords are different';

  @override
  String get iAcceptThe => 'I accept the ';

  @override
  String get andThe => ' and the ';

  @override
  String get createMyAccount => 'Create My Account';

  @override
  String get afterRegistrationEmailVerification =>
      'After registration, you will receive a verification code by email';

  @override
  String accountCreatedSuccessfully(String firstName, String lastName) {
    return 'Account created successfully! $firstName $lastName\nCheck your email to activate your account.';
  }

  @override
  String get emailAlreadyExists => 'This email address is already in use';

  @override
  String get passwordTooWeak => 'Password is too weak';

  @override
  String get validationError => 'The entered data is not valid';

  @override
  String get noShoppingLists => 'No shopping lists';

  @override
  String get createFirstListToStart => 'Create your first list to get started';

  @override
  String get leaveList => 'Leave list';

  @override
  String sureToLeave(String listName) {
    return 'Are you sure you want to leave \"$listName\"?';
  }

  @override
  String get loseAccessWarning =>
      'You will lose access to this list and all its items.';

  @override
  String get list => 'List';

  @override
  String get noActiveShares => 'No active shares';

  @override
  String get user => 'User';

  @override
  String get modifyPermissions => 'Modify permissions';

  @override
  String get revoke => 'Revoke';

  @override
  String get createNewShare => 'Create new share';

  @override
  String get close => 'Close';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get on => 'on';

  @override
  String get cad => ' CAD\$';

  @override
  String createShareLinkFor(String listName) {
    return 'Create a share link for \"$listName\"';
  }

  @override
  String get permissions => 'Permissions';

  @override
  String get linkExpiration => 'Link expiration';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get creating => 'Creating...';

  @override
  String get generateShareLink => 'Generate share link';

  @override
  String get linkCreatedSuccessfully => 'Link created successfully';

  @override
  String get copy => 'Copy';

  @override
  String get newLink => 'New link';

  @override
  String linkExpirationInfo(int days) {
    return 'The link expires after $days days. You can revoke access at any time.';
  }

  @override
  String get shareLinkCreatedSuccessfully => 'Share link created successfully!';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard!';

  @override
  String get you => 'You';

  @override
  String epilistInvitation(String listName) {
    return 'EpiList Invitation - $listName';
  }

  @override
  String get shareError => 'Error sharing';

  @override
  String get readOnlyDescription => 'Can view the list but not modify it';

  @override
  String get editDescription => 'Can add, edit and mark items';

  @override
  String get adminDescription =>
      'Can do everything, including share and delete';

  @override
  String get total => 'Total';

  @override
  String get progress => 'Progress';

  @override
  String get editList => 'Edit list';

  @override
  String get thisListIsEmpty => 'This list is empty';

  @override
  String get yourListIsEmpty => 'Your list is empty';

  @override
  String get noItemsReadOnlyDescription =>
      'There are no items in this list yet.\nYou can only view its content.';

  @override
  String get noItemsNoPermissionDescription =>
      'There are no items in this list yet.\nYou don\'t have permission to add items.';

  @override
  String get noItemsAddFirstDescription =>
      'Start by adding your first item\nto organize your shopping.';

  @override
  String get addItem => 'Add item';

  @override
  String get readOnlyMode => 'Read-only mode';

  @override
  String get permissionRequiredToAdd => 'Permission required to add';

  @override
  String get addItemTooltip => 'Add item';

  @override
  String get insufficientPermission => 'Insufficient permission';

  @override
  String get readOnlyAccessMode =>
      'Read-only mode - You cannot modify this list';

  @override
  String get sharedListCanEdit => 'Shared list - You can edit items';

  @override
  String get limitedAccess => 'Limited access to this list';

  @override
  String get by => 'By';

  @override
  String get quantity => 'Quantity';

  @override
  String get deleteItem => 'Delete';

  @override
  String get editItem => 'Edit item';

  @override
  String get listInformation => 'List information';

  @override
  String detailsAndPermissions(String listName) {
    return 'Details and permissions for \"$listName\"';
  }

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get private => 'Private';

  @override
  String get yourRole => 'Your role';

  @override
  String get owner => 'Owner';

  @override
  String get collaborator => 'Collaborator';

  @override
  String get understood => 'Understood';

  @override
  String get moreInfo => 'More info';

  @override
  String get contactOwnerForPermissions =>
      'Contact the owner to get more permissions';

  @override
  String deleteItemConfirm(String itemName) {
    return 'Are you sure you want to delete \"$itemName\" from the list?';
  }

  @override
  String leaveListConfirm(String listName) {
    return 'Are you sure you want to leave \"$listName\"?\n\nYou will lose access to this list and can no longer view its content.';
  }

  @override
  String leftList(String listName) {
    return 'You left the list \"$listName\"';
  }

  @override
  String listDeleted(String listName) {
    return 'List \"$listName\" deleted';
  }

  @override
  String get editItems => 'Edit items';

  @override
  String get shareList => 'Share list';

  @override
  String get deleteList => 'Delete list';

  @override
  String get readOnlyShort => 'Read';

  @override
  String get quantityShort => 'Qty';

  @override
  String get modification => 'Modification';

  @override
  String get consultation => 'Consultation';

  @override
  String get modifyThisList => 'modify this list';

  @override
  String get modifyThisItem => 'modify this item';

  @override
  String get deleteThisItem => 'delete this item';

  @override
  String get limited => 'Limited';

  @override
  String cannotActionReadOnly(String action, String permission) {
    return 'You cannot $action because this list is in read-only mode.\n\nYour current permission: $permission';
  }

  @override
  String cannotActionPermission(String action, String permission) {
    return 'You don\'t have permission to $action.\n\nYour current permission: $permission';
  }

  @override
  String sharedByUser(String userName) {
    return 'Shared by $userName';
  }

  @override
  String get deleteItemTitle => 'Delete item';

  @override
  String deleteQuickConfirm(String itemName) {
    return 'Delete \"$itemName\"?';
  }

  @override
  String get newItem => 'New Item';

  @override
  String get addNewItemToList => 'Add a new item to your grocery list';

  @override
  String get productNameRequired => 'Product name*';

  @override
  String get productNameRequiredMessage => 'Product name is required';

  @override
  String get productNameHint => 'Ex: Bananas, Bread, Milk...';

  @override
  String get priceCAD => 'Price (\$CAD)';

  @override
  String get storeOptional => 'Store (optional)';

  @override
  String get storeHint => 'Ex: IGA, Metro, Provigo...';

  @override
  String get add => 'Add';

  @override
  String get giveNameToNewList => 'Give a name to your new grocery list';

  @override
  String get listName => 'List name';

  @override
  String get listNameHint => 'Ex: Weekly groceries';

  @override
  String get create => 'Create';

  @override
  String get processingInProgress => 'Processing...';

  @override
  String get emailAddressRequired => 'Email address *';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get verificationCodeSent => 'Verification code sent!';

  @override
  String get checkEmailAndEnterCode =>
      'Check your email and enter the code below';

  @override
  String get verificationCodeRequired => 'Verification code *';

  @override
  String get sixDigitCodeHint => '6-digit code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get newPasswordRequired => 'New password *';

  @override
  String get minimumSixCharacters => 'Minimum 6 characters';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinSixChars =>
      'Password must contain at least 6 characters';

  @override
  String get retypePassword => 'Retype password';

  @override
  String get confirmationRequired => 'Confirmation is required';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get verificationCodeSentCheckEmail =>
      'Verification code sent! Check your email.';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get attention => '⚠️ WARNING';

  @override
  String get actionDefinitiveIrreversible =>
      'This action is final and irreversible!';

  @override
  String get whatWillBeDeleted => 'What will be deleted:';

  @override
  String get profileAndPersonalInfo =>
      '• Your profile and personal information';

  @override
  String get allPrivateGroceryLists => '• All your private grocery lists';

  @override
  String get preferencesAndSettings => '• Your preferences and settings';

  @override
  String get purchaseHistory => '• Your purchase history';

  @override
  String get whatWillBePreserved => 'What will be preserved:';

  @override
  String get sharedListsAnonymized =>
      '• Lists shared with other users (anonymized)';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get whyDeleteAccount => 'Why are you deleting your account?';

  @override
  String get understandIrreversible =>
      'I understand this action is irreversible';

  @override
  String get allDataWillBeDeleted => 'All my data will be permanently deleted';

  @override
  String verificationCodeSentToEmail(String email) {
    return 'A verification code has been sent to $email';
  }

  @override
  String get requestDeletion => 'Request deletion';

  @override
  String get confirmDeletionWithCode => 'Confirm deletion';

  @override
  String accountWillBeDeletedOn(String date) {
    return 'Your account will be deleted on $date. You have 30 days to cancel this action.';
  }

  @override
  String get deleteListTitle => 'Delete list';

  @override
  String get sureToDeleteItem => 'Are you sure you want to delete';

  @override
  String get sureToDeleteList => 'Are you sure you want to delete the list';

  @override
  String get actionIrreversible => 'This action is irreversible.';

  @override
  String get actionIrreversibleDeletesAllItems =>
      'This action is irreversible and will delete all items.';

  @override
  String get confirm => 'Confirm';

  @override
  String sureToDeleteItemFromList(String itemName) {
    return 'Are you sure you want to delete \"$itemName\" from your list?';
  }

  @override
  String get sureToLeaveQuestion => 'Are you sure you want to leave';

  @override
  String get modifyItemInformation => 'Modify your item information';

  @override
  String get save => 'Save';

  @override
  String get modify => 'Modify';

  @override
  String get fromYourList => 'from your list';

  @override
  String get processing => 'Processing...';

  @override
  String get verificationCodeSentTitle => 'Verification code sent';

  @override
  String get enterCodeReceived => 'Enter the received code';

  @override
  String get codeExpiresIn => 'Code expires in';

  @override
  String get hours => 'hours';

  @override
  String get checkEmailsAndSpam => 'Check your emails and spam folder';

  @override
  String get areYouSure => 'Are you sure';

  @override
  String get wantToDelete => 'you want to delete';

  @override
  String get wantToLeave => 'you want to leave';

  @override
  String get thisAction => 'This action';

  @override
  String get isIrreversible => 'is irreversible';

  @override
  String get andWillDelete => 'and will delete';

  @override
  String get allItems => 'all items';

  @override
  String get codeIsRequired => 'Code is required';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get codeExpired => 'Code expired';

  @override
  String get editListName => 'Edit name';

  @override
  String get modifyListName => 'Modify the name of your grocery list';

  @override
  String get modifyPersonalInformation => 'Modify your personal information';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get emailCannotBeModified => 'Email cannot be modified';

  @override
  String get firstNameAndLastNameRequired =>
      'First name and last name are required';

  @override
  String get confirmLogoutMessage =>
      'Do you really want to log out of your account?';

  @override
  String get manageAccountSecurity => 'Manage your account security';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordDescription => 'Modify your current password';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountDescription => 'Permanently delete your account';

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get emailAddress => 'Email address';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordMustBeSixCharacters =>
      'Password must contain at least 6 characters';

  @override
  String get youWillReceiveVerificationCode =>
      'You will receive a 6-digit verification code';

  @override
  String get send => 'Send';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get emailFormatInvalid => 'Invalid email format';

  @override
  String get confirmDeletionTitle => 'Confirm deletion';

  @override
  String get enterCodeToConfirm =>
      'Enter the code received by email to confirm';

  @override
  String get actionIrreversibleAllDataDeleted =>
      'This action is irreversible. All your data will be deleted.';

  @override
  String get reasonForDeletion => 'Reason for deletion (optional)';

  @override
  String get codeSentCheckEmail => 'Code sent! Check your email inbox.';

  @override
  String get deletionCode => 'Deletion code';

  @override
  String get actionDefinitiveAccountDeleted30Days =>
      'This action is final. Your account will be deleted in 30 days.';

  @override
  String get accountDeletedIn30DaysCanCancel =>
      'Your account will be deleted in 30 days. You can cancel this action during this period.';

  @override
  String get accountDeletionCodeSent => 'Deletion code sent! Check your email.';
}
