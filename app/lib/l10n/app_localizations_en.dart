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
  String get viewAll => 'View All';

  @override
  String get newList => 'New';

  @override
  String get createList => 'Create a list';

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
  String get readOnlyAccess => 'Read only';

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
  String get alreadyHaveAccount => 'Already have an account?';

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
  String get networkError => 'Network error';

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
  String get myShoppingLists => 'My shopping lists';

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
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

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
  String get changePassword => 'Change Password';

  @override
  String get enterYourCode => 'Enter your code';

  @override
  String get enterCodeAndNewPassword =>
      'Enter the code received by email and your new password';

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
  String get newPassword => 'New Password';

  @override
  String get pleaseEnterNewPassword => 'Please enter your new password';

  @override
  String get passwordMinSixCharacters =>
      'Password must contain at least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get pleaseConfirmNewPassword => 'Please confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get sendCode => 'Send Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get codeExpiresInTwoHours =>
      'The code expires in 2 hours. Check your emails and spam folder.';

  @override
  String get verificationCodeWillBeSent =>
      'You will receive a verification code by email to change your password.';

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
  String get shareLinkCreatedSuccessfully => 'Share link created successfully';

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
  String get total => 'total';

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
  String get quantity => 'Qty';

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

  @override
  String get listCreatedSuccessfully => 'List created successfully';

  @override
  String get listUpdatedSuccessfully => 'List updated successfully';

  @override
  String get listDeletedSuccessfully => 'List deleted successfully';

  @override
  String get listDuplicatedSuccessfully => 'List duplicated successfully';

  @override
  String get listsLoadedSuccessfully => 'Lists loaded successfully';

  @override
  String get operationSuccess => 'Operation successful';

  @override
  String get listNotFound => 'List not found';

  @override
  String get serverError => 'Server error';

  @override
  String get itemAddedSuccessfully => 'Item added successfully';

  @override
  String get itemUpdatedSuccessfully => 'Item updated successfully';

  @override
  String get itemDeletedSuccessfully => 'Item deleted successfully';

  @override
  String get itemStatusUpdatedSuccessfully => 'Status updated successfully';

  @override
  String get itemsLoadedSuccessfully => 'Items loaded successfully';

  @override
  String get errorLoadingItems => 'Error loading items';

  @override
  String get errorAddingItem => 'Error adding item';

  @override
  String get errorUpdatingItem => 'Error updating item';

  @override
  String get errorDeletingItem => 'Error deleting item';

  @override
  String get errorUpdatingStatus => 'Error updating status';

  @override
  String get invitationReceived => 'Invitation received!';

  @override
  String get loginRequiredForInvitation =>
      'Login required to access invitation';

  @override
  String get invalidShareLink => 'Invalid share link';

  @override
  String get errorOpeningInvitation => 'Error opening invitation';

  @override
  String get cannotOpenInvitation => 'Cannot open invitation';

  @override
  String get authSuccessNavigation =>
      'Authentication successful, navigating to invitation';

  @override
  String get invitationEpiList => 'EpiList Invitation';

  @override
  String get invitationSubject =>
      'Invitation to share a grocery list - EpiList';

  @override
  String invitationMessage(String owner, String listName) {
    return '$owner invites you to \"$listName\"';
  }

  @override
  String get directLinkRecommended => 'Direct EpiList link (recommended)';

  @override
  String get orViaBrowser => 'Or via browser';

  @override
  String get directLinkAutoOpen =>
      'The direct link will automatically open the app!';

  @override
  String get clickToOpenEpiList => 'Click to open EpiList';

  @override
  String get appWillOpenAutomatically => 'The app will open automatically!';

  @override
  String get sharedListsLoadedSuccessfully =>
      'Shared lists loaded successfully';

  @override
  String get sharesLoadedSuccessfully => 'Shares loaded successfully';

  @override
  String get invitationLoadedSuccessfully => 'Invitation loaded successfully';

  @override
  String get invitationAcceptedSuccessfully =>
      'Invitation accepted successfully';

  @override
  String get invitationDeclinedSuccessfully =>
      'Invitation declined successfully';

  @override
  String get permissionsUpdatedSuccessfully =>
      'Permissions updated successfully';

  @override
  String get shareRevokedSuccessfully => 'Share revoked successfully';

  @override
  String get leftSharedListSuccessfully => 'You left the shared list';

  @override
  String get allShareLinksRevokedSuccessfully =>
      'All share links have been revoked';

  @override
  String get errorLoadingSharedLists => 'Error loading shared lists';

  @override
  String get errorLoadingShares => 'Error loading shares';

  @override
  String get errorCreatingShareLink => 'Error creating share link';

  @override
  String get invalidOrExpiredInvitation => 'Invalid or expired invitation';

  @override
  String get errorAcceptingInvitation => 'Error accepting invitation';

  @override
  String get errorDecliningInvitation => 'Error declining invitation';

  @override
  String get errorUpdatingPermissions => 'Error updating permissions';

  @override
  String get errorRevokingShare => 'Error revoking share';

  @override
  String get errorLeavingList => 'Error leaving list';

  @override
  String get errorRevokingLinks => 'Error revoking links';

  @override
  String get operationSuccessful => 'Operation successful';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get noInternetMessage =>
      'You need to be connected to the Internet to use this application. Please check your connection and try again.';

  @override
  String get connectionTips => 'Tips:';

  @override
  String get checkWifiConnection => 'Check your Wi-Fi connection';

  @override
  String get checkMobileData => 'Enable your mobile data';

  @override
  String get restartRouter => 'Restart your router if necessary';

  @override
  String get offlineMode => 'Offline mode - Connection required';

  @override
  String get backOnline => 'Connection restored!';

  @override
  String get connectionRequired => 'Internet connection required';

  @override
  String get connectionRequiredForInvitation =>
      'Internet connection required to open invitation';

  @override
  String get productSuggestions => 'Product suggestions';

  @override
  String get noSuggestionsFound => 'No suggestions found';

  @override
  String get searchingSuggestions => 'Searching suggestions...';

  @override
  String get usedOnce => 'Used 1 time';

  @override
  String usedXTimes(int count) {
    return 'Used $count times';
  }

  @override
  String weeksAgo(int weeks, String plural) {
    return '$weeks week$plural ago';
  }

  @override
  String monthsAgo(int months, Object plural) {
    return '$months month$plural ago';
  }

  @override
  String suggestionWithDate(String usage, String date) {
    return '$usage • $date';
  }

  @override
  String get suggestionSelected => 'Suggestion selected';

  @override
  String get clearSuggestion => 'Clear suggestion';

  @override
  String get popularSuggestions => 'Popular suggestions';

  @override
  String get recentSuggestions => 'Recent suggestions';

  @override
  String get manageSuggestions => 'Manage suggestions';

  @override
  String get deleteSuggestion => 'Delete suggestion';

  @override
  String get deleteSuggestionConfirm =>
      'Are you sure you want to delete this suggestion?';

  @override
  String get clearAllSuggestions => 'Clear all suggestions';

  @override
  String get clearAllSuggestionsConfirm =>
      'Are you sure you want to delete all your suggestions? This action is irreversible.';

  @override
  String get suggestionsCleared => 'All suggestions have been cleared';

  @override
  String get errorLoadingSuggestions => 'Error loading suggestions';

  @override
  String get errorSavingSuggestion => 'Error saving suggestion';

  @override
  String get suggestionSaved => 'Suggestion saved';

  @override
  String get noSuggestionsYet => 'No suggestions yet';

  @override
  String get startTypingForSuggestions =>
      'Start typing to see your suggestions';

  @override
  String get basedOnHistory => 'Based on your history';

  @override
  String get autoComplete => 'Auto-complete';

  @override
  String get suggestionHelper => 'Your frequent products will appear here';

  @override
  String get lastUsed => 'Last used';

  @override
  String get suggestionDeleted => 'Suggestion deleted';

  @override
  String get totalSuggestions => 'Total suggestions';

  @override
  String get mostUsedSuggestion => 'Most used suggestion';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get neverUsed => 'Never used';

  @override
  String get usageStatistics => 'Usage statistics';

  @override
  String get averageUsage => 'Average usage';

  @override
  String get oldestSuggestion => 'Oldest suggestion';

  @override
  String get newestSuggestion => 'Newest suggestion';

  @override
  String get exportSuggestions => 'Export suggestions';

  @override
  String get importSuggestions => 'Import suggestions';

  @override
  String get suggestionSettings => 'Suggestion settings';

  @override
  String get enableAutoSuggestions => 'Enable auto suggestions';

  @override
  String get suggestionThreshold => 'Suggestion threshold';

  @override
  String get maxSuggestions => 'Maximum suggestions';

  @override
  String get clearOldSuggestions => 'Clear old suggestions';

  @override
  String get suggestionsOlderThan => 'Suggestions older than';

  @override
  String get oneMonth => '1 month';

  @override
  String get threeMonths => '3 months';

  @override
  String get sixMonths => '6 months';

  @override
  String get oneYear => '1 year';

  @override
  String get cleanupCompleted => 'Cleanup completed';

  @override
  String get suggestionsOptimized => 'Suggestions optimized';

  @override
  String get backupSuggestions => 'Backup suggestions';

  @override
  String get restoreSuggestions => 'Restore suggestions';

  @override
  String get suggestionBackupCreated => 'Backup created successfully';

  @override
  String get suggestionBackupRestored => 'Suggestions restored successfully';

  @override
  String get noBackupFound => 'No backup found';

  @override
  String get suggestionTips => 'Suggestion tips';

  @override
  String get tipMoreUsage =>
      'The more you use the app, the better the suggestions';

  @override
  String get tipRegularUpdates => 'Suggestions update automatically';

  @override
  String get tipPersonalized => 'Your suggestions are unique and personalized';

  @override
  String priceFormat(String price) {
    return '$price \$CAD';
  }

  @override
  String get noStoreSpecified => 'No store specified';

  @override
  String get noPriceSet => 'No price set';

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
  String get similarItemDetected => 'Similar item detected';

  @override
  String get itemToAdd => 'Item to add';

  @override
  String get product => 'Product';

  @override
  String get store => 'Store';

  @override
  String get similarItemsFound => 'Similar items found';

  @override
  String get identical => 'Identical';

  @override
  String get similar => 'Similar';

  @override
  String get mergeWithExisting => 'Merge with existing';

  @override
  String get addAnyway => 'Add anyway';

  @override
  String get duplicateDetectedMessage => 'We found similar items in your list.';

  @override
  String get noSearchResults => 'No results found';

  @override
  String get tryDifferentKeywords => 'Try different keywords';

  @override
  String get suggestionsWillAppearAfterShopping =>
      'Suggestions will appear after your shopping';

  @override
  String get startShopping => 'Start shopping';

  @override
  String get searchTips => 'Try more general terms or check spelling';

  @override
  String get suggestionsBasedOnUsage =>
      'Suggestions are based on your shopping habits';

  @override
  String get scheduleReminder => 'Schedule Reminder';

  @override
  String get remindIn2Hours => 'Remind in 2h';

  @override
  String get remindTomorrow => 'Remind Tomorrow';

  @override
  String get viewReminders => 'View Reminders';

  @override
  String get cancelReminders => 'Cancel Reminders';

  @override
  String get scheduledReminders => 'Scheduled Reminders';

  @override
  String get noRemindersScheduled => 'No reminders scheduled';

  @override
  String get reminderScheduled => 'Reminder scheduled successfully';

  @override
  String get reminderScheduledFor => 'Reminder scheduled for';

  @override
  String get reminderCancelled => 'Reminder cancelled';

  @override
  String get allRemindersCancelled => 'All reminders cancelled';

  @override
  String get errorSchedulingReminder => 'Error scheduling reminder';

  @override
  String get errorLoadingReminders => 'Error loading reminders';

  @override
  String get errorCancellingReminder => 'Error cancelling reminder';

  @override
  String get errorCancellingReminders => 'Error cancelling reminders';

  @override
  String get cancelAllReminders => 'Cancel All Reminders';

  @override
  String get cancelAllRemindersConfirm =>
      'Do you really want to cancel all reminders for this list?';

  @override
  String get cancelAll => 'Cancel All';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get quickOptions => 'Quick Options';

  @override
  String get customDateTime => 'Custom Date & Time';

  @override
  String get storeName => 'Store Name';

  @override
  String get storeNameHint => 'e.g. Walmart, Target, Costco...';

  @override
  String get customMessage => 'Custom Message';

  @override
  String get customMessageHint => 'Custom message for the reminder';

  @override
  String get selectDateTime => 'Select Date & Time';

  @override
  String get in2Hours => 'In 2h';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeekend => 'This Weekend';

  @override
  String get allOfAbove => 'All of Above';

  @override
  String inHours(int hours) {
    return 'In $hours hours';
  }

  @override
  String showingXOfY(int x, int y) {
    return 'Showing $x of $y lists';
  }

  @override
  String get optionalFields => 'Optional Fields';

  @override
  String get aboutMission => 'Our Mission';

  @override
  String get aboutMissionText =>
      'EpiList revolutionizes how you manage your grocery shopping. Create smart lists, track your expenses in real-time, share with your family and never miss an important item again thanks to our collaborative management system.';

  @override
  String get aboutFeatures => 'Main Features';

  @override
  String get aboutFeaturesText =>
      '• Secure account creation (first name, last name, email)\n• Personalized and smart grocery lists\n• Add items with quantity, price and store\n• Automatic calculation of totals and percentages\n• Real-time marking of purchased items\n• Quick duplication of existing lists\n• Secure sharing via links with permissions\n• Rights management (read, edit, administration)\n• Synchronization across all your devices\n• Modern and intuitive interface';

  @override
  String get aboutCollaboration => 'Family Collaboration';

  @override
  String get aboutCollaborationText =>
      'EpiList makes family shopping easy with its advanced sharing system. Share your lists with a simple link, define who can view, edit or administer each list. Everyone stays synchronized in real-time!';

  @override
  String get aboutDevelopment => 'Development';

  @override
  String get aboutDevelopmentText =>
      'EpiList is passionately developed by M2atech Solutions Inc. to provide you with the best grocery management experience. We are constantly listening to your feedback to improve the app and add new innovative features.';

  @override
  String get aboutContact => 'Contact us';

  @override
  String get aboutRateApp => 'Rate the app';

  @override
  String get aboutShareApp => 'Share EpiList';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutRightsReserved => 'All rights reserved.';

  @override
  String get aboutDevelopedWith => 'Developed with';

  @override
  String get aboutByCompany => 'by M2atech Solutions Inc.';

  @override
  String get aboutContactError => 'Unable to open contact link';

  @override
  String get aboutWebsiteError => 'Unable to open website';

  @override
  String get aboutStoreUnavailable =>
      'Store unavailable. Please rate EpiList on your usual store!';

  @override
  String get aboutStoreError => 'Unable to open store at the moment';

  @override
  String get aboutShareDescription =>
      'Organize your grocery shopping with family using EpiList! Shared lists, automatic calculations, real-time synchronization.';

  @override
  String get aboutDiscoverApp => 'Discover the app';

  @override
  String get aboutShareSubject =>
      'Discover EpiList - Your family grocery assistant!';

  @override
  String get aboutShareError => 'Unable to share at the moment';

  @override
  String get termsLastUpdated => 'Last updated: July 5, 2025';

  @override
  String get termsAcceptanceTitle => '1. Acceptance of Terms';

  @override
  String get termsAcceptanceText =>
      'By using the EpiList application, you agree to be bound by these terms of service. If you do not accept these terms in their entirety, please do not use the application.';

  @override
  String get termsServiceTitle => '2. Service Description';

  @override
  String get termsServiceText =>
      'EpiList is a mobile grocery list management application that allows:\n\n• Creating an account with first name, last name, email and password\n• Creating, editing and deleting grocery lists\n• Adding items with name, quantity, price and store (optional)\n• Marking items as purchased or deleting them\n• Automatically calculating totals and purchase percentages\n• Duplicating existing lists\n• Sharing lists with secure links\n• Managing access permissions (read, edit, administration)\n\nThe service is provided \"as is\" and \"as available\".';

  @override
  String get termsAccountTitle => '3. User Account and Security';

  @override
  String get termsAccountText =>
      'To use EpiList, you must:\n\n• Create an account with accurate information (first name, last name, email)\n• Choose a secure password and keep it confidential\n• Be responsible for all activities performed under your account\n• Notify us immediately of any unauthorized use\n• Update your personal information as necessary\n\nYou are solely responsible for the security of your login credentials.';

  @override
  String get termsUsageTitle => '4. List Usage and Sharing';

  @override
  String get termsUsageText =>
      'Regarding the use of the application\'s features:\n\n• You can create unlimited grocery lists\n• Sharing links are your responsibility\n• You control the access permissions you grant\n• Invited people must respect the defined permissions\n• You can revoke access at any time\n• Shared content must remain appropriate and legal\n\nYou are responsible for managing your shared lists.';

  @override
  String get termsAcceptableTitle => '5. Acceptable Use';

  @override
  String get termsAcceptableText =>
      'You agree to:\n\n• Use the application only for grocery list management\n• Not attempt to disrupt the service operation\n• Not illegally access other users\' data\n• Respect intellectual property rights\n• Not use the application for commercial purposes without authorization\n• Not share offensive or illegal content\n\nAny abusive use may result in immediate account suspension.';

  @override
  String get termsOwnershipTitle => '6. Content Ownership';

  @override
  String get termsOwnershipText =>
      'Regarding the content you create in EpiList:\n\n• You retain ownership of your lists and personal data\n• You grant us a limited license to provide the service\n• You are responsible for the accuracy of your information\n• We claim no rights to your personal data\n• You can export your data at any time\n\nYour data belongs to you and remains under your control.';

  @override
  String get termsCalculationsTitle => '7. Calculations and Prices';

  @override
  String get termsCalculationsText =>
      'Regarding calculation features:\n\n• Totals and percentages are calculated automatically\n• We do not guarantee absolute accuracy of calculations\n• Prices entered are your responsibility\n• Always verify calculations for your important purchases\n• We are not responsible for price errors\n\nUse calculations as an aid, not as an absolute reference.';

  @override
  String get termsAvailabilityTitle => '8. Service Availability';

  @override
  String get termsAvailabilityText =>
      'We strive to ensure continuous service availability, but we do not guarantee:\n\n• Uninterrupted 24/7 access\n• Complete absence of bugs or errors\n• Compatibility with all devices\n• Permanent backup of all data\n\nScheduled maintenance may cause temporary interruptions.';

  @override
  String get termsLiabilityTitle => '9. Limitation of Liability';

  @override
  String get termsLiabilityText =>
      'EpiList and its developers cannot be held responsible for:\n\n• Indirect or consequential damages\n• Data loss due to technical problems\n• Errors in price calculations or totals\n• Incorrect use of provided information\n• Problems related to list sharing\n• Purchases made based on created lists\n\nYour use of the application is at your own risk.';

  @override
  String get termsTerminationTitle => '10. Suspension and Termination';

  @override
  String get termsTerminationText =>
      'We reserve the right to suspend or terminate your access:\n\n• In case of violation of these terms of service\n• For security or maintenance reasons\n• If the account is inactive for more than 24 months\n• In case of abusive use of sharing features\n\nYou can delete your account at any time from the application settings.';

  @override
  String get termsModificationsTitle => '11. Modifications';

  @override
  String get termsModificationsText =>
      'We reserve the right to:\n\n• Modify or improve the application\'s features\n• Update these terms of service\n• Temporarily suspend the service for maintenance\n• Permanently discontinue the service with 60 days\' notice\n\nImportant changes will be notified to you by email or in the application.';

  @override
  String get termsJurisdictionTitle => '12. Applicable Law and Jurisdiction';

  @override
  String get termsJurisdictionText =>
      'These terms of service are governed by Canadian law. Any dispute relating to the use of EpiList will be subject to the jurisdiction of the competent courts of New Brunswick, Canada.';

  @override
  String get termsContactTitle => '13. Contact and Support';

  @override
  String get termsContactText =>
      'For any questions regarding these terms of service or for assistance, please contact us through our website.\n\nWe are committed to responding as quickly as possible.';

  @override
  String get privacyLastUpdated => 'Last updated: July 5, 2025';

  @override
  String get privacyCollectionTitle => '1. Information Collection';

  @override
  String get privacyCollectionText =>
      'EpiList collects the following information for its operation:\n\n• Account information: first name, last name, email, password (encrypted)\n• Grocery list data: list names, items, quantities, prices, stores (optional)\n• Sharing data: sharing links, access permissions (read, edit, administration)\n• Usage data: item purchase status, totals and percentage calculations\n• Technical data: error logs, application performance\n\nWe do not collect any sensitive personal information beyond what is necessary for operation.';

  @override
  String get privacyUsageTitle => '2. Data Usage';

  @override
  String get privacyUsageText =>
      'Your data is used exclusively to:\n\n• Create and manage your user account\n• Create, edit and delete your grocery lists\n• Calculate totals and percentages of purchased items\n• Duplicate your existing lists\n• Share your lists with family members or friends via secure links\n• Manage access permissions (read, edit, administration)\n• Synchronize your data across your devices\n• Provide technical support\n\nWe do not sell or rent your personal data to third parties.';

  @override
  String get privacyStorageTitle => '3. Storage and Security';

  @override
  String get privacyStorageText =>
      'Your data is protected by:\n\n• Secure storage on our servers with encryption\n• Password encryption with secure algorithms\n• Data protection during transit and at rest\n• Secure sharing links with access control\n• Regular backup of your lists and data\n• Security measures compliant with industry standards\n\nWe apply security best practices to protect your information.';

  @override
  String get privacySharingTitle => '4. Data Sharing';

  @override
  String get privacySharingText =>
      'Your personal data is only shared in the following cases:\n\n• With people you authorize via list sharing links\n• With our technical service providers (hosting, support)\n• With legal authorities if required by law\n\nList sharing is done according to the permissions you define:\n• Read-only: viewing lists without modification\n• Edit: adding, deleting and modifying items\n• Administration: complete management including list deletion\n\nNo commercial sharing of your data is performed.';

  @override
  String get privacyRightsTitle => '5. Your Rights';

  @override
  String get privacyRightsText =>
      'You have the right to:\n\n• Access all your personal data\n• Modify your account information (first name, last name, email)\n• Delete your account and all associated data\n• Export your grocery lists\n• Revoke sharing links at any time\n• Modify access permissions for invited users\n• Delete your lists or items individually\n\nContact us to exercise these rights.';

  @override
  String get privacyFeaturesTitle => '6. Application Features';

  @override
  String get privacyFeaturesText =>
      'EpiList processes your data to offer the following features:\n\n• Creation and management of user accounts\n• Creation, duplication, modification and deletion of lists\n• Adding items with name, quantity, price and store (optional)\n• Marking items as purchased or deleting items\n• Automatic calculation of totals and purchase percentages\n• Generation of secure sharing links\n• Management of collaborative access permissions\n\nAll this data remains under your control.';

  @override
  String get privacyCookiesTitle => '7. Cookies and Similar Technologies';

  @override
  String get privacyCookiesText =>
      'EpiList uses tracking technologies to:\n\n• Maintain your active session\n• Remember your usage preferences\n• Analyze application usage (anonymous data)\n• Optimize application performance\n\nYou can disable these functions in the application settings.';

  @override
  String get privacyChangesTitle => '8. Changes';

  @override
  String get privacyChangesText =>
      'This policy may be updated to reflect application developments. We will inform you of important changes by:\n\n• Email to the address associated with your account\n• Updating the date at the top of this policy\n\nYour continued use of the application after changes constitutes your acceptance.';

  @override
  String get privacyContactTitle => '9. Contact';

  @override
  String get privacyContactText =>
      'For any questions regarding this privacy policy or your data, please contact us through our website.\n\nWe are committed to responding within 48 business hours.';

  @override
  String get currency => 'Currency';

  @override
  String get currencies => 'Currencies';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get changeCurrency => 'Change Currency';

  @override
  String get currencySettings => 'Currency Settings';

  @override
  String get currencyCode => 'Currency Code';

  @override
  String get currencySymbol => 'Currency Symbol';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get preferredCurrency => 'Preferred Currency';

  @override
  String get currentCurrency => 'Current Currency';

  @override
  String get noCurrencySet => 'No currency set';

  @override
  String get chooseCurrencyDescription =>
      'Choose your preferred display currency';

  @override
  String get manageCurrencyDescription => 'Manage your currency preferences';

  @override
  String get currencyConversionInfo =>
      'Prices will be automatically converted to your currency';

  @override
  String get showPopularOnly => 'Show popular currencies only';

  @override
  String get convertPrices => 'Convert Prices';

  @override
  String get viewInLocalCurrency => 'View in Local Currency';

  @override
  String get formatUserAmount => 'Format Amount';

  @override
  String get updateCurrency => 'Update Currency';

  @override
  String get select => 'Select';

  @override
  String get each => 'each';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get formattedPrice => 'Formatted Price';

  @override
  String get originalAmount => 'Original Amount';

  @override
  String get convertedAmount => 'Converted Amount';

  @override
  String get exchangeRateToCAD => 'Exchange Rate to CAD';

  @override
  String get popularCurrencies => 'Popular Currencies';

  @override
  String get allCurrencies => 'All Currencies';

  @override
  String get supportedCurrencies => 'Supported Currencies';

  @override
  String get currencyNotFound => 'Currency not found';

  @override
  String get invalidCurrency => 'Invalid currency';

  @override
  String get currencyUpdateFailed => 'Failed to update currency';

  @override
  String get conversionFailed => 'Currency conversion failed';

  @override
  String get exchangeRateNotAvailable => 'Exchange rate not available';

  @override
  String get currencyUpdatedSuccessfully => 'Currency updated successfully';

  @override
  String get currencySelectedSuccessfully => 'Currency selected successfully';

  @override
  String get conversionSuccessful => 'Conversion successful';

  @override
  String get currencyInfo => 'Currency Information';

  @override
  String get rateLastUpdated => 'Rate last updated';

  @override
  String get basedOnCAD => 'Based on Canadian Dollar (CAD)';

  @override
  String get exchangeRateDisclaimer => 'Exchange rates are for reference only';

  @override
  String priceInCurrency(String currency) {
    return 'Price in $currency';
  }

  @override
  String amountInCurrency(String currency) {
    return 'Amount in $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Convert to $currency';
  }

  @override
  String oneXEqualsYCAD(String currency, String rate) {
    return '1 $currency = $rate CAD';
  }

  @override
  String get price => 'Price';

  @override
  String get currencySelectionDialog => 'Currency Selection Dialog';

  @override
  String get chooseCurrencyPreference => 'Choose your currency preference';

  @override
  String get currencyDisplayOnly =>
      'This currency will be used for display only. Prices are not converted.';

  @override
  String get pricesNotConverted => 'Prices are not automatically converted';

  @override
  String get currentSelectedCurrency => 'Currently selected currency';

  @override
  String get loadingCurrencies => 'Loading currencies...';

  @override
  String get noCurrenciesAvailable => 'No currencies available';

  @override
  String get cannotLoadCurrencies => 'Unable to load currencies from server';

  @override
  String get currencyUpdated => 'Your currency has been updated successfully';

  @override
  String get confirmCurrencyChange => 'Confirm currency change';

  @override
  String get currencySettingsTile => 'Currency Settings';

  @override
  String get manageCurrencySettings => 'Manage currency settings';

  @override
  String get defaultCurrencyCAD => 'CAD (default)';

  @override
  String get selectPreferredCurrency => 'Select preferred currency';

  @override
  String get currencySettingsUpdated => 'Currency settings updated';

  @override
  String get selectYourCurrency => 'Select Your Currency';

  @override
  String get chooseDisplayCurrency => 'Choose your display currency';

  @override
  String get currencyForPrices =>
      'This currency will be used to display prices';

  @override
  String get noCurrencySelected => 'No currency selected';

  @override
  String get popularCurrenciesOnly => 'Popular currencies only';

  @override
  String get allAvailableCurrencies => 'All available currencies';

  @override
  String get currencySelectionComplete => 'Currency selection complete';

  @override
  String get applyChanges => 'Apply changes';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get popular => 'Popular';

  @override
  String get analytics => 'Analytics';

  @override
  String get overview => 'Overview';

  @override
  String get trends => 'Trends';

  @override
  String get categories => 'Categories';

  @override
  String get topProducts => 'Top Products';

  @override
  String get userCurrency => 'My Currency';

  @override
  String get noAnalyticsData => 'No analytics data available';

  @override
  String get loadData => 'Load Data';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get monthlyOverview => 'Monthly Overview';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get itemsPurchased => 'Items Purchased';

  @override
  String get uniqueProducts => 'Unique Products';

  @override
  String get shoppingSessions => 'Shopping Sessions';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get averageDailySpending => 'Average Daily Spending';

  @override
  String get busiestDay => 'Busiest Day';

  @override
  String get comparisonWithLastMonth => 'Comparison with Last Month';

  @override
  String get spendingIncreased => 'Spending Increased';

  @override
  String get spendingDecreased => 'Spending Decreased';

  @override
  String get spendingStable => 'Spending Stable';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get noCategoriesData => 'No category data';

  @override
  String get monthlyTrends => 'Monthly Trends';

  @override
  String get monthlyAverage => 'Monthly Average';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get showing => 'Showing';

  @override
  String get noProductsData => 'No product data';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get viewSpendingReports => 'View spending reports';

  @override
  String get manageAllLists => 'Manage all lists';

  @override
  String recentLists(Object count) {
    return 'Recent lists ($count)';
  }

  @override
  String get items => 'items';

  @override
  String get done => 'done';

  @override
  String get shared => 'Shared';

  @override
  String get sharedWithYou => 'Shared with you';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByAmount => 'Sort by amount';

  @override
  String get sortByQuantity => 'By quantity';

  @override
  String get sortByFrequency => 'By frequency';

  @override
  String get unknownProduct => 'Unknown product';

  @override
  String get itemsCount => 'items';

  @override
  String get storesLabel => 'Stores';

  @override
  String get averagePrice => 'Average price';

  @override
  String get stores => 'Stores';

  @override
  String get averagePriceLabel => 'Average price';

  @override
  String get amountSort => 'Amount';

  @override
  String get quantitySort => 'Quantity';

  @override
  String get frequencySort => 'Frequency';

  @override
  String get loadingAnalytics => 'Loading analytics...';

  @override
  String get errorLoadingAnalytics => 'Error loading analytics';

  @override
  String get analyticsUnavailable => 'Analytics unavailable';

  @override
  String get refreshAnalytics => 'Refresh analytics';

  @override
  String get rank => 'Rank';

  @override
  String get ranking => 'Ranking';

  @override
  String get position => 'Position';

  @override
  String get topRanked => 'Top ranked';

  @override
  String get mostPurchased => 'Most purchased';

  @override
  String get frequentlyBought => 'Frequently bought';

  @override
  String get times => 'times';

  @override
  String get timesSingular => 'time';

  @override
  String get timesPlural => 'times';

  @override
  String get purchases => 'purchases';

  @override
  String get purchase => 'purchase';

  @override
  String get analyticsError => 'Analytics error';

  @override
  String get noAnalyticsAvailable => 'No analytics available';

  @override
  String get analyticsLoading => 'Loading...';

  @override
  String get dataNotAvailable => 'Data not available';

  @override
  String get selectPeriod => 'Select period';

  @override
  String get changePeriod => 'Change period';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get period => 'Period';

  @override
  String get timeframe => 'Timeframe';

  @override
  String get chooseCurrency => 'Choose currency';

  @override
  String get displayCurrency => 'Display currency';

  @override
  String get currencyFormat => 'Currency format';

  @override
  String get viewDetails => 'View details';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get expandChart => 'Expand chart';

  @override
  String get collapseChart => 'Collapse chart';

  @override
  String get statistics => 'Statistics';

  @override
  String get dataRange => 'Data range';

  @override
  String get noDataFound => 'No data found';

  @override
  String get insufficientData => 'Insufficient data';

  @override
  String get calculatingData => 'Calculating data...';

  @override
  String get networkErrorAnalytics => 'Network error loading analytics';

  @override
  String get serverErrorAnalytics => 'Server error for analytics';

  @override
  String get timeoutErrorAnalytics => 'Timeout error for analytics';

  @override
  String get noSpendingRecorded => 'No spending recorded';

  @override
  String get dailyTrends => 'Daily trends';

  @override
  String get weeklyTrends => 'Weekly trends';

  @override
  String get yearlyTrends => 'Yearly trends';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get dailyAverage => 'Daily average';

  @override
  String get weeklyAverage => 'Weekly average';

  @override
  String get yearlyAverage => 'Yearly average';

  @override
  String get choosePeriod => 'Choose period';

  @override
  String get updateChart => 'Update chart';

  @override
  String get refreshChart => 'Refresh chart';

  @override
  String get chartData => 'Chart data';

  @override
  String get barChart => 'Bar chart';

  @override
  String get lineChart => 'Line chart';

  @override
  String get noChartData => 'No chart data';

  @override
  String get loadingChart => 'Loading chart...';

  @override
  String get summaryData => 'Summary data';

  @override
  String get periodSummary => 'Period summary';

  @override
  String get averageSpending => 'Average spending';

  @override
  String get totalForPeriod => 'Total for period';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get currentPeriod => 'Current period';

  @override
  String get comparePeriods => 'Compare periods';

  @override
  String get dataLoadingError => 'Data loading error';

  @override
  String get chartError => 'Chart error';

  @override
  String get noDataForPeriod => 'No data for this period';

  @override
  String get selectDifferentPeriod => 'Select a different period';

  @override
  String weekNumber(int number) {
    return 'Week $number';
  }

  @override
  String weekLabel(int number) {
    return 'W$number';
  }

  @override
  String get receipts => 'Receipts';

  @override
  String get allReceipts => 'All';

  @override
  String get byStore => 'By Store';

  @override
  String get addReceipt => 'Add Receipt';

  @override
  String get editReceipt => 'Edit Receipt';

  @override
  String get deleteReceipt => 'Delete Receipt';

  @override
  String get deleteReceiptConfirm =>
      'Are you sure you want to delete this receipt?';

  @override
  String get noReceipts => 'No receipts';

  @override
  String get addFirstReceipt =>
      'Add your first receipt to track your actual spending';

  @override
  String get enterStoreName => 'Enter store name';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get notes => 'Notes';

  @override
  String get optionalNotes => 'Optional notes';

  @override
  String get storeNameRequired => 'Store name is required';

  @override
  String get storeNameTooShort => 'Name must be at least 2 characters';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get amountMustBePositive => 'Amount must be positive';

  @override
  String get amountTooHigh => 'Amount is too high';

  @override
  String get spendingSummary => 'Spending Summary';

  @override
  String get totalExpensesSummary => 'Overview of your expenses';

  @override
  String get totalFromReceipts => 'Total from receipts';

  @override
  String get totalFromItems => 'Total from items';

  @override
  String get bestEstimate => 'Best estimate';

  @override
  String get dataComparison => 'Data Comparison';

  @override
  String get receiptVsItemComparison => 'Receipts vs item prices';

  @override
  String get dataQuality => 'Data Quality';

  @override
  String get dataQualityExcellent => 'Excellent';

  @override
  String get dataQualityGood => 'Good';

  @override
  String get dataQualityFair => 'Fair';

  @override
  String get dataQualityPoor => 'Poor';

  @override
  String get dataQualityUnknown => 'Unknown';

  @override
  String get addReceiptsRecommendation => 'Add receipts for more accurate data';

  @override
  String get addItemPricesRecommendation => 'Add item prices for more details';

  @override
  String significantVarianceDetected(String percentage) {
    return 'Significant variance detected ($percentage%)';
  }

  @override
  String get lastVisit => 'Last visit';

  @override
  String get added => 'Added';

  @override
  String get receiptAddedSuccessfully => 'Receipt added successfully';

  @override
  String get receiptUpdatedSuccessfully => 'Receipt updated successfully';

  @override
  String get receiptDeletedSuccessfully => 'Receipt deleted successfully';

  @override
  String get receiptsLoadedSuccessfully => 'Receipts loaded successfully';

  @override
  String get errorLoadingReceipts => 'Error loading receipts';

  @override
  String get errorAddingReceipt => 'Error adding receipt';

  @override
  String get errorUpdatingReceipt => 'Error updating receipt';

  @override
  String get errorDeletingReceipt => 'Error deleting receipt';

  @override
  String get receiptValidationError => 'Invalid receipt data';

  @override
  String get storeNameInvalid => 'Invalid store name';

  @override
  String get amountTooLow => 'Amount too low';

  @override
  String get dateInFuture => 'Date cannot be in the future';

  @override
  String get dateTooOld => 'Date cannot be more than 2 years ago';

  @override
  String get notesTooLong => 'Notes too long (max 1000 characters)';

  @override
  String get receiptDetails => 'Receipt Details';

  @override
  String get receiptInformation => 'Receipt Information';

  @override
  String get manageReceipts => 'Manage Receipts';

  @override
  String get viewReceipts => 'View Receipts';

  @override
  String get receiptHistory => 'Receipt History';

  @override
  String get totalReceipts => 'Total Receipts';

  @override
  String get averageReceiptAmount => 'Average Receipt Amount';

  @override
  String get largestReceipt => 'Largest Receipt';

  @override
  String get smallestReceipt => 'Smallest Receipt';

  @override
  String get mostFrequentStore => 'Most Frequent Store';

  @override
  String get comparisonResults => 'Comparison Results';

  @override
  String get dataAccuracy => 'Data Accuracy';

  @override
  String get recommendationsTitle => 'Recommendations';

  @override
  String get improvementsNeeded => 'Improvements Needed';

  @override
  String get wellDoneMessage => 'Well done! Your data is accurate';

  @override
  String get addMoreReceiptsAdvice => 'Add more receipts to improve accuracy';

  @override
  String get priceItemsAdvice =>
      'Add prices to your items for better estimates';

  @override
  String get loadingReceiptStats => 'Loading receipt statistics...';

  @override
  String get noReceiptStats => 'No receipt statistics available';

  @override
  String get receiptStatsUnavailable => 'Receipt statistics unavailable';

  @override
  String get refreshReceiptStats => 'Refresh statistics';

  @override
  String get receiptOperationFailed => 'Receipt operation failed';

  @override
  String get backToReceipts => 'Back to receipts';

  @override
  String get addNewReceipt => 'Add new receipt';

  @override
  String get editReceiptInfo => 'Edit receipt information';

  @override
  String get duplicateReceipt => 'Duplicate receipt';

  @override
  String get shareReceipt => 'Share receipt';

  @override
  String get exportReceipts => 'Export receipts';

  @override
  String get importReceipts => 'Import receipts';

  @override
  String get filterByStore => 'Filter by store';

  @override
  String get filterByDate => 'Filter by date';

  @override
  String get filterByAmount => 'Filter by amount';

  @override
  String get sortByDate => 'Sort by date';

  @override
  String get sortByStore => 'Sort by store';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get highestFirst => 'Highest amount first';

  @override
  String get lowestFirst => 'Lowest amount first';

  @override
  String get cannotAddReceipt => 'Cannot add receipt';

  @override
  String get cannotEditReceipt => 'Cannot edit receipt';

  @override
  String get cannotDeleteReceipt => 'Cannot delete receipt';

  @override
  String get receiptPermissionDenied =>
      'Permission denied for receipt operations';

  @override
  String get receiptReadOnlyAccess => 'Read-only access to receipts';

  @override
  String get receiptDateFormat => 'Receipt date format';

  @override
  String get amountDisplayFormat => 'Amount display format';

  @override
  String receiptNumberFormat(int number) {
    return 'Receipt #$number';
  }

  @override
  String get receiptSavedSuccessfully => 'Receipt saved successfully';

  @override
  String get receiptDeletedPermanently => 'Receipt deleted permanently';

  @override
  String get allReceiptsCleared => 'All receipts cleared';

  @override
  String get receiptDataExported => 'Receipt data exported';

  @override
  String get receiptDataImported => 'Receipt data imported';

  @override
  String get receiptHelpTitle => 'About Receipts';

  @override
  String get receiptHelpDescription =>
      'Add your actual shopping receipts to track real spending versus estimated costs';

  @override
  String get receiptBenefits => 'Benefits of adding receipts';

  @override
  String get accurateSpendingData => '• Accurate spending data';

  @override
  String get betterBudgetTracking => '• Better budget tracking';

  @override
  String get spendingComparisons => '• Compare estimates vs actual costs';

  @override
  String get storeSpendingAnalysis => '• Analyze spending by store';

  @override
  String get error => 'Error';
}
