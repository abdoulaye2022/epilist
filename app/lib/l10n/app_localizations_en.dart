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
  String get hello => 'Hello!';

  @override
  String get manageGroceryLists => 'Manage your grocery lists easily';

  @override
  String get myGroceryLists => 'My Grocery Lists';

  @override
  String get viewAll => 'View all';

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
  String get completed => 'Completed';

  @override
  String get inProgress => 'In progress';

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
  String get yesterday => 'Yesterday';

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
  String get attention => 'WARNING';

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
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineUnavailableHint =>
      'This section is not available offline. Reconnect and try again.';

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
  String get errorLoadingSuggestions => 'Failed to load suggestions';

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
  String get basedOnHistory => 'Based on your shopping history';

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
      'Choose your preferred currency for prices';

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
  String get currencyDisplayOnly => 'Display only';

  @override
  String get pricesNotConverted => 'Prices are not automatically converted';

  @override
  String get currentSelectedCurrency => 'Currently selected currency';

  @override
  String get loadingCurrencies => 'Loading available currencies...';

  @override
  String get noCurrenciesAvailable => 'No currencies available at the moment';

  @override
  String get cannotLoadCurrencies => 'Unable to load currency list';

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
  String get amountTooHigh => 'Amount is too high (max 999,999.99)';

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
  String get sortByStore => 'Store';

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

  @override
  String get budgets => 'Budgets';

  @override
  String get createBudget => 'Create Budget';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get deleteBudget => 'Delete Budget';

  @override
  String get quickBudget => 'Quick Budget';

  @override
  String get budgetName => 'Budget Name';

  @override
  String get budgetNameHint => 'Ex: Monthly Groceries';

  @override
  String get budgetAmount => 'Budget Amount';

  @override
  String get budgetAmountRequired => 'Budget amount is required';

  @override
  String get budgetAmountInvalid => 'Invalid budget amount';

  @override
  String get budgetAmountTooHigh => 'Budget amount too high';

  @override
  String get budgetNameRequired => 'Budget name is required';

  @override
  String get budgetNameTooShort => 'Budget name too short';

  @override
  String get periodType => 'Period Type';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get alertThreshold => 'Alert Threshold';

  @override
  String get alertThresholdDescription =>
      'Get an alert when this percentage of budget is reached';

  @override
  String get associatedList => 'Associated List';

  @override
  String get generalBudget => 'General Budget';

  @override
  String get budgetCreatedSuccessfully => 'Budget created successfully';

  @override
  String get budgetUpdatedSuccessfully => 'Budget updated successfully';

  @override
  String get budgetDeletedSuccessfully => 'Budget deleted successfully';

  @override
  String get errorLoadingBudgets => 'Error loading budgets';

  @override
  String get budgetSummary => 'Budget Summary';

  @override
  String get overviewOfYourBudgets => 'Overview of your budgets';

  @override
  String get totalBudgets => 'Total Budgets';

  @override
  String get active => 'Active';

  @override
  String get warnings => 'Warnings';

  @override
  String get exceeded => 'Exceeded';

  @override
  String get noBudgetsYet => 'No budgets yet';

  @override
  String get createFirstBudgetDescription =>
      'Create your first budget to manage your expenses';

  @override
  String get noActiveBudgets => 'No active budgets';

  @override
  String get createActiveBudgetDescription =>
      'Create an active budget to start tracking';

  @override
  String get noBudgetAlerts => 'No budget alerts';

  @override
  String get allBudgetsOnTrack => 'All your budgets are on track';

  @override
  String get budgeted => 'Budgeted';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get pause => 'Pause';

  @override
  String get activate => 'Activate';

  @override
  String get custom => 'Custom';

  @override
  String get alerts => 'Alerts';

  @override
  String get createQuickBudget => 'Create quick budget';

  @override
  String get createMonthlyBudget => 'Create monthly budget';

  @override
  String get quickBudgetDescription =>
      'Create a budget quickly with predefined templates';

  @override
  String get monthlyBudgetDescription => 'Budget for the current month';

  @override
  String get yearlyBudgetDescription => 'Budget for the current year';

  @override
  String get weeklyBudgetDescription => 'Budget for the current week';

  @override
  String get selectBudgetType => 'Select budget type';

  @override
  String get createBudgetQuickly => 'Create a budget quickly';

  @override
  String get weeklyBudget => 'Weekly Budget';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get yearlyBudget => 'Yearly Budget';

  @override
  String get recentBudgets => 'Recent Budgets';

  @override
  String deleteBudgetConfirmation(String budgetName) {
    return 'Are you sure you want to delete budget \"$budgetName\"?';
  }

  @override
  String get setBudgetForPeriod => 'Set budget for period';

  @override
  String get modifyBudgetDetails => 'Modify budget details';

  @override
  String get expired => 'Expired';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get warning => 'Warning';

  @override
  String get sortByName => 'Name';

  @override
  String get filters => 'Filters';

  @override
  String get scope => 'Scope';

  @override
  String get general => 'General';

  @override
  String get specific => 'Specific';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get update => 'Update';

  @override
  String get filtersAndSort => 'Filters & Sort';

  @override
  String get spendingProgress => 'Spending Progress';

  @override
  String get specificList => 'Specific List';

  @override
  String get budgetPeriod => 'Budget Period';

  @override
  String get pleaseEnterAmount => 'Please enter amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get budgetScope => 'Budget Scope';

  @override
  String get enterBudgetName => 'Enter budget name';

  @override
  String get pleaseEnterBudgetName => 'Please enter budget name';

  @override
  String get preview => 'Preview';

  @override
  String get type => 'Type';

  @override
  String get amount => 'Amount';

  @override
  String get generalBudgetDescription => 'Applies to all your shopping lists';

  @override
  String get orSelectSpecificList => 'Or select a specific list';

  @override
  String get unknownList => 'Unknown list';

  @override
  String get date => 'Date';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get days => 'jours';

  @override
  String get all => 'All';

  @override
  String get budgetPeriodTypeWeekly => 'Weekly';

  @override
  String get budgetPeriodTypeMonthly => 'Monthly';

  @override
  String get budgetPeriodTypeYearly => 'Yearly';

  @override
  String get budgetPeriodTypeCustom => 'Custom';

  @override
  String get budgetFilterAll => 'All';

  @override
  String get budgetFilterActive => 'Active';

  @override
  String get budgetFilterInactive => 'Inactive';

  @override
  String get budgetFilterExpired => 'Expired';

  @override
  String get budgetFilterUpcoming => 'Upcoming';

  @override
  String get budgetFilterWarning => 'Warning';

  @override
  String get budgetFilterExceeded => 'Exceeded';

  @override
  String get budgetScopeGeneral => 'General';

  @override
  String get budgetScopeSpecific => 'Specific to a list';

  @override
  String get budgetValidationNameRequired => 'Budget name is required';

  @override
  String get budgetValidationNameTooShort =>
      'Budget name must be at least 3 characters';

  @override
  String get budgetValidationNameTooLong =>
      'Budget name cannot exceed 50 characters';

  @override
  String get budgetValidationAmountRequired => 'Budget amount is required';

  @override
  String get budgetValidationAmountMustBePositive =>
      'Budget amount must be positive';

  @override
  String get budgetValidationAmountTooHigh =>
      'Budget amount cannot exceed 999,999.99';

  @override
  String get budgetValidationStartDateRequired => 'Start date is required';

  @override
  String get budgetValidationEndDateRequired => 'End date is required';

  @override
  String get budgetValidationEndDateAfterStart =>
      'End date must be after start date';

  @override
  String get budgetValidationAlertThresholdInvalid =>
      'Alert threshold must be between 1 and 100';

  @override
  String get hideFilters => 'Hide filters';

  @override
  String get showFilters => 'Show filters';

  @override
  String get moreOptions => 'More options';

  @override
  String get toggleBudgetStatus => 'Toggle budget status';

  @override
  String get viewBudgetDetails => 'View budget details';

  @override
  String get pauseBudget => 'Pause budget';

  @override
  String get resumeBudget => 'Resume budget';

  @override
  String get budgetOnTrack => 'Budget on track';

  @override
  String get budgetWarning => 'Budget warning';

  @override
  String get budgetExceeded => 'Budget exceeded';

  @override
  String get budgetDetails => 'Budget Details';

  @override
  String get budgetProgress => 'Budget Progress';

  @override
  String get spentAmount => 'Amount Spent';

  @override
  String get remainingAmount => 'Amount Remaining';

  @override
  String get budgetStatus => 'Budget Status';

  @override
  String get budgetCreateError => 'Error creating budget';

  @override
  String get budgetUpdateError => 'Error updating budget';

  @override
  String get budgetDeleteError => 'Error deleting budget';

  @override
  String get budgetLoadError => 'Error loading budget';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryAdjustingFilters =>
      'Try adjusting your filters or clear current filters';

  @override
  String get daysRemaining => 'days remaining';

  @override
  String get dayRemaining => 'day remaining';

  @override
  String get epilistUser => 'EpiList User';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get appLogoError => 'Logo loading error';

  @override
  String get userMenuHeader => 'User Menu';

  @override
  String get userRole => 'User Role';

  @override
  String get accessLevel => 'Access Level';

  @override
  String get confirmAction => 'Confirm Action';

  @override
  String get menuOptions => 'Menu Options';

  @override
  String get userActions => 'User Actions';

  @override
  String get appReady => 'Application Ready';

  @override
  String get loadingUser => 'Loading User';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get readOnly => 'Read only';

  @override
  String get addItems => 'add items';

  @override
  String get deleteItems => 'delete items';

  @override
  String get modifyItemStatus => 'modify item status';

  @override
  String cannotPerformActionReadOnly(String action, String permission) {
    return 'You cannot $action because this list is in read-only mode.\n\nYour current permission: $permission';
  }

  @override
  String cannotPerformAction(String action, String permission) {
    return 'You don\'t have permission to $action.\n\nYour current permission: $permission';
  }

  @override
  String get codePastedSuccessfully => 'Code pasted successfully!';

  @override
  String get codePartiallyPasted => 'Code partially pasted';

  @override
  String get noCodeFoundInClipboard => 'No code found in clipboard';

  @override
  String get errorPastingCode => 'Error pasting code';

  @override
  String get pasteCode => 'Paste code';

  @override
  String get clear => 'Clear';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get export => 'Export';

  @override
  String get exportReceiptsDescription =>
      'Export your receipts to PDF or CSV format';

  @override
  String get exportToPDF => 'Export to PDF';

  @override
  String get exportToCSV => 'Export to CSV';

  @override
  String get exportPDFInProgress => 'PDF export in progress...';

  @override
  String get exportCSVInProgress => 'CSV export in progress...';

  @override
  String get addFirstReceiptToStart =>
      'Add your first receipt to start tracking your actual spending';

  @override
  String get createReceiptNow => 'Create a receipt now';

  @override
  String get errorExportingReceipts => 'Error exporting receipts';

  @override
  String get exportCompletedSuccessfully => 'Export completed successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get refreshingData => 'Refreshing data...';

  @override
  String get dataRefreshedSuccessfully => 'Data refreshed successfully';

  @override
  String get exportOptions => 'Export options';

  @override
  String get selectExportFormat => 'Select export format';

  @override
  String get exportToPDFFile => 'Export to PDF file';

  @override
  String get exportToCSVFile => 'Export to CSV file';

  @override
  String get exportStarted => 'Export started';

  @override
  String get checkDownloadsFolder => 'Check your downloads folder';

  @override
  String get pdfExportError => 'PDF export error';

  @override
  String get csvExportError => 'CSV export error';

  @override
  String get fileCreationError => 'File creation error';

  @override
  String get permissionDeniedError => 'Permission denied for file creation';

  @override
  String get overBudget => 'Over Budget';

  @override
  String get highestPurchase => 'Highest Purchase';

  @override
  String get topCategory => 'Top Category';

  @override
  String get mostFrequentCategory => 'Most Frequent Category';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get includeSharedLists => 'Include shared lists';

  @override
  String get showingOnlyOwnLists => 'Showing only your own lists';

  @override
  String get spendingBreakdown => 'Spending Breakdown';

  @override
  String get myLists => 'My Lists';

  @override
  String get sharedLists => 'Shared Lists';

  @override
  String get ownListsOnly => 'Own lists only';

  @override
  String get dataSourceBreakdown => 'Data Source Breakdown';

  @override
  String get andXMore => 'And';

  @override
  String get moreCategories => 'more categories';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get mayShort => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get support => 'Support';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get feedbackSubtitle => 'Help us improve EpiList';

  @override
  String get feedbackDescription =>
      'Your feedback helps us improve EpiList. Describe your experience, report a bug, or suggest improvements.';

  @override
  String get feedbackType => 'Feedback Type';

  @override
  String get priority => 'Priority';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Message';

  @override
  String get subjectHint => 'Briefly describe your feedback...';

  @override
  String get subjectRequired => 'Subject is required';

  @override
  String get subjectTooShort => 'Subject must be at least 5 characters';

  @override
  String get messageHint =>
      'Describe in detail your feedback, encountered problem or improvement suggestion...';

  @override
  String get messageRequired => 'Message is required';

  @override
  String get messageTooShort => 'Message must be at least 10 characters';

  @override
  String get feedbackPrivacyNote =>
      'Your feedback will be sent to our technical team. No sensitive personal information will be shared.';

  @override
  String get bugReport => 'Report a bug';

  @override
  String get bugReportDescription => 'Technical issue or malfunction';

  @override
  String get newFeature => 'New feature';

  @override
  String get newFeatureDescription => 'Improvement suggestion or new feature';

  @override
  String get improvement => 'Improvement';

  @override
  String get improvementDescription => 'Enhancement of existing feature';

  @override
  String get question => 'Question';

  @override
  String get questionDescription => 'Help or usage question';

  @override
  String get other => 'Other';

  @override
  String get otherDescription => 'Other type of feedback';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get signUpWithApple => 'Sign up with Apple';

  @override
  String get ssoDisclaimer => 'By using SSO, you agree to our terms of service';

  @override
  String get ssoSignupDisclaimer =>
      'By signing up via SSO, you agree to our terms';

  @override
  String get quickSignupWithSSO => 'Quick signup with SSO';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get activeFilters => 'Active filters';

  @override
  String get allStores => 'All stores';

  @override
  String get noStoresAvailable => 'No stores available';

  @override
  String get purchased => 'Purchased';

  @override
  String get unpurchased => 'Unpurchased';

  @override
  String get sortByPrice => 'Price';

  @override
  String get sortByDateAdded => 'Date added';

  @override
  String get category => 'Category';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get selectCategory => 'Select category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryIcon => 'Category icon';

  @override
  String get categoryColor => 'Category color';

  @override
  String get noCategorySelected => 'No category selected';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get categoryCreatedSuccessfully => 'Category created successfully';

  @override
  String get categoryUpdatedSuccessfully => 'Category updated successfully';

  @override
  String get categoryDeletedSuccessfully => 'Category deleted successfully';

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get errorCreatingCategory => 'Error creating category';

  @override
  String get errorUpdatingCategory => 'Error updating category';

  @override
  String get errorDeletingCategory => 'Error deleting category';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryNameTooShort => 'Name must be at least 2 characters';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get createFirstCategoryDescription =>
      'Create your first category to organize your items';

  @override
  String get deleteCategoryConfirm =>
      'Are you sure you want to delete this category?';

  @override
  String get selectIcon => 'Select icon';

  @override
  String get selectColor => 'Select color';

  @override
  String get categoryFruitsVegetables => 'Fruits & Vegetables';

  @override
  String get categoryMeatFish => 'Meat & Fish';

  @override
  String get categoryDairy => 'Dairy Products';

  @override
  String get categoryBakery => 'Bakery';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categorySnacksSweets => 'Snacks & Sweets';

  @override
  String get categoryHygieneBeauty => 'Hygiene & Beauty';

  @override
  String get categoryHouseholdCleaning => 'Household Cleaning';

  @override
  String get categoryBabyKids => 'Baby & Kids';

  @override
  String get categoryPets => 'Pets';

  @override
  String get categoryHealthPharmacy => 'Health & Pharmacy';

  @override
  String get categoryOther => 'Other';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get allCategories => 'All categories';

  @override
  String get modifyCategoryInfo => 'Modify category information';

  @override
  String get createNewCategory =>
      'Create a new category to organize your items';

  @override
  String get searchIcon => 'Search for an icon...';

  @override
  String get noIconFound => 'No icon found';

  @override
  String get chatTitle => 'Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get startConversation => 'Start the conversation by sending a message';

  @override
  String get errorLoadingMessages => 'Failed to load messages';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deleteMessageConfirmation =>
      'Are you sure you want to delete this message?';

  @override
  String get chatWithTeam => 'Chat with team';

  @override
  String get openChat => 'Open chat';

  @override
  String get smartSuggestions => 'Smart Suggestions';

  @override
  String get loadingSuggestions => 'Loading suggestions...';

  @override
  String get buySoon => 'Buy Soon';

  @override
  String get reject => 'Reject';

  @override
  String get addToList => 'Add to List';

  @override
  String get suggestionAdded => 'Suggestion added to list';

  @override
  String get noSuggestionsDescription =>
      'Start shopping to get personalized suggestions';

  @override
  String get highConfidence => 'Highly Recommended';

  @override
  String get mediumConfidence => 'Good Matches';

  @override
  String get lowConfidence => 'You Might Like';

  @override
  String get suggestionsInfoDescription =>
      'We analyze your shopping history to suggest products you might need.';

  @override
  String get patternBased => 'Pattern-based';

  @override
  String get patternBasedDescription => 'Based on how often you buy items';

  @override
  String get seasonal => 'Seasonal';

  @override
  String get seasonalDescription => 'Products you buy during specific periods';

  @override
  String get associations => 'Associations';

  @override
  String get associationsDescription => 'Items often bought together';

  @override
  String get trending => 'Trending';

  @override
  String get trendingDescription => 'Popular items right now';

  @override
  String oftenBoughtWith(Object item) {
    return 'Often bought with $item';
  }

  @override
  String get seasonalProduct => 'Seasonal product';

  @override
  String get confidenceScore => 'Confidence';

  @override
  String get buyRegularly => 'You buy this regularly';

  @override
  String get addReceiptDescription => 'Add a new receipt to your list';

  @override
  String get editReceiptDescription => 'Edit your receipt information';

  @override
  String get noChangeDetected => 'No changes detected';

  @override
  String get synchronizing => 'Synchronizing';

  @override
  String get offlineWithPendingActions => 'Offline with pending actions';

  @override
  String get pendingActions => 'Pending Actions';

  @override
  String get allSynced => 'All synced';

  @override
  String get syncInProgress => 'Sync in progress...';

  @override
  String get willSyncWhenOnline => 'Will sync when back online';

  @override
  String get tapToViewDetails => 'Tap to view details';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get connectionStatus => 'Connection';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get syncState => 'Sync State';

  @override
  String get syncing => 'Syncing';

  @override
  String get idle => 'Idle';

  @override
  String get offlineDataWillSync =>
      'Your changes will be automatically synced when you\'re back online';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get offlineModeModificationsWillSync =>
      'Offline mode - Changes will be synced later';

  @override
  String get connectionRestored => 'Connection restored';

  @override
  String get preferencesSavedSuccessfully => 'Preferences saved successfully';

  @override
  String get errorSavingPreferences => 'Error saving preferences';

  @override
  String get emailPreferencesUnavailableOffline =>
      'Email preferences unavailable offline';

  @override
  String get visitPageOnlineToCache =>
      'Please visit this page while online to cache your preferences';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get loadingOptions => 'Loading options...';

  @override
  String get pleaseSelectFeedbackTypeAndPriority =>
      'Please select a feedback type and priority';

  @override
  String get voiceListening => 'Listening...';

  @override
  String get voiceTapToSpeak => 'Tap to speak';

  @override
  String get voicePermissionDenied => 'Microphone permission denied';

  @override
  String get voicePermissionRequired =>
      'Microphone access is required for voice input';

  @override
  String get voiceItemAdded => 'Item added by voice';

  @override
  String get voiceRequiresInternet =>
      'Voice recognition requires an Internet connection';

  @override
  String get voiceVerifyAndModify => 'Verify and modify if necessary:';

  @override
  String get voiceItemName => 'Item name';

  @override
  String get voiceQuantity => 'Quantity';

  @override
  String get voiceRetry => 'Retry';

  @override
  String get voiceAdd => 'Add';

  @override
  String get voiceExamplesTitle => 'Example commands:';

  @override
  String get voiceExamples =>
      '• \"3 apples\"\n• \"5 kilograms of tomatoes\"\n• \"Bread\"\n• \"2 liters of milk\"';

  @override
  String get myStores => 'My stores';

  @override
  String get addStore => 'Add a store';

  @override
  String get renameStore => 'Rename store';

  @override
  String get deleteStore => 'Delete store';

  @override
  String deleteStoreConfirm(String name) {
    return 'Delete “$name”? Its aisle order will be kept if you recreate it.';
  }

  @override
  String get aisleOrder => 'Aisle order';

  @override
  String get aisleOrderHint =>
      'Drag the aisles in the order you walk through them in this store. Your list will sort itself automatically.';

  @override
  String get noStoresYet => 'No stores';

  @override
  String get noStoresHint =>
      'Add your stores to sort your lists by their aisle order.';

  @override
  String get storeCreated => 'Store added';

  @override
  String get storeRenamed => 'Store renamed';

  @override
  String get storeDeleted => 'Store deleted';

  @override
  String get aisleOrderSaved => 'Aisle order saved';

  @override
  String get sortByAisle => 'By aisle';

  @override
  String get chooseStore => 'I\'m at store...';

  @override
  String get noActiveStore => 'No store';

  @override
  String get aisleOrderNotConfigured =>
      'First set this store\'s aisle order in Profile > My stores.';

  @override
  String get mergeStore => 'Merge with...';

  @override
  String mergeStoreConfirm(String source, String target) {
    return 'Merge “$source” into “$target”? “$target” will be kept and inherit the aisle order if needed.';
  }

  @override
  String get storesMerged => 'Stores merged';

  @override
  String get mergeUnavailableOffline => 'Merge unavailable offline';

  @override
  String get storePendingSync => 'Waiting for sync';

  @override
  String get uncategorizedAisle => 'Uncategorized';

  @override
  String get shareAndCollaborate => 'Share your lists with family';

  @override
  String get trackYourBudget => 'Track your grocery budgets';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get photoRemoved => 'Photo removed';

  @override
  String get photoUploadFailed => 'Photo upload failed';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get productPhoto => 'Product photo';

  @override
  String get helloGreeting => 'Hello 👋';

  @override
  String get readyToShop => 'Ready for your next groceries?';

  @override
  String get budgetOfMonth => 'Budget of the month';

  @override
  String get seeDetail => 'See details';

  @override
  String remainingThisMonth(String amount) {
    return '$amount left this month';
  }

  @override
  String get withinBudget => 'You\'re within budget!';

  @override
  String get budgetExceededShort => 'Budget exceeded';

  @override
  String get createBudgetCta => 'Create a budget to track your spending';

  @override
  String get spendingThisMonth => 'Spending this month';

  @override
  String get quickAddItem => 'Add an item';

  @override
  String get quickVoice => 'Add by voice';

  @override
  String get onLastList => 'On your latest list';

  @override
  String get noListYet => 'Create a list first';

  @override
  String get newListShort => 'New list';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String noBudgetForMonth(String month) {
    return 'No budget for $month';
  }

  @override
  String get pickMonth => 'Pick a month';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get scanReceipt => 'Scan a receipt';

  @override
  String get scanReceiptSubtitle =>
      'Snap your receipt, EpiList reads the prices';

  @override
  String get receiptFromCamera => 'Take a photo of the receipt';

  @override
  String get receiptFromGallery => 'Choose from gallery';

  @override
  String get readingReceipt => 'Reading receipt…';

  @override
  String get ocrFailed =>
      'Couldn\'t read the receipt. You can enter the items manually.';

  @override
  String get reviewReceipt => 'Review receipt';

  @override
  String get reviewReceiptHint =>
      'Check and fix before saving. Nothing is saved automatically.';

  @override
  String get storeLabel => 'Store';

  @override
  String get purchaseDateLabel => 'Purchase date';

  @override
  String get receiptNumberLabel => 'Receipt # (optional)';

  @override
  String get receiptTotalLabel => 'Receipt total';

  @override
  String receiptItemsSection(int count) {
    return 'Items ($count)';
  }

  @override
  String get addReceiptItem => 'Add an item';

  @override
  String get uncertainLine => 'Needs review';

  @override
  String get discountLine => 'Discount / return (not counted)';

  @override
  String unrecognizedLinesTitle(int count) {
    return 'Unrecognized lines ($count)';
  }

  @override
  String totalMismatchWarning(String sum, String total) {
    return 'Items sum ($sum) doesn\'t match the read total ($total).';
  }

  @override
  String get saveReceipt => 'Save receipt';

  @override
  String get receiptSaved => 'Receipt saved. Prices feed your history.';

  @override
  String get duplicateReceiptTitle => 'Duplicate receipt?';

  @override
  String get duplicateReceiptMessage =>
      'This receipt seems to have been added already. Save it anyway?';

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get itemNameLabel => 'Product';

  @override
  String rawLabelHint(String label) {
    return 'Receipt label: $label';
  }

  @override
  String get priceLabel => 'Price';

  @override
  String suggestionApplied(String name) {
    return 'Suggestion: $name';
  }

  @override
  String get priceHistoryTitle => 'Price history';

  @override
  String get noPriceHistory =>
      'No known price for this product yet. It will appear after your next purchases or receipt scans.';

  @override
  String get lastPaidPrice => 'Last price paid';

  @override
  String get usualPrice => 'Usual price';

  @override
  String get priceRange => 'Min – max';

  @override
  String aboveUsualPrice(String pct) {
    return 'Higher than your usual average (+$pct%)';
  }

  @override
  String belowUsualPrice(String pct) {
    return 'Lower than your usual average ($pct%)';
  }

  @override
  String seenOnReceipt(String store, String date) {
    return 'Seen on your $store receipt · $date';
  }

  @override
  String seenOnPurchase(String store, String date) {
    return 'Bought at $store · $date';
  }

  @override
  String observationsInWindow(int count, int days) {
    return '$count observations over $days days';
  }

  @override
  String get compareStores => 'Compare stores';

  @override
  String get storeComparisonTitle => 'Store comparison';

  @override
  String comparisonBasedOn(int days) {
    return 'Based on your purchases from the last $days days. These are not official prices.';
  }

  @override
  String knownPricesOn(int known, int total) {
    return '$known known prices out of $total items';
  }

  @override
  String get noComparisonData =>
      'Not enough data yet. Scan a few receipts to compare your stores.';

  @override
  String get priceFreshnessFresh => 'recent';

  @override
  String get priceFreshnessAcceptable => '< 1 month';

  @override
  String get priceFreshnessOld => '< 3 months';

  @override
  String get priceFreshnessStale => 'old';

  @override
  String get unknownPrice => 'unknown price';

  @override
  String get optimizePlan => 'Optimize my shopping';

  @override
  String get optimizationTitle => 'Optimized shopping plan';

  @override
  String get maxStoresLabel => 'Max stores';

  @override
  String estimatedSaving(String amount) {
    return 'Estimated saving: $amount';
  }

  @override
  String singleStorePlan(String store, String amount) {
    return 'Everything in one place: $store ($amount)';
  }

  @override
  String get notWorthSplitting =>
      'Splitting your shopping isn\'t worth it: the saving would be too small.';

  @override
  String estimatedElsewhereNote(String items) {
    return 'Prices unknown in these stores, estimated from your other purchases: $items';
  }

  @override
  String get notEnoughPriceData =>
      'Not enough price data to optimize this list.';

  @override
  String get windowDaysLabel => 'Window';

  @override
  String daysShort(int days) {
    return '${days}d';
  }

  @override
  String get quickScan => 'Scan';

  @override
  String get aReceipt => 'a receipt';

  @override
  String get tabHome => 'Home';

  @override
  String get tabLists => 'Lists';

  @override
  String get predictionsTitle => 'You may need soon';

  @override
  String get allPredictions => 'All suggestions';

  @override
  String get seeAllSuggestions => 'See all suggestions';

  @override
  String usuallyEveryDays(int days) {
    return 'Usually every $days days';
  }

  @override
  String lastBoughtDaysAgo(int days) {
    return 'Last bought $days days ago';
  }

  @override
  String get mightRunOutSoon => 'You might run out soon.';

  @override
  String get predictionAdd => 'Add';

  @override
  String get predictionNotNow => 'Not now';

  @override
  String get predictionStillHave => 'Still have some';

  @override
  String get predictionNever => 'Don\'t suggest again';

  @override
  String predictionAdded(String product) {
    return '$product added to your recent list';
  }

  @override
  String get noPredictionsYet =>
      'No suggestions yet. EpiList learns from your purchases: they will appear after a few shopping trips.';

  @override
  String get statusSoon => 'Soon';

  @override
  String get statusLikelyNeeded => 'Likely needed';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get confidenceLow => 'low confidence';

  @override
  String get inventoryTitle => 'At home';

  @override
  String get inventoryAtHome => 'At home';

  @override
  String get inventoryRunningLow => 'Running low';

  @override
  String get inventoryOut => 'Out';

  @override
  String get inventoryProbablyLow => 'Probably running low';

  @override
  String get inventoryEmpty =>
      'Add your essentials to track what\'s left at home.';

  @override
  String get inventoryAddProduct => 'Add a product';

  @override
  String get inventoryProductName => 'Product name';

  @override
  String addToListQuestion(String product) {
    return 'Add $product to your list?';
  }

  @override
  String addedToList(String product) {
    return '$product added to the list';
  }

  @override
  String get removeFromInventory => 'Remove from inventory';

  @override
  String atYourCurrentPace(String amount) {
    return 'At your current pace: ~$amount';
  }

  @override
  String perDayToStayOnBudget(String amount) {
    return 'About $amount/day to stay on target';
  }

  @override
  String recommendedThisWeek(String amount) {
    return '$amount recommended this week';
  }

  @override
  String daysLeftShort(int days) {
    return '$days days left';
  }

  @override
  String underBudgetPace(String pct) {
    return 'You are $pct% under your budget pace';
  }

  @override
  String overBudgetPace(String pct) {
    return 'You are $pct% over your budget pace';
  }

  @override
  String get shoppingModeTitle => 'My shopping';

  @override
  String itemsRemaining(int count) {
    return '$count items remaining';
  }

  @override
  String itemsProgress(int done, int total) {
    return '$done / $total items';
  }

  @override
  String get showCompletedItems => 'Show checked items';

  @override
  String get hideCompletedItems => 'Hide checked items';

  @override
  String get shoppingDone => 'Shopping done 🎉';

  @override
  String get recurringListsTitle => 'Recurring lists';

  @override
  String get newRecurringList => 'New recurring list';

  @override
  String get recurrenceWeekly => 'Every week';

  @override
  String get recurrenceBiweekly => 'Every 2 weeks';

  @override
  String get recurrenceMonthly => 'Every month';

  @override
  String get autoGenerateLabel => 'Generate automatically';

  @override
  String get autoGenerateHint =>
      'EpiList prepares the list on schedule and notifies you.';

  @override
  String nextRunOn(String date) {
    return 'Next: $date';
  }

  @override
  String get prepareMyList => 'Prepare my list';

  @override
  String get recurringListReady => 'Your list is ready';

  @override
  String get recurringEmpty =>
      'Create a template (weekly groceries, monthly Costco…) and EpiList will prefill it from your habits.';

  @override
  String get reasonInventoryOut => 'out at home';

  @override
  String get reasonInventoryAtHome => 'already at home';

  @override
  String get reasonBoughtRecently => 'bought recently';

  @override
  String get reasonPredictionDue => 'needed soon';

  @override
  String get reasonNormalCycle => 'normal cycle';

  @override
  String get createTheList => 'Create the list';

  @override
  String get listCreated => 'List created';

  @override
  String get deleteRecurringConfirm => 'Delete this recurring list?';

  @override
  String get recurringProducts => 'Template products';

  @override
  String get recurringNameHint => 'E.g.: Weekly groceries';

  @override
  String get mealPlannerTitle => 'Plan my meals';

  @override
  String get mealPlannerSubtitle => 'Pick your meals, EpiList builds the list';

  @override
  String get chooseMeals => 'Choose your meals';

  @override
  String get peopleCount => 'People';

  @override
  String get budgetMaxOptional => 'Maximum budget (optional)';

  @override
  String get createMyPlan => 'Create my plan';

  @override
  String planEstimatedAt(String amount) {
    return 'Estimated cost: $amount';
  }

  @override
  String planOverBudget(String amount) {
    return 'Your plan is estimated at $amount, above your budget.';
  }

  @override
  String estimationCoverage(int pct) {
    return 'Estimate based on $pct% of ingredients';
  }

  @override
  String get alreadyAtHome => 'Already at home';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String servingsCount(int count) {
    return '$count servings';
  }

  @override
  String get intelligenceSettings => 'EpiList Intelligence';

  @override
  String get settingPredictions => 'Predictive suggestions';

  @override
  String get settingPredictionsHint => '\"You may need soon\" on the dashboard';

  @override
  String get settingInventoryEstimates => 'Smart inventory';

  @override
  String get settingInventoryEstimatesHint =>
      'Estimate what\'s running low from your purchases';

  @override
  String get settingAutoAddOut => 'Auto-add products marked out';

  @override
  String get settingAutoAddOutHint =>
      'A product marked \"Out\" joins your recent list';

  @override
  String get settingBudgetForecast => 'Budget projection';

  @override
  String get settingBudgetForecastHint =>
      'Pace, end-of-month projection and daily budget';

  @override
  String get search => 'Search';

  @override
  String get scanBarcode => 'Scan a barcode';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateNow => 'Update now';

  @override
  String get pickListTitle => 'Which list?';

  @override
  String get toChosenList => 'on the list you pick';

  @override
  String get budgetAllocated => 'Allocated budget';

  @override
  String get details => 'Details';

  @override
  String get inactive => 'Inactive';

  @override
  String scopeList(String name) {
    return 'List: $name';
  }

  @override
  String get later => 'Later';

  @override
  String get completeAction => 'Complete';

  @override
  String get exportPdfInProgress => 'Exporting PDF…';

  @override
  String get exportCsvInProgress => 'Exporting CSV…';

  @override
  String get stillOffline => 'Still offline';

  @override
  String get connectToLoadProfile =>
      'Connect to the Internet to load your profile';

  @override
  String get restoreOriginalName => 'Restore original name';

  @override
  String get productFound => 'Product found';

  @override
  String get noInternetBody =>
      'You need an Internet connection to use this app. Please check your connection and try again.';

  @override
  String get analyticsEmptyHint => 'Start shopping to see your analytics';

  @override
  String get tryOtherKeywords => 'Try different keywords';

  @override
  String get suggestionsAfterPurchases =>
      'Suggestions will appear after your purchases';

  @override
  String get selectCurrencyTitle => 'Select a currency';

  @override
  String get noCurrencyAvailable => 'No currency available';

  @override
  String get currencyLoadFailed => 'Unable to load currencies from the server';

  @override
  String get enterBarcodeTitle => 'Enter a barcode';

  @override
  String get scannerUnavailableSimulator =>
      'Scanner unavailable on the simulator';

  @override
  String get enterBarcodeHint => 'Type a barcode manually or pick an example';

  @override
  String get pleaseEnterBarcode => 'Please enter a barcode';

  @override
  String get barcodeTooShort => 'Barcode too short (min 8 digits)';

  @override
  String get barcodeExamples => 'Barcode examples:';

  @override
  String get alignBarcodeInFrame => 'Align the barcode within the frame';

  @override
  String get positionBarcodeInZone => 'Position the barcode in the scan area';

  @override
  String get codeDetected => 'Code detected!';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get searchingProduct => 'Looking up product…';

  @override
  String productNotFoundBarcode(String barcode) {
    return 'Product not found. Barcode: $barcode';
  }

  @override
  String get quantityMustBeValid =>
      'Quantity must be a valid number (minimum 1)';

  @override
  String get priceMustBeValid => 'Price must be a valid number';

  @override
  String get itemAlreadyPresent => 'Item already in the list';

  @override
  String get itemExistsInList => 'This item already exists in your list:';

  @override
  String get similarItemExists => 'A similar item already exists in your list:';

  @override
  String get whatToDo => 'What would you like to do?';

  @override
  String get limitedPermission => 'Limited';

  @override
  String yourCurrentPermission(String permission) {
    return 'Your current permission: $permission';
  }

  @override
  String get listDetailsAndPermissions =>
      'Details and permissions of this list';

  @override
  String get sharedByLabel => 'Shared by';

  @override
  String get allowed => 'Allowed';

  @override
  String get denied => 'Denied';

  @override
  String get categoryLabel => 'Category';

  @override
  String get googleAccountCreated => 'Google account created and signed in!';

  @override
  String get appleAccountCreated => 'Apple account created and signed in!';

  @override
  String get accountCreatedConnected => 'Account created and signed in!';

  @override
  String get accountAlreadyExists => 'An account already exists';

  @override
  String get accountExistsTryLogin =>
      'An account already exists with this email. Try signing in.';

  @override
  String get googleAccountExistsRedirect =>
      'A Google account already exists. Redirecting to sign-in…';

  @override
  String get accountCreatedVerifyEmail => 'Account created! Check your email.';

  @override
  String get appleUnavailableDevice =>
      'Apple Sign-In is not available on this device';

  @override
  String get appleOnlyIos => 'Apple Sign-In is only available on iOS';

  @override
  String get googleSignInSuccess => 'Signed in with Google!';

  @override
  String get appleSignInSuccess => 'Signed in with Apple!';

  @override
  String get noAccountFound => 'No account found';

  @override
  String get linkGoogleWithPassword =>
      'Sign in with your password first to link your Google account.';

  @override
  String get connectionProblem =>
      'Connection problem. Check your Internet and try again.';

  @override
  String get appleSignInError => 'Error signing in with Apple';

  @override
  String get manageYourSuggestions => 'Manage your personalized suggestions';

  @override
  String get emailPreferences => 'Email preferences';

  @override
  String get manageEmailNotifications => 'Manage email notifications';

  @override
  String get showingOwnListsOnly => 'Showing only your own lists';

  @override
  String get noListFound => 'No list found';

  @override
  String get noActiveList => 'No active list';

  @override
  String get noCompletedList => 'No completed list';

  @override
  String get noSharedList => 'No shared list';

  @override
  String get tryAnotherFilter => 'Try another filter';

  @override
  String get invalidData => 'Invalid data';

  @override
  String get periodInfo => 'Period information';

  @override
  String periodLabel(String period) {
    return 'Period: $period';
  }

  @override
  String get epTitle => 'Email preferences';

  @override
  String get epResetDefaults => 'Reset to defaults';

  @override
  String get epResetConfirm =>
      'Reset all email preferences to their default values?';

  @override
  String get epResetDone => 'Preferences reset';

  @override
  String get epTransactional => 'Transactional emails';

  @override
  String get epTransactionalDesc => 'Essential emails about your account';

  @override
  String get epVerifTitle => 'Email verification';

  @override
  String get epVerifDesc => 'Verification email when you create an account';

  @override
  String get epPwdReqTitle => 'Password change request';

  @override
  String get epPwdReqDesc => 'Email with the code to reset your password';

  @override
  String get epPwdChangedTitle => 'Password changed confirmation';

  @override
  String get epPwdChangedDesc => 'Security alert when your password changes';

  @override
  String get epListNotif => 'List notifications';

  @override
  String get epListNotifDesc => 'Updates about your shared lists';

  @override
  String get epListSharedTitle => 'List shared with me';

  @override
  String get epListSharedDesc => 'Someone shares a list with you';

  @override
  String get epListCompletedTitle => 'List completed';

  @override
  String get epListCompletedDesc => 'All items in a shared list are checked';

  @override
  String get epBudgetAlerts => 'Budget alerts';

  @override
  String get epBudgetAlertsDesc => 'Notifications about your spending';

  @override
  String get epBudgetExceededTitle => 'Budget exceeded';

  @override
  String get epBudgetExceededDesc => 'Alert when you go over budget';

  @override
  String get epMonthlySummaryTitle => 'Monthly summary';

  @override
  String get epMonthlySummaryDesc => 'Budget recap at the end of each month';

  @override
  String get epTipsDesc => 'Helpful advice to get more from EpiList';

  @override
  String get epTipsToggleDesc => 'Receive tips and reminders';

  @override
  String get siTitle => 'Share invitation';

  @override
  String get siAccepted => 'Invitation accepted!';

  @override
  String get siDeclined => 'Invitation declined';

  @override
  String get siValidating => 'Validating invitation…';

  @override
  String get siVerifyingToken => 'Verifying share link';

  @override
  String get siAlreadyAccepted =>
      'You have already accepted this invitation for the list';

  @override
  String get siAlreadyDeclined =>
      'You have declined this invitation for the list';

  @override
  String get siGoToList => 'Go to list';

  @override
  String get siBackHome => 'Back to home';

  @override
  String get siSharedBy => 'Shared by';

  @override
  String get siExpiresOn => 'Expires on';

  @override
  String get siCreatedOn => 'Created on';

  @override
  String get siListPreview => 'List preview';

  @override
  String get siEstimatedBudget => 'Estimated budget';

  @override
  String get siAccept => 'Accept invitation';

  @override
  String get siAcceptConfirm => 'Do you want to accept the invitation from';

  @override
  String get siDecline => 'Decline invitation';

  @override
  String get siDeclineConfirm => 'Do you want to decline the invitation from';

  @override
  String get siDeclineWarning =>
      'You will need to request a new invitation to access this list.';

  @override
  String get siReadOnlyDesc => 'You can view the list but not modify it';

  @override
  String get siPermViewItems => 'View items and their status';

  @override
  String get siPermViewPrices => 'See prices and quantities';

  @override
  String get siEditDesc => 'You can modify the list but not delete it';

  @override
  String get siPermAddEdit => 'Add and edit items';

  @override
  String get siPermMarkPurchased => 'Mark items as purchased';

  @override
  String get siPermEditPrices => 'Edit prices and quantities';

  @override
  String get siFullRights => 'You have full rights on this list';

  @override
  String get siPermModifyDelete => 'Modify and delete the list';

  @override
  String get siPermManageItems => 'Manage all items';

  @override
  String get siPermShare => 'Share with other users';

  @override
  String get siInvalid => 'Invalid invitation';

  @override
  String siInDays(int days) {
    return 'In $days days';
  }

  @override
  String get adCheckingStatus => 'Checking deletion status…';

  @override
  String get adErrorLoading => 'Error loading status';

  @override
  String get adScheduled => 'Account deletion scheduled';

  @override
  String get adCancelDeletion => 'Cancel deletion';

  @override
  String get adPeriodExpired => 'The 30-day cancellation period has expired';

  @override
  String get adCancelled => 'Account deletion cancelled!';

  @override
  String get adCancelConfirm =>
      'Are you sure you want to cancel the deletion of your account? Your account will become active immediately.';

  @override
  String get adKeepDeletion => 'No, keep deletion';

  @override
  String get adYesCancel => 'Yes, cancel';

  @override
  String get startShoppingForSuggestions =>
      'Start shopping to get personalized suggestions';

  @override
  String get suggestionsExplain =>
      'We analyze your shopping history to suggest products you might need.';

  @override
  String get suggestionsFrequency => 'Based on how often you buy items';

  @override
  String get suggestionsSeasonal => 'Products you buy during specific periods';

  @override
  String get suggestionsAssociations => 'Items often bought together';

  @override
  String get baCheckExpenses =>
      'Check your recent expenses to spot unnecessary spending';

  @override
  String get baIncreaseBudget =>
      'Consider increasing the budget if expenses are justified';

  @override
  String get baReduceTitle => 'Reduce spending';

  @override
  String get baReduceDesc => 'Focus on essentials for the remaining period';

  @override
  String permReadOnlyMessage(String action) {
    return 'You cannot $action because this list is read-only.';
  }

  @override
  String permNoPermissionMessage(String action) {
    return 'You do not have permission to $action.';
  }

  @override
  String get permActionEditItems => 'edit items';

  @override
  String get permActionEditStatus => 'change item status';

  @override
  String get permActionEditList => 'edit this list';

  @override
  String get permActionShareList => 'share this list';

  @override
  String get permActionAccessChat => 'access the chat';

  @override
  String get permActionManageShares => 'manage shares';

  @override
  String get permActionAddItems => 'add items';
}
