import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @accountsActivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be available again.'**
  String accountsActivateMessage(String name);

  /// No description provided for @accountsActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate account?'**
  String get accountsActivateTitle;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAdd;

  /// No description provided for @accountsAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get accountsAmountInvalid;

  /// No description provided for @accountsDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from new entries. Existing data is kept.'**
  String accountsDeactivateMessage(String name);

  /// No description provided for @accountsDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account?'**
  String get accountsDeactivateTitle;

  /// No description provided for @accountsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountsEdit;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Tap + to add one.'**
  String get accountsEmpty;

  /// No description provided for @accountsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountsNameLabel;

  /// No description provided for @accountsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get accountsNameRequired;

  /// No description provided for @accountsOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountsOpeningBalance;

  /// No description provided for @accountsOpeningDate.
  ///
  /// In en, this message translates to:
  /// **'Opening date'**
  String get accountsOpeningDate;

  /// No description provided for @accountsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search accounts'**
  String get accountsSearchHint;

  /// No description provided for @accountsSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage accounts.'**
  String get accountsSelectProfile;

  /// No description provided for @accountsShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get accountsShowInactive;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountsTypeBank;

  /// No description provided for @accountsTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountsTypeCash;

  /// No description provided for @accountsTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountsTypeCreditCard;

  /// No description provided for @accountsTypeMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile banking'**
  String get accountsTypeMobile;

  /// No description provided for @accountsTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountsTypeOther;

  /// No description provided for @accountsTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountsTypeSavings;

  /// No description provided for @appShellAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get appShellAbout;

  /// No description provided for @appShellAboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get appShellAboutContact;

  /// No description provided for @appShellAboutCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String appShellAboutCopied(String label);

  /// No description provided for @appShellAboutCurrentWork.
  ///
  /// In en, this message translates to:
  /// **'Current work'**
  String get appShellAboutCurrentWork;

  /// No description provided for @appShellAboutEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get appShellAboutEmail;

  /// No description provided for @appShellAboutJob.
  ///
  /// In en, this message translates to:
  /// **'Software Engineer - Jan 2024 to present'**
  String get appShellAboutJob;

  /// No description provided for @appShellAboutPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get appShellAboutPortfolio;

  /// No description provided for @appShellAboutRole.
  ///
  /// In en, this message translates to:
  /// **'Software Engineer | Full Stack .NET Developer'**
  String get appShellAboutRole;

  /// No description provided for @appShellAboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline-first personal and family budget manager. Your data stays on your device.'**
  String get appShellAboutTagline;

  /// No description provided for @appShellAboutTapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap a contact to copy it'**
  String get appShellAboutTapToCopy;

  /// No description provided for @appShellAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get appShellAccounts;

  /// No description provided for @appShellBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get appShellBackupRestore;

  /// No description provided for @appShellBankLoans.
  ///
  /// In en, this message translates to:
  /// **'Bank loans'**
  String get appShellBankLoans;

  /// No description provided for @appShellCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get appShellCategories;

  /// No description provided for @appShellCostItems.
  ///
  /// In en, this message translates to:
  /// **'Cost Items'**
  String get appShellCostItems;

  /// No description provided for @appShellCreditCards.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get appShellCreditCards;

  /// No description provided for @appShellDebtsLoans.
  ///
  /// In en, this message translates to:
  /// **'Debts & loans'**
  String get appShellDebtsLoans;

  /// No description provided for @appShellExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get appShellExchangeRates;

  /// No description provided for @appShellFixedDeposits.
  ///
  /// In en, this message translates to:
  /// **'Fixed deposits (FDR)'**
  String get appShellFixedDeposits;

  /// No description provided for @appShellImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get appShellImportCsv;

  /// No description provided for @appShellInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get appShellInsights;

  /// No description provided for @appShellMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get appShellMore;

  /// No description provided for @appShellNoErrorsLogged.
  ///
  /// In en, this message translates to:
  /// **'No errors have been logged.'**
  String get appShellNoErrorsLogged;

  /// No description provided for @appShellNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get appShellNotifications;

  /// No description provided for @appShellPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get appShellPreferences;

  /// No description provided for @appShellProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get appShellProfiles;

  /// No description provided for @appShellRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get appShellRecurring;

  /// No description provided for @appShellSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get appShellSavingsGoals;

  /// No description provided for @appShellSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appShellSectionApp;

  /// No description provided for @appShellSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get appShellSectionData;

  /// No description provided for @appShellSectionMaster.
  ///
  /// In en, this message translates to:
  /// **'Master Configuration'**
  String get appShellSectionMaster;

  /// No description provided for @appShellSectionOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get appShellSectionOperations;

  /// No description provided for @appShellSectionPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get appShellSectionPlan;

  /// No description provided for @appShellSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get appShellSecurity;

  /// No description provided for @appShellSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appShellSettings;

  /// No description provided for @appShellShareErrorLog.
  ///
  /// In en, this message translates to:
  /// **'Share error log'**
  String get appShellShareErrorLog;

  /// No description provided for @appShellShareErrorLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stays on your device unless you send it'**
  String get appShellShareErrorLogSubtitle;

  /// No description provided for @appShellSubCategories.
  ///
  /// In en, this message translates to:
  /// **'Sub-categories'**
  String get appShellSubCategories;

  /// No description provided for @appShellTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get appShellTabAdd;

  /// No description provided for @appShellTabBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get appShellTabBudget;

  /// No description provided for @appShellTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appShellTabHome;

  /// No description provided for @appShellTabLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get appShellTabLedger;

  /// No description provided for @appShellTabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get appShellTabReports;

  /// No description provided for @appShellTagReport.
  ///
  /// In en, this message translates to:
  /// **'Tag report'**
  String get appShellTagReport;

  /// No description provided for @appShellTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get appShellTags;

  /// No description provided for @appShellWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets & balances'**
  String get appShellWallets;

  /// No description provided for @attachmentsAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the photo.'**
  String get attachmentsAddFailed;

  /// No description provided for @attachmentsAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get attachmentsAddPhoto;

  /// No description provided for @attachmentsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachmentsCamera;

  /// No description provided for @attachmentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete attachment'**
  String get attachmentsDeleteTitle;

  /// No description provided for @attachmentsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get attachmentsGallery;

  /// No description provided for @attachmentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Attachments ({count}/{max})'**
  String attachmentsHeader(int count, int max);

  /// No description provided for @attachmentsNone.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get attachmentsNone;

  /// No description provided for @attachmentsRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get attachmentsRemoveMessage;

  /// No description provided for @attachmentsViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachmentsViewerTitle;

  /// No description provided for @backupAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoBackup;

  /// No description provided for @backupAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Android decides when background work runs, so automatic backups may be delayed by hours (battery saver, Doze). Backups stay on this device. Manual and safety backups are never removed automatically. Automatic backups are NOT password protected and do not include receipt photos; use \"Create & share\" for an encrypted copy with photos.'**
  String get backupAutoNote;

  /// No description provided for @backupBackUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupBackUpNow;

  /// No description provided for @backupCannotRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup cannot be restored'**
  String get backupCannotRestoreTitle;

  /// No description provided for @backupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get backupConfirmPassword;

  /// No description provided for @backupContains.
  ///
  /// In en, this message translates to:
  /// **'Contains:'**
  String get backupContains;

  /// No description provided for @backupContainsRow.
  ///
  /// In en, this message translates to:
  /// **'• {count} {label}'**
  String backupContainsRow(int count, String label);

  /// No description provided for @backupCreateAndShare.
  ///
  /// In en, this message translates to:
  /// **'Create & share'**
  String get backupCreateAndShare;

  /// No description provided for @backupCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreateBackup;

  /// No description provided for @backupCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Backup created: {date}'**
  String backupCreatedAt(String date);

  /// No description provided for @backupDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String backupDeleteMessage(String name);

  /// No description provided for @backupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete backup?'**
  String get backupDeleteTitle;

  /// No description provided for @backupEncrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt with a password'**
  String get backupEncrypt;

  /// No description provided for @backupEncryptNote.
  ///
  /// In en, this message translates to:
  /// **'AES-256. If you forget the password the backup cannot be opened by anyone, including us.'**
  String get backupEncryptNote;

  /// No description provided for @backupEncryptedPrompt.
  ///
  /// In en, this message translates to:
  /// **'This backup is encrypted. Enter its password.'**
  String get backupEncryptedPrompt;

  /// No description provided for @backupEncryptedSuffix.
  ///
  /// In en, this message translates to:
  /// **' (encrypted)'**
  String get backupEncryptedSuffix;

  /// No description provided for @backupFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupFreqDaily;

  /// No description provided for @backupFreqOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get backupFreqOff;

  /// No description provided for @backupFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupFreqWeekly;

  /// No description provided for @backupFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get backupFrequency;

  /// No description provided for @backupHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get backupHide;

  /// No description provided for @backupIncludePhotos.
  ///
  /// In en, this message translates to:
  /// **'Include receipt photos'**
  String get backupIncludePhotos;

  /// No description provided for @backupKeepLast.
  ///
  /// In en, this message translates to:
  /// **'Keep last automatic backups'**
  String get backupKeepLast;

  /// No description provided for @backupKindAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get backupKindAuto;

  /// No description provided for @backupKindManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get backupKindManual;

  /// No description provided for @backupKindSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety (before restore)'**
  String get backupKindSafety;

  /// No description provided for @backupLastRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Last run failed'**
  String get backupLastRunFailed;

  /// No description provided for @backupLastRunSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Last run succeeded'**
  String get backupLastRunSucceeded;

  /// No description provided for @backupMissingPhotosSuffix.
  ///
  /// In en, this message translates to:
  /// **'. {count} receipt photo(s) were missing and skipped.'**
  String backupMissingPhotosSuffix(int count);

  /// No description provided for @backupMissingSkipped.
  ///
  /// In en, this message translates to:
  /// **' ({count} missing file(s) will be skipped)'**
  String backupMissingSkipped(int count);

  /// No description provided for @backupNoAutoRun.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup has run yet.'**
  String get backupNoAutoRun;

  /// No description provided for @backupNoBackupsYet.
  ///
  /// In en, this message translates to:
  /// **'No backups yet. Tap \"Create backup\" to make the first one.'**
  String get backupNoBackupsYet;

  /// No description provided for @backupNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No receipt photos to include.'**
  String get backupNoPhotos;

  /// No description provided for @backupNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed. Problems found:'**
  String get backupNothingChanged;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPassword;

  /// No description provided for @backupPasswordMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Password (min {min})'**
  String backupPasswordMinLabel(int min);

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get backupPasswordRequired;

  /// No description provided for @backupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters for the password.'**
  String backupPasswordTooShort(int min);

  /// No description provided for @backupPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s), about {size}'**
  String backupPhotoCount(int count, String size);

  /// No description provided for @backupReminderAction.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backupReminderAction;

  /// No description provided for @backupReminderLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get backupReminderLater;

  /// No description provided for @backupReminderNone.
  ///
  /// In en, this message translates to:
  /// **'You have no backup yet. Your data exists only on this phone.'**
  String get backupReminderNone;

  /// No description provided for @backupReminderOld.
  ///
  /// In en, this message translates to:
  /// **'Your last backup was {days} days ago.'**
  String backupReminderOld(int days);

  /// No description provided for @backupReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up your data'**
  String get backupReminderTitle;

  /// No description provided for @backupReplaceAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get backupReplaceAllTitle;

  /// No description provided for @backupReplaceData.
  ///
  /// In en, this message translates to:
  /// **'Replace data'**
  String get backupReplaceData;

  /// No description provided for @backupReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Restoring will REPLACE all current data in the app with this backup. A safety backup of your current data is created first, so you can go back.'**
  String get backupReplaceWarning;

  /// No description provided for @backupRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete. A safety backup of the previous data was saved.'**
  String get backupRestoreComplete;

  /// No description provided for @backupRestoreCompleteCleared.
  ///
  /// In en, this message translates to:
  /// **'Restore complete. Your previous profile is not in this backup; please choose a profile.'**
  String get backupRestoreCompleteCleared;

  /// No description provided for @backupRestoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get backupRestoreFromFile;

  /// No description provided for @backupSavedBackups.
  ///
  /// In en, this message translates to:
  /// **'Saved backups'**
  String get backupSavedBackups;

  /// No description provided for @backupSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {name}'**
  String backupSavedToast(String name);

  /// No description provided for @backupShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get backupShow;

  /// No description provided for @backupSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String backupSomethingWrong(String error);

  /// No description provided for @backupStatusAt.
  ///
  /// In en, this message translates to:
  /// **' at {time}'**
  String backupStatusAt(String time);

  /// No description provided for @backupStatusMessage.
  ///
  /// In en, this message translates to:
  /// **' ({message})'**
  String backupStatusMessage(String message);

  /// No description provided for @backupTableAccounts.
  ///
  /// In en, this message translates to:
  /// **'accounts'**
  String get backupTableAccounts;

  /// No description provided for @backupTableCategories.
  ///
  /// In en, this message translates to:
  /// **'categories'**
  String get backupTableCategories;

  /// No description provided for @backupTableCategoryBudgets.
  ///
  /// In en, this message translates to:
  /// **'category budgets'**
  String get backupTableCategoryBudgets;

  /// No description provided for @backupTableCostItems.
  ///
  /// In en, this message translates to:
  /// **'cost items'**
  String get backupTableCostItems;

  /// No description provided for @backupTableDebtPayments.
  ///
  /// In en, this message translates to:
  /// **'debt payments'**
  String get backupTableDebtPayments;

  /// No description provided for @backupTableDebts.
  ///
  /// In en, this message translates to:
  /// **'debts'**
  String get backupTableDebts;

  /// No description provided for @backupTableExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'exchange rates'**
  String get backupTableExchangeRates;

  /// No description provided for @backupTableFinancialProfiles.
  ///
  /// In en, this message translates to:
  /// **'financial profiles'**
  String get backupTableFinancialProfiles;

  /// No description provided for @backupTableFinancialTransactions.
  ///
  /// In en, this message translates to:
  /// **'financial transactions'**
  String get backupTableFinancialTransactions;

  /// No description provided for @backupTableMonthlyBudgets.
  ///
  /// In en, this message translates to:
  /// **'monthly budgets'**
  String get backupTableMonthlyBudgets;

  /// No description provided for @backupTableRecurringRules.
  ///
  /// In en, this message translates to:
  /// **'recurring rules'**
  String get backupTableRecurringRules;

  /// No description provided for @backupTableSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'savings goals'**
  String get backupTableSavingsGoals;

  /// No description provided for @backupTableSubCategories.
  ///
  /// In en, this message translates to:
  /// **'sub categories'**
  String get backupTableSubCategories;

  /// No description provided for @backupTableTags.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get backupTableTags;

  /// No description provided for @backupTableTransactionAttachments.
  ///
  /// In en, this message translates to:
  /// **'transaction attachments'**
  String get backupTableTransactionAttachments;

  /// No description provided for @backupTableTransactionAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'transaction audit logs'**
  String get backupTableTransactionAuditLogs;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get backupUnlock;

  /// No description provided for @backupUnreadableFile.
  ///
  /// In en, this message translates to:
  /// **'That file is not a readable JSON backup.'**
  String get backupUnreadableFile;

  /// No description provided for @budgetsAddAllocation.
  ///
  /// In en, this message translates to:
  /// **'Add allocation'**
  String get budgetsAddAllocation;

  /// No description provided for @budgetsAllocatedSummary.
  ///
  /// In en, this message translates to:
  /// **'Allocated {allocated} of {total} (inside the total, not added).'**
  String budgetsAllocatedSummary(String allocated, String total);

  /// No description provided for @budgetsAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get budgetsAllocation;

  /// No description provided for @budgetsBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetsBudget;

  /// No description provided for @budgetsCarriedOver.
  ///
  /// In en, this message translates to:
  /// **'+{amount} carried over'**
  String budgetsCarriedOver(String amount);

  /// No description provided for @budgetsCarryOverUnspent.
  ///
  /// In en, this message translates to:
  /// **'Carry over unspent'**
  String get budgetsCarryOverUnspent;

  /// No description provided for @budgetsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetsCategory;

  /// No description provided for @budgetsCategoryAllocations.
  ///
  /// In en, this message translates to:
  /// **'Category allocations'**
  String get budgetsCategoryAllocations;

  /// No description provided for @budgetsEditAllocation.
  ///
  /// In en, this message translates to:
  /// **'Edit allocation'**
  String get budgetsEditAllocation;

  /// No description provided for @budgetsEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetsEditBudget;

  /// No description provided for @budgetsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New month: set a budget; nothing carries over.'**
  String get budgetsEmptyMessage;

  /// No description provided for @budgetsErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String budgetsErrorWithDetail(String error);

  /// No description provided for @budgetsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get budgetsInvalidAmount;

  /// No description provided for @budgetsMonthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get budgetsMonthApril;

  /// No description provided for @budgetsMonthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get budgetsMonthAugust;

  /// No description provided for @budgetsMonthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get budgetsMonthDecember;

  /// No description provided for @budgetsMonthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get budgetsMonthFebruary;

  /// No description provided for @budgetsMonthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get budgetsMonthJanuary;

  /// No description provided for @budgetsMonthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get budgetsMonthJuly;

  /// No description provided for @budgetsMonthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get budgetsMonthJune;

  /// No description provided for @budgetsMonthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get budgetsMonthMarch;

  /// No description provided for @budgetsMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get budgetsMonthMay;

  /// No description provided for @budgetsMonthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get budgetsMonthNovember;

  /// No description provided for @budgetsMonthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get budgetsMonthOctober;

  /// No description provided for @budgetsMonthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get budgetsMonthSeptember;

  /// No description provided for @budgetsMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String budgetsMonthYear(String month, String year);

  /// No description provided for @budgetsMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get budgetsMonthlyBudget;

  /// No description provided for @budgetsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get budgetsNextMonth;

  /// No description provided for @budgetsNoAllocations.
  ///
  /// In en, this message translates to:
  /// **'No category allocations for this month.'**
  String get budgetsNoAllocations;

  /// No description provided for @budgetsNoCategoriesLeft.
  ///
  /// In en, this message translates to:
  /// **'No active categories left to allocate.'**
  String get budgetsNoCategoriesLeft;

  /// No description provided for @budgetsPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetsPercentUsed(String percent);

  /// No description provided for @budgetsPickMonthHelp.
  ///
  /// In en, this message translates to:
  /// **'Select any day in the month'**
  String get budgetsPickMonthHelp;

  /// No description provided for @budgetsPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get budgetsPreviousMonth;

  /// No description provided for @budgetsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetsRemaining;

  /// No description provided for @budgetsRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining {amount}'**
  String budgetsRemainingAmount(String amount);

  /// No description provided for @budgetsRemoveAllocation.
  ///
  /// In en, this message translates to:
  /// **'Remove allocation'**
  String get budgetsRemoveAllocation;

  /// No description provided for @budgetsRemoveAllocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove the allocation for \"{name}\"?'**
  String budgetsRemoveAllocationMessage(String name);

  /// No description provided for @budgetsRemoveAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove allocation?'**
  String get budgetsRemoveAllocationTitle;

  /// No description provided for @budgetsSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage budgets.'**
  String get budgetsSelectProfile;

  /// No description provided for @budgetsSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get budgetsSetBudget;

  /// No description provided for @budgetsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSpent;

  /// No description provided for @budgetsSpentOf.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {allowance}'**
  String budgetsSpentOf(String spent, String allowance);

  /// No description provided for @budgetsTotalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get budgetsTotalBudget;

  /// No description provided for @categoriesActivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be available again.'**
  String categoriesActivateMessage(String name);

  /// No description provided for @categoriesActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate category?'**
  String get categoriesActivateTitle;

  /// No description provided for @categoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAdd;

  /// No description provided for @categoriesColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoriesColorLabel;

  /// No description provided for @categoriesDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from new entries. Existing data is kept.'**
  String categoriesDeactivateMessage(String name);

  /// No description provided for @categoriesDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate category?'**
  String get categoriesDeactivateTitle;

  /// No description provided for @categoriesDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get categoriesDescriptionLabel;

  /// No description provided for @categoriesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoriesEdit;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Tap + to add one.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoriesIconLabel;

  /// No description provided for @categoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String categoriesLoadError(String error);

  /// No description provided for @categoriesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoriesNameLabel;

  /// No description provided for @categoriesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get categoriesNameRequired;

  /// No description provided for @categoriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get categoriesSearchHint;

  /// No description provided for @categoriesSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage categories.'**
  String get categoriesSelectProfile;

  /// No description provided for @categoriesShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get categoriesShowInactive;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get commonInactive;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get commonNoData;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to continue.'**
  String get commonSelectProfile;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @costItemsActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get costItemsActivateAction;

  /// No description provided for @costItemsActivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be available again.'**
  String costItemsActivateMessage(String name);

  /// No description provided for @costItemsActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate cost item?'**
  String get costItemsActivateTitle;

  /// No description provided for @costItemsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add cost item'**
  String get costItemsAdd;

  /// No description provided for @costItemsAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get costItemsAmountInvalid;

  /// No description provided for @costItemsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get costItemsCategoryLabel;

  /// No description provided for @costItemsDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get costItemsDeactivateAction;

  /// No description provided for @costItemsDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from new entries. Existing data is preserved.'**
  String costItemsDeactivateMessage(String name);

  /// No description provided for @costItemsDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate cost item?'**
  String get costItemsDeactivateTitle;

  /// No description provided for @costItemsDefaultAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Default amount (optional)'**
  String get costItemsDefaultAmountOptional;

  /// No description provided for @costItemsDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get costItemsDescriptionOptional;

  /// No description provided for @costItemsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit cost item'**
  String get costItemsEdit;

  /// No description provided for @costItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cost items found.'**
  String get costItemsEmpty;

  /// No description provided for @costItemsFavAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to quick add'**
  String get costItemsFavAddTooltip;

  /// No description provided for @costItemsFavRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from quick add'**
  String get costItemsFavRemoveTooltip;

  /// No description provided for @costItemsInactiveSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Inactive'**
  String get costItemsInactiveSuffix;

  /// No description provided for @costItemsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cost items: {error}'**
  String costItemsLoadError(String error);

  /// No description provided for @costItemsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get costItemsNameLabel;

  /// No description provided for @costItemsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get costItemsNameRequired;

  /// No description provided for @costItemsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or description'**
  String get costItemsSearchHint;

  /// No description provided for @costItemsSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get costItemsSelectCategory;

  /// No description provided for @costItemsSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile first.'**
  String get costItemsSelectProfile;

  /// No description provided for @costItemsSelectSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a sub-category'**
  String get costItemsSelectSubCategory;

  /// No description provided for @costItemsShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get costItemsShowInactive;

  /// No description provided for @costItemsSubCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-category'**
  String get costItemsSubCategoryLabel;

  /// No description provided for @costItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost Items'**
  String get costItemsTitle;

  /// No description provided for @creditCardsActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate card'**
  String get creditCardsActivate;

  /// No description provided for @creditCardsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get creditCardsAdd;

  /// No description provided for @creditCardsAddBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get creditCardsAddBill;

  /// No description provided for @creditCardsAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get creditCardsAmountPositive;

  /// No description provided for @creditCardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available credit'**
  String get creditCardsAvailable;

  /// No description provided for @creditCardsAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get creditCardsAvailableShort;

  /// No description provided for @creditCardsBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Bill {amount}'**
  String creditCardsBillAmount(String amount);

  /// No description provided for @creditCardsBillAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill amount'**
  String get creditCardsBillAmountLabel;

  /// No description provided for @creditCardsBillNotFound.
  ///
  /// In en, this message translates to:
  /// **'Bill not found.'**
  String get creditCardsBillNotFound;

  /// No description provided for @creditCardsBillTitle.
  ///
  /// In en, this message translates to:
  /// **'{month} bill'**
  String creditCardsBillTitle(String month);

  /// No description provided for @creditCardsBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get creditCardsBills;

  /// No description provided for @creditCardsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Bill breakdown'**
  String get creditCardsBreakdown;

  /// No description provided for @creditCardsChargesAdded.
  ///
  /// In en, this message translates to:
  /// **'Interest & fees added'**
  String get creditCardsChargesAdded;

  /// No description provided for @creditCardsChipApr.
  ///
  /// In en, this message translates to:
  /// **'APR {rate}'**
  String creditCardsChipApr(String rate);

  /// No description provided for @creditCardsChipDueDays.
  ///
  /// In en, this message translates to:
  /// **'Pay within {days} days'**
  String creditCardsChipDueDays(int days);

  /// No description provided for @creditCardsChipLateFee.
  ///
  /// In en, this message translates to:
  /// **'Late fee {rate}'**
  String creditCardsChipLateFee(String rate);

  /// No description provided for @creditCardsChipMin.
  ///
  /// In en, this message translates to:
  /// **'Min {rate}'**
  String creditCardsChipMin(String rate);

  /// No description provided for @creditCardsChipStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement day {day}'**
  String creditCardsChipStatementDay(int day);

  /// No description provided for @creditCardsDaysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days} days overdue'**
  String creditCardsDaysOverdue(int days);

  /// No description provided for @creditCardsDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate card'**
  String get creditCardsDeactivate;

  /// No description provided for @creditCardsDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String creditCardsDueOn(String date);

  /// No description provided for @creditCardsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get creditCardsEdit;

  /// No description provided for @creditCardsEditBill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get creditCardsEditBill;

  /// No description provided for @creditCardsEffectiveAnnual.
  ///
  /// In en, this message translates to:
  /// **'Effective annual cost so far: {percent}'**
  String creditCardsEffectiveAnnual(String percent);

  /// No description provided for @creditCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit cards yet. Add one to track bills, interest and late fees.'**
  String get creditCardsEmpty;

  /// No description provided for @creditCardsExtraCharges.
  ///
  /// In en, this message translates to:
  /// **'Added to this bill'**
  String get creditCardsExtraCharges;

  /// No description provided for @creditCardsExtraPct.
  ///
  /// In en, this message translates to:
  /// **'+{percent} charges'**
  String creditCardsExtraPct(String percent);

  /// No description provided for @creditCardsExtraValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} (+{percent})'**
  String creditCardsExtraValue(String amount, String percent);

  /// No description provided for @creditCardsFieldApr.
  ///
  /// In en, this message translates to:
  /// **'Interest rate per year (APR %)'**
  String get creditCardsFieldApr;

  /// No description provided for @creditCardsFieldBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get creditCardsFieldBank;

  /// No description provided for @creditCardsFieldBillAmount.
  ///
  /// In en, this message translates to:
  /// **'New charges this month'**
  String get creditCardsFieldBillAmount;

  /// No description provided for @creditCardsFieldDueDate.
  ///
  /// In en, this message translates to:
  /// **'Payment due date'**
  String get creditCardsFieldDueDate;

  /// No description provided for @creditCardsFieldDueDays.
  ///
  /// In en, this message translates to:
  /// **'Days to pay after statement'**
  String get creditCardsFieldDueDays;

  /// No description provided for @creditCardsFieldLastFour.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits (optional)'**
  String get creditCardsFieldLastFour;

  /// No description provided for @creditCardsFieldLateFeeFloor.
  ///
  /// In en, this message translates to:
  /// **'Late fee minimum amount'**
  String get creditCardsFieldLateFeeFloor;

  /// No description provided for @creditCardsFieldLateFeePct.
  ///
  /// In en, this message translates to:
  /// **'Late fee (% of unpaid minimum)'**
  String get creditCardsFieldLateFeePct;

  /// No description provided for @creditCardsFieldLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditCardsFieldLimit;

  /// No description provided for @creditCardsFieldMinDue.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment due'**
  String get creditCardsFieldMinDue;

  /// No description provided for @creditCardsFieldMinFloor.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment floor (amount)'**
  String get creditCardsFieldMinFloor;

  /// No description provided for @creditCardsFieldMinPct.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment (% of bill)'**
  String get creditCardsFieldMinPct;

  /// No description provided for @creditCardsFieldMonth.
  ///
  /// In en, this message translates to:
  /// **'Statement month (YYYY-MM)'**
  String get creditCardsFieldMonth;

  /// No description provided for @creditCardsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get creditCardsFieldName;

  /// No description provided for @creditCardsFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get creditCardsFieldNote;

  /// No description provided for @creditCardsFieldPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get creditCardsFieldPayAmount;

  /// No description provided for @creditCardsFieldPayDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get creditCardsFieldPayDate;

  /// No description provided for @creditCardsFieldStatementDate.
  ///
  /// In en, this message translates to:
  /// **'Statement date'**
  String get creditCardsFieldStatementDate;

  /// No description provided for @creditCardsFieldStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement day (1-28)'**
  String get creditCardsFieldStatementDay;

  /// No description provided for @creditCardsHelpApr.
  ///
  /// In en, this message translates to:
  /// **'Charged on the unpaid bill after the due date, as a daily rate (APR / 365).'**
  String get creditCardsHelpApr;

  /// No description provided for @creditCardsHelpBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Only this month\'s new charges, not the unpaid balance of earlier bills.'**
  String get creditCardsHelpBillAmount;

  /// No description provided for @creditCardsHelpDueDays.
  ///
  /// In en, this message translates to:
  /// **'Payment due date = statement date + this many days.'**
  String get creditCardsHelpDueDays;

  /// No description provided for @creditCardsHelpInterestFromStatement.
  ///
  /// In en, this message translates to:
  /// **'Many banks remove the interest-free period when the whole bill is not paid by the due date. On: interest runs from the statement date. Off: from the due date.'**
  String get creditCardsHelpInterestFromStatement;

  /// No description provided for @creditCardsHelpLateFee.
  ///
  /// In en, this message translates to:
  /// **'Charged when the minimum is not paid by the due date: the larger of the % and this amount.'**
  String get creditCardsHelpLateFee;

  /// No description provided for @creditCardsHelpMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum due = the larger of the % and this amount, never more than the bill.'**
  String get creditCardsHelpMin;

  /// No description provided for @creditCardsHelpMinDue.
  ///
  /// In en, this message translates to:
  /// **'Filled from the card policy; change it to match your statement.'**
  String get creditCardsHelpMinDue;

  /// No description provided for @creditCardsHelpStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Day of the month your bank generates the statement.'**
  String get creditCardsHelpStatementDay;

  /// No description provided for @creditCardsInactiveBanner.
  ///
  /// In en, this message translates to:
  /// **'This card is inactive.'**
  String get creditCardsInactiveBanner;

  /// No description provided for @creditCardsInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest ({rate} APR)'**
  String creditCardsInterest(String rate);

  /// No description provided for @creditCardsInterestFromStatement.
  ///
  /// In en, this message translates to:
  /// **'Interest from statement date if not paid in full'**
  String get creditCardsInterestFromStatement;

  /// No description provided for @creditCardsInvalidMonth.
  ///
  /// In en, this message translates to:
  /// **'Use the format YYYY-MM'**
  String get creditCardsInvalidMonth;

  /// No description provided for @creditCardsInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get creditCardsInvalidNumber;

  /// No description provided for @creditCardsInvalidPercent.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage from 0 to 100'**
  String get creditCardsInvalidPercent;

  /// No description provided for @creditCardsLastFourInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 4 digits'**
  String get creditCardsLastFourInvalid;

  /// No description provided for @creditCardsLateFee.
  ///
  /// In en, this message translates to:
  /// **'Late fee ({rate})'**
  String creditCardsLateFee(String rate);

  /// No description provided for @creditCardsLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditCardsLimit;

  /// No description provided for @creditCardsMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum is {amount}'**
  String creditCardsMaxAmount(String amount);

  /// No description provided for @creditCardsMinimumDue.
  ///
  /// In en, this message translates to:
  /// **'Minimum due'**
  String get creditCardsMinimumDue;

  /// No description provided for @creditCardsNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due: {card} on {date}'**
  String creditCardsNextDue(String card, String date);

  /// No description provided for @creditCardsNoBills.
  ///
  /// In en, this message translates to:
  /// **'No bills yet. Add a monthly statement to start tracking.'**
  String get creditCardsNoBills;

  /// No description provided for @creditCardsNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded.'**
  String get creditCardsNoPayments;

  /// No description provided for @creditCardsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Card not found.'**
  String get creditCardsNotFound;

  /// No description provided for @creditCardsNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due'**
  String get creditCardsNothingDue;

  /// No description provided for @creditCardsOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get creditCardsOutstanding;

  /// No description provided for @creditCardsOverdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get creditCardsOverdueBadge;

  /// No description provided for @creditCardsOverdueBills.
  ///
  /// In en, this message translates to:
  /// **'Overdue bills: {count}'**
  String creditCardsOverdueBills(int count);

  /// No description provided for @creditCardsPaidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get creditCardsPaidSoFar;

  /// No description provided for @creditCardsPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get creditCardsPay;

  /// No description provided for @creditCardsPayFull.
  ///
  /// In en, this message translates to:
  /// **'Full remaining'**
  String get creditCardsPayFull;

  /// No description provided for @creditCardsPayMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum due'**
  String get creditCardsPayMinimum;

  /// No description provided for @creditCardsPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get creditCardsPaymentTitle;

  /// No description provided for @creditCardsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get creditCardsPayments;

  /// No description provided for @creditCardsPolicy.
  ///
  /// In en, this message translates to:
  /// **'Billing policy'**
  String get creditCardsPolicy;

  /// No description provided for @creditCardsProjectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Estimated interest and fees on this bill by {date} (30 days after the due date):'**
  String creditCardsProjectionIntro(String date);

  /// No description provided for @creditCardsProjectionMin.
  ///
  /// In en, this message translates to:
  /// **'Pay only the minimum ({amount}) now: {charges}'**
  String creditCardsProjectionMin(String amount, String charges);

  /// No description provided for @creditCardsProjectionNothing.
  ///
  /// In en, this message translates to:
  /// **'Pay nothing more: {charges}'**
  String creditCardsProjectionNothing(String charges);

  /// No description provided for @creditCardsProjectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What if you delay?'**
  String get creditCardsProjectionTitle;

  /// No description provided for @creditCardsRangeInt.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}'**
  String creditCardsRangeInt(int min, int max);

  /// No description provided for @creditCardsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get creditCardsRemaining;

  /// No description provided for @creditCardsRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining {amount}'**
  String creditCardsRemainingAmount(String amount);

  /// No description provided for @creditCardsRemainingNow.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String creditCardsRemainingNow(String amount);

  /// No description provided for @creditCardsShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive cards'**
  String get creditCardsShowInactive;

  /// No description provided for @creditCardsStatusMinPaid.
  ///
  /// In en, this message translates to:
  /// **'Minimum paid'**
  String get creditCardsStatusMinPaid;

  /// No description provided for @creditCardsStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get creditCardsStatusOverdue;

  /// No description provided for @creditCardsStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get creditCardsStatusPaid;

  /// No description provided for @creditCardsStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly paid'**
  String get creditCardsStatusPartial;

  /// No description provided for @creditCardsStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get creditCardsStatusUnpaid;

  /// No description provided for @creditCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get creditCardsTitle;

  /// No description provided for @creditCardsTotalLimit.
  ///
  /// In en, this message translates to:
  /// **'Total limit'**
  String get creditCardsTotalLimit;

  /// No description provided for @creditCardsTotalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total outstanding'**
  String get creditCardsTotalOutstanding;

  /// No description provided for @creditCardsTotalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get creditCardsTotalPayable;

  /// No description provided for @creditCardsUsed.
  ///
  /// In en, this message translates to:
  /// **'Used {percent}'**
  String creditCardsUsed(String percent);

  /// No description provided for @creditCardsVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get creditCardsVoid;

  /// No description provided for @creditCardsVoidBill.
  ///
  /// In en, this message translates to:
  /// **'Void bill'**
  String get creditCardsVoidBill;

  /// No description provided for @creditCardsVoidBillMessage.
  ///
  /// In en, this message translates to:
  /// **'Void this bill? It is kept for history but no longer counts toward your outstanding balance.'**
  String get creditCardsVoidBillMessage;

  /// No description provided for @creditCardsVoidPayment.
  ///
  /// In en, this message translates to:
  /// **'Void payment'**
  String get creditCardsVoidPayment;

  /// No description provided for @creditCardsVoidPaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Void the payment of {amount}? The balance, interest and fees will be recalculated.'**
  String creditCardsVoidPaymentMessage(String amount);

  /// No description provided for @creditCardsVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get creditCardsVoided;

  /// No description provided for @creditCardsVoidedBanner.
  ///
  /// In en, this message translates to:
  /// **'This bill is voided.'**
  String get creditCardsVoidedBanner;

  /// No description provided for @currencyAddRate.
  ///
  /// In en, this message translates to:
  /// **'Add exchange rate'**
  String get currencyAddRate;

  /// No description provided for @currencyAddRateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add rate'**
  String get currencyAddRateTooltip;

  /// No description provided for @currencyBaseCard.
  ///
  /// In en, this message translates to:
  /// **'Base currency: {code} ({symbol})'**
  String currencyBaseCard(String code, String symbol);

  /// No description provided for @currencyBaseCardSub.
  ///
  /// In en, this message translates to:
  /// **'All balances, budgets and reports use it'**
  String get currencyBaseCardSub;

  /// No description provided for @currencyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'3-letter currency code'**
  String get currencyCodeLabel;

  /// No description provided for @currencyEditRate.
  ///
  /// In en, this message translates to:
  /// **'Edit exchange rate'**
  String get currencyEditRate;

  /// No description provided for @currencyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a rate for each foreign currency you spend or earn in, e.g. 1 USD = your base currency amount.'**
  String get currencyEmptyBody;

  /// No description provided for @currencyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No exchange rates yet'**
  String get currencyEmptyTitle;

  /// No description provided for @currencyErrChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a currency.'**
  String get currencyErrChoose;

  /// No description provided for @currencyErrCode.
  ///
  /// In en, this message translates to:
  /// **'Currency code must be 3 letters, e.g. USD.'**
  String get currencyErrCode;

  /// No description provided for @currencyErrRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than zero with up to 6 decimals, e.g. 122.5.'**
  String get currencyErrRate;

  /// No description provided for @currencyFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyFieldCurrency;

  /// No description provided for @currencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Rates are entered by you and are never fetched online. They are only used when you enter a transaction in a foreign currency. Transactions you already saved keep the rate they were saved with, so changing a rate here never rewrites history.'**
  String get currencyInfo;

  /// No description provided for @currencyNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage exchange rates.'**
  String get currencyNoProfile;

  /// No description provided for @currencyOtherCode.
  ///
  /// In en, this message translates to:
  /// **'Other code'**
  String get currencyOtherCode;

  /// No description provided for @currencyRateEquals.
  ///
  /// In en, this message translates to:
  /// **'1 {code} = {symbol}{rate}'**
  String currencyRateEquals(String code, String symbol, String rate);

  /// No description provided for @currencyRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Base currency amount for 1 unit of the foreign currency'**
  String get currencyRateHelper;

  /// No description provided for @currencyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate (in {base})'**
  String currencyRateLabel(String base);

  /// No description provided for @currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get currencyTitle;

  /// No description provided for @currencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String currencyUpdated(String date);

  /// No description provided for @currencyUpdatedInactive.
  ///
  /// In en, this message translates to:
  /// **'Updated {date} - inactive'**
  String currencyUpdatedInactive(String date);

  /// No description provided for @dashboardAverageDailyExpense.
  ///
  /// In en, this message translates to:
  /// **'Average daily expense'**
  String get dashboardAverageDailyExpense;

  /// No description provided for @dashboardAverageMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Average monthly expense'**
  String get dashboardAverageMonthlyExpense;

  /// No description provided for @dashboardBudgetUtilization.
  ///
  /// In en, this message translates to:
  /// **'Budget utilization'**
  String get dashboardBudgetUtilization;

  /// No description provided for @dashboardCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash balance (active accounts)'**
  String get dashboardCashBalance;

  /// No description provided for @dashboardCategoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get dashboardCategoryDistribution;

  /// No description provided for @dashboardCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get dashboardCurrentMonth;

  /// No description provided for @dashboardHighestSpendingDay.
  ///
  /// In en, this message translates to:
  /// **'Highest spending day'**
  String get dashboardHighestSpendingDay;

  /// No description provided for @dashboardHighestSpendingMonth.
  ///
  /// In en, this message translates to:
  /// **'Highest spending month'**
  String get dashboardHighestSpendingMonth;

  /// No description provided for @dashboardLowestSpendingMonth.
  ///
  /// In en, this message translates to:
  /// **'Lowest spending month'**
  String get dashboardLowestSpendingMonth;

  /// No description provided for @dashboardMonthExpense.
  ///
  /// In en, this message translates to:
  /// **'Month expense'**
  String get dashboardMonthExpense;

  /// No description provided for @dashboardMonthIncome.
  ///
  /// In en, this message translates to:
  /// **'Month income'**
  String get dashboardMonthIncome;

  /// No description provided for @dashboardMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get dashboardMonthlyBudget;

  /// No description provided for @dashboardMonthlyExpenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly expense trend'**
  String get dashboardMonthlyExpenseTrend;

  /// No description provided for @dashboardNoCategoryExpenses.
  ///
  /// In en, this message translates to:
  /// **'No category expenses this month.'**
  String get dashboardNoCategoryExpenses;

  /// No description provided for @dashboardNoCostItemExpenses.
  ///
  /// In en, this message translates to:
  /// **'No cost-item expenses this month.'**
  String get dashboardNoCostItemExpenses;

  /// No description provided for @dashboardNoExpensesToChart.
  ///
  /// In en, this message translates to:
  /// **'No expenses to chart this month.'**
  String get dashboardNoExpensesToChart;

  /// No description provided for @dashboardNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No profile'**
  String get dashboardNoProfile;

  /// No description provided for @dashboardPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get dashboardPreviousMonth;

  /// No description provided for @dashboardRemainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining budget'**
  String get dashboardRemainingBudget;

  /// No description provided for @dashboardSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get dashboardSelectMonth;

  /// No description provided for @dashboardSpendingHighlights.
  ///
  /// In en, this message translates to:
  /// **'Spending highlights'**
  String get dashboardSpendingHighlights;

  /// No description provided for @dashboardSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get dashboardSwitch;

  /// No description provided for @dashboardTop5Categories.
  ///
  /// In en, this message translates to:
  /// **'Top 5 categories'**
  String get dashboardTop5Categories;

  /// No description provided for @dashboardTop5CostItems.
  ///
  /// In en, this message translates to:
  /// **'Top 5 cost items'**
  String get dashboardTop5CostItems;

  /// No description provided for @dashboardTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expense'**
  String get dashboardTotalExpense;

  /// No description provided for @dashboardTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get dashboardTotalIncome;

  /// No description provided for @dashboardYear.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String dashboardYear(int year);

  /// No description provided for @dashboardYearlyOverview.
  ///
  /// In en, this message translates to:
  /// **'Yearly overview'**
  String get dashboardYearlyOverview;

  /// No description provided for @debtsAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Add debt'**
  String get debtsAddDebt;

  /// No description provided for @debtsAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get debtsAddPayment;

  /// No description provided for @debtsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get debtsAmount;

  /// No description provided for @debtsAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get debtsAmountPositive;

  /// No description provided for @debtsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get debtsArchived;

  /// No description provided for @debtsBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get debtsBorrowed;

  /// No description provided for @debtsClearField.
  ///
  /// In en, this message translates to:
  /// **'Clear {label}'**
  String debtsClearField(String label);

  /// No description provided for @debtsDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String debtsDue(String date);

  /// No description provided for @debtsDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get debtsDueDate;

  /// No description provided for @debtsDueWithPrincipal.
  ///
  /// In en, this message translates to:
  /// **'{due}  •  of {principal}'**
  String debtsDueWithPrincipal(String due, String principal);

  /// No description provided for @debtsEditDebt.
  ///
  /// In en, this message translates to:
  /// **'Edit debt'**
  String get debtsEditDebt;

  /// No description provided for @debtsGroupByPerson.
  ///
  /// In en, this message translates to:
  /// **'Group by person'**
  String get debtsGroupByPerson;

  /// No description provided for @debtsIAmOwed.
  ///
  /// In en, this message translates to:
  /// **'I am owed'**
  String get debtsIAmOwed;

  /// No description provided for @debtsIBorrowed.
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get debtsIBorrowed;

  /// No description provided for @debtsILent.
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get debtsILent;

  /// No description provided for @debtsIOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe'**
  String get debtsIOwe;

  /// No description provided for @debtsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get debtsInvalidAmount;

  /// No description provided for @debtsLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get debtsLent;

  /// No description provided for @debtsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Debts & loans'**
  String get debtsListTitle;

  /// No description provided for @debtsMarkSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark fully settled'**
  String get debtsMarkSettled;

  /// No description provided for @debtsMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum is {amount}'**
  String debtsMaxAmount(String amount);

  /// No description provided for @debtsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get debtsNet;

  /// No description provided for @debtsNoBorrowed.
  ///
  /// In en, this message translates to:
  /// **'No money borrowed yet.'**
  String get debtsNoBorrowed;

  /// No description provided for @debtsNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get debtsNoDueDate;

  /// No description provided for @debtsNoLent.
  ///
  /// In en, this message translates to:
  /// **'No money lent yet.'**
  String get debtsNoLent;

  /// No description provided for @debtsNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get debtsNoPayments;

  /// No description provided for @debtsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Debt not found.'**
  String get debtsNotFound;

  /// No description provided for @debtsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get debtsNotSet;

  /// No description provided for @debtsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get debtsNote;

  /// No description provided for @debtsOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get debtsOutstanding;

  /// No description provided for @debtsOutstandingAmount.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {amount}'**
  String debtsOutstandingAmount(String amount);

  /// No description provided for @debtsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtsOverdue;

  /// No description provided for @debtsOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'Owed to me'**
  String get debtsOwedToMe;

  /// No description provided for @debtsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get debtsPaid;

  /// No description provided for @debtsPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get debtsPaymentDate;

  /// No description provided for @debtsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get debtsPayments;

  /// No description provided for @debtsPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get debtsPerson;

  /// No description provided for @debtsPersonRequired.
  ///
  /// In en, this message translates to:
  /// **'Person name is required'**
  String get debtsPersonRequired;

  /// No description provided for @debtsPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get debtsPrincipal;

  /// No description provided for @debtsReminderBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Reminder: I owe {person} {outstanding} (of {principal}).'**
  String debtsReminderBorrowed(
    String person,
    String outstanding,
    String principal,
  );

  /// No description provided for @debtsReminderBorrowedDue.
  ///
  /// In en, this message translates to:
  /// **'Reminder: I owe {person} {outstanding} (of {principal}). Due: {date}.'**
  String debtsReminderBorrowedDue(
    String person,
    String outstanding,
    String principal,
    String date,
  );

  /// No description provided for @debtsReminderLent.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {person} owes me {outstanding} (of {principal}).'**
  String debtsReminderLent(String person, String outstanding, String principal);

  /// No description provided for @debtsReminderLentDue.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {person} owes me {outstanding} (of {principal}). Due: {date}.'**
  String debtsReminderLentDue(
    String person,
    String outstanding,
    String principal,
    String date,
  );

  /// No description provided for @debtsSettle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get debtsSettle;

  /// No description provided for @debtsSettleMessage.
  ///
  /// In en, this message translates to:
  /// **'Record a payment of {amount}?'**
  String debtsSettleMessage(String amount);

  /// No description provided for @debtsShareReminder.
  ///
  /// In en, this message translates to:
  /// **'Share reminder'**
  String get debtsShareReminder;

  /// No description provided for @debtsShowFlatList.
  ///
  /// In en, this message translates to:
  /// **'Show flat list'**
  String get debtsShowFlatList;

  /// No description provided for @debtsStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get debtsStartDate;

  /// No description provided for @debtsStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String debtsStarted(String date);

  /// No description provided for @debtsStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get debtsStatusOpen;

  /// No description provided for @debtsStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtsStatusOverdue;

  /// No description provided for @debtsStatusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtsStatusSettled;

  /// No description provided for @debtsTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtsTitle;

  /// No description provided for @debtsUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get debtsUnarchive;

  /// No description provided for @debtsVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get debtsVoid;

  /// No description provided for @debtsVoidMessage.
  ///
  /// In en, this message translates to:
  /// **'Void this payment of {amount}? The outstanding balance will increase.'**
  String debtsVoidMessage(String amount);

  /// No description provided for @debtsVoidPayment.
  ///
  /// In en, this message translates to:
  /// **'Void payment'**
  String get debtsVoidPayment;

  /// No description provided for @debtsVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get debtsVoided;

  /// No description provided for @fixedDepositsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add deposit'**
  String get fixedDepositsAdd;

  /// No description provided for @fixedDepositsAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get fixedDepositsAmountPositive;

  /// No description provided for @fixedDepositsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get fixedDepositsArchived;

  /// No description provided for @fixedDepositsBadgeReissued.
  ///
  /// In en, this message translates to:
  /// **'Reissued'**
  String get fixedDepositsBadgeReissued;

  /// No description provided for @fixedDepositsBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get fixedDepositsBank;

  /// No description provided for @fixedDepositsBankRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the bank name'**
  String get fixedDepositsBankRequired;

  /// No description provided for @fixedDepositsBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary name'**
  String get fixedDepositsBeneficiary;

  /// No description provided for @fixedDepositsCalculatedNet.
  ///
  /// In en, this message translates to:
  /// **'Calculated net: {amount}'**
  String fixedDepositsCalculatedNet(String amount);

  /// No description provided for @fixedDepositsClosedBanner.
  ///
  /// In en, this message translates to:
  /// **'This deposit is closed (encashed).'**
  String get fixedDepositsClosedBanner;

  /// No description provided for @fixedDepositsClosedOn.
  ///
  /// In en, this message translates to:
  /// **'Closed on {date}'**
  String fixedDepositsClosedOn(String date);

  /// No description provided for @fixedDepositsClosingCharge.
  ///
  /// In en, this message translates to:
  /// **'Bank charge'**
  String get fixedDepositsClosingCharge;

  /// No description provided for @fixedDepositsClosingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing date'**
  String get fixedDepositsClosingDate;

  /// No description provided for @fixedDepositsClosingInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest received'**
  String get fixedDepositsClosingInterest;

  /// No description provided for @fixedDepositsClosingTax.
  ///
  /// In en, this message translates to:
  /// **'Tax deducted'**
  String get fixedDepositsClosingTax;

  /// No description provided for @fixedDepositsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String fixedDepositsDaysLeft(int days);

  /// No description provided for @fixedDepositsEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit bank details'**
  String get fixedDepositsEditDetails;

  /// No description provided for @fixedDepositsEditInstrument.
  ///
  /// In en, this message translates to:
  /// **'Edit instrument'**
  String get fixedDepositsEditInstrument;

  /// No description provided for @fixedDepositsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit deposit'**
  String get fixedDepositsEditTitle;

  /// No description provided for @fixedDepositsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deposits yet. Tap + to add an FDR, DPS or savings certificate.'**
  String get fixedDepositsEmpty;

  /// No description provided for @fixedDepositsEncash.
  ///
  /// In en, this message translates to:
  /// **'Encash'**
  String get fixedDepositsEncash;

  /// No description provided for @fixedDepositsEncashNote.
  ///
  /// In en, this message translates to:
  /// **'After encashing, this deposit is closed and its instrument can no longer be edited.'**
  String get fixedDepositsEncashNote;

  /// No description provided for @fixedDepositsEncashTitle.
  ///
  /// In en, this message translates to:
  /// **'Encash deposit'**
  String get fixedDepositsEncashTitle;

  /// No description provided for @fixedDepositsExpectedInterest.
  ///
  /// In en, this message translates to:
  /// **'Expected interest'**
  String get fixedDepositsExpectedInterest;

  /// No description provided for @fixedDepositsExpectedNote.
  ///
  /// In en, this message translates to:
  /// **'An estimate (simple interest on 365 days). You enter the bank figure when you close it.'**
  String get fixedDepositsExpectedNote;

  /// No description provided for @fixedDepositsFinalNet.
  ///
  /// In en, this message translates to:
  /// **'Final net received (optional)'**
  String get fixedDepositsFinalNet;

  /// No description provided for @fixedDepositsFinalNetHelper.
  ///
  /// In en, this message translates to:
  /// **'Fill only if the bank paid a different amount.'**
  String get fixedDepositsFinalNetHelper;

  /// No description provided for @fixedDepositsHistory.
  ///
  /// In en, this message translates to:
  /// **'Instrument history'**
  String get fixedDepositsHistory;

  /// No description provided for @fixedDepositsInstrumentNo.
  ///
  /// In en, this message translates to:
  /// **'Instrument #{no}'**
  String fixedDepositsInstrumentNo(int no);

  /// No description provided for @fixedDepositsInstrumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Instrument number'**
  String get fixedDepositsInstrumentNumber;

  /// No description provided for @fixedDepositsInstrumentRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the instrument number'**
  String get fixedDepositsInstrumentRequired;

  /// No description provided for @fixedDepositsInstrumentRow.
  ///
  /// In en, this message translates to:
  /// **'Instrument {number}'**
  String fixedDepositsInstrumentRow(String number);

  /// No description provided for @fixedDepositsInterestHelper.
  ///
  /// In en, this message translates to:
  /// **'Suggested for {days} days. Change it to the amount the bank paid.'**
  String fixedDepositsInterestHelper(int days);

  /// No description provided for @fixedDepositsInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (% per year)'**
  String get fixedDepositsInterestRate;

  /// No description provided for @fixedDepositsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get fixedDepositsInvalidAmount;

  /// No description provided for @fixedDepositsInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate between 0 and 100'**
  String get fixedDepositsInvalidRate;

  /// No description provided for @fixedDepositsInvalidTenure.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 36500 days'**
  String get fixedDepositsInvalidTenure;

  /// No description provided for @fixedDepositsIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get fixedDepositsIssueDate;

  /// No description provided for @fixedDepositsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed deposits'**
  String get fixedDepositsListTitle;

  /// No description provided for @fixedDepositsMaturedAgo.
  ///
  /// In en, this message translates to:
  /// **'Matured {days} days ago'**
  String fixedDepositsMaturedAgo(int days);

  /// No description provided for @fixedDepositsMaturedAlert.
  ///
  /// In en, this message translates to:
  /// **'{count} matured: encash or reissue'**
  String fixedDepositsMaturedAlert(int count);

  /// No description provided for @fixedDepositsMaturedBanner.
  ///
  /// In en, this message translates to:
  /// **'This deposit has matured. Encash it or reissue it as a new instrument.'**
  String get fixedDepositsMaturedBanner;

  /// No description provided for @fixedDepositsMaturesToday.
  ///
  /// In en, this message translates to:
  /// **'Matures today'**
  String get fixedDepositsMaturesToday;

  /// No description provided for @fixedDepositsMaturityDate.
  ///
  /// In en, this message translates to:
  /// **'Maturity date'**
  String get fixedDepositsMaturityDate;

  /// No description provided for @fixedDepositsNetMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Net received must be greater than zero to reissue'**
  String get fixedDepositsNetMustBePositive;

  /// No description provided for @fixedDepositsNetReceived.
  ///
  /// In en, this message translates to:
  /// **'Net received'**
  String get fixedDepositsNetReceived;

  /// No description provided for @fixedDepositsNewInstrument.
  ///
  /// In en, this message translates to:
  /// **'New instrument'**
  String get fixedDepositsNewInstrument;

  /// No description provided for @fixedDepositsNewInstrumentNumber.
  ///
  /// In en, this message translates to:
  /// **'New instrument number'**
  String get fixedDepositsNewInstrumentNumber;

  /// No description provided for @fixedDepositsNewPrincipal.
  ///
  /// In en, this message translates to:
  /// **'New principal = net received: {amount}'**
  String fixedDepositsNewPrincipal(String amount);

  /// No description provided for @fixedDepositsNextMaturity.
  ///
  /// In en, this message translates to:
  /// **'Next maturity {date} • {amount}'**
  String fixedDepositsNextMaturity(String date, String amount);

  /// No description provided for @fixedDepositsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Deposit not found.'**
  String get fixedDepositsNotFound;

  /// No description provided for @fixedDepositsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get fixedDepositsNote;

  /// No description provided for @fixedDepositsOutcomeEncashed.
  ///
  /// In en, this message translates to:
  /// **'Encashed'**
  String get fixedDepositsOutcomeEncashed;

  /// No description provided for @fixedDepositsOutcomeReissued.
  ///
  /// In en, this message translates to:
  /// **'Reissued'**
  String get fixedDepositsOutcomeReissued;

  /// No description provided for @fixedDepositsOutcomeRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get fixedDepositsOutcomeRunning;

  /// No description provided for @fixedDepositsPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get fixedDepositsPrincipal;

  /// No description provided for @fixedDepositsRatePerYear.
  ///
  /// In en, this message translates to:
  /// **'{rate}% per year'**
  String fixedDepositsRatePerYear(String rate);

  /// No description provided for @fixedDepositsReissue.
  ///
  /// In en, this message translates to:
  /// **'Reissue'**
  String get fixedDepositsReissue;

  /// No description provided for @fixedDepositsReissueDate.
  ///
  /// In en, this message translates to:
  /// **'Reissue date'**
  String get fixedDepositsReissueDate;

  /// No description provided for @fixedDepositsReissueTitle.
  ///
  /// In en, this message translates to:
  /// **'Reissue deposit'**
  String get fixedDepositsReissueTitle;

  /// No description provided for @fixedDepositsReissuedFrom.
  ///
  /// In en, this message translates to:
  /// **'Reissued from #{no}'**
  String fixedDepositsReissuedFrom(int no);

  /// No description provided for @fixedDepositsSchemeDps.
  ///
  /// In en, this message translates to:
  /// **'DPS'**
  String get fixedDepositsSchemeDps;

  /// No description provided for @fixedDepositsSchemeFdr.
  ///
  /// In en, this message translates to:
  /// **'FDR'**
  String get fixedDepositsSchemeFdr;

  /// No description provided for @fixedDepositsSchemeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the scheme type'**
  String get fixedDepositsSchemeRequired;

  /// No description provided for @fixedDepositsSchemeSanchaypatra.
  ///
  /// In en, this message translates to:
  /// **'Sanchaypatra'**
  String get fixedDepositsSchemeSanchaypatra;

  /// No description provided for @fixedDepositsSchemeType.
  ///
  /// In en, this message translates to:
  /// **'Scheme type'**
  String get fixedDepositsSchemeType;

  /// No description provided for @fixedDepositsShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived deposits'**
  String get fixedDepositsShowArchived;

  /// No description provided for @fixedDepositsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fixedDepositsStatusActive;

  /// No description provided for @fixedDepositsStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get fixedDepositsStatusClosed;

  /// No description provided for @fixedDepositsStatusMatured.
  ///
  /// In en, this message translates to:
  /// **'Matured'**
  String get fixedDepositsStatusMatured;

  /// No description provided for @fixedDepositsSummaryInterest.
  ///
  /// In en, this message translates to:
  /// **'Expected interest'**
  String get fixedDepositsSummaryInterest;

  /// No description provided for @fixedDepositsSummaryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get fixedDepositsSummaryOpen;

  /// No description provided for @fixedDepositsSummaryPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get fixedDepositsSummaryPlaced;

  /// No description provided for @fixedDepositsTenureDays.
  ///
  /// In en, this message translates to:
  /// **'Tenure (days)'**
  String get fixedDepositsTenureDays;

  /// No description provided for @fixedDepositsTenureHelper.
  ///
  /// In en, this message translates to:
  /// **'≈ {months} months (30 days = 1 month)'**
  String fixedDepositsTenureHelper(String months);

  /// No description provided for @fixedDepositsTenureValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days (~{months} months)'**
  String fixedDepositsTenureValue(int days, String months);

  /// No description provided for @fixedDepositsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get fixedDepositsTitle;

  /// No description provided for @goalsAccountLine.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String goalsAccountLine(String account);

  /// No description provided for @goalsAccountLineArchived.
  ///
  /// In en, this message translates to:
  /// **'Account: {account} - archived'**
  String goalsAccountLineArchived(String account);

  /// No description provided for @goalsAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get goalsAchieved;

  /// No description provided for @goalsAddGoal.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalsAddGoal;

  /// No description provided for @goalsArchiveGoal.
  ///
  /// In en, this message translates to:
  /// **'Archive goal'**
  String get goalsArchiveGoal;

  /// No description provided for @goalsArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from your goals. Your account and transactions are not affected.'**
  String goalsArchiveMessage(String name);

  /// No description provided for @goalsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive goal?'**
  String get goalsArchiveTitle;

  /// No description provided for @goalsChooseAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose the account that holds the savings.'**
  String get goalsChooseAccount;

  /// No description provided for @goalsClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get goalsClearDate;

  /// No description provided for @goalsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left ({date})} other{{days} days left ({date})}}'**
  String goalsDaysLeft(int days, String date);

  /// No description provided for @goalsDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today ({date})'**
  String goalsDueToday(String date);

  /// No description provided for @goalsEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsEditGoal;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet. Tap + to add one.'**
  String get goalsEmpty;

  /// No description provided for @goalsGoalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalsGoalName;

  /// No description provided for @goalsGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get goalsGoalReached;

  /// No description provided for @goalsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (max 2 decimals)'**
  String get goalsInvalidAmount;

  /// No description provided for @goalsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get goalsNameRequired;

  /// No description provided for @goalsNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No active accounts. Add an account first.'**
  String get goalsNoAccounts;

  /// No description provided for @goalsNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get goalsNoDeadline;

  /// No description provided for @goalsNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get goalsNoteOptional;

  /// No description provided for @goalsOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days, plural, =1{1 day} other{{days} days}} ({date})'**
  String goalsOverdueBy(int days, String date);

  /// No description provided for @goalsProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String goalsProgressOf(String current, String target);

  /// No description provided for @goalsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String goalsRemaining(String amount);

  /// No description provided for @goalsRestoreGoal.
  ///
  /// In en, this message translates to:
  /// **'Restore goal'**
  String get goalsRestoreGoal;

  /// No description provided for @goalsSavePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} / month'**
  String goalsSavePerMonth(String amount);

  /// No description provided for @goalsSavingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get goalsSavingsAccount;

  /// No description provided for @goalsSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage goals.'**
  String get goalsSelectProfile;

  /// No description provided for @goalsShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get goalsShowArchived;

  /// No description provided for @goalsTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalsTargetAmount;

  /// No description provided for @goalsTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date {date}'**
  String goalsTargetDate(String date);

  /// No description provided for @goalsTargetDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Target date (optional)'**
  String get goalsTargetDateOptional;

  /// No description provided for @goalsTargetPositive.
  ///
  /// In en, this message translates to:
  /// **'Target must be greater than zero'**
  String get goalsTargetPositive;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get goalsTitle;

  /// No description provided for @importChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV file'**
  String get importChooseFile;

  /// No description provided for @importColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get importColAmount;

  /// No description provided for @importColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get importColCategory;

  /// No description provided for @importColDate.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get importColDate;

  /// No description provided for @importColDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get importColDescription;

  /// No description provided for @importColType.
  ///
  /// In en, this message translates to:
  /// **'Type (expense/income)'**
  String get importColType;

  /// No description provided for @importColTypeNone.
  ///
  /// In en, this message translates to:
  /// **'Use the +/- sign of the amount'**
  String get importColTypeNone;

  /// No description provided for @importCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file: {error}'**
  String importCouldNotRead(String error);

  /// No description provided for @importDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get importDateFormat;

  /// No description provided for @importDefaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Default category for expenses'**
  String get importDefaultCategory;

  /// No description provided for @importDefaultCategoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Used when a row has no category or its name does not match an existing category exactly. Categories are never created automatically.'**
  String get importDefaultCategoryHelp;

  /// No description provided for @importDefaultCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'None (rows without a match are invalid)'**
  String get importDefaultCategoryNone;

  /// No description provided for @importDelimiterTab.
  ///
  /// In en, this message translates to:
  /// **'tab'**
  String get importDelimiterTab;

  /// No description provided for @importFinished.
  ///
  /// In en, this message translates to:
  /// **'Import finished'**
  String get importFinished;

  /// No description provided for @importFirstRowHeader.
  ///
  /// In en, this message translates to:
  /// **'First row is a header'**
  String get importFirstRowHeader;

  /// No description provided for @importImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importImportFailed(String error);

  /// No description provided for @importImportRows.
  ///
  /// In en, this message translates to:
  /// **'Import {count} rows'**
  String importImportRows(int count);

  /// No description provided for @importImported.
  ///
  /// In en, this message translates to:
  /// **'Imported: {count}'**
  String importImported(int count);

  /// No description provided for @importIntoAccount.
  ///
  /// In en, this message translates to:
  /// **'Import into account *'**
  String get importIntoAccount;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Import expenses and income from a bank or e-wallet CSV. Re-importing the same file never creates duplicates.'**
  String get importIntro;

  /// No description provided for @importInvalidNote.
  ///
  /// In en, this message translates to:
  /// **'Invalid rows are skipped; the valid rows are imported all-or-nothing.'**
  String get importInvalidNote;

  /// No description provided for @importInvalidRows.
  ///
  /// In en, this message translates to:
  /// **'Invalid rows: {count}'**
  String importInvalidRows(int count);

  /// No description provided for @importKindExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get importKindExpense;

  /// No description provided for @importKindIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get importKindIncome;

  /// No description provided for @importNoDescription.
  ///
  /// In en, this message translates to:
  /// **'(no description)'**
  String get importNoDescription;

  /// No description provided for @importNotMapped.
  ///
  /// In en, this message translates to:
  /// **'(not mapped)'**
  String get importNotMapped;

  /// No description provided for @importRowDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Row {number}: already imported'**
  String importRowDuplicate(int number);

  /// No description provided for @importRowInvalid.
  ///
  /// In en, this message translates to:
  /// **'Row {number}: {cells}'**
  String importRowInvalid(int number, String cells);

  /// No description provided for @importRowValid.
  ///
  /// In en, this message translates to:
  /// **'Row {number}: {kind} {amount}'**
  String importRowValid(int number, String kind, String amount);

  /// No description provided for @importSkippedDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Skipped duplicates: {count}'**
  String importSkippedDuplicates(int count);

  /// No description provided for @importStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Choose a file'**
  String get importStep1;

  /// No description provided for @importStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Map the columns  ({rows} rows, delimiter \"{delimiter}\")'**
  String importStep2(int rows, String delimiter);

  /// No description provided for @importStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Preview'**
  String get importStep3;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{valid} to import · {duplicate} already imported · {invalid} invalid (showing first {shown} rows)'**
  String importSummary(int valid, int duplicate, int invalid, int shown);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importTitle;

  /// No description provided for @insightsCategoryDown.
  ///
  /// In en, this message translates to:
  /// **'{name} is down {amount}{percent} vs last month'**
  String insightsCategoryDown(String name, String amount, String percent);

  /// No description provided for @insightsCategoryNew.
  ///
  /// In en, this message translates to:
  /// **'{name} is new this month: {amount}'**
  String insightsCategoryNew(String name, String amount);

  /// No description provided for @insightsCategoryUp.
  ///
  /// In en, this message translates to:
  /// **'{name} is up {amount}{percent} vs last month'**
  String insightsCategoryUp(String name, String amount, String percent);

  /// No description provided for @insightsForecastAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk: projected {projected} is close to your {budget} budget'**
  String insightsForecastAtRisk(String projected, String budget);

  /// No description provided for @insightsForecastDetail.
  ///
  /// In en, this message translates to:
  /// **'Spent so far {spent} · daily average {average} · {days} days left'**
  String insightsForecastDetail(String spent, String average, int days);

  /// No description provided for @insightsForecastNoBudget.
  ///
  /// In en, this message translates to:
  /// **'Projected month-end spending: {projected} (no budget set)'**
  String insightsForecastNoBudget(String projected);

  /// No description provided for @insightsForecastOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track: projected {projected} of your {budget} budget'**
  String insightsForecastOnTrack(String projected, String budget);

  /// No description provided for @insightsForecastOver.
  ///
  /// In en, this message translates to:
  /// **'Projected to exceed your budget by {over} ({projected} vs {budget})'**
  String insightsForecastOver(String over, String projected, String budget);

  /// No description provided for @insightsForecastRecurring.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} of upcoming recurring expenses'**
  String insightsForecastRecurring(String amount);

  /// No description provided for @insightsForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Month-end forecast'**
  String get insightsForecastTitle;

  /// No description provided for @insightsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get insightsNextMonth;

  /// No description provided for @insightsNoData.
  ///
  /// In en, this message translates to:
  /// **'No spending data for this month yet.'**
  String get insightsNoData;

  /// No description provided for @insightsNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month.'**
  String get insightsNoExpenses;

  /// No description provided for @insightsNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded this month.'**
  String get insightsNoIncome;

  /// No description provided for @insightsNothingUnusual.
  ///
  /// In en, this message translates to:
  /// **'Nothing unusual this month.'**
  String get insightsNothingUnusual;

  /// No description provided for @insightsPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get insightsPreviousMonth;

  /// No description provided for @insightsSavingsOverspent.
  ///
  /// In en, this message translates to:
  /// **'You spent {percent}% more than you earned this month'**
  String insightsSavingsOverspent(int percent);

  /// No description provided for @insightsSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get insightsSavingsRate;

  /// No description provided for @insightsSavingsSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved {percent}% of your income this month'**
  String insightsSavingsSaved(int percent);

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsTopItems.
  ///
  /// In en, this message translates to:
  /// **'Top items this month'**
  String get insightsTopItems;

  /// No description provided for @insightsTotalDown.
  ///
  /// In en, this message translates to:
  /// **'Total spending is down {amount}{percent} vs last month'**
  String insightsTotalDown(String amount, String percent);

  /// No description provided for @insightsTotalNoPrevious.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} with no spending last month'**
  String insightsTotalNoPrevious(String amount);

  /// No description provided for @insightsTotalNone.
  ///
  /// In en, this message translates to:
  /// **'No spending this month or last month'**
  String get insightsTotalNone;

  /// No description provided for @insightsTotalSame.
  ///
  /// In en, this message translates to:
  /// **'Spending is the same as last month'**
  String get insightsTotalSame;

  /// No description provided for @insightsTotalUp.
  ///
  /// In en, this message translates to:
  /// **'Total spending is up {amount}{percent} vs last month'**
  String insightsTotalUp(String amount, String percent);

  /// No description provided for @insightsUnusual.
  ///
  /// In en, this message translates to:
  /// **'Unusual: {amount} on {label} is {excess} above your usual {usual}'**
  String insightsUnusual(
    String amount,
    String label,
    String excess,
    String usual,
  );

  /// No description provided for @insightsUnusualSpending.
  ///
  /// In en, this message translates to:
  /// **'Unusual spending'**
  String get insightsUnusualSpending;

  /// No description provided for @insightsVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Vs last month'**
  String get insightsVsLastMonth;

  /// No description provided for @insightsWeekdayCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by weekday (last 90 days)'**
  String get insightsWeekdayCardTitle;

  /// No description provided for @insightsWeekdayMostFri.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Fridays'**
  String get insightsWeekdayMostFri;

  /// No description provided for @insightsWeekdayMostMon.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Mondays'**
  String get insightsWeekdayMostMon;

  /// No description provided for @insightsWeekdayMostSat.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Saturdays'**
  String get insightsWeekdayMostSat;

  /// No description provided for @insightsWeekdayMostSun.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Sundays'**
  String get insightsWeekdayMostSun;

  /// No description provided for @insightsWeekdayMostThu.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Thursdays'**
  String get insightsWeekdayMostThu;

  /// No description provided for @insightsWeekdayMostTue.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Tuesdays'**
  String get insightsWeekdayMostTue;

  /// No description provided for @insightsWeekdayMostWed.
  ///
  /// In en, this message translates to:
  /// **'You spend the most on Wednesdays'**
  String get insightsWeekdayMostWed;

  /// No description provided for @ledgerAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get ledgerAccount;

  /// No description provided for @ledgerAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'{name} (inactive)'**
  String ledgerAccountInactive(String name);

  /// No description provided for @ledgerAccountTab.
  ///
  /// In en, this message translates to:
  /// **'Account Ledger'**
  String get ledgerAccountTab;

  /// No description provided for @ledgerBudgetTab.
  ///
  /// In en, this message translates to:
  /// **'Budget Ledger'**
  String get ledgerBudgetTab;

  /// No description provided for @ledgerClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get ledgerClearSearch;

  /// No description provided for @ledgerColBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get ledgerColBalance;

  /// No description provided for @ledgerColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ledgerColCategory;

  /// No description provided for @ledgerColCostItem.
  ///
  /// In en, this message translates to:
  /// **'Cost Item'**
  String get ledgerColCostItem;

  /// No description provided for @ledgerColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ledgerColDate;

  /// No description provided for @ledgerColDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ledgerColDescription;

  /// No description provided for @ledgerColExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get ledgerColExpense;

  /// No description provided for @ledgerColIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get ledgerColIncome;

  /// No description provided for @ledgerColRemainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining Budget'**
  String get ledgerColRemainingBudget;

  /// No description provided for @ledgerColTransferIn.
  ///
  /// In en, this message translates to:
  /// **'Transfer In'**
  String get ledgerColTransferIn;

  /// No description provided for @ledgerColTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Transfer Out'**
  String get ledgerColTransferOut;

  /// No description provided for @ledgerMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget: {amount}'**
  String ledgerMonthlyBudget(String amount);

  /// No description provided for @ledgerNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get ledgerNextMonth;

  /// No description provided for @ledgerNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get ledgerNextYear;

  /// No description provided for @ledgerNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Add an account to see its ledger.'**
  String get ledgerNoAccounts;

  /// No description provided for @ledgerNoBudget.
  ///
  /// In en, this message translates to:
  /// **'No budget'**
  String get ledgerNoBudget;

  /// No description provided for @ledgerNoBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set for this month.'**
  String get ledgerNoBudgetSet;

  /// No description provided for @ledgerNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this month.'**
  String get ledgerNoExpenses;

  /// No description provided for @ledgerNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period.'**
  String get ledgerNoTransactions;

  /// No description provided for @ledgerOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get ledgerOpeningBalance;

  /// No description provided for @ledgerPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get ledgerPreviousMonth;

  /// No description provided for @ledgerPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get ledgerPreviousYear;

  /// No description provided for @ledgerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, remarks, category, item'**
  String get ledgerSearchHint;

  /// No description provided for @ledgerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get ledgerSelect;

  /// No description provided for @ledgerTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ledgerTotal;

  /// No description provided for @loansAdd.
  ///
  /// In en, this message translates to:
  /// **'Add loan'**
  String get loansAdd;

  /// No description provided for @loansAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust / top-up'**
  String get loansAdjust;

  /// No description provided for @loansAdjustHelper.
  ///
  /// In en, this message translates to:
  /// **'The current loan is closed and a new loan replaces it. The amount is prefilled with the principal you still owe; add new money if you are topping up.'**
  String get loansAdjustHelper;

  /// No description provided for @loansAdjustNewLoan.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get loansAdjustNewLoan;

  /// No description provided for @loansAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust loan'**
  String get loansAdjustTitle;

  /// No description provided for @loansAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get loansAdjusted;

  /// No description provided for @loansAdjustedFromBanner.
  ///
  /// In en, this message translates to:
  /// **'This loan replaced an earlier loan (adjustment).'**
  String get loansAdjustedFromBanner;

  /// No description provided for @loansAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loansAmount;

  /// No description provided for @loansAmountPaidToClose.
  ///
  /// In en, this message translates to:
  /// **'Amount paid to close (optional)'**
  String get loansAmountPaidToClose;

  /// No description provided for @loansAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get loansAmountPositive;

  /// No description provided for @loansArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get loansArchived;

  /// No description provided for @loansBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String loansBalanceAfter(String amount);

  /// No description provided for @loansBannerAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted on {date}: replaced by a new loan'**
  String loansBannerAdjusted(String date);

  /// No description provided for @loansBannerEarly.
  ///
  /// In en, this message translates to:
  /// **'Closed early on {date}'**
  String loansBannerEarly(String date);

  /// No description provided for @loansBannerPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid to close: {amount}'**
  String loansBannerPaid(String amount);

  /// No description provided for @loansBannerRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks: {remarks}'**
  String loansBannerRemarks(String remarks);

  /// No description provided for @loansCloseEarly.
  ///
  /// In en, this message translates to:
  /// **'Close early'**
  String get loansCloseEarly;

  /// No description provided for @loansCloseEarlyNote.
  ///
  /// In en, this message translates to:
  /// **'The rest of the schedule is waived and the loan becomes history. An amount you enter is recorded as a payment on the closing date.'**
  String get loansCloseEarlyNote;

  /// No description provided for @loansCloseEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Close loan early'**
  String get loansCloseEarlyTitle;

  /// No description provided for @loansClosedEarly.
  ///
  /// In en, this message translates to:
  /// **'Early closed'**
  String get loansClosedEarly;

  /// No description provided for @loansClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Loan fully paid'**
  String get loansClosedMessage;

  /// No description provided for @loansClosingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing date'**
  String get loansClosingDate;

  /// No description provided for @loansClosingRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get loansClosingRemarks;

  /// No description provided for @loansDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}. Pick the date you actually paid.'**
  String loansDueOn(String date);

  /// No description provided for @loansEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit loan'**
  String get loansEdit;

  /// No description provided for @loansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans yet. Tap + to add a bank loan.'**
  String get loansEmpty;

  /// No description provided for @loansFirstDueDate.
  ///
  /// In en, this message translates to:
  /// **'First installment date'**
  String get loansFirstDueDate;

  /// No description provided for @loansFreqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get loansFreqMonthly;

  /// No description provided for @loansFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get loansFreqWeekly;

  /// No description provided for @loansFreqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get loansFreqYearly;

  /// No description provided for @loansFrequency.
  ///
  /// In en, this message translates to:
  /// **'Repayment frequency'**
  String get loansFrequency;

  /// No description provided for @loansInstDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get loansInstDue;

  /// No description provided for @loansInstOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loansInstOverdue;

  /// No description provided for @loansInstPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get loansInstPaid;

  /// No description provided for @loansInstPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get loansInstPartial;

  /// No description provided for @loansInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment per period'**
  String get loansInstallment;

  /// No description provided for @loansInstallmentHelper.
  ///
  /// In en, this message translates to:
  /// **'Calculated: {amount}. Leave empty to use it, or type the figure from your bank.'**
  String loansInstallmentHelper(String amount);

  /// No description provided for @loansInstallmentNo.
  ///
  /// In en, this message translates to:
  /// **'Installment {no}'**
  String loansInstallmentNo(int no);

  /// No description provided for @loansInterestMethod.
  ///
  /// In en, this message translates to:
  /// **'Interest method'**
  String get loansInterestMethod;

  /// No description provided for @loansInterestPart.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get loansInterestPart;

  /// No description provided for @loansInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Annual interest rate (%)'**
  String get loansInterestRate;

  /// No description provided for @loansInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get loansInvalidAmount;

  /// No description provided for @loansInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate between 0 and 100'**
  String get loansInvalidRate;

  /// No description provided for @loansInvalidTenure.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 1200 installments'**
  String get loansInvalidTenure;

  /// No description provided for @loansLender.
  ///
  /// In en, this message translates to:
  /// **'Bank / lender name'**
  String get loansLender;

  /// No description provided for @loansLenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the bank or lender name'**
  String get loansLenderRequired;

  /// No description provided for @loansListTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansListTitle;

  /// No description provided for @loansMarkInstallmentPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark installment {no} as paid'**
  String loansMarkInstallmentPaid(int no);

  /// No description provided for @loansMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get loansMarkPaid;

  /// No description provided for @loansMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum is {max}'**
  String loansMaxAmount(String max);

  /// No description provided for @loansMethodFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat rate'**
  String get loansMethodFlat;

  /// No description provided for @loansMethodReducing.
  ///
  /// In en, this message translates to:
  /// **'Reducing balance'**
  String get loansMethodReducing;

  /// No description provided for @loansMonthlyCommitment.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get loansMonthlyCommitment;

  /// No description provided for @loansNextDueRow.
  ///
  /// In en, this message translates to:
  /// **'Next due {date} • {amount}'**
  String loansNextDueRow(String date, String amount);

  /// No description provided for @loansNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get loansNoPayments;

  /// No description provided for @loansNotFound.
  ///
  /// In en, this message translates to:
  /// **'Loan not found.'**
  String get loansNotFound;

  /// No description provided for @loansNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get loansNote;

  /// No description provided for @loansOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loansOverdue;

  /// No description provided for @loansOverdueSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue installments • {amount}'**
  String loansOverdueSummary(int count, String amount);

  /// No description provided for @loansPaidOfAmount.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid'**
  String loansPaidOfAmount(String paid, String total);

  /// No description provided for @loansPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String loansPaidOn(String date);

  /// No description provided for @loansPaidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get loansPaidSoFar;

  /// No description provided for @loansPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get loansPaymentDate;

  /// No description provided for @loansPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get loansPayments;

  /// No description provided for @loansPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String loansPerMonth(String amount);

  /// No description provided for @loansPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{amount} / week'**
  String loansPerWeek(String amount);

  /// No description provided for @loansPerYear.
  ///
  /// In en, this message translates to:
  /// **'{amount} / year'**
  String loansPerYear(String amount);

  /// No description provided for @loansPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Loan amount (principal)'**
  String get loansPrincipal;

  /// No description provided for @loansPrincipalPart.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get loansPrincipalPart;

  /// No description provided for @loansProcessingFee.
  ///
  /// In en, this message translates to:
  /// **'Processing fee (optional)'**
  String get loansProcessingFee;

  /// No description provided for @loansProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% repaid'**
  String loansProgressPercent(int percent);

  /// No description provided for @loansRatePerYear.
  ///
  /// In en, this message translates to:
  /// **'{rate}% per year'**
  String loansRatePerYear(String rate);

  /// No description provided for @loansRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get loansRecordPayment;

  /// No description provided for @loansReferenceNo.
  ///
  /// In en, this message translates to:
  /// **'Loan account / reference no. (optional)'**
  String get loansReferenceNo;

  /// No description provided for @loansRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get loansRemaining;

  /// No description provided for @loansRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String loansRemainingAmount(String amount);

  /// No description provided for @loansRemainingInstallments.
  ///
  /// In en, this message translates to:
  /// **'Remaining installments'**
  String get loansRemainingInstallments;

  /// No description provided for @loansRemainingInterest.
  ///
  /// In en, this message translates to:
  /// **'Remaining interest'**
  String get loansRemainingInterest;

  /// No description provided for @loansRemainingPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Remaining principal'**
  String get loansRemainingPrincipal;

  /// No description provided for @loansSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get loansSchedule;

  /// No description provided for @loansShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived loans'**
  String get loansShowArchived;

  /// No description provided for @loansStartDate.
  ///
  /// In en, this message translates to:
  /// **'Disbursement date'**
  String get loansStartDate;

  /// No description provided for @loansStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get loansStatusActive;

  /// No description provided for @loansStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get loansStatusClosed;

  /// No description provided for @loansStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loansStatusOverdue;

  /// No description provided for @loansTenure.
  ///
  /// In en, this message translates to:
  /// **'Number of installments'**
  String get loansTenure;

  /// No description provided for @loansTenureApprox.
  ///
  /// In en, this message translates to:
  /// **'≈ {years} years {months} months'**
  String loansTenureApprox(int years, int months);

  /// No description provided for @loansTenureValue.
  ///
  /// In en, this message translates to:
  /// **'{count} installments ({frequency})'**
  String loansTenureValue(int count, String frequency);

  /// No description provided for @loansTermsLocked.
  ///
  /// In en, this message translates to:
  /// **'Payments are recorded. You can still change the interest rate and installment (for a rate revision); other terms are locked. Void the payments to change them.'**
  String get loansTermsLocked;

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loansTitle;

  /// No description provided for @loansTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost (with fee)'**
  String get loansTotalCost;

  /// No description provided for @loansTotalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get loansTotalInterest;

  /// No description provided for @loansTotalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get loansTotalPayable;

  /// No description provided for @loansTotalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get loansTotalRemaining;

  /// No description provided for @loansType.
  ///
  /// In en, this message translates to:
  /// **'Loan type'**
  String get loansType;

  /// No description provided for @loansTypeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business loan'**
  String get loansTypeBusiness;

  /// No description provided for @loansTypeEducation.
  ///
  /// In en, this message translates to:
  /// **'Education loan'**
  String get loansTypeEducation;

  /// No description provided for @loansTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home loan'**
  String get loansTypeHome;

  /// No description provided for @loansTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other loan'**
  String get loansTypeOther;

  /// No description provided for @loansTypePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal loan'**
  String get loansTypePersonal;

  /// No description provided for @loansTypeVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle loan'**
  String get loansTypeVehicle;

  /// No description provided for @loansUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get loansUnarchive;

  /// No description provided for @loansViewPrevious.
  ///
  /// In en, this message translates to:
  /// **'View the previous loan'**
  String get loansViewPrevious;

  /// No description provided for @loansViewReplacement.
  ///
  /// In en, this message translates to:
  /// **'View the new loan'**
  String get loansViewReplacement;

  /// No description provided for @loansVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get loansVoid;

  /// No description provided for @loansVoidMessage.
  ///
  /// In en, this message translates to:
  /// **'Void the payment of {amount}? The remaining balance will be recalculated.'**
  String loansVoidMessage(String amount);

  /// No description provided for @loansVoidPayment.
  ///
  /// In en, this message translates to:
  /// **'Void payment'**
  String get loansVoidPayment;

  /// No description provided for @loansVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get loansVoided;

  /// No description provided for @notificationsBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get notificationsBudgetAlerts;

  /// No description provided for @notificationsBudgetAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warn me at 80% and when I go over a budget'**
  String get notificationsBudgetAlertsSubtitle;

  /// No description provided for @notificationsBudgetSound.
  ///
  /// In en, this message translates to:
  /// **'Budget alert sound'**
  String get notificationsBudgetSound;

  /// No description provided for @notificationsBudgetWarningBody.
  ///
  /// In en, this message translates to:
  /// **'You have used 80% of your budget ({spent} of {budget}).'**
  String notificationsBudgetWarningBody(String spent, String budget);

  /// No description provided for @notificationsBudgetWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget warning: {label}'**
  String notificationsBudgetWarningTitle(String label);

  /// No description provided for @notificationsCardName.
  ///
  /// In en, this message translates to:
  /// **'{card} card bill'**
  String notificationsCardName(String card);

  /// No description provided for @notificationsCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get notificationsCategoryFallback;

  /// No description provided for @notificationsCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Money to collect'**
  String get notificationsCollectTitle;

  /// No description provided for @notificationsDaysAfter.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day after} other{{days} days after}}'**
  String notificationsDaysAfter(int days);

  /// No description provided for @notificationsDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day before} other{{days} days before}}'**
  String notificationsDaysBefore(int days);

  /// No description provided for @notificationsDebtBorrowedName.
  ///
  /// In en, this message translates to:
  /// **'Debt to {person}'**
  String notificationsDebtBorrowedName(String person);

  /// No description provided for @notificationsDebtDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt payment due'**
  String get notificationsDebtDueTitle;

  /// No description provided for @notificationsDebtLentName.
  ///
  /// In en, this message translates to:
  /// **'{person} (to collect)'**
  String notificationsDebtLentName(String person);

  /// No description provided for @notificationsDueInDays.
  ///
  /// In en, this message translates to:
  /// **'{title} ({amount}) is due in {days} days ({date}).'**
  String notificationsDueInDays(
    String title,
    String amount,
    int days,
    String date,
  );

  /// No description provided for @notificationsDueToday.
  ///
  /// In en, this message translates to:
  /// **'{title} ({amount}) is due today.'**
  String notificationsDueToday(String title, String amount);

  /// No description provided for @notificationsDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{title} ({amount}) is due tomorrow.'**
  String notificationsDueTomorrow(String title, String amount);

  /// No description provided for @notificationsExpireReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind once after it expires'**
  String get notificationsExpireReminder;

  /// No description provided for @notificationsExpireReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One reminder if it is still unpaid after the date'**
  String get notificationsExpireReminderSubtitle;

  /// No description provided for @notificationsFdrBodyToday.
  ///
  /// In en, this message translates to:
  /// **'{scheme} {number} of {bank} matures today. Principal {amount}.'**
  String notificationsFdrBodyToday(
    String scheme,
    String number,
    String bank,
    String amount,
  );

  /// No description provided for @notificationsFdrBodyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{scheme} {number} of {bank} matures tomorrow. Principal {amount}.'**
  String notificationsFdrBodyTomorrow(
    String scheme,
    String number,
    String bank,
    String amount,
  );

  /// No description provided for @notificationsFdrBodyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'{scheme} {number} of {bank} matures in {days} days ({date}). Principal {amount}.'**
  String notificationsFdrBodyUpcoming(
    String scheme,
    String number,
    String bank,
    int days,
    String date,
    String amount,
  );

  /// No description provided for @notificationsFdrTitle.
  ///
  /// In en, this message translates to:
  /// **'{scheme} maturing'**
  String notificationsFdrTitle(String scheme);

  /// No description provided for @notificationsFiresAt.
  ///
  /// In en, this message translates to:
  /// **'Notifies on {when}'**
  String notificationsFiresAt(String when);

  /// No description provided for @notificationsFiresAtOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off ({when})'**
  String notificationsFiresAtOff(String when);

  /// No description provided for @notificationsItemExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'{name} ({amount}) was due on {date} and is still unpaid.'**
  String notificationsItemExpiredBody(String name, String amount, String date);

  /// No description provided for @notificationsItemExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {name}'**
  String notificationsItemExpiredTitle(String name);

  /// No description provided for @notificationsItemTodayBody.
  ///
  /// In en, this message translates to:
  /// **'{name} ({amount}) is due today.'**
  String notificationsItemTodayBody(String name, String amount);

  /// No description provided for @notificationsItemTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Due today: {name}'**
  String notificationsItemTodayTitle(String name);

  /// No description provided for @notificationsItemUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'{name} ({amount}) is due in {days, plural, =1{1 day} other{{days} days}} ({date}). Get ready.'**
  String notificationsItemUpcomingBody(
    String name,
    String amount,
    int days,
    String date,
  );

  /// No description provided for @notificationsItemUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming: {name}'**
  String notificationsItemUpcomingTitle(String name);

  /// No description provided for @notificationsLoanName.
  ///
  /// In en, this message translates to:
  /// **'{lender} installment #{no}'**
  String notificationsLoanName(String lender, int no);

  /// No description provided for @notificationsMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get notificationsMonthlyBudget;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationsOff;

  /// No description provided for @notificationsOverBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'You have spent {spent} of {budget} this month and are over budget.'**
  String notificationsOverBudgetBody(String spent, String budget);

  /// No description provided for @notificationsOverBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Over budget: {label}'**
  String notificationsOverBudgetTitle(String label);

  /// No description provided for @notificationsOwesYouToday.
  ///
  /// In en, this message translates to:
  /// **'{person} owes you {amount}, due today.'**
  String notificationsOwesYouToday(String person, String amount);

  /// No description provided for @notificationsOwesYouTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{person} owes you {amount}, due tomorrow.'**
  String notificationsOwesYouTomorrow(String person, String amount);

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. Allow notifications for MyBudget in the system settings, then turn this on again.'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsPhaseExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get notificationsPhaseExpired;

  /// No description provided for @notificationsPhaseToday.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get notificationsPhaseToday;

  /// No description provided for @notificationsPhaseUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get notificationsPhaseUpcoming;

  /// No description provided for @notificationsPickDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get notificationsPickDays;

  /// No description provided for @notificationsReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get notificationsReminderSound;

  /// No description provided for @notificationsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notificationsReminderTime;

  /// No description provided for @notificationsReminders.
  ///
  /// In en, this message translates to:
  /// **'Bill & debt reminders'**
  String get notificationsReminders;

  /// No description provided for @notificationsRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me before recurring bills and debt due dates'**
  String get notificationsRemindersSubtitle;

  /// No description provided for @notificationsScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders. Add a due date to a loan, card bill, debt or recurring task.'**
  String get notificationsScheduleEmpty;

  /// No description provided for @notificationsScheduleOffBanner.
  ///
  /// In en, this message translates to:
  /// **'Reminders are switched off, so none of these will be delivered. Turn them on in Notification settings.'**
  String get notificationsScheduleOffBanner;

  /// No description provided for @notificationsSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get notificationsSendTest;

  /// No description provided for @notificationsSoundCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom sound'**
  String get notificationsSoundCustom;

  /// No description provided for @notificationsSoundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notificationsSoundDefault;

  /// No description provided for @notificationsSoundSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get notificationsSoundSilent;

  /// No description provided for @notificationsTestBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are working.'**
  String get notificationsTestBody;

  /// No description provided for @notificationsTestDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied - cannot send'**
  String get notificationsTestDenied;

  /// No description provided for @notificationsTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get notificationsTestSent;

  /// No description provided for @notificationsTestTitle.
  ///
  /// In en, this message translates to:
  /// **'MyBudget test notification'**
  String get notificationsTestTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsTodayReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind on the due day'**
  String get notificationsTodayReminder;

  /// No description provided for @notificationsTodayReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A notification on the day an installment, bill or task is due'**
  String get notificationsTodayReminderSubtitle;

  /// No description provided for @notificationsUpcomingReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind before the due date'**
  String get notificationsUpcomingReminder;

  /// No description provided for @notificationsUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming: {title}'**
  String notificationsUpcomingTitle(String title);

  /// No description provided for @notificationsViewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Notification schedule'**
  String get notificationsViewSchedule;

  /// No description provided for @notificationsViewScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See when each reminder will fire and switch single ones off'**
  String get notificationsViewScheduleSubtitle;

  /// No description provided for @notificationsYouOweToday.
  ///
  /// In en, this message translates to:
  /// **'You owe {person} {amount}, due today.'**
  String notificationsYouOweToday(String person, String amount);

  /// No description provided for @notificationsYouOweTomorrow.
  ///
  /// In en, this message translates to:
  /// **'You owe {person} {amount}, due tomorrow.'**
  String notificationsYouOweTomorrow(String person, String amount);

  /// No description provided for @preferencesLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get preferencesLanguage;

  /// No description provided for @preferencesLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get preferencesLanguageSystem;

  /// No description provided for @preferencesTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get preferencesTheme;

  /// No description provided for @preferencesThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get preferencesThemeDark;

  /// No description provided for @preferencesThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get preferencesThemeLight;

  /// No description provided for @preferencesThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get preferencesThemeSystem;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @profilesCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profilesCurrencyLabel;

  /// No description provided for @profilesDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get profilesDeactivate;

  /// No description provided for @profilesDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from selection. No data is deleted and you can reactivate it anytime.'**
  String profilesDeactivateMessage(String name);

  /// No description provided for @profilesDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate profile?'**
  String get profilesDeactivateTitle;

  /// No description provided for @profilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet.\nCreate one to get started.'**
  String get profilesEmpty;

  /// No description provided for @profilesInactiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{currency} - Inactive'**
  String profilesInactiveSubtitle(String currency);

  /// No description provided for @profilesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profilesNameLabel;

  /// No description provided for @profilesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profilesNameRequired;

  /// No description provided for @profilesNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get profilesNew;

  /// No description provided for @profilesReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get profilesReactivate;

  /// No description provided for @profilesReactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be available again.'**
  String profilesReactivateMessage(String name);

  /// No description provided for @profilesReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate profile?'**
  String get profilesReactivateTitle;

  /// No description provided for @profilesSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select profile'**
  String get profilesSelectTitle;

  /// No description provided for @recurringAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add recurring rule'**
  String get recurringAddTooltip;

  /// No description provided for @recurringClearEndDate.
  ///
  /// In en, this message translates to:
  /// **'Clear end date'**
  String get recurringClearEndDate;

  /// No description provided for @recurringCreateRule.
  ///
  /// In en, this message translates to:
  /// **'Create rule'**
  String get recurringCreateRule;

  /// No description provided for @recurringDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} day before} other{{count} days before}}'**
  String recurringDaysBefore(int count);

  /// No description provided for @recurringDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a different account'**
  String get recurringDifferentAccount;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring rules yet. Tap + to add one.'**
  String get recurringEmpty;

  /// No description provided for @recurringEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get recurringEnterAmount;

  /// No description provided for @recurringEnterIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Enter an income source'**
  String get recurringEnterIncomeSource;

  /// No description provided for @recurringEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get recurringEnterTitle;

  /// No description provided for @recurringEveryN.
  ///
  /// In en, this message translates to:
  /// **'{frequency} (every {count})'**
  String recurringEveryN(String frequency, int count);

  /// No description provided for @recurringFieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get recurringFieldAccount;

  /// No description provided for @recurringFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurringFieldAmount;

  /// No description provided for @recurringFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recurringFieldCategory;

  /// No description provided for @recurringFieldCostItem.
  ///
  /// In en, this message translates to:
  /// **'Cost item (optional)'**
  String get recurringFieldCostItem;

  /// No description provided for @recurringFieldEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get recurringFieldEndDate;

  /// No description provided for @recurringFieldEveryN.
  ///
  /// In en, this message translates to:
  /// **'Every N'**
  String get recurringFieldEveryN;

  /// No description provided for @recurringFieldFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringFieldFrequency;

  /// No description provided for @recurringFieldFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get recurringFieldFromAccount;

  /// No description provided for @recurringFieldIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get recurringFieldIncomeSource;

  /// No description provided for @recurringFieldRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks (optional)'**
  String get recurringFieldRemarks;

  /// No description provided for @recurringFieldReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get recurringFieldReminder;

  /// No description provided for @recurringFieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get recurringFieldStartDate;

  /// No description provided for @recurringFieldSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-category (optional)'**
  String get recurringFieldSubCategory;

  /// No description provided for @recurringFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recurringFieldTitle;

  /// No description provided for @recurringFieldToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get recurringFieldToAccount;

  /// No description provided for @recurringFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring rule'**
  String get recurringFormEdit;

  /// No description provided for @recurringFormNew.
  ///
  /// In en, this message translates to:
  /// **'New recurring rule'**
  String get recurringFormNew;

  /// No description provided for @recurringFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurringFreqDaily;

  /// No description provided for @recurringFreqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringFreqMonthly;

  /// No description provided for @recurringFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringFreqWeekly;

  /// No description provided for @recurringFreqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringFreqYearly;

  /// No description provided for @recurringMin1.
  ///
  /// In en, this message translates to:
  /// **'Min 1'**
  String get recurringMin1;

  /// No description provided for @recurringNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end'**
  String get recurringNoEnd;

  /// No description provided for @recurringNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile to manage recurring transactions.'**
  String get recurringNoProfile;

  /// No description provided for @recurringNoReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get recurringNoReminder;

  /// No description provided for @recurringOnTheDay.
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get recurringOnTheDay;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringReminderDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (notification settings)'**
  String get recurringReminderDefault;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get recurringSaveChanges;

  /// No description provided for @recurringSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get recurringSelectAccount;

  /// No description provided for @recurringSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get recurringSelectCategory;

  /// No description provided for @recurringSelectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select a destination'**
  String get recurringSelectDestination;

  /// No description provided for @recurringStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get recurringStatusEnded;

  /// No description provided for @recurringStatusNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringStatusNext(String date);

  /// No description provided for @recurringStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringStatusPaused;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTitle;

  /// No description provided for @recurringTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get recurringTypeExpense;

  /// No description provided for @recurringTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get recurringTypeIncome;

  /// No description provided for @recurringTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get recurringTypeTransfer;

  /// No description provided for @reportsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get reportsAccount;

  /// No description provided for @reportsAccountFlow.
  ///
  /// In en, this message translates to:
  /// **'{name}\n+{income}  -{expense}  in {transferIn}  out {transferOut}'**
  String reportsAccountFlow(
    String name,
    String income,
    String expense,
    String transferIn,
    String transferOut,
  );

  /// No description provided for @reportsAccountMovements.
  ///
  /// In en, this message translates to:
  /// **'Account movements'**
  String get reportsAccountMovements;

  /// No description provided for @reportsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsAmount;

  /// No description provided for @reportsAvgMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Avg monthly expense'**
  String get reportsAvgMonthlyExpense;

  /// No description provided for @reportsBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get reportsBudget;

  /// No description provided for @reportsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsCategory;

  /// No description provided for @reportsCategoryComparison.
  ///
  /// In en, this message translates to:
  /// **'Category comparison'**
  String get reportsCategoryComparison;

  /// No description provided for @reportsCategoryWiseExpense.
  ///
  /// In en, this message translates to:
  /// **'Category-wise expense'**
  String get reportsCategoryWiseExpense;

  /// No description provided for @reportsClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get reportsClosing;

  /// No description provided for @reportsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get reportsCustomRange;

  /// No description provided for @reportsCustomRangeReport.
  ///
  /// In en, this message translates to:
  /// **'Custom range report'**
  String get reportsCustomRangeReport;

  /// No description provided for @reportsCustomRangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick any start and end date'**
  String get reportsCustomRangeSubtitle;

  /// No description provided for @reportsDailyExpenditure.
  ///
  /// In en, this message translates to:
  /// **'Daily expenditure'**
  String get reportsDailyExpenditure;

  /// No description provided for @reportsExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get reportsExpense;

  /// No description provided for @reportsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportsExportCsv;

  /// No description provided for @reportsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String reportsExportFailed(String error);

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsHighestMonth.
  ///
  /// In en, this message translates to:
  /// **'Highest month'**
  String get reportsHighestMonth;

  /// No description provided for @reportsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsIncome;

  /// No description provided for @reportsIncomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs expense'**
  String get reportsIncomeVsExpense;

  /// No description provided for @reportsItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get reportsItem;

  /// No description provided for @reportsItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get reportsItems;

  /// No description provided for @reportsLowestMonth.
  ///
  /// In en, this message translates to:
  /// **'Lowest month'**
  String get reportsLowestMonth;

  /// No description provided for @reportsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get reportsMonth;

  /// No description provided for @reportsMonth01Full.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get reportsMonth01Full;

  /// No description provided for @reportsMonth01Short.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get reportsMonth01Short;

  /// No description provided for @reportsMonth02Full.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get reportsMonth02Full;

  /// No description provided for @reportsMonth02Short.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get reportsMonth02Short;

  /// No description provided for @reportsMonth03Full.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get reportsMonth03Full;

  /// No description provided for @reportsMonth03Short.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get reportsMonth03Short;

  /// No description provided for @reportsMonth04Full.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get reportsMonth04Full;

  /// No description provided for @reportsMonth04Short.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get reportsMonth04Short;

  /// No description provided for @reportsMonth05Full.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get reportsMonth05Full;

  /// No description provided for @reportsMonth05Short.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get reportsMonth05Short;

  /// No description provided for @reportsMonth06Full.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get reportsMonth06Full;

  /// No description provided for @reportsMonth06Short.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get reportsMonth06Short;

  /// No description provided for @reportsMonth07Full.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get reportsMonth07Full;

  /// No description provided for @reportsMonth07Short.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get reportsMonth07Short;

  /// No description provided for @reportsMonth08Full.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get reportsMonth08Full;

  /// No description provided for @reportsMonth08Short.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get reportsMonth08Short;

  /// No description provided for @reportsMonth09Full.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get reportsMonth09Full;

  /// No description provided for @reportsMonth09Short.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get reportsMonth09Short;

  /// No description provided for @reportsMonth10Full.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get reportsMonth10Full;

  /// No description provided for @reportsMonth10Short.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get reportsMonth10Short;

  /// No description provided for @reportsMonth11Full.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get reportsMonth11Full;

  /// No description provided for @reportsMonth11Short.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get reportsMonth11Short;

  /// No description provided for @reportsMonth12Full.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get reportsMonth12Full;

  /// No description provided for @reportsMonth12Short.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get reportsMonth12Short;

  /// No description provided for @reportsMonthlyComparison.
  ///
  /// In en, this message translates to:
  /// **'Monthly comparison'**
  String get reportsMonthlyComparison;

  /// No description provided for @reportsMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get reportsMonthlyReport;

  /// No description provided for @reportsMonthlyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income, expense, budget, categories, daily spending'**
  String get reportsMonthlyReportSubtitle;

  /// No description provided for @reportsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsNet;

  /// No description provided for @reportsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reportsNext;

  /// No description provided for @reportsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get reportsNoData;

  /// No description provided for @reportsNoDataMonth.
  ///
  /// In en, this message translates to:
  /// **'No data for this month.'**
  String get reportsNoDataMonth;

  /// No description provided for @reportsNoDataYear.
  ///
  /// In en, this message translates to:
  /// **'No data for this year.'**
  String get reportsNoDataYear;

  /// No description provided for @reportsNoExpensesMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month.'**
  String get reportsNoExpensesMonth;

  /// No description provided for @reportsNoExpensesRange.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this range.'**
  String get reportsNoExpensesRange;

  /// No description provided for @reportsNoTransactionsRange.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this range.'**
  String get reportsNoTransactionsRange;

  /// No description provided for @reportsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get reportsNotSet;

  /// No description provided for @reportsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get reportsOpening;

  /// No description provided for @reportsOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get reportsOverBudget;

  /// No description provided for @reportsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get reportsPrevious;

  /// No description provided for @reportsPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get reportsPrint;

  /// No description provided for @reportsRangeFromTo.
  ///
  /// In en, this message translates to:
  /// **'{from}  to  {to}'**
  String reportsRangeFromTo(String from, String to);

  /// No description provided for @reportsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get reportsRemaining;

  /// No description provided for @reportsSelectDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Select any day in the month'**
  String get reportsSelectDayHelp;

  /// No description provided for @reportsSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get reportsSelectYear;

  /// No description provided for @reportsSubCategories.
  ///
  /// In en, this message translates to:
  /// **'Sub-categories'**
  String get reportsSubCategories;

  /// No description provided for @reportsSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-category'**
  String get reportsSubCategory;

  /// No description provided for @reportsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsTotal;

  /// No description provided for @reportsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsTransactions;

  /// No description provided for @reportsTxnComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get reportsTxnComment;

  /// No description provided for @reportsTxnTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportsTxnTitle;

  /// No description provided for @reportsUtilization.
  ///
  /// In en, this message translates to:
  /// **'Utilization'**
  String get reportsUtilization;

  /// No description provided for @reportsYearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly report'**
  String get reportsYearlyReport;

  /// No description provided for @reportsYearlyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All 12 months, comparison, highest and lowest month'**
  String get reportsYearlyReportSubtitle;

  /// No description provided for @searchChipAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get searchChipAccount;

  /// No description provided for @searchChipCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get searchChipCategory;

  /// No description provided for @searchChipFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String searchChipFrom(String date);

  /// No description provided for @searchChipTag.
  ///
  /// In en, this message translates to:
  /// **'#{name}'**
  String searchChipTag(String name);

  /// No description provided for @searchChipTo.
  ///
  /// In en, this message translates to:
  /// **'To {date}'**
  String searchChipTo(String date);

  /// No description provided for @searchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchClearAll;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @searchClearText.
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get searchClearText;

  /// No description provided for @searchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, remarks, category, account, tag…'**
  String get searchEmptyHint;

  /// No description provided for @searchErrDateOrder.
  ///
  /// In en, this message translates to:
  /// **'From date is after to date'**
  String get searchErrDateOrder;

  /// No description provided for @searchErrInvalidMax.
  ///
  /// In en, this message translates to:
  /// **'Invalid maximum amount'**
  String get searchErrInvalidMax;

  /// No description provided for @searchErrInvalidMin.
  ///
  /// In en, this message translates to:
  /// **'Invalid minimum amount'**
  String get searchErrInvalidMin;

  /// No description provided for @searchErrMinGreater.
  ///
  /// In en, this message translates to:
  /// **'Minimum is greater than maximum'**
  String get searchErrMinGreater;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFilters;

  /// No description provided for @searchFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get searchFrom;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get searchHint;

  /// No description provided for @searchMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get searchMax;

  /// No description provided for @searchMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get searchMin;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions.'**
  String get searchNoResults;

  /// No description provided for @searchNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'None available'**
  String get searchNoneAvailable;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get searchRemove;

  /// No description provided for @searchReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get searchReset;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get searchResults;

  /// No description provided for @searchSectionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get searchSectionAccounts;

  /// No description provided for @searchSectionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get searchSectionAmount;

  /// No description provided for @searchSectionCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get searchSectionCategories;

  /// No description provided for @searchSectionDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get searchSectionDateRange;

  /// No description provided for @searchSectionSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchSectionSortBy;

  /// No description provided for @searchSectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchSectionTags;

  /// No description provided for @searchSectionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get searchSectionType;

  /// No description provided for @searchSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get searchSortHighest;

  /// No description provided for @searchSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get searchSortLowest;

  /// No description provided for @searchSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get searchSortNewest;

  /// No description provided for @searchSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get searchSortOldest;

  /// No description provided for @searchTagFallback.
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get searchTagFallback;

  /// No description provided for @searchTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get searchTo;

  /// No description provided for @searchTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get searchTypeExpense;

  /// No description provided for @searchTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get searchTypeIncome;

  /// No description provided for @searchTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get searchTypeTransfer;

  /// No description provided for @securityAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get securityAppLock;

  /// No description provided for @securityAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN to open MyBudget'**
  String get securityAppLockSubtitle;

  /// No description provided for @securityAutoLock.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get securityAutoLock;

  /// No description provided for @securityAutoLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock after the app is in the background'**
  String get securityAutoLockSubtitle;

  /// No description provided for @securityBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get securityBiometric;

  /// No description provided for @securityBiometricConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm to enable biometric unlock'**
  String get securityBiometricConfirm;

  /// No description provided for @securityBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock MyBudget'**
  String get securityBiometricUnlock;

  /// No description provided for @securityChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePin;

  /// No description provided for @securityConfirmNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get securityConfirmNewPinLabel;

  /// No description provided for @securityConfirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get securityConfirmPinLabel;

  /// No description provided for @securityCurrentPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get securityCurrentPinLabel;

  /// No description provided for @securityDelay1m.
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get securityDelay1m;

  /// No description provided for @securityDelay30s.
  ///
  /// In en, this message translates to:
  /// **'After 30 seconds'**
  String get securityDelay30s;

  /// No description provided for @securityDelay5m.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get securityDelay5m;

  /// No description provided for @securityDelayImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get securityDelayImmediately;

  /// No description provided for @securityEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to unlock'**
  String get securityEnterPin;

  /// No description provided for @securityForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get securityForgotPin;

  /// No description provided for @securityIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN.'**
  String get securityIncorrectPin;

  /// No description provided for @securityIncorrectPinShort.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get securityIncorrectPinShort;

  /// No description provided for @securityLockout.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String securityLockout(int seconds);

  /// No description provided for @securityLockoutShort.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s'**
  String securityLockoutShort(int seconds);

  /// No description provided for @securityNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4-6 digits)'**
  String get securityNewPinLabel;

  /// No description provided for @securityNewPinsMismatch.
  ///
  /// In en, this message translates to:
  /// **'New PINs do not match.'**
  String get securityNewPinsMismatch;

  /// No description provided for @securityNewRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'New recovery code'**
  String get securityNewRecoveryCode;

  /// No description provided for @securityNewRecoveryCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replaces your old code'**
  String get securityNewRecoveryCodeSubtitle;

  /// No description provided for @securityNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'App lock is not enabled.'**
  String get securityNotEnabled;

  /// No description provided for @securityPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get securityPinChanged;

  /// No description provided for @securityPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 to 6 digits.'**
  String get securityPinInvalid;

  /// No description provided for @securityPinsMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match.'**
  String get securityPinsMismatch;

  /// No description provided for @securityRecoverAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get securityRecoverAction;

  /// No description provided for @securityRecoverBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery code. App lock will be turned off, and you can set a new PIN in Settings > Security.'**
  String get securityRecoverBody;

  /// No description provided for @securityRecoverCancel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get securityRecoverCancel;

  /// No description provided for @securityRecoverInvalid.
  ///
  /// In en, this message translates to:
  /// **'That recovery code is not correct.'**
  String get securityRecoverInvalid;

  /// No description provided for @securityRecoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get securityRecoverLabel;

  /// No description provided for @securityRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset with recovery code'**
  String get securityRecoverTitle;

  /// No description provided for @securityRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN, this code is the only way back in. Write it down and keep it somewhere safe. It is shown only once.'**
  String get securityRecoveryBody;

  /// No description provided for @securityRecoveryCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get securityRecoveryCopied;

  /// No description provided for @securityRecoveryCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get securityRecoveryCopy;

  /// No description provided for @securityRecoverySaved.
  ///
  /// In en, this message translates to:
  /// **'I have saved it'**
  String get securityRecoverySaved;

  /// No description provided for @securityRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recovery code'**
  String get securityRecoveryTitle;

  /// No description provided for @securitySetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get securitySetPin;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securityTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock'**
  String get securityTurnOff;

  /// No description provided for @setupAllDone.
  ///
  /// In en, this message translates to:
  /// **'All set! You are ready to use MyBudget.'**
  String get setupAllDone;

  /// No description provided for @setupCardAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupCardAction;

  /// No description provided for @setupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get setupCardTitle;

  /// No description provided for @setupDismiss.
  ///
  /// In en, this message translates to:
  /// **'Hide this guide'**
  String get setupDismiss;

  /// No description provided for @setupDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupDone;

  /// No description provided for @setupGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get setupGo;

  /// No description provided for @setupOpenManual.
  ///
  /// In en, this message translates to:
  /// **'Read the user manual'**
  String get setupOpenManual;

  /// No description provided for @setupProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps done'**
  String setupProgress(int done, int total);

  /// No description provided for @setupStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get setupStepAccount;

  /// No description provided for @setupStepAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Where your money sits, such as Cash or a bank. Enter its opening balance.'**
  String get setupStepAccountBody;

  /// No description provided for @setupStepBudget.
  ///
  /// In en, this message translates to:
  /// **'Set this month\'s budget'**
  String get setupStepBudget;

  /// No description provided for @setupStepBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'How much you plan to spend this month.'**
  String get setupStepBudgetBody;

  /// No description provided for @setupStepCategory.
  ///
  /// In en, this message translates to:
  /// **'Create a category'**
  String get setupStepCategory;

  /// No description provided for @setupStepCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'For example Food or Transport. Sub-categories and items can come later.'**
  String get setupStepCategoryBody;

  /// No description provided for @setupStepTransaction.
  ///
  /// In en, this message translates to:
  /// **'Record your first transaction'**
  String get setupStepTransaction;

  /// No description provided for @setupStepTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'Add an expense or some income.'**
  String get setupStepTransactionBody;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get setupTitle;

  /// No description provided for @splitAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get splitAccount;

  /// No description provided for @splitAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get splitAddLine;

  /// No description provided for @splitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get splitAmount;

  /// No description provided for @splitBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get splitBillTitle;

  /// No description provided for @splitCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get splitCategory;

  /// No description provided for @splitCostItem.
  ///
  /// In en, this message translates to:
  /// **'Cost item (optional)'**
  String get splitCostItem;

  /// No description provided for @splitErrAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose an account.'**
  String get splitErrAccount;

  /// No description provided for @splitErrLine.
  ///
  /// In en, this message translates to:
  /// **'Every line needs a category and an amount greater than zero.'**
  String get splitErrLine;

  /// No description provided for @splitIntro.
  ///
  /// In en, this message translates to:
  /// **'Use this when one bill covers several categories, for example groceries and household items. Each line is saved as its own expense, all together or not at all.'**
  String get splitIntro;

  /// No description provided for @splitLine.
  ///
  /// In en, this message translates to:
  /// **'Line {n}'**
  String splitLine(int n);

  /// No description provided for @splitOpen.
  ///
  /// In en, this message translates to:
  /// **'Split a bill'**
  String get splitOpen;

  /// No description provided for @splitRemoveLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get splitRemoveLine;

  /// No description provided for @splitSave.
  ///
  /// In en, this message translates to:
  /// **'Save split'**
  String get splitSave;

  /// No description provided for @splitSaved.
  ///
  /// In en, this message translates to:
  /// **'{n} expenses saved'**
  String splitSaved(int n);

  /// No description provided for @splitSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-category (optional)'**
  String get splitSubCategory;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split a bill'**
  String get splitTitle;

  /// No description provided for @splitTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String splitTotal(String amount);

  /// No description provided for @subCategoriesActivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be available again.'**
  String subCategoriesActivateMessage(String name);

  /// No description provided for @subCategoriesActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate sub-category?'**
  String get subCategoriesActivateTitle;

  /// No description provided for @subCategoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add sub-category'**
  String get subCategoriesAdd;

  /// No description provided for @subCategoriesCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get subCategoriesCategoryLabel;

  /// No description provided for @subCategoriesDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be hidden from new entries. Existing data is kept.'**
  String subCategoriesDeactivateMessage(String name);

  /// No description provided for @subCategoriesDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate sub-category?'**
  String get subCategoriesDeactivateTitle;

  /// No description provided for @subCategoriesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit sub-category'**
  String get subCategoriesEdit;

  /// No description provided for @subCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sub-categories found.'**
  String get subCategoriesEmpty;

  /// No description provided for @subCategoriesInactiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} - inactive'**
  String subCategoriesInactiveSubtitle(String category);

  /// No description provided for @subCategoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load sub-categories: {error}'**
  String subCategoriesLoadError(String error);

  /// No description provided for @subCategoriesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subCategoriesNameLabel;

  /// No description provided for @subCategoriesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get subCategoriesNameRequired;

  /// No description provided for @subCategoriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search sub-categories'**
  String get subCategoriesSearchHint;

  /// No description provided for @subCategoriesSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get subCategoriesSelectCategory;

  /// No description provided for @subCategoriesSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select a profile first.'**
  String get subCategoriesSelectProfile;

  /// No description provided for @subCategoriesShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get subCategoriesShowInactive;

  /// No description provided for @subCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sub-categories'**
  String get subCategoriesTitle;

  /// No description provided for @tagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagsAdd;

  /// No description provided for @tagsArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" stays on old transactions but can no longer be added to new ones.'**
  String tagsArchiveMessage(String name);

  /// No description provided for @tagsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive tag'**
  String get tagsArchiveTitle;

  /// No description provided for @tagsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get tagsArchived;

  /// No description provided for @tagsDateRange.
  ///
  /// In en, this message translates to:
  /// **'{from}  to  {to}'**
  String tagsDateRange(String from, String to);

  /// No description provided for @tagsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagsEdit;

  /// No description provided for @tagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Tap + to create one.'**
  String get tagsEmpty;

  /// No description provided for @tagsHideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get tagsHideArchived;

  /// No description provided for @tagsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagsName;

  /// No description provided for @tagsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Tag name is required.'**
  String get tagsNameRequired;

  /// No description provided for @tagsNew.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagsNew;

  /// No description provided for @tagsNewName.
  ///
  /// In en, this message translates to:
  /// **'New tag name'**
  String get tagsNewName;

  /// No description provided for @tagsReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tagged transactions in this range.'**
  String get tagsReportEmpty;

  /// No description provided for @tagsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag report'**
  String get tagsReportTitle;

  /// No description provided for @tagsShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get tagsShowArchived;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @tagsTransactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} transaction} other{{count} transactions}}'**
  String tagsTransactionCount(int count);

  /// No description provided for @transactionsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionsAccount;

  /// No description provided for @transactionsAddExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Add exchange rates'**
  String get transactionsAddExchangeRates;

  /// No description provided for @transactionsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionsAmount;

  /// No description provided for @transactionsAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get transactionsAmountPositive;

  /// No description provided for @transactionsAuditCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get transactionsAuditCreated;

  /// No description provided for @transactionsAuditDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get transactionsAuditDeleted;

  /// No description provided for @transactionsAuditEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get transactionsAuditEdited;

  /// No description provided for @transactionsAuditRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get transactionsAuditRestored;

  /// No description provided for @transactionsCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get transactionsCalculator;

  /// No description provided for @transactionsCannotConvertSave.
  ///
  /// In en, this message translates to:
  /// **'This amount cannot be converted at the selected rate (it rounds to zero or is too large). Change the amount or rate.'**
  String get transactionsCannotConvertSave;

  /// No description provided for @transactionsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionsCategory;

  /// No description provided for @transactionsChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'amount: {from} → {to}'**
  String transactionsChangeAmount(String from, String to);

  /// No description provided for @transactionsChangeGeneric.
  ///
  /// In en, this message translates to:
  /// **'{field}: {from} → {to}'**
  String transactionsChangeGeneric(String field, String from, String to);

  /// No description provided for @transactionsChangeOriginalAmount.
  ///
  /// In en, this message translates to:
  /// **'original amount: {from} → {to}'**
  String transactionsChangeOriginalAmount(String from, String to);

  /// No description provided for @transactionsChangeOriginalCurrency.
  ///
  /// In en, this message translates to:
  /// **'original currency: {from} → {to}'**
  String transactionsChangeOriginalCurrency(String from, String to);

  /// No description provided for @transactionsChangeRate.
  ///
  /// In en, this message translates to:
  /// **'rate: {from} → {to}'**
  String transactionsChangeRate(String from, String to);

  /// No description provided for @transactionsChooseDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a different account'**
  String get transactionsChooseDifferentAccount;

  /// No description provided for @transactionsConvertFail.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be converted (rounds to zero or too large).'**
  String get transactionsConvertFail;

  /// No description provided for @transactionsConvertedLine.
  ///
  /// In en, this message translates to:
  /// **'= {amount} at 1 {code} = {rate}'**
  String transactionsConvertedLine(String amount, String code, String rate);

  /// No description provided for @transactionsCostItem.
  ///
  /// In en, this message translates to:
  /// **'Cost item'**
  String get transactionsCostItem;

  /// No description provided for @transactionsCostItemOptional.
  ///
  /// In en, this message translates to:
  /// **'Cost item (optional)'**
  String get transactionsCostItemOptional;

  /// No description provided for @transactionsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionsDate;

  /// No description provided for @transactionsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This transaction will be removed from balances, budgets and reports. You can undo this.'**
  String get transactionsDeleteMessage;

  /// No description provided for @transactionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get transactionsDeleteTitle;

  /// No description provided for @transactionsDeleteTransferMessage.
  ///
  /// In en, this message translates to:
  /// **'This transfer will be removed from both accounts. You can undo this.'**
  String get transactionsDeleteTransferMessage;

  /// No description provided for @transactionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionsDeleted;

  /// No description provided for @transactionsDeletedCannotEdit.
  ///
  /// In en, this message translates to:
  /// **'This transaction is deleted. Restore it to edit.'**
  String get transactionsDeletedCannotEdit;

  /// No description provided for @transactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transactionsDescription;

  /// No description provided for @transactionsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionsDetailTitle;

  /// No description provided for @transactionsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionsEditTitle;

  /// No description provided for @transactionsEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get transactionsEnterAmount;

  /// No description provided for @transactionsEnterIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Enter an income source'**
  String get transactionsEnterIncomeSource;

  /// No description provided for @transactionsExcludedNote.
  ///
  /// In en, this message translates to:
  /// **'It is excluded from balances, budgets and reports.'**
  String get transactionsExcludedNote;

  /// No description provided for @transactionsExtrasWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: {problems}. You can add them by editing the transaction.'**
  String transactionsExtrasWarning(String problems);

  /// No description provided for @transactionsFieldDate.
  ///
  /// In en, this message translates to:
  /// **'txnDate'**
  String get transactionsFieldDate;

  /// No description provided for @transactionsFieldIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'incomeSource'**
  String get transactionsFieldIncomeSource;

  /// No description provided for @transactionsFieldRemarks.
  ///
  /// In en, this message translates to:
  /// **'remarks'**
  String get transactionsFieldRemarks;

  /// No description provided for @transactionsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get transactionsFieldTitle;

  /// No description provided for @transactionsFieldType.
  ///
  /// In en, this message translates to:
  /// **'type'**
  String get transactionsFieldType;

  /// No description provided for @transactionsFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get transactionsFromAccount;

  /// No description provided for @transactionsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get transactionsHistory;

  /// No description provided for @transactionsHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history: {error}'**
  String transactionsHistoryLoadFailed(String error);

  /// No description provided for @transactionsInactiveSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (inactive)'**
  String transactionsInactiveSuffix(String name);

  /// No description provided for @transactionsIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get transactionsIncomeSource;

  /// No description provided for @transactionsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount, like 1250 or 1250.50 (max 2 decimals)'**
  String get transactionsInvalidAmount;

  /// No description provided for @transactionsIsDeleted.
  ///
  /// In en, this message translates to:
  /// **'This transaction is deleted'**
  String get transactionsIsDeleted;

  /// No description provided for @transactionsKeypadAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get transactionsKeypadAmountPositive;

  /// No description provided for @transactionsKeypadUseAmount.
  ///
  /// In en, this message translates to:
  /// **'Use amount'**
  String get transactionsKeypadUseAmount;

  /// No description provided for @transactionsNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.\nCreate an account in Settings > Accounts before adding transactions.'**
  String get transactionsNoAccounts;

  /// No description provided for @transactionsNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Create a category in Settings > Categories to record expenses.'**
  String get transactionsNoCategories;

  /// No description provided for @transactionsNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get transactionsNoHistory;

  /// No description provided for @transactionsNoRate.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate for {code}. Add one in exchange rates.'**
  String transactionsNoRate(String code);

  /// No description provided for @transactionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found.'**
  String get transactionsNotFound;

  /// No description provided for @transactionsOriginalLine.
  ///
  /// In en, this message translates to:
  /// **'{original} at 1 {code} = {symbol}{rate}'**
  String transactionsOriginalLine(
    String original,
    String code,
    String symbol,
    String rate,
  );

  /// No description provided for @transactionsRateLine.
  ///
  /// In en, this message translates to:
  /// **'1 {code} = {symbol}{rate}'**
  String transactionsRateLine(String code, String symbol, String rate);

  /// No description provided for @transactionsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get transactionsReceipts;

  /// No description provided for @transactionsReceiptsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'receipts could not be saved ({reason})'**
  String transactionsReceiptsSaveFailed(String reason);

  /// No description provided for @transactionsRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get transactionsRemarks;

  /// No description provided for @transactionsRemarksOptional.
  ///
  /// In en, this message translates to:
  /// **'Remarks (optional)'**
  String get transactionsRemarksOptional;

  /// No description provided for @transactionsRepeatLast.
  ///
  /// In en, this message translates to:
  /// **'Repeat last'**
  String get transactionsRepeatLast;

  /// No description provided for @transactionsRestored.
  ///
  /// In en, this message translates to:
  /// **'Transaction restored'**
  String get transactionsRestored;

  /// No description provided for @transactionsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get transactionsSaveChanges;

  /// No description provided for @transactionsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the transaction: {error}'**
  String transactionsSaveFailed(String error);

  /// No description provided for @transactionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionsSaved;

  /// No description provided for @transactionsSavedWithWarning.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved. {warning}'**
  String transactionsSavedWithWarning(String warning);

  /// No description provided for @transactionsSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get transactionsSelectAccount;

  /// No description provided for @transactionsSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get transactionsSelectCategory;

  /// No description provided for @transactionsSelectProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a profile first.'**
  String get transactionsSelectProfileFirst;

  /// No description provided for @transactionsSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get transactionsSource;

  /// No description provided for @transactionsSourceBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get transactionsSourceBusiness;

  /// No description provided for @transactionsSourceFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get transactionsSourceFreelance;

  /// No description provided for @transactionsSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get transactionsSourceOther;

  /// No description provided for @transactionsSourceSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get transactionsSourceSalary;

  /// No description provided for @transactionsSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-category'**
  String get transactionsSubCategory;

  /// No description provided for @transactionsSubCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Sub-category (optional)'**
  String get transactionsSubCategoryOptional;

  /// No description provided for @transactionsTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionsTags;

  /// No description provided for @transactionsTagsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'tags could not be saved ({reason})'**
  String transactionsTagsSaveFailed(String reason);

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get transactionsTitle;

  /// No description provided for @transactionsTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get transactionsTitleOptional;

  /// No description provided for @transactionsToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get transactionsToAccount;

  /// No description provided for @transactionsTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionsTypeExpense;

  /// No description provided for @transactionsTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsTypeIncome;

  /// No description provided for @transactionsTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionsTypeTransfer;

  /// No description provided for @transactionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionsUpdated;

  /// No description provided for @transactionsWarningAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get transactionsWarningAnd;

  /// No description provided for @walletsAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get walletsAddAccount;

  /// No description provided for @walletsAddMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get walletsAddMoney;

  /// No description provided for @walletsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get walletsAmount;

  /// No description provided for @walletsBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after: {amount}'**
  String walletsBalanceAfter(String amount);

  /// No description provided for @walletsCardsNote.
  ///
  /// In en, this message translates to:
  /// **'Credit-card accounts are shown separately and are not part of the total.'**
  String get walletsCardsNote;

  /// No description provided for @walletsClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get walletsClosing;

  /// No description provided for @walletsCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get walletsCurrentBalance;

  /// No description provided for @walletsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get walletsDate;

  /// No description provided for @walletsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Add a cash, bank or mobile wallet account to start tracking balances.'**
  String get walletsEmpty;

  /// No description provided for @walletsInOut.
  ///
  /// In en, this message translates to:
  /// **'In {inAmount} · Out {outAmount}'**
  String walletsInOut(String inAmount, String outAmount);

  /// No description provided for @walletsLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get walletsLedgerTitle;

  /// No description provided for @walletsMoneyAdded.
  ///
  /// In en, this message translates to:
  /// **'Money added'**
  String get walletsMoneyAdded;

  /// No description provided for @walletsMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get walletsMoneyIn;

  /// No description provided for @walletsMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get walletsMoneyOut;

  /// No description provided for @walletsNoMovements.
  ///
  /// In en, this message translates to:
  /// **'No movements in this period.'**
  String get walletsNoMovements;

  /// No description provided for @walletsNoOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'Add another account first to transfer money.'**
  String get walletsNoOtherAccount;

  /// No description provided for @walletsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found.'**
  String get walletsNotFound;

  /// No description provided for @walletsNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get walletsNote;

  /// No description provided for @walletsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get walletsOpening;

  /// No description provided for @walletsOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get walletsOpeningBalance;

  /// No description provided for @walletsPeriod3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get walletsPeriod3Months;

  /// No description provided for @walletsPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get walletsPeriodAll;

  /// No description provided for @walletsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get walletsPeriodMonth;

  /// No description provided for @walletsPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get walletsPeriodYear;

  /// No description provided for @walletsPreviewAdd.
  ///
  /// In en, this message translates to:
  /// **'Current {current} + {added} = {after} after'**
  String walletsPreviewAdd(String current, String added, String after);

  /// No description provided for @walletsPreviewMove.
  ///
  /// In en, this message translates to:
  /// **'{name}: {before} → {after}'**
  String walletsPreviewMove(String name, String before, String after);

  /// No description provided for @walletsSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get walletsSource;

  /// No description provided for @walletsSourceDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletsSourceDeposit;

  /// No description provided for @walletsSourceGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get walletsSourceGift;

  /// No description provided for @walletsSourceInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get walletsSourceInterest;

  /// No description provided for @walletsSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get walletsSourceOther;

  /// No description provided for @walletsSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the source of this money'**
  String get walletsSourceRequired;

  /// No description provided for @walletsSourceSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get walletsSourceSalary;

  /// No description provided for @walletsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get walletsThisMonth;

  /// No description provided for @walletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallets & balances'**
  String get walletsTitle;

  /// No description provided for @walletsTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get walletsTotalBalance;

  /// No description provided for @walletsTotalIn.
  ///
  /// In en, this message translates to:
  /// **'Total in'**
  String get walletsTotalIn;

  /// No description provided for @walletsTotalNote.
  ///
  /// In en, this message translates to:
  /// **'Cash, bank, mobile and savings accounts (credit cards excluded)'**
  String get walletsTotalNote;

  /// No description provided for @walletsTotalOut.
  ///
  /// In en, this message translates to:
  /// **'Total out'**
  String get walletsTotalOut;

  /// No description provided for @walletsTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Moving money from a bank to cash is a withdrawal.'**
  String get walletsTransferHint;

  /// No description provided for @walletsTransferSaved.
  ///
  /// In en, this message translates to:
  /// **'Transfer saved'**
  String get walletsTransferSaved;

  /// No description provided for @walletsTransferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer to'**
  String get walletsTransferTo;

  /// No description provided for @walletsTransferWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Transfer / Withdraw'**
  String get walletsTransferWithdraw;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
