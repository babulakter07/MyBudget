// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String accountsActivateMessage(String name) {
    return '\"$name\" will be available again.';
  }

  @override
  String get accountsActivateTitle => 'Activate account?';

  @override
  String get accountsAdd => 'Add account';

  @override
  String get accountsAmountInvalid => 'Enter a valid amount (max 2 decimals)';

  @override
  String accountsDeactivateMessage(String name) {
    return '\"$name\" will be hidden from new entries. Existing data is kept.';
  }

  @override
  String get accountsDeactivateTitle => 'Deactivate account?';

  @override
  String get accountsEdit => 'Edit account';

  @override
  String get accountsEmpty => 'No accounts yet. Tap + to add one.';

  @override
  String get accountsNameLabel => 'Name';

  @override
  String get accountsNameRequired => 'Name is required';

  @override
  String get accountsOpeningBalance => 'Opening balance';

  @override
  String get accountsOpeningDate => 'Opening date';

  @override
  String get accountsSearchHint => 'Search accounts';

  @override
  String get accountsSelectProfile => 'Select a profile to manage accounts.';

  @override
  String get accountsShowInactive => 'Show inactive';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsTypeBank => 'Bank';

  @override
  String get accountsTypeCash => 'Cash';

  @override
  String get accountsTypeCreditCard => 'Credit card';

  @override
  String get accountsTypeMobile => 'Mobile banking';

  @override
  String get accountsTypeOther => 'Other';

  @override
  String get accountsTypeSavings => 'Savings account';

  @override
  String get appShellAbout => 'About';

  @override
  String get appShellAboutContact => 'Contact';

  @override
  String appShellAboutCopied(String label) {
    return '$label copied';
  }

  @override
  String get appShellAboutCurrentWork => 'Current work';

  @override
  String get appShellAboutEmail => 'Email';

  @override
  String get appShellAboutJob => 'Software Engineer - Jan 2024 to present';

  @override
  String get appShellAboutPortfolio => 'Portfolio';

  @override
  String get appShellAboutRole =>
      'Software Engineer | Full Stack .NET Developer';

  @override
  String get appShellAboutTagline =>
      'Offline-first personal and family budget manager. Your data stays on your device.';

  @override
  String get appShellAboutTapToCopy => 'Tap a contact to copy it';

  @override
  String get appShellAccounts => 'Accounts';

  @override
  String get appShellBackupRestore => 'Backup & Restore';

  @override
  String get appShellBankLoans => 'Bank loans';

  @override
  String get appShellCategories => 'Categories';

  @override
  String get appShellCostItems => 'Cost Items';

  @override
  String get appShellCreditCards => 'Credit cards';

  @override
  String get appShellDebtsLoans => 'Debts & loans';

  @override
  String get appShellExchangeRates => 'Exchange rates';

  @override
  String get appShellFixedDeposits => 'Fixed deposits (FDR)';

  @override
  String get appShellImportCsv => 'Import from CSV';

  @override
  String get appShellInsights => 'Insights';

  @override
  String get appShellMore => 'More';

  @override
  String get appShellNoErrorsLogged => 'No errors have been logged.';

  @override
  String get appShellNotifications => 'Notifications';

  @override
  String get appShellPreferences => 'Preferences';

  @override
  String get appShellProfiles => 'Profiles';

  @override
  String get appShellRecurring => 'Recurring transactions';

  @override
  String get appShellSavingsGoals => 'Savings goals';

  @override
  String get appShellSectionApp => 'App';

  @override
  String get appShellSectionData => 'Data';

  @override
  String get appShellSectionMaster => 'Master Configuration';

  @override
  String get appShellSectionOperations => 'Operations';

  @override
  String get appShellSectionPlan => 'Plan';

  @override
  String get appShellSecurity => 'Security';

  @override
  String get appShellSettings => 'Settings';

  @override
  String get appShellShareErrorLog => 'Share error log';

  @override
  String get appShellShareErrorLogSubtitle =>
      'Stays on your device unless you send it';

  @override
  String get appShellSubCategories => 'Sub-categories';

  @override
  String get appShellTabAdd => 'Add';

  @override
  String get appShellTabBudget => 'Budget';

  @override
  String get appShellTabHome => 'Home';

  @override
  String get appShellTabLedger => 'Ledger';

  @override
  String get appShellTabReports => 'Reports';

  @override
  String get appShellTagReport => 'Tag report';

  @override
  String get appShellTags => 'Tags';

  @override
  String get appShellWallets => 'Wallets & balances';

  @override
  String get attachmentsAddFailed => 'Could not add the photo.';

  @override
  String get attachmentsAddPhoto => 'Add photo';

  @override
  String get attachmentsCamera => 'Camera';

  @override
  String get attachmentsDeleteTitle => 'Delete attachment';

  @override
  String get attachmentsGallery => 'Gallery';

  @override
  String attachmentsHeader(int count, int max) {
    return 'Attachments ($count/$max)';
  }

  @override
  String get attachmentsNone => 'No attachments';

  @override
  String get attachmentsRemoveMessage => 'Remove this photo?';

  @override
  String get attachmentsViewerTitle => 'Attachment';

  @override
  String get backupAutoBackup => 'Automatic backup';

  @override
  String get backupAutoNote =>
      'Android decides when background work runs, so automatic backups may be delayed by hours (battery saver, Doze). Backups stay on this device. Manual and safety backups are never removed automatically. Automatic backups are NOT password protected and do not include receipt photos; use \"Create & share\" for an encrypted copy with photos.';

  @override
  String get backupBackUpNow => 'Back up now';

  @override
  String get backupCannotRestoreTitle => 'Backup cannot be restored';

  @override
  String get backupConfirmPassword => 'Confirm password';

  @override
  String get backupContains => 'Contains:';

  @override
  String backupContainsRow(int count, String label) {
    return '• $count $label';
  }

  @override
  String get backupCreateAndShare => 'Create & share';

  @override
  String get backupCreateBackup => 'Create backup';

  @override
  String backupCreatedAt(String date) {
    return 'Backup created: $date';
  }

  @override
  String backupDeleteMessage(String name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String get backupDeleteTitle => 'Delete backup?';

  @override
  String get backupEncrypt => 'Encrypt with a password';

  @override
  String get backupEncryptNote =>
      'AES-256. If you forget the password the backup cannot be opened by anyone, including us.';

  @override
  String get backupEncryptedPrompt =>
      'This backup is encrypted. Enter its password.';

  @override
  String get backupEncryptedSuffix => ' (encrypted)';

  @override
  String get backupFolderChange => 'Change folder';

  @override
  String get backupFolderChoose => 'Choose folder';

  @override
  String backupFolderCurrent(String name) {
    return 'Folder: $name';
  }

  @override
  String backupFolderError(String message) {
    return 'Last attempt failed: $message';
  }

  @override
  String get backupFolderFailed => 'Could not save the copy.';

  @override
  String get backupFolderIntro =>
      'Keep password-protected copies in a folder you choose. They stay there even if the app is uninstalled.';

  @override
  String backupFolderLastCopy(String time) {
    return 'Last copy: $time';
  }

  @override
  String get backupFolderNewPassword => 'New password';

  @override
  String get backupFolderNoCopy => 'No copy saved yet.';

  @override
  String get backupFolderNote =>
      'A new copy is saved when you open or leave the app after your data changes. One copy per day is kept, using the \'Keep last automatic backups\' number as the number of days. A folder on this phone does not help if the phone is lost: copy the files elsewhere, or use a folder that is synced or on an SD card. To restore, tap \'Restore from file\'.';

  @override
  String get backupFolderNothing =>
      'Folder set. A copy will be saved once you add an account or a record.';

  @override
  String get backupFolderOffMessage =>
      'No new copies will be saved. Files already in the folder are kept.';

  @override
  String get backupFolderOffTitle => 'Turn off folder backup?';

  @override
  String get backupFolderPasswordTitle => 'Backup password';

  @override
  String get backupFolderPasswordWarning =>
      'Write this password down. Without it the copies cannot be restored, and nobody can recover it.';

  @override
  String get backupFolderSaveNow => 'Save now';

  @override
  String get backupFolderSavePassword => 'Save';

  @override
  String get backupFolderSaved => 'Copy saved to the backup folder.';

  @override
  String get backupFolderTitle => 'Backup folder';

  @override
  String get backupFolderTurnOff => 'Turn off';

  @override
  String get backupFreqDaily => 'Daily';

  @override
  String get backupFreqOff => 'Off';

  @override
  String get backupFreqWeekly => 'Weekly';

  @override
  String get backupFrequency => 'Frequency';

  @override
  String get backupHide => 'Hide';

  @override
  String get backupIncludePhotos => 'Include receipt photos';

  @override
  String get backupKeepLast => 'Keep last automatic backups';

  @override
  String get backupKindAuto => 'Automatic';

  @override
  String get backupKindManual => 'Manual';

  @override
  String get backupKindSafety => 'Safety (before restore)';

  @override
  String get backupLastRunFailed => 'Last run failed';

  @override
  String get backupLastRunSucceeded => 'Last run succeeded';

  @override
  String backupMissingPhotosSuffix(int count) {
    return '. $count receipt photo(s) were missing and skipped.';
  }

  @override
  String backupMissingSkipped(int count) {
    return ' ($count missing file(s) will be skipped)';
  }

  @override
  String get backupNoAutoRun => 'No automatic backup has run yet.';

  @override
  String get backupNoBackupsYet =>
      'No backups yet. Tap \"Create backup\" to make the first one.';

  @override
  String get backupNoPhotos => 'No receipt photos to include.';

  @override
  String get backupNothingChanged => 'Nothing was changed. Problems found:';

  @override
  String get backupPassword => 'Password';

  @override
  String backupPasswordMinLabel(int min) {
    return 'Password (min $min)';
  }

  @override
  String get backupPasswordMismatch => 'The two passwords do not match.';

  @override
  String get backupPasswordRequired => 'Password required';

  @override
  String backupPasswordTooShort(int min) {
    return 'Use at least $min characters for the password.';
  }

  @override
  String backupPhotoCount(int count, String size) {
    return '$count photo(s), about $size';
  }

  @override
  String get backupReminderAction => 'Back up';

  @override
  String get backupReminderLater => 'Later';

  @override
  String get backupReminderNone =>
      'Automatic backups are lost if the app is removed. Create and share a backup, or set a backup folder.';

  @override
  String backupReminderOld(int days) {
    return 'Your last backup was $days days ago.';
  }

  @override
  String get backupReminderTitle => 'Back up your data';

  @override
  String get backupReplaceAllTitle => 'Replace all data?';

  @override
  String get backupReplaceData => 'Replace data';

  @override
  String get backupReplaceWarning =>
      'Restoring will REPLACE all current data in the app with this backup. A safety backup of your current data is created first, so you can go back.';

  @override
  String get backupRestoreComplete =>
      'Restore complete. A safety backup of the previous data was saved.';

  @override
  String get backupRestoreCompleteCleared =>
      'Restore complete. Your previous profile is not in this backup; please choose a profile.';

  @override
  String get backupRestoreFromFile => 'Restore from file';

  @override
  String get backupSavedBackups => 'Saved backups';

  @override
  String backupSavedToast(String name) {
    return 'Backup saved: $name';
  }

  @override
  String get backupShow => 'Show';

  @override
  String backupSomethingWrong(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String backupStatusAt(String time) {
    return ' at $time';
  }

  @override
  String backupStatusMessage(String message) {
    return ' ($message)';
  }

  @override
  String get backupTableAccounts => 'accounts';

  @override
  String get backupTableCategories => 'categories';

  @override
  String get backupTableCategoryBudgets => 'category budgets';

  @override
  String get backupTableCostItems => 'cost items';

  @override
  String get backupTableDebtPayments => 'debt payments';

  @override
  String get backupTableDebts => 'debts';

  @override
  String get backupTableExchangeRates => 'exchange rates';

  @override
  String get backupTableFinancialProfiles => 'financial profiles';

  @override
  String get backupTableFinancialTransactions => 'financial transactions';

  @override
  String get backupTableMonthlyBudgets => 'monthly budgets';

  @override
  String get backupTableRecurringRules => 'recurring rules';

  @override
  String get backupTableSavingsGoals => 'savings goals';

  @override
  String get backupTableSubCategories => 'sub categories';

  @override
  String get backupTableTags => 'tags';

  @override
  String get backupTableTransactionAttachments => 'transaction attachments';

  @override
  String get backupTableTransactionAuditLogs => 'transaction audit logs';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupUnlock => 'Unlock';

  @override
  String get backupUnreadableFile => 'That file is not a readable JSON backup.';

  @override
  String get budgetsAddAllocation => 'Add allocation';

  @override
  String budgetsAllocatedSummary(String allocated, String total) {
    return 'Allocated $allocated of $total (inside the total, not added).';
  }

  @override
  String get budgetsAllocation => 'Allocation';

  @override
  String get budgetsBudget => 'Budget';

  @override
  String budgetsCarriedOver(String amount) {
    return '+$amount carried over';
  }

  @override
  String get budgetsCarryOverUnspent => 'Carry over unspent';

  @override
  String get budgetsCategory => 'Category';

  @override
  String get budgetsCategoryAllocations => 'Category allocations';

  @override
  String get budgetsEditAllocation => 'Edit allocation';

  @override
  String get budgetsEditBudget => 'Edit budget';

  @override
  String get budgetsEmptyMessage =>
      'New month: set a budget; nothing carries over.';

  @override
  String budgetsErrorWithDetail(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get budgetsInvalidAmount => 'Enter a valid amount (max 2 decimals)';

  @override
  String get budgetsMonthApril => 'April';

  @override
  String get budgetsMonthAugust => 'August';

  @override
  String get budgetsMonthDecember => 'December';

  @override
  String get budgetsMonthFebruary => 'February';

  @override
  String get budgetsMonthJanuary => 'January';

  @override
  String get budgetsMonthJuly => 'July';

  @override
  String get budgetsMonthJune => 'June';

  @override
  String get budgetsMonthMarch => 'March';

  @override
  String get budgetsMonthMay => 'May';

  @override
  String get budgetsMonthNovember => 'November';

  @override
  String get budgetsMonthOctober => 'October';

  @override
  String get budgetsMonthSeptember => 'September';

  @override
  String budgetsMonthYear(String month, String year) {
    return '$month $year';
  }

  @override
  String get budgetsMonthlyBudget => 'Monthly budget';

  @override
  String get budgetsNextMonth => 'Next month';

  @override
  String get budgetsNoAllocations => 'No category allocations for this month.';

  @override
  String get budgetsNoCategoriesLeft =>
      'No active categories left to allocate.';

  @override
  String budgetsPercentUsed(String percent) {
    return '$percent% used';
  }

  @override
  String get budgetsPickMonthHelp => 'Select any day in the month';

  @override
  String get budgetsPreviousMonth => 'Previous month';

  @override
  String get budgetsRemaining => 'Remaining';

  @override
  String budgetsRemainingAmount(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get budgetsRemoveAllocation => 'Remove allocation';

  @override
  String budgetsRemoveAllocationMessage(String name) {
    return 'Remove the allocation for \"$name\"?';
  }

  @override
  String get budgetsRemoveAllocationTitle => 'Remove allocation?';

  @override
  String get budgetsSelectProfile => 'Select a profile to manage budgets.';

  @override
  String get budgetsSetBudget => 'Set budget';

  @override
  String get budgetsSpent => 'Spent';

  @override
  String budgetsSpentOf(String spent, String allowance) {
    return 'Spent $spent of $allowance';
  }

  @override
  String get budgetsTotalBudget => 'Total budget';

  @override
  String categoriesActivateMessage(String name) {
    return '\"$name\" will be available again.';
  }

  @override
  String get categoriesActivateTitle => 'Activate category?';

  @override
  String get categoriesAdd => 'Add category';

  @override
  String get categoriesColorLabel => 'Color';

  @override
  String categoriesDeactivateMessage(String name) {
    return '\"$name\" will be hidden from new entries. Existing data is kept.';
  }

  @override
  String get categoriesDeactivateTitle => 'Deactivate category?';

  @override
  String get categoriesDescriptionLabel => 'Description';

  @override
  String get categoriesEdit => 'Edit category';

  @override
  String get categoriesEmpty => 'No categories yet. Tap + to add one.';

  @override
  String get categoriesIconLabel => 'Icon';

  @override
  String categoriesLoadError(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get categoriesNameLabel => 'Name';

  @override
  String get categoriesNameRequired => 'Name is required';

  @override
  String get categoriesSearchHint => 'Search categories';

  @override
  String get categoriesSelectProfile =>
      'Select a profile to manage categories.';

  @override
  String get categoriesShowInactive => 'Show inactive';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get commonActive => 'Active';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonAll => 'All';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonInactive => 'Inactive';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonNext => 'Next';

  @override
  String get commonNo => 'No';

  @override
  String get commonNoData => 'No data yet';

  @override
  String get commonNone => 'None';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSelectProfile => 'Select a profile to continue.';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonUpdate => 'Update';

  @override
  String get commonYes => 'Yes';

  @override
  String get costItemsActivateAction => 'Activate';

  @override
  String costItemsActivateMessage(String name) {
    return '\"$name\" will be available again.';
  }

  @override
  String get costItemsActivateTitle => 'Activate cost item?';

  @override
  String get costItemsAdd => 'Add cost item';

  @override
  String get costItemsAmountInvalid => 'Enter a valid amount (max 2 decimals)';

  @override
  String get costItemsCategoryLabel => 'Category';

  @override
  String get costItemsDeactivateAction => 'Deactivate';

  @override
  String costItemsDeactivateMessage(String name) {
    return '\"$name\" will be hidden from new entries. Existing data is preserved.';
  }

  @override
  String get costItemsDeactivateTitle => 'Deactivate cost item?';

  @override
  String get costItemsDefaultAmountOptional => 'Default amount (optional)';

  @override
  String get costItemsDescriptionOptional => 'Description (optional)';

  @override
  String get costItemsEdit => 'Edit cost item';

  @override
  String get costItemsEmpty => 'No cost items found.';

  @override
  String get costItemsFavAddTooltip => 'Add to quick add';

  @override
  String get costItemsFavRemoveTooltip => 'Remove from quick add';

  @override
  String get costItemsInactiveSuffix => ' · Inactive';

  @override
  String costItemsLoadError(String error) {
    return 'Could not load cost items: $error';
  }

  @override
  String get costItemsNameLabel => 'Name';

  @override
  String get costItemsNameRequired => 'Name is required';

  @override
  String get costItemsSearchHint => 'Search name or description';

  @override
  String get costItemsSelectCategory => 'Select a category';

  @override
  String get costItemsSelectProfile => 'Select a profile first.';

  @override
  String get costItemsSelectSubCategory => 'Select a sub-category';

  @override
  String get costItemsShowInactive => 'Show inactive';

  @override
  String get costItemsSubCategoryLabel => 'Sub-category';

  @override
  String get costItemsTitle => 'Cost Items';

  @override
  String get creditCardsActivate => 'Activate card';

  @override
  String get creditCardsAdd => 'Add card';

  @override
  String get creditCardsAddBill => 'Add bill';

  @override
  String get creditCardsAmountPositive => 'Amount must be greater than zero';

  @override
  String get creditCardsAvailable => 'Available credit';

  @override
  String get creditCardsAvailableShort => 'Available';

  @override
  String creditCardsBillAmount(String amount) {
    return 'Bill $amount';
  }

  @override
  String get creditCardsBillAmountLabel => 'Bill amount';

  @override
  String get creditCardsBillNotFound => 'Bill not found.';

  @override
  String creditCardsBillTitle(String month) {
    return '$month bill';
  }

  @override
  String get creditCardsBills => 'Bills';

  @override
  String get creditCardsBreakdown => 'Bill breakdown';

  @override
  String get creditCardsChargesAdded => 'Interest & fees added';

  @override
  String creditCardsChipApr(String rate) {
    return 'APR $rate';
  }

  @override
  String creditCardsChipDueDays(int days) {
    return 'Pay within $days days';
  }

  @override
  String creditCardsChipLateFee(String rate) {
    return 'Late fee $rate';
  }

  @override
  String creditCardsChipMin(String rate) {
    return 'Min $rate';
  }

  @override
  String creditCardsChipStatementDay(int day) {
    return 'Statement day $day';
  }

  @override
  String creditCardsDaysOverdue(int days) {
    return '$days days overdue';
  }

  @override
  String get creditCardsDeactivate => 'Deactivate card';

  @override
  String creditCardsDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get creditCardsEdit => 'Edit card';

  @override
  String get creditCardsEditBill => 'Edit bill';

  @override
  String creditCardsEffectiveAnnual(String percent) {
    return 'Effective annual cost so far: $percent';
  }

  @override
  String get creditCardsEmpty =>
      'No credit cards yet. Add one to track bills, interest and late fees.';

  @override
  String get creditCardsExtraCharges => 'Added to this bill';

  @override
  String creditCardsExtraPct(String percent) {
    return '+$percent charges';
  }

  @override
  String creditCardsExtraValue(String amount, String percent) {
    return '$amount (+$percent)';
  }

  @override
  String get creditCardsFieldApr => 'Interest rate per year (APR %)';

  @override
  String get creditCardsFieldBank => 'Bank';

  @override
  String get creditCardsFieldBillAmount => 'New charges this month';

  @override
  String get creditCardsFieldDueDate => 'Payment due date';

  @override
  String get creditCardsFieldDueDays => 'Days to pay after statement';

  @override
  String get creditCardsFieldLastFour => 'Last 4 digits (optional)';

  @override
  String get creditCardsFieldLateFeeFloor => 'Late fee minimum amount';

  @override
  String get creditCardsFieldLateFeePct => 'Late fee (% of unpaid minimum)';

  @override
  String get creditCardsFieldLimit => 'Credit limit';

  @override
  String get creditCardsFieldMinDue => 'Minimum payment due';

  @override
  String get creditCardsFieldMinFloor => 'Minimum payment floor (amount)';

  @override
  String get creditCardsFieldMinPct => 'Minimum payment (% of bill)';

  @override
  String get creditCardsFieldMonth => 'Statement month (YYYY-MM)';

  @override
  String get creditCardsFieldName => 'Card name';

  @override
  String get creditCardsFieldNote => 'Note';

  @override
  String get creditCardsFieldPayAmount => 'Amount';

  @override
  String get creditCardsFieldPayDate => 'Payment date';

  @override
  String get creditCardsFieldStatementDate => 'Statement date';

  @override
  String get creditCardsFieldStatementDay => 'Statement day (1-28)';

  @override
  String get creditCardsHelpApr =>
      'Charged on the unpaid bill after the due date, as a daily rate (APR / 365).';

  @override
  String get creditCardsHelpBillAmount =>
      'Only this month\'s new charges, not the unpaid balance of earlier bills.';

  @override
  String get creditCardsHelpDueDays =>
      'Payment due date = statement date + this many days.';

  @override
  String get creditCardsHelpInterestFromStatement =>
      'Many banks remove the interest-free period when the whole bill is not paid by the due date. On: interest runs from the statement date. Off: from the due date.';

  @override
  String get creditCardsHelpLateFee =>
      'Charged when the minimum is not paid by the due date: the larger of the % and this amount.';

  @override
  String get creditCardsHelpMin =>
      'Minimum due = the larger of the % and this amount, never more than the bill.';

  @override
  String get creditCardsHelpMinDue =>
      'Filled from the card policy; change it to match your statement.';

  @override
  String get creditCardsHelpStatementDay =>
      'Day of the month your bank generates the statement.';

  @override
  String get creditCardsInactiveBanner => 'This card is inactive.';

  @override
  String creditCardsInterest(String rate) {
    return 'Interest ($rate APR)';
  }

  @override
  String get creditCardsInterestFromStatement =>
      'Interest from statement date if not paid in full';

  @override
  String get creditCardsInvalidMonth => 'Use the format YYYY-MM';

  @override
  String get creditCardsInvalidNumber => 'Enter a valid number';

  @override
  String get creditCardsInvalidPercent => 'Enter a percentage from 0 to 100';

  @override
  String get creditCardsLastFourInvalid => 'Enter exactly 4 digits';

  @override
  String creditCardsLateFee(String rate) {
    return 'Late fee ($rate)';
  }

  @override
  String get creditCardsLimit => 'Credit limit';

  @override
  String creditCardsMaxAmount(String amount) {
    return 'Maximum is $amount';
  }

  @override
  String get creditCardsMinimumDue => 'Minimum due';

  @override
  String creditCardsNextDue(String card, String date) {
    return 'Next due: $card on $date';
  }

  @override
  String get creditCardsNoBills =>
      'No bills yet. Add a monthly statement to start tracking.';

  @override
  String get creditCardsNoPayments => 'No payments recorded.';

  @override
  String get creditCardsNotFound => 'Card not found.';

  @override
  String get creditCardsNothingDue => 'Nothing due';

  @override
  String get creditCardsOutstanding => 'Outstanding';

  @override
  String get creditCardsOverdueBadge => 'Overdue';

  @override
  String creditCardsOverdueBills(int count) {
    return 'Overdue bills: $count';
  }

  @override
  String get creditCardsPaidSoFar => 'Paid so far';

  @override
  String get creditCardsPay => 'Pay';

  @override
  String get creditCardsPayFull => 'Full remaining';

  @override
  String get creditCardsPayMinimum => 'Minimum due';

  @override
  String get creditCardsPaymentTitle => 'Record payment';

  @override
  String get creditCardsPayments => 'Payments';

  @override
  String get creditCardsPolicy => 'Billing policy';

  @override
  String creditCardsProjectionIntro(String date) {
    return 'Estimated interest and fees on this bill by $date (30 days after the due date):';
  }

  @override
  String creditCardsProjectionMin(String amount, String charges) {
    return 'Pay only the minimum ($amount) now: $charges';
  }

  @override
  String creditCardsProjectionNothing(String charges) {
    return 'Pay nothing more: $charges';
  }

  @override
  String get creditCardsProjectionTitle => 'What if you delay?';

  @override
  String creditCardsRangeInt(int min, int max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String get creditCardsRemaining => 'Remaining';

  @override
  String creditCardsRemainingAmount(String amount) {
    return 'Remaining $amount';
  }

  @override
  String creditCardsRemainingNow(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get creditCardsShowInactive => 'Show inactive cards';

  @override
  String get creditCardsStatusMinPaid => 'Minimum paid';

  @override
  String get creditCardsStatusOverdue => 'Overdue';

  @override
  String get creditCardsStatusPaid => 'Paid';

  @override
  String get creditCardsStatusPartial => 'Partly paid';

  @override
  String get creditCardsStatusUnpaid => 'Unpaid';

  @override
  String get creditCardsTitle => 'Credit cards';

  @override
  String get creditCardsTotalLimit => 'Total limit';

  @override
  String get creditCardsTotalOutstanding => 'Total outstanding';

  @override
  String get creditCardsTotalPayable => 'Total payable';

  @override
  String creditCardsUsed(String percent) {
    return 'Used $percent';
  }

  @override
  String get creditCardsVoid => 'Void';

  @override
  String get creditCardsVoidBill => 'Void bill';

  @override
  String get creditCardsVoidBillMessage =>
      'Void this bill? It is kept for history but no longer counts toward your outstanding balance.';

  @override
  String get creditCardsVoidPayment => 'Void payment';

  @override
  String creditCardsVoidPaymentMessage(String amount) {
    return 'Void the payment of $amount? The balance, interest and fees will be recalculated.';
  }

  @override
  String get creditCardsVoided => 'Voided';

  @override
  String get creditCardsVoidedBanner => 'This bill is voided.';

  @override
  String get currencyAddRate => 'Add exchange rate';

  @override
  String get currencyAddRateTooltip => 'Add rate';

  @override
  String currencyBaseCard(String code, String symbol) {
    return 'Base currency: $code ($symbol)';
  }

  @override
  String get currencyBaseCardSub => 'All balances, budgets and reports use it';

  @override
  String get currencyCodeLabel => '3-letter currency code';

  @override
  String get currencyEditRate => 'Edit exchange rate';

  @override
  String get currencyEmptyBody =>
      'Add a rate for each foreign currency you spend or earn in, e.g. 1 USD = your base currency amount.';

  @override
  String get currencyEmptyTitle => 'No exchange rates yet';

  @override
  String get currencyErrChoose => 'Choose a currency.';

  @override
  String get currencyErrCode => 'Currency code must be 3 letters, e.g. USD.';

  @override
  String get currencyErrRate =>
      'Enter a rate greater than zero with up to 6 decimals, e.g. 122.5.';

  @override
  String get currencyFieldCurrency => 'Currency';

  @override
  String get currencyInfo =>
      'Rates are entered by you and are never fetched online. They are only used when you enter a transaction in a foreign currency. Transactions you already saved keep the rate they were saved with, so changing a rate here never rewrites history.';

  @override
  String get currencyNoProfile => 'Select a profile to manage exchange rates.';

  @override
  String get currencyOtherCode => 'Other code';

  @override
  String currencyRateEquals(String code, String symbol, String rate) {
    return '1 $code = $symbol$rate';
  }

  @override
  String get currencyRateHelper =>
      'Base currency amount for 1 unit of the foreign currency';

  @override
  String currencyRateLabel(String base) {
    return 'Rate (in $base)';
  }

  @override
  String get currencyTitle => 'Exchange rates';

  @override
  String currencyUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String currencyUpdatedInactive(String date) {
    return 'Updated $date - inactive';
  }

  @override
  String get dashboardAverageDailyExpense => 'Average daily expense';

  @override
  String get dashboardAverageMonthlyExpense => 'Average monthly expense';

  @override
  String get dashboardBudgetUtilization => 'Budget utilization';

  @override
  String get dashboardCashBalance => 'Cash balance (active accounts)';

  @override
  String get dashboardCategoryDistribution => 'Category distribution';

  @override
  String get dashboardCurrentMonth => 'Current month';

  @override
  String get dashboardHighestSpendingDay => 'Highest spending day';

  @override
  String get dashboardHighestSpendingMonth => 'Highest spending month';

  @override
  String get dashboardLowestSpendingMonth => 'Lowest spending month';

  @override
  String get dashboardMonthExpense => 'Month expense';

  @override
  String get dashboardMonthIncome => 'Month income';

  @override
  String get dashboardMonthlyBudget => 'Monthly budget';

  @override
  String get dashboardMonthlyExpenseTrend => 'Monthly expense trend';

  @override
  String get dashboardNoCategoryExpenses => 'No category expenses this month.';

  @override
  String get dashboardNoCostItemExpenses => 'No cost-item expenses this month.';

  @override
  String get dashboardNoExpensesToChart => 'No expenses to chart this month.';

  @override
  String get dashboardNoProfile => 'No profile';

  @override
  String get dashboardPreviousMonth => 'Previous month';

  @override
  String get dashboardRemainingBudget => 'Remaining budget';

  @override
  String get dashboardSelectMonth => 'Select month';

  @override
  String get dashboardSpendingHighlights => 'Spending highlights';

  @override
  String get dashboardSwitch => 'Switch';

  @override
  String get dashboardTop5Categories => 'Top 5 categories';

  @override
  String get dashboardTop5CostItems => 'Top 5 cost items';

  @override
  String get dashboardTotalExpense => 'Total expense';

  @override
  String get dashboardTotalIncome => 'Total income';

  @override
  String dashboardYear(int year) {
    return 'Year $year';
  }

  @override
  String get dashboardYearlyOverview => 'Yearly overview';

  @override
  String get debtsAddDebt => 'Add debt';

  @override
  String get debtsAddPayment => 'Add payment';

  @override
  String get debtsAmount => 'Amount';

  @override
  String get debtsAmountPositive => 'Amount must be greater than zero';

  @override
  String get debtsArchived => 'Archived';

  @override
  String get debtsBorrowed => 'Borrowed';

  @override
  String debtsClearField(String label) {
    return 'Clear $label';
  }

  @override
  String debtsDue(String date) {
    return 'Due $date';
  }

  @override
  String get debtsDueDate => 'Due date';

  @override
  String debtsDueWithPrincipal(String due, String principal) {
    return '$due  •  of $principal';
  }

  @override
  String get debtsEditDebt => 'Edit debt';

  @override
  String get debtsGroupByPerson => 'Group by person';

  @override
  String get debtsIAmOwed => 'I am owed';

  @override
  String get debtsIBorrowed => 'I borrowed';

  @override
  String get debtsILent => 'I lent';

  @override
  String get debtsIOwe => 'I owe';

  @override
  String get debtsInvalidAmount => 'Enter a valid amount (max 2 decimals)';

  @override
  String get debtsLent => 'Lent';

  @override
  String get debtsListTitle => 'Debts & loans';

  @override
  String get debtsMarkSettled => 'Mark fully settled';

  @override
  String debtsMaxAmount(String amount) {
    return 'Maximum is $amount';
  }

  @override
  String get debtsNet => 'Net';

  @override
  String get debtsNoBorrowed => 'No money borrowed yet.';

  @override
  String get debtsNoDueDate => 'No due date';

  @override
  String get debtsNoLent => 'No money lent yet.';

  @override
  String get debtsNoPayments => 'No payments yet.';

  @override
  String get debtsNotFound => 'Debt not found.';

  @override
  String get debtsNotSet => 'Not set';

  @override
  String get debtsNote => 'Note';

  @override
  String get debtsOutstanding => 'Outstanding';

  @override
  String debtsOutstandingAmount(String amount) {
    return 'Outstanding: $amount';
  }

  @override
  String get debtsOverdue => 'Overdue';

  @override
  String get debtsOwedToMe => 'Owed to me';

  @override
  String get debtsPaid => 'Paid';

  @override
  String get debtsPaymentDate => 'Payment date';

  @override
  String get debtsPayments => 'Payments';

  @override
  String get debtsPerson => 'Person';

  @override
  String get debtsPersonRequired => 'Person name is required';

  @override
  String get debtsPrincipal => 'Principal';

  @override
  String debtsReminderBorrowed(
    String person,
    String outstanding,
    String principal,
  ) {
    return 'Reminder: I owe $person $outstanding (of $principal).';
  }

  @override
  String debtsReminderBorrowedDue(
    String person,
    String outstanding,
    String principal,
    String date,
  ) {
    return 'Reminder: I owe $person $outstanding (of $principal). Due: $date.';
  }

  @override
  String debtsReminderLent(
    String person,
    String outstanding,
    String principal,
  ) {
    return 'Reminder: $person owes me $outstanding (of $principal).';
  }

  @override
  String debtsReminderLentDue(
    String person,
    String outstanding,
    String principal,
    String date,
  ) {
    return 'Reminder: $person owes me $outstanding (of $principal). Due: $date.';
  }

  @override
  String get debtsSettle => 'Settle';

  @override
  String debtsSettleMessage(String amount) {
    return 'Record a payment of $amount?';
  }

  @override
  String get debtsShareReminder => 'Share reminder';

  @override
  String get debtsShowFlatList => 'Show flat list';

  @override
  String get debtsStartDate => 'Start date';

  @override
  String debtsStarted(String date) {
    return 'Started $date';
  }

  @override
  String get debtsStatusOpen => 'Open';

  @override
  String get debtsStatusOverdue => 'Overdue';

  @override
  String get debtsStatusSettled => 'Settled';

  @override
  String get debtsTitle => 'Debt';

  @override
  String get debtsUnarchive => 'Unarchive';

  @override
  String get debtsVoid => 'Void';

  @override
  String debtsVoidMessage(String amount) {
    return 'Void this payment of $amount? The outstanding balance will increase.';
  }

  @override
  String get debtsVoidPayment => 'Void payment';

  @override
  String get debtsVoided => 'Voided';

  @override
  String get dpsAccountNumber => 'DPS account number (optional)';

  @override
  String dpsAccountNumberValue(String number) {
    return 'Account: $number';
  }

  @override
  String get dpsAdd => 'Add DPS';

  @override
  String get dpsAlreadyPaid => 'Installments already paid (optional)';

  @override
  String dpsAlreadyPaidHelper(int count) {
    return 'For a DPS you already have. $count due dates have passed. Check your statement.';
  }

  @override
  String get dpsArchive => 'Archive';

  @override
  String get dpsArchived => 'Archived';

  @override
  String dpsAtRiskWarning(int count) {
    return '$count installments are overdue. Your bank may close this DPS. Contact the bank.';
  }

  @override
  String get dpsBankMaturity => 'Maturity amount quoted by bank (optional)';

  @override
  String get dpsBankMaturityHelper =>
      'Before tax. Use the figure from your bank if you have it.';

  @override
  String get dpsBankName => 'Bank or institution';

  @override
  String get dpsBankRequired => 'Enter a name (up to 80 characters)';

  @override
  String get dpsBankRules => 'Your bank\'s rules';

  @override
  String get dpsBankRulesNote =>
      'These differ between banks. Copy them from your DPS terms.';

  @override
  String dpsCalculatedNet(String amount) {
    return 'Calculated amount received: $amount';
  }

  @override
  String get dpsCharges => 'Excise duty and other charges';

  @override
  String get dpsChargesHelper => 'Enter what the bank deducted.';

  @override
  String get dpsClose => 'Close DPS';

  @override
  String get dpsCloseBank => 'Closed by bank';

  @override
  String dpsCloseConfirm(String amount) {
    return 'Close this DPS with $amount received? A closed DPS cannot be changed.';
  }

  @override
  String get dpsCloseMatured => 'Matured';

  @override
  String get dpsClosePremature => 'Closed early';

  @override
  String get dpsCloseTitle => 'Close or encash';

  @override
  String get dpsClosingDate => 'Closing date';

  @override
  String get dpsDepositDate => 'Deposit date';

  @override
  String dpsDepositTotal(String amount) {
    return 'Total paid: $amount';
  }

  @override
  String dpsDepositedAmount(String amount) {
    return 'Deposited $amount';
  }

  @override
  String get dpsDeposits => 'Deposits';

  @override
  String get dpsEarlyNote =>
      'Rules for early closure differ between banks. Some do not allow it in the first months and many pay a lower rate. Enter the figures from your bank.';

  @override
  String get dpsEdit => 'Edit DPS';

  @override
  String get dpsEmpty => 'No DPS yet. Tap + to add one.';

  @override
  String dpsEstimateHelper(String amount) {
    return 'Before tax. App estimate: $amount. Your bank\'s figure may differ.';
  }

  @override
  String get dpsExpectedNet => 'Expected after tax';

  @override
  String dpsExpectedTax(String rate) {
    return 'Tax on profit at $rate%';
  }

  @override
  String get dpsFinalNet => 'Amount actually received (optional)';

  @override
  String get dpsFinalNetHelper =>
      'Fill only if it differs from the calculated amount.';

  @override
  String get dpsFirstDueDate => 'First installment due date';

  @override
  String get dpsGraceDays => 'Grace days after the due date';

  @override
  String get dpsInstallment => 'Monthly installment';

  @override
  String get dpsInstallmentCount => 'Number of installments';

  @override
  String dpsInstallmentCountHelper(int remaining, int overdue) {
    return '$remaining left, $overdue overdue';
  }

  @override
  String get dpsInstallmentDue => 'Due';

  @override
  String get dpsInstallmentPaid => 'Paid';

  @override
  String get dpsInstallmentUpcoming => 'Upcoming';

  @override
  String dpsInstallmentsCount(int count) {
    return '$count installment(s)';
  }

  @override
  String get dpsInvalid => 'Check this value';

  @override
  String get dpsLateFee => 'Late fee per installment (0 if none)';

  @override
  String get dpsLateFeeCharged => 'Late fee charged';

  @override
  String dpsLateFeeValue(String amount) {
    return 'Late fee $amount';
  }

  @override
  String get dpsLateFeesPaid => 'Late fees paid';

  @override
  String get dpsLockedNote =>
      'The installment, term and dates are locked because deposits are recorded.';

  @override
  String dpsMaturesOn(String date) {
    return 'All paid. Matures $date';
  }

  @override
  String get dpsMaturityDate => 'Maturity date';

  @override
  String get dpsMaturityEstimate => 'Maturity value (app estimate)';

  @override
  String get dpsMaturityFromBank => 'Maturity value (from bank)';

  @override
  String get dpsMaturityNote =>
      'Assumes every installment is paid on time. Excise duty and bank charges are not included.';

  @override
  String get dpsMissedLimit => 'Missed installments in a row before closure';

  @override
  String get dpsMissedLimitHelper =>
      'Some banks use 3. Enter 0 if yours has no such rule.';

  @override
  String get dpsNetReceived => 'Amount received';

  @override
  String dpsNextDue(String date) {
    return 'Next installment: $date';
  }

  @override
  String get dpsNextInstallment => 'Next installment';

  @override
  String get dpsNoDeposits => 'No deposits recorded yet.';

  @override
  String get dpsNotFound => 'This DPS was not found.';

  @override
  String get dpsNote => 'Note (optional)';

  @override
  String dpsOneMoreWarning(int limit) {
    return 'One more missed installment reaches your bank\'s limit of $limit.';
  }

  @override
  String get dpsOpenDate => 'Opening date';

  @override
  String dpsOverdueWarning(int count, String amount) {
    return '$count installment(s) overdue: $amount';
  }

  @override
  String dpsPaidOf(int paid, int total) {
    return '$paid of $total installments paid';
  }

  @override
  String dpsPaidOn(String date) {
    return 'Paid $date';
  }

  @override
  String dpsPerMonth(String amount) {
    return '$amount per month';
  }

  @override
  String get dpsProfit => 'Profit';

  @override
  String get dpsProfitHelper => 'Before tax, from the bank\'s statement.';

  @override
  String get dpsRate => 'Yearly profit rate %';

  @override
  String get dpsRecordDeposit => 'Record deposit';

  @override
  String get dpsSchedule => 'Installment schedule';

  @override
  String get dpsSeparateLedgerNote =>
      'This does not change your account balances or budgets.';

  @override
  String get dpsShowArchived => 'Show archived';

  @override
  String get dpsStatusActive => 'Active';

  @override
  String get dpsStatusAtRisk => 'At risk';

  @override
  String get dpsStatusClosed => 'Closed';

  @override
  String get dpsStatusMatured => 'Matured';

  @override
  String get dpsStatusOverdue => 'Overdue';

  @override
  String get dpsSummaryDeposited => 'Deposited';

  @override
  String get dpsSummaryMonthly => 'Per month';

  @override
  String get dpsSummaryOpen => 'Open';

  @override
  String dpsSummaryOverdue(String amount) {
    return 'Overdue installments: $amount';
  }

  @override
  String get dpsTax => 'Tax deducted';

  @override
  String get dpsTaxHelper =>
      'Often 10% with a TIN and 15% without. Rules change, so confirm with your bank.';

  @override
  String get dpsTaxRate => 'Tax deducted from profit %';

  @override
  String get dpsTenureMonths => 'Term in months';

  @override
  String get dpsTitle => 'DPS (monthly savings)';

  @override
  String get dpsUnarchive => 'Unarchive';

  @override
  String get dpsVoid => 'Void';

  @override
  String get dpsVoidMessage => 'It stays in the history but no longer counts.';

  @override
  String get dpsVoidTitle => 'Void this deposit?';

  @override
  String get dpsVoided => 'Voided';

  @override
  String dpsYears(int years) {
    return '$years years';
  }

  @override
  String get fixedDepositsAdd => 'Add deposit';

  @override
  String get fixedDepositsAmountPositive => 'Amount must be greater than zero';

  @override
  String get fixedDepositsArchived => 'Archived';

  @override
  String get fixedDepositsBadgeReissued => 'Reissued';

  @override
  String get fixedDepositsBank => 'Bank';

  @override
  String get fixedDepositsBankRequired => 'Enter the bank name';

  @override
  String get fixedDepositsBeneficiary => 'Beneficiary name';

  @override
  String fixedDepositsCalculatedNet(String amount) {
    return 'Calculated net: $amount';
  }

  @override
  String get fixedDepositsClosedBanner => 'This deposit is closed (encashed).';

  @override
  String fixedDepositsClosedOn(String date) {
    return 'Closed on $date';
  }

  @override
  String get fixedDepositsClosingCharge => 'Bank charge';

  @override
  String get fixedDepositsClosingDate => 'Closing date';

  @override
  String get fixedDepositsClosingInterest => 'Interest received';

  @override
  String get fixedDepositsClosingTax => 'Tax deducted';

  @override
  String fixedDepositsDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get fixedDepositsEditDetails => 'Edit bank details';

  @override
  String get fixedDepositsEditInstrument => 'Edit instrument';

  @override
  String get fixedDepositsEditTitle => 'Edit deposit';

  @override
  String get fixedDepositsEmpty =>
      'No deposits yet. Tap + to add an FDR, DPS or savings certificate.';

  @override
  String get fixedDepositsEncash => 'Encash';

  @override
  String get fixedDepositsEncashNote =>
      'After encashing, this deposit is closed and its instrument can no longer be edited.';

  @override
  String get fixedDepositsEncashTitle => 'Encash deposit';

  @override
  String get fixedDepositsExpectedInterest => 'Expected interest';

  @override
  String get fixedDepositsExpectedNote =>
      'An estimate (simple interest on 365 days). You enter the bank figure when you close it.';

  @override
  String get fixedDepositsFinalNet => 'Final net received (optional)';

  @override
  String get fixedDepositsFinalNetHelper =>
      'Fill only if the bank paid a different amount.';

  @override
  String get fixedDepositsHistory => 'Instrument history';

  @override
  String fixedDepositsInstrumentNo(int no) {
    return 'Instrument #$no';
  }

  @override
  String get fixedDepositsInstrumentNumber => 'Instrument number';

  @override
  String get fixedDepositsInstrumentRequired => 'Enter the instrument number';

  @override
  String fixedDepositsInstrumentRow(String number) {
    return 'Instrument $number';
  }

  @override
  String fixedDepositsInterestHelper(int days) {
    return 'Suggested for $days days. Change it to the amount the bank paid.';
  }

  @override
  String get fixedDepositsInterestRate => 'Interest rate (% per year)';

  @override
  String get fixedDepositsInvalidAmount => 'Enter a valid amount';

  @override
  String get fixedDepositsInvalidRate => 'Enter a rate between 0 and 100';

  @override
  String get fixedDepositsInvalidTenure => 'Enter 1 to 36500 days';

  @override
  String get fixedDepositsIssueDate => 'Issue date';

  @override
  String get fixedDepositsListTitle => 'Fixed deposits';

  @override
  String fixedDepositsMaturedAgo(int days) {
    return 'Matured $days days ago';
  }

  @override
  String fixedDepositsMaturedAlert(int count) {
    return '$count matured: encash or reissue';
  }

  @override
  String get fixedDepositsMaturedBanner =>
      'This deposit has matured. Encash it or reissue it as a new instrument.';

  @override
  String get fixedDepositsMaturesToday => 'Matures today';

  @override
  String get fixedDepositsMaturityDate => 'Maturity date';

  @override
  String get fixedDepositsNetMustBePositive =>
      'Net received must be greater than zero to reissue';

  @override
  String get fixedDepositsNetReceived => 'Net received';

  @override
  String get fixedDepositsNewInstrument => 'New instrument';

  @override
  String get fixedDepositsNewInstrumentNumber => 'New instrument number';

  @override
  String fixedDepositsNewPrincipal(String amount) {
    return 'New principal = net received: $amount';
  }

  @override
  String fixedDepositsNextMaturity(String date, String amount) {
    return 'Next maturity $date • $amount';
  }

  @override
  String get fixedDepositsNotFound => 'Deposit not found.';

  @override
  String get fixedDepositsNote => 'Note';

  @override
  String get fixedDepositsOutcomeEncashed => 'Encashed';

  @override
  String get fixedDepositsOutcomeReissued => 'Reissued';

  @override
  String get fixedDepositsOutcomeRunning => 'Running';

  @override
  String get fixedDepositsPrincipal => 'Principal';

  @override
  String fixedDepositsRatePerYear(String rate) {
    return '$rate% per year';
  }

  @override
  String get fixedDepositsReissue => 'Reissue';

  @override
  String get fixedDepositsReissueDate => 'Reissue date';

  @override
  String get fixedDepositsReissueTitle => 'Reissue deposit';

  @override
  String fixedDepositsReissuedFrom(int no) {
    return 'Reissued from #$no';
  }

  @override
  String get fixedDepositsSchemeDps => 'DPS';

  @override
  String get fixedDepositsSchemeFdr => 'FDR';

  @override
  String get fixedDepositsSchemeRequired => 'Enter the scheme type';

  @override
  String get fixedDepositsSchemeSanchaypatra => 'Sanchaypatra';

  @override
  String get fixedDepositsSchemeType => 'Scheme type';

  @override
  String get fixedDepositsShowArchived => 'Show archived deposits';

  @override
  String get fixedDepositsStatusActive => 'Active';

  @override
  String get fixedDepositsStatusClosed => 'Closed';

  @override
  String get fixedDepositsStatusMatured => 'Matured';

  @override
  String get fixedDepositsSummaryInterest => 'Expected interest';

  @override
  String get fixedDepositsSummaryOpen => 'Open';

  @override
  String get fixedDepositsSummaryPlaced => 'Placed';

  @override
  String get fixedDepositsTenureDays => 'Tenure (days)';

  @override
  String fixedDepositsTenureHelper(String months) {
    return '≈ $months months (30 days = 1 month)';
  }

  @override
  String fixedDepositsTenureValue(int days, String months) {
    return '$days days (~$months months)';
  }

  @override
  String get fixedDepositsTitle => 'Deposit';

  @override
  String goalsAccountLine(String account) {
    return 'Account: $account';
  }

  @override
  String goalsAccountLineArchived(String account) {
    return 'Account: $account - archived';
  }

  @override
  String get goalsAchieved => 'Achieved';

  @override
  String get goalsAddGoal => 'Add goal';

  @override
  String get goalsArchiveGoal => 'Archive goal';

  @override
  String goalsArchiveMessage(String name) {
    return '\"$name\" will be hidden from your goals. Your account and transactions are not affected.';
  }

  @override
  String get goalsArchiveTitle => 'Archive goal?';

  @override
  String get goalsChooseAccount => 'Choose the account that holds the savings.';

  @override
  String get goalsClearDate => 'Clear date';

  @override
  String goalsDaysLeft(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left ($date)',
      one: '1 day left ($date)',
    );
    return '$_temp0';
  }

  @override
  String goalsDueToday(String date) {
    return 'Due today ($date)';
  }

  @override
  String get goalsEditGoal => 'Edit goal';

  @override
  String get goalsEmpty => 'No savings goals yet. Tap + to add one.';

  @override
  String get goalsGoalName => 'Goal name';

  @override
  String get goalsGoalReached => 'Goal reached';

  @override
  String get goalsInvalidAmount => 'Enter a valid amount (max 2 decimals)';

  @override
  String get goalsNameRequired => 'Name is required';

  @override
  String get goalsNoAccounts => 'No active accounts. Add an account first.';

  @override
  String get goalsNoDeadline => 'No deadline';

  @override
  String get goalsNoteOptional => 'Note (optional)';

  @override
  String goalsOverdueBy(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Overdue by $_temp0 ($date)';
  }

  @override
  String goalsProgressOf(String current, String target) {
    return '$current of $target';
  }

  @override
  String goalsRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String get goalsRestoreGoal => 'Restore goal';

  @override
  String goalsSavePerMonth(String amount) {
    return 'Save $amount / month';
  }

  @override
  String get goalsSavingsAccount => 'Savings account';

  @override
  String get goalsSelectProfile => 'Select a profile to manage goals.';

  @override
  String get goalsShowArchived => 'Show archived';

  @override
  String get goalsTargetAmount => 'Target amount';

  @override
  String goalsTargetDate(String date) {
    return 'Target date $date';
  }

  @override
  String get goalsTargetDateOptional => 'Target date (optional)';

  @override
  String get goalsTargetPositive => 'Target must be greater than zero';

  @override
  String get goalsTitle => 'Savings goals';

  @override
  String get importChooseFile => 'Choose CSV file';

  @override
  String get importColAmount => 'Amount *';

  @override
  String get importColCategory => 'Category';

  @override
  String get importColDate => 'Date *';

  @override
  String get importColDescription => 'Description';

  @override
  String get importColType => 'Type (expense/income)';

  @override
  String get importColTypeNone => 'Use the +/- sign of the amount';

  @override
  String importCouldNotRead(String error) {
    return 'Could not read that file: $error';
  }

  @override
  String get importDateFormat => 'Date format';

  @override
  String get importDefaultCategory => 'Default category for expenses';

  @override
  String get importDefaultCategoryHelp =>
      'Used when a row has no category or its name does not match an existing category exactly. Categories are never created automatically.';

  @override
  String get importDefaultCategoryNone =>
      'None (rows without a match are invalid)';

  @override
  String get importDelimiterTab => 'tab';

  @override
  String get importFinished => 'Import finished';

  @override
  String get importFirstRowHeader => 'First row is a header';

  @override
  String importImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String importImportRows(int count) {
    return 'Import $count rows';
  }

  @override
  String importImported(int count) {
    return 'Imported: $count';
  }

  @override
  String get importIntoAccount => 'Import into account *';

  @override
  String get importIntro =>
      'Import expenses and income from a bank or e-wallet CSV. Re-importing the same file never creates duplicates.';

  @override
  String get importInvalidNote =>
      'Invalid rows are skipped; the valid rows are imported all-or-nothing.';

  @override
  String importInvalidRows(int count) {
    return 'Invalid rows: $count';
  }

  @override
  String get importKindExpense => 'Expense';

  @override
  String get importKindIncome => 'Income';

  @override
  String get importNoDescription => '(no description)';

  @override
  String get importNotMapped => '(not mapped)';

  @override
  String importRowDuplicate(int number) {
    return 'Row $number: already imported';
  }

  @override
  String importRowInvalid(int number, String cells) {
    return 'Row $number: $cells';
  }

  @override
  String importRowValid(int number, String kind, String amount) {
    return 'Row $number: $kind $amount';
  }

  @override
  String importSkippedDuplicates(int count) {
    return 'Skipped duplicates: $count';
  }

  @override
  String get importStep1 => '1. Choose a file';

  @override
  String importStep2(int rows, String delimiter) {
    return '2. Map the columns  ($rows rows, delimiter \"$delimiter\")';
  }

  @override
  String get importStep3 => '3. Preview';

  @override
  String importSummary(int valid, int duplicate, int invalid, int shown) {
    return '$valid to import · $duplicate already imported · $invalid invalid (showing first $shown rows)';
  }

  @override
  String get importTitle => 'Import CSV';

  @override
  String insightsCategoryDown(String name, String amount, String percent) {
    return '$name is down $amount$percent vs last month';
  }

  @override
  String insightsCategoryNew(String name, String amount) {
    return '$name is new this month: $amount';
  }

  @override
  String insightsCategoryUp(String name, String amount, String percent) {
    return '$name is up $amount$percent vs last month';
  }

  @override
  String insightsForecastAtRisk(String projected, String budget) {
    return 'At risk: projected $projected is close to your $budget budget';
  }

  @override
  String insightsForecastDetail(String spent, String average, int days) {
    return 'Spent so far $spent · daily average $average · $days days left';
  }

  @override
  String insightsForecastNoBudget(String projected) {
    return 'Projected month-end spending: $projected (no budget set)';
  }

  @override
  String insightsForecastOnTrack(String projected, String budget) {
    return 'On track: projected $projected of your $budget budget';
  }

  @override
  String insightsForecastOver(String over, String projected, String budget) {
    return 'Projected to exceed your budget by $over ($projected vs $budget)';
  }

  @override
  String insightsForecastRecurring(String amount) {
    return 'Includes $amount of upcoming recurring expenses';
  }

  @override
  String get insightsForecastTitle => 'Month-end forecast';

  @override
  String get insightsNextMonth => 'Next month';

  @override
  String get insightsNoData => 'No spending data for this month yet.';

  @override
  String get insightsNoExpenses => 'No expenses this month.';

  @override
  String get insightsNoIncome => 'No income recorded this month.';

  @override
  String get insightsNothingUnusual => 'Nothing unusual this month.';

  @override
  String get insightsPreviousMonth => 'Previous month';

  @override
  String insightsSavingsOverspent(int percent) {
    return 'You spent $percent% more than you earned this month';
  }

  @override
  String get insightsSavingsRate => 'Savings rate';

  @override
  String insightsSavingsSaved(int percent) {
    return 'You saved $percent% of your income this month';
  }

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsTopItems => 'Top items this month';

  @override
  String insightsTotalDown(String amount, String percent) {
    return 'Total spending is down $amount$percent vs last month';
  }

  @override
  String insightsTotalNoPrevious(String amount) {
    return 'You spent $amount with no spending last month';
  }

  @override
  String get insightsTotalNone => 'No spending this month or last month';

  @override
  String get insightsTotalSame => 'Spending is the same as last month';

  @override
  String insightsTotalUp(String amount, String percent) {
    return 'Total spending is up $amount$percent vs last month';
  }

  @override
  String insightsUnusual(
    String amount,
    String label,
    String excess,
    String usual,
  ) {
    return 'Unusual: $amount on $label is $excess above your usual $usual';
  }

  @override
  String get insightsUnusualSpending => 'Unusual spending';

  @override
  String get insightsVsLastMonth => 'Vs last month';

  @override
  String get insightsWeekdayCardTitle => 'Spending by weekday (last 90 days)';

  @override
  String get insightsWeekdayMostFri => 'You spend the most on Fridays';

  @override
  String get insightsWeekdayMostMon => 'You spend the most on Mondays';

  @override
  String get insightsWeekdayMostSat => 'You spend the most on Saturdays';

  @override
  String get insightsWeekdayMostSun => 'You spend the most on Sundays';

  @override
  String get insightsWeekdayMostThu => 'You spend the most on Thursdays';

  @override
  String get insightsWeekdayMostTue => 'You spend the most on Tuesdays';

  @override
  String get insightsWeekdayMostWed => 'You spend the most on Wednesdays';

  @override
  String get ledgerAccount => 'Account';

  @override
  String ledgerAccountInactive(String name) {
    return '$name (inactive)';
  }

  @override
  String get ledgerAccountTab => 'Account Ledger';

  @override
  String get ledgerBudgetTab => 'Budget Ledger';

  @override
  String get ledgerClearSearch => 'Clear search';

  @override
  String get ledgerColBalance => 'Balance';

  @override
  String get ledgerColCategory => 'Category';

  @override
  String get ledgerColCostItem => 'Cost Item';

  @override
  String get ledgerColDate => 'Date';

  @override
  String get ledgerColDescription => 'Description';

  @override
  String get ledgerColExpense => 'Expense';

  @override
  String get ledgerColIncome => 'Income';

  @override
  String get ledgerColRemainingBudget => 'Remaining Budget';

  @override
  String get ledgerColTransferIn => 'Transfer In';

  @override
  String get ledgerColTransferOut => 'Transfer Out';

  @override
  String ledgerMonthlyBudget(String amount) {
    return 'Monthly budget: $amount';
  }

  @override
  String get ledgerNextMonth => 'Next month';

  @override
  String get ledgerNextYear => 'Next year';

  @override
  String get ledgerNoAccounts =>
      'No accounts yet. Add an account to see its ledger.';

  @override
  String get ledgerNoBudget => 'No budget';

  @override
  String get ledgerNoBudgetSet => 'No budget set for this month.';

  @override
  String get ledgerNoExpenses => 'No expenses in this month.';

  @override
  String get ledgerNoTransactions => 'No transactions in this period.';

  @override
  String get ledgerOpeningBalance => 'Opening Balance';

  @override
  String get ledgerPreviousMonth => 'Previous month';

  @override
  String get ledgerPreviousYear => 'Previous year';

  @override
  String get ledgerSearchHint => 'Search title, remarks, category, item';

  @override
  String get ledgerSelect => 'Select';

  @override
  String get ledgerTotal => 'Total';

  @override
  String get loansAdd => 'Add loan';

  @override
  String get loansAdjust => 'Adjust / top-up';

  @override
  String get loansAdjustHelper =>
      'The current loan is closed and a new loan replaces it. The amount is prefilled with the principal you still owe; add new money if you are topping up.';

  @override
  String get loansAdjustNewLoan => 'New loan';

  @override
  String get loansAdjustTitle => 'Adjust loan';

  @override
  String get loansAdjusted => 'Adjusted';

  @override
  String get loansAdjustedFromBanner =>
      'This loan replaced an earlier loan (adjustment).';

  @override
  String get loansAmount => 'Amount';

  @override
  String get loansAmountPaidToClose => 'Amount paid to close (optional)';

  @override
  String get loansAmountPositive => 'Amount must be greater than zero';

  @override
  String get loansArchived => 'Archived';

  @override
  String loansBalanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String loansBannerAdjusted(String date) {
    return 'Adjusted on $date: replaced by a new loan';
  }

  @override
  String loansBannerEarly(String date) {
    return 'Closed early on $date';
  }

  @override
  String loansBannerPaid(String amount) {
    return 'Paid to close: $amount';
  }

  @override
  String loansBannerRemarks(String remarks) {
    return 'Remarks: $remarks';
  }

  @override
  String get loansCloseEarly => 'Close early';

  @override
  String get loansCloseEarlyNote =>
      'The rest of the schedule is waived and the loan becomes history. An amount you enter is recorded as a payment on the closing date.';

  @override
  String get loansCloseEarlyTitle => 'Close loan early';

  @override
  String get loansClosedEarly => 'Early closed';

  @override
  String get loansClosedMessage => 'Loan fully paid';

  @override
  String get loansClosingDate => 'Closing date';

  @override
  String get loansClosingRemarks => 'Remarks';

  @override
  String loansDueOn(String date) {
    return 'Due on $date. Pick the date you actually paid.';
  }

  @override
  String get loansEdit => 'Edit loan';

  @override
  String get loansEmpty => 'No loans yet. Tap + to add a bank loan.';

  @override
  String get loansFirstDueDate => 'First installment date';

  @override
  String get loansFreqMonthly => 'Monthly';

  @override
  String get loansFreqWeekly => 'Weekly';

  @override
  String get loansFreqYearly => 'Yearly';

  @override
  String get loansFrequency => 'Repayment frequency';

  @override
  String get loansInstDue => 'Due';

  @override
  String get loansInstOverdue => 'Overdue';

  @override
  String get loansInstPaid => 'Paid';

  @override
  String get loansInstPartial => 'Partial';

  @override
  String get loansInstallment => 'Installment per period';

  @override
  String loansInstallmentHelper(String amount) {
    return 'Calculated: $amount. Leave empty to use it, or type the figure from your bank.';
  }

  @override
  String loansInstallmentNo(int no) {
    return 'Installment $no';
  }

  @override
  String get loansInterestMethod => 'Interest method';

  @override
  String get loansInterestPart => 'Interest';

  @override
  String get loansInterestRate => 'Annual interest rate (%)';

  @override
  String get loansInvalidAmount => 'Enter a valid amount';

  @override
  String get loansInvalidRate => 'Enter a rate between 0 and 100';

  @override
  String get loansInvalidTenure => 'Enter 1 to 1200 installments';

  @override
  String get loansLender => 'Bank / lender name';

  @override
  String get loansLenderRequired => 'Enter the bank or lender name';

  @override
  String get loansListTitle => 'Loans';

  @override
  String loansMarkInstallmentPaid(int no) {
    return 'Mark installment $no as paid';
  }

  @override
  String get loansMarkPaid => 'Mark paid';

  @override
  String loansMaxAmount(String max) {
    return 'Maximum is $max';
  }

  @override
  String get loansMethodFlat => 'Flat rate';

  @override
  String get loansMethodReducing => 'Reducing balance';

  @override
  String get loansMonthlyCommitment => 'Per month';

  @override
  String loansNextDueRow(String date, String amount) {
    return 'Next due $date • $amount';
  }

  @override
  String get loansNoPayments => 'No payments recorded yet.';

  @override
  String get loansNotFound => 'Loan not found.';

  @override
  String get loansNote => 'Note';

  @override
  String get loansOverdue => 'Overdue';

  @override
  String loansOverdueSummary(int count, String amount) {
    return '$count overdue installments • $amount';
  }

  @override
  String loansPaidOfAmount(String paid, String total) {
    return '$paid of $total paid';
  }

  @override
  String loansPaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get loansPaidSoFar => 'Paid so far';

  @override
  String get loansPaymentDate => 'Payment date';

  @override
  String get loansPayments => 'Payments';

  @override
  String loansPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String loansPerWeek(String amount) {
    return '$amount / week';
  }

  @override
  String loansPerYear(String amount) {
    return '$amount / year';
  }

  @override
  String get loansPrincipal => 'Loan amount (principal)';

  @override
  String get loansPrincipalPart => 'Principal';

  @override
  String get loansProcessingFee => 'Processing fee (optional)';

  @override
  String loansProgressPercent(int percent) {
    return '$percent% repaid';
  }

  @override
  String loansRatePerYear(String rate) {
    return '$rate% per year';
  }

  @override
  String get loansRecordPayment => 'Record payment';

  @override
  String get loansReferenceNo => 'Loan account / reference no. (optional)';

  @override
  String get loansRemaining => 'Remaining';

  @override
  String loansRemainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get loansRemainingInstallments => 'Remaining installments';

  @override
  String get loansRemainingInterest => 'Remaining interest';

  @override
  String get loansRemainingPrincipal => 'Remaining principal';

  @override
  String get loansSchedule => 'Schedule';

  @override
  String get loansShowArchived => 'Show archived loans';

  @override
  String get loansStartDate => 'Disbursement date';

  @override
  String get loansStatusActive => 'Active';

  @override
  String get loansStatusClosed => 'Closed';

  @override
  String get loansStatusOverdue => 'Overdue';

  @override
  String get loansTenure => 'Number of installments';

  @override
  String loansTenureApprox(int years, int months) {
    return '≈ $years years $months months';
  }

  @override
  String loansTenureValue(int count, String frequency) {
    return '$count installments ($frequency)';
  }

  @override
  String get loansTermsLocked =>
      'Payments are recorded. You can still change the interest rate and installment (for a rate revision); other terms are locked. Void the payments to change them.';

  @override
  String get loansTitle => 'Loan';

  @override
  String get loansTotalCost => 'Total cost (with fee)';

  @override
  String get loansTotalInterest => 'Total interest';

  @override
  String get loansTotalPayable => 'Total payable';

  @override
  String get loansTotalRemaining => 'Remaining';

  @override
  String get loansType => 'Loan type';

  @override
  String get loansTypeBusiness => 'Business loan';

  @override
  String get loansTypeEducation => 'Education loan';

  @override
  String get loansTypeHome => 'Home loan';

  @override
  String get loansTypeOther => 'Other loan';

  @override
  String get loansTypePersonal => 'Personal loan';

  @override
  String get loansTypeVehicle => 'Vehicle loan';

  @override
  String get loansUnarchive => 'Unarchive';

  @override
  String get loansViewPrevious => 'View the previous loan';

  @override
  String get loansViewReplacement => 'View the new loan';

  @override
  String get loansVoid => 'Void';

  @override
  String loansVoidMessage(String amount) {
    return 'Void the payment of $amount? The remaining balance will be recalculated.';
  }

  @override
  String get loansVoidPayment => 'Void payment';

  @override
  String get loansVoided => 'Voided';

  @override
  String get notificationsBudgetAlerts => 'Budget alerts';

  @override
  String get notificationsBudgetAlertsSubtitle =>
      'Warn me at 80% and when I go over a budget';

  @override
  String get notificationsBudgetSound => 'Budget alert sound';

  @override
  String notificationsBudgetWarningBody(String spent, String budget) {
    return 'You have used 80% of your budget ($spent of $budget).';
  }

  @override
  String notificationsBudgetWarningTitle(String label) {
    return 'Budget warning: $label';
  }

  @override
  String notificationsCardName(String card) {
    return '$card card bill';
  }

  @override
  String get notificationsCategoryFallback => 'Category';

  @override
  String get notificationsCollectTitle => 'Money to collect';

  @override
  String notificationsDaysAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days after',
      one: '1 day after',
    );
    return '$_temp0';
  }

  @override
  String notificationsDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String notificationsDebtBorrowedName(String person) {
    return 'Debt to $person';
  }

  @override
  String get notificationsDebtDueTitle => 'Debt payment due';

  @override
  String notificationsDebtLentName(String person) {
    return '$person (to collect)';
  }

  @override
  String notificationsDpsName(String bank, int number) {
    return '$bank DPS installment #$number';
  }

  @override
  String notificationsDueInDays(
    String title,
    String amount,
    int days,
    String date,
  ) {
    return '$title ($amount) is due in $days days ($date).';
  }

  @override
  String notificationsDueToday(String title, String amount) {
    return '$title ($amount) is due today.';
  }

  @override
  String notificationsDueTomorrow(String title, String amount) {
    return '$title ($amount) is due tomorrow.';
  }

  @override
  String get notificationsExpireReminder => 'Remind once after it expires';

  @override
  String get notificationsExpireReminderSubtitle =>
      'One reminder if it is still unpaid after the date';

  @override
  String notificationsFdrBodyToday(
    String scheme,
    String number,
    String bank,
    String amount,
  ) {
    return '$scheme $number of $bank matures today. Principal $amount.';
  }

  @override
  String notificationsFdrBodyTomorrow(
    String scheme,
    String number,
    String bank,
    String amount,
  ) {
    return '$scheme $number of $bank matures tomorrow. Principal $amount.';
  }

  @override
  String notificationsFdrBodyUpcoming(
    String scheme,
    String number,
    String bank,
    int days,
    String date,
    String amount,
  ) {
    return '$scheme $number of $bank matures in $days days ($date). Principal $amount.';
  }

  @override
  String notificationsFdrTitle(String scheme) {
    return '$scheme maturing';
  }

  @override
  String notificationsFiresAt(String when) {
    return 'Notifies on $when';
  }

  @override
  String notificationsFiresAtOff(String when) {
    return 'Switched off ($when)';
  }

  @override
  String notificationsItemExpiredBody(String name, String amount, String date) {
    return '$name ($amount) was due on $date and is still unpaid.';
  }

  @override
  String notificationsItemExpiredTitle(String name) {
    return 'Overdue: $name';
  }

  @override
  String notificationsItemTodayBody(String name, String amount) {
    return '$name ($amount) is due today.';
  }

  @override
  String notificationsItemTodayTitle(String name) {
    return 'Due today: $name';
  }

  @override
  String notificationsItemUpcomingBody(
    String name,
    String amount,
    int days,
    String date,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$name ($amount) is due in $_temp0 ($date). Get ready.';
  }

  @override
  String notificationsItemUpcomingTitle(String name) {
    return 'Upcoming: $name';
  }

  @override
  String notificationsLoanName(String lender, int no) {
    return '$lender installment #$no';
  }

  @override
  String get notificationsMonthlyBudget => 'Monthly budget';

  @override
  String get notificationsOff => 'Off';

  @override
  String notificationsOverBudgetBody(String spent, String budget) {
    return 'You have spent $spent of $budget this month and are over budget.';
  }

  @override
  String notificationsOverBudgetTitle(String label) {
    return 'Over budget: $label';
  }

  @override
  String notificationsOwesYouToday(String person, String amount) {
    return '$person owes you $amount, due today.';
  }

  @override
  String notificationsOwesYouTomorrow(String person, String amount) {
    return '$person owes you $amount, due tomorrow.';
  }

  @override
  String get notificationsPermissionDenied =>
      'Notification permission was denied. Allow notifications for MyBudget in the system settings, then turn this on again.';

  @override
  String get notificationsPhaseExpired => 'Expired';

  @override
  String get notificationsPhaseToday => 'Due day';

  @override
  String get notificationsPhaseUpcoming => 'Upcoming';

  @override
  String get notificationsPickDays => 'Number of days';

  @override
  String get notificationsReminderSound => 'Reminder sound';

  @override
  String get notificationsReminderTime => 'Reminder time';

  @override
  String get notificationsReminders => 'Bill & debt reminders';

  @override
  String get notificationsRemindersSubtitle =>
      'Remind me before recurring bills and debt due dates';

  @override
  String get notificationsScheduleEmpty =>
      'No upcoming reminders. Add a due date to a loan, card bill, debt or recurring task.';

  @override
  String get notificationsScheduleOffBanner =>
      'Reminders are switched off, so none of these will be delivered. Turn them on in Notification settings.';

  @override
  String get notificationsSendTest => 'Send test notification';

  @override
  String get notificationsSoundCustom => 'Custom sound';

  @override
  String get notificationsSoundDefault => 'Default';

  @override
  String get notificationsSoundSilent => 'Silent';

  @override
  String get notificationsTestBody => 'Notifications are working.';

  @override
  String get notificationsTestDenied => 'Permission denied - cannot send';

  @override
  String get notificationsTestSent => 'Test notification sent';

  @override
  String get notificationsTestTitle => 'MyBudget test notification';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTodayReminder => 'Remind on the due day';

  @override
  String get notificationsTodayReminderSubtitle =>
      'A notification on the day an installment, bill or task is due';

  @override
  String get notificationsUpcomingReminder => 'Remind before the due date';

  @override
  String notificationsUpcomingTitle(String title) {
    return 'Upcoming: $title';
  }

  @override
  String get notificationsViewSchedule => 'Notification schedule';

  @override
  String get notificationsViewScheduleSubtitle =>
      'See when each reminder will fire and switch single ones off';

  @override
  String notificationsYouOweToday(String person, String amount) {
    return 'You owe $person $amount, due today.';
  }

  @override
  String notificationsYouOweTomorrow(String person, String amount) {
    return 'You owe $person $amount, due tomorrow.';
  }

  @override
  String get preferencesLanguage => 'Language';

  @override
  String get preferencesLanguageSystem => 'System default';

  @override
  String get preferencesTheme => 'Theme';

  @override
  String get preferencesThemeDark => 'Dark';

  @override
  String get preferencesThemeLight => 'Light';

  @override
  String get preferencesThemeSystem => 'System';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get profilesCurrencyLabel => 'Currency';

  @override
  String get profilesDeactivate => 'Deactivate';

  @override
  String profilesDeactivateMessage(String name) {
    return '\"$name\" will be hidden from selection. No data is deleted and you can reactivate it anytime.';
  }

  @override
  String get profilesDeactivateTitle => 'Deactivate profile?';

  @override
  String get profilesEmpty => 'No profiles yet.\nCreate one to get started.';

  @override
  String profilesInactiveSubtitle(String currency) {
    return '$currency - Inactive';
  }

  @override
  String get profilesNameLabel => 'Profile name';

  @override
  String get profilesNameRequired => 'Name is required';

  @override
  String get profilesNew => 'New profile';

  @override
  String get profilesReactivate => 'Reactivate';

  @override
  String profilesReactivateMessage(String name) {
    return '\"$name\" will be available again.';
  }

  @override
  String get profilesReactivateTitle => 'Reactivate profile?';

  @override
  String get profilesSelectTitle => 'Select profile';

  @override
  String get recurringAddTooltip => 'Add recurring rule';

  @override
  String get recurringClearEndDate => 'Clear end date';

  @override
  String get recurringCreateRule => 'Create rule';

  @override
  String recurringDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '$count day before',
    );
    return '$_temp0';
  }

  @override
  String get recurringDifferentAccount => 'Choose a different account';

  @override
  String get recurringEmpty => 'No recurring rules yet. Tap + to add one.';

  @override
  String get recurringEnterAmount => 'Enter a valid amount';

  @override
  String get recurringEnterIncomeSource => 'Enter an income source';

  @override
  String get recurringEnterTitle => 'Enter a title';

  @override
  String recurringEveryN(String frequency, int count) {
    return '$frequency (every $count)';
  }

  @override
  String get recurringFieldAccount => 'Account';

  @override
  String get recurringFieldAmount => 'Amount';

  @override
  String get recurringFieldCategory => 'Category';

  @override
  String get recurringFieldCostItem => 'Cost item (optional)';

  @override
  String get recurringFieldEndDate => 'End date (optional)';

  @override
  String get recurringFieldEveryN => 'Every N';

  @override
  String get recurringFieldFrequency => 'Frequency';

  @override
  String get recurringFieldFromAccount => 'From account';

  @override
  String get recurringFieldIncomeSource => 'Income source';

  @override
  String get recurringFieldRemarks => 'Remarks (optional)';

  @override
  String get recurringFieldReminder => 'Reminder';

  @override
  String get recurringFieldStartDate => 'Start date';

  @override
  String get recurringFieldSubCategory => 'Sub-category (optional)';

  @override
  String get recurringFieldTitle => 'Title';

  @override
  String get recurringFieldToAccount => 'To account';

  @override
  String get recurringFormEdit => 'Edit recurring rule';

  @override
  String get recurringFormNew => 'New recurring rule';

  @override
  String get recurringFreqDaily => 'Daily';

  @override
  String get recurringFreqMonthly => 'Monthly';

  @override
  String get recurringFreqWeekly => 'Weekly';

  @override
  String get recurringFreqYearly => 'Yearly';

  @override
  String get recurringMin1 => 'Min 1';

  @override
  String get recurringNoEnd => 'No end';

  @override
  String get recurringNoProfile =>
      'Select a profile to manage recurring transactions.';

  @override
  String get recurringNoReminder => 'No reminder';

  @override
  String get recurringOnTheDay => 'On the day';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringReminderDefault => 'Default (notification settings)';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringSaveChanges => 'Save changes';

  @override
  String get recurringSelectAccount => 'Select an account';

  @override
  String get recurringSelectCategory => 'Select a category';

  @override
  String get recurringSelectDestination => 'Select a destination';

  @override
  String get recurringStatusEnded => 'Ended';

  @override
  String recurringStatusNext(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringStatusPaused => 'Paused';

  @override
  String get recurringTitle => 'Recurring transactions';

  @override
  String get recurringTypeExpense => 'Expense';

  @override
  String get recurringTypeIncome => 'Income';

  @override
  String get recurringTypeTransfer => 'Transfer';

  @override
  String get reportsAccount => 'Account';

  @override
  String reportsAccountFlow(
    String name,
    String income,
    String expense,
    String transferIn,
    String transferOut,
  ) {
    return '$name\n+$income  -$expense  in $transferIn  out $transferOut';
  }

  @override
  String get reportsAccountMovements => 'Account movements';

  @override
  String get reportsAmount => 'Amount';

  @override
  String get reportsAvgMonthlyExpense => 'Avg monthly expense';

  @override
  String get reportsBudget => 'Budget';

  @override
  String get reportsCategory => 'Category';

  @override
  String get reportsCategoryComparison => 'Category comparison';

  @override
  String get reportsCategoryWiseExpense => 'Category-wise expense';

  @override
  String get reportsClosing => 'Closing';

  @override
  String get reportsCustomRange => 'Custom range';

  @override
  String get reportsCustomRangeReport => 'Custom range report';

  @override
  String get reportsCustomRangeSubtitle => 'Pick any start and end date';

  @override
  String get reportsDailyExpenditure => 'Daily expenditure';

  @override
  String get reportsExpense => 'Expense';

  @override
  String get reportsExportCsv => 'Export CSV';

  @override
  String reportsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get reportsExportPdf => 'Export PDF';

  @override
  String get reportsHighestMonth => 'Highest month';

  @override
  String get reportsIncome => 'Income';

  @override
  String get reportsIncomeVsExpense => 'Income vs expense';

  @override
  String get reportsItem => 'Item';

  @override
  String get reportsItems => 'Items';

  @override
  String get reportsLowestMonth => 'Lowest month';

  @override
  String get reportsMonth => 'Month';

  @override
  String get reportsMonth01Full => 'January';

  @override
  String get reportsMonth01Short => 'Jan';

  @override
  String get reportsMonth02Full => 'February';

  @override
  String get reportsMonth02Short => 'Feb';

  @override
  String get reportsMonth03Full => 'March';

  @override
  String get reportsMonth03Short => 'Mar';

  @override
  String get reportsMonth04Full => 'April';

  @override
  String get reportsMonth04Short => 'Apr';

  @override
  String get reportsMonth05Full => 'May';

  @override
  String get reportsMonth05Short => 'May';

  @override
  String get reportsMonth06Full => 'June';

  @override
  String get reportsMonth06Short => 'Jun';

  @override
  String get reportsMonth07Full => 'July';

  @override
  String get reportsMonth07Short => 'Jul';

  @override
  String get reportsMonth08Full => 'August';

  @override
  String get reportsMonth08Short => 'Aug';

  @override
  String get reportsMonth09Full => 'September';

  @override
  String get reportsMonth09Short => 'Sep';

  @override
  String get reportsMonth10Full => 'October';

  @override
  String get reportsMonth10Short => 'Oct';

  @override
  String get reportsMonth11Full => 'November';

  @override
  String get reportsMonth11Short => 'Nov';

  @override
  String get reportsMonth12Full => 'December';

  @override
  String get reportsMonth12Short => 'Dec';

  @override
  String get reportsMonthlyComparison => 'Monthly comparison';

  @override
  String get reportsMonthlyReport => 'Monthly report';

  @override
  String get reportsMonthlyReportSubtitle =>
      'Income, expense, budget, categories, daily spending';

  @override
  String get reportsNet => 'Net';

  @override
  String get reportsNext => 'Next';

  @override
  String get reportsNoData => 'No data';

  @override
  String get reportsNoDataMonth => 'No data for this month.';

  @override
  String get reportsNoDataYear => 'No data for this year.';

  @override
  String get reportsNoExpensesMonth => 'No expenses this month.';

  @override
  String get reportsNoExpensesRange => 'No expenses in this range.';

  @override
  String get reportsNoTransactionsRange => 'No transactions in this range.';

  @override
  String get reportsNotSet => 'Not set';

  @override
  String get reportsOpening => 'Opening';

  @override
  String get reportsOverBudget => 'Over budget';

  @override
  String get reportsPrevious => 'Previous';

  @override
  String get reportsPrint => 'Print';

  @override
  String reportsRangeFromTo(String from, String to) {
    return '$from  to  $to';
  }

  @override
  String get reportsRemaining => 'Remaining';

  @override
  String get reportsSelectDayHelp => 'Select any day in the month';

  @override
  String get reportsSelectYear => 'Select year';

  @override
  String get reportsSubCategories => 'Sub-categories';

  @override
  String get reportsSubCategory => 'Sub-category';

  @override
  String get reportsTotal => 'Total';

  @override
  String get reportsTransactions => 'Transactions';

  @override
  String get reportsTxnComment => 'Comment';

  @override
  String get reportsTxnTitle => 'Title';

  @override
  String get reportsUtilization => 'Utilization';

  @override
  String get reportsYearlyReport => 'Yearly report';

  @override
  String get reportsYearlyReportSubtitle =>
      'All 12 months, comparison, highest and lowest month';

  @override
  String get searchChipAccount => 'Account';

  @override
  String get searchChipCategory => 'Category';

  @override
  String searchChipFrom(String date) {
    return 'From $date';
  }

  @override
  String searchChipTag(String name) {
    return '#$name';
  }

  @override
  String searchChipTo(String date) {
    return 'To $date';
  }

  @override
  String get searchClearAll => 'Clear all';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get searchClearText => 'Clear text';

  @override
  String get searchEmptyHint =>
      'Search by title, remarks, category, account, tag…';

  @override
  String get searchErrDateOrder => 'From date is after to date';

  @override
  String get searchErrInvalidMax => 'Invalid maximum amount';

  @override
  String get searchErrInvalidMin => 'Invalid minimum amount';

  @override
  String get searchErrMinGreater => 'Minimum is greater than maximum';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchFrom => 'From';

  @override
  String get searchHint => 'Search transactions';

  @override
  String get searchMax => 'Max';

  @override
  String get searchMin => 'Min';

  @override
  String get searchNoResults => 'No matching transactions.';

  @override
  String get searchNoneAvailable => 'None available';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchRemove => 'Remove';

  @override
  String get searchReset => 'Reset';

  @override
  String get searchResults => 'Results';

  @override
  String get searchSectionAccounts => 'Accounts';

  @override
  String get searchSectionAmount => 'Amount';

  @override
  String get searchSectionCategories => 'Categories';

  @override
  String get searchSectionDateRange => 'Date range';

  @override
  String get searchSectionSortBy => 'Sort by';

  @override
  String get searchSectionTags => 'Tags';

  @override
  String get searchSectionType => 'Type';

  @override
  String get searchSortHighest => 'Highest';

  @override
  String get searchSortLowest => 'Lowest';

  @override
  String get searchSortNewest => 'Newest';

  @override
  String get searchSortOldest => 'Oldest';

  @override
  String get searchTagFallback => 'tag';

  @override
  String get searchTo => 'To';

  @override
  String get searchTypeExpense => 'Expense';

  @override
  String get searchTypeIncome => 'Income';

  @override
  String get searchTypeTransfer => 'Transfer';

  @override
  String get securityAppLock => 'App lock';

  @override
  String get securityAppLockSubtitle => 'Require a PIN to open MyBudget';

  @override
  String get securityAutoLock => 'Auto-lock';

  @override
  String get securityAutoLockSubtitle =>
      'Lock after the app is in the background';

  @override
  String get securityBiometric => 'Unlock with biometrics';

  @override
  String get securityBiometricConfirm => 'Confirm to enable biometric unlock';

  @override
  String get securityBiometricUnlock => 'Unlock MyBudget';

  @override
  String get securityChangePin => 'Change PIN';

  @override
  String get securityConfirmNewPinLabel => 'Confirm new PIN';

  @override
  String get securityConfirmPinLabel => 'Confirm PIN';

  @override
  String get securityCurrentPinLabel => 'Current PIN';

  @override
  String get securityDelay1m => 'After 1 minute';

  @override
  String get securityDelay30s => 'After 30 seconds';

  @override
  String get securityDelay5m => 'After 5 minutes';

  @override
  String get securityDelayImmediately => 'Immediately';

  @override
  String get securityEnterPin => 'Enter PIN to unlock';

  @override
  String get securityForgotPin => 'Forgot PIN?';

  @override
  String get securityIncorrectPin => 'Incorrect PIN.';

  @override
  String get securityIncorrectPinShort => 'Incorrect PIN';

  @override
  String securityLockout(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String securityLockoutShort(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s';
  }

  @override
  String get securityNewPinLabel => 'New PIN (4-6 digits)';

  @override
  String get securityNewPinsMismatch => 'New PINs do not match.';

  @override
  String get securityNewRecoveryCode => 'New recovery code';

  @override
  String get securityNewRecoveryCodeSubtitle => 'Replaces your old code';

  @override
  String get securityNotEnabled => 'App lock is not enabled.';

  @override
  String get securityPinChanged => 'PIN changed';

  @override
  String get securityPinInvalid => 'PIN must be 4 to 6 digits.';

  @override
  String get securityPinsMismatch => 'PINs do not match.';

  @override
  String get securityRecoverAction => 'Reset';

  @override
  String get securityRecoverBody =>
      'Enter your recovery code. App lock will be turned off, and you can set a new PIN in Settings > Security.';

  @override
  String get securityRecoverCancel => 'Back';

  @override
  String get securityRecoverInvalid => 'That recovery code is not correct.';

  @override
  String get securityRecoverLabel => 'Recovery code';

  @override
  String get securityRecoverTitle => 'Reset with recovery code';

  @override
  String get securityRecoveryBody =>
      'If you forget your PIN, this code is the only way back in. Write it down and keep it somewhere safe. It is shown only once.';

  @override
  String get securityRecoveryCopied => 'Code copied';

  @override
  String get securityRecoveryCopy => 'Copy';

  @override
  String get securityRecoverySaved => 'I have saved it';

  @override
  String get securityRecoveryTitle => 'Your recovery code';

  @override
  String get securitySetPin => 'Set PIN';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityTurnOff => 'Turn off app lock';

  @override
  String get setupAllDone => 'All set! You are ready to use MyBudget.';

  @override
  String get setupCardAction => 'Continue';

  @override
  String get setupCardTitle => 'Finish setting up';

  @override
  String get setupDismiss => 'Hide this guide';

  @override
  String get setupDone => 'Done';

  @override
  String get setupGo => 'Go';

  @override
  String get setupOpenManual => 'Read the user manual';

  @override
  String setupProgress(int done, int total) {
    return '$done of $total steps done';
  }

  @override
  String get setupStepAccount => 'Add an account';

  @override
  String get setupStepAccountBody =>
      'Where your money sits, such as Cash or a bank. Enter its opening balance.';

  @override
  String get setupStepBudget => 'Set this month\'s budget';

  @override
  String get setupStepBudgetBody => 'How much you plan to spend this month.';

  @override
  String get setupStepCategory => 'Create a category';

  @override
  String get setupStepCategoryBody =>
      'For example Food or Transport. Sub-categories and items can come later.';

  @override
  String get setupStepTransaction => 'Record your first transaction';

  @override
  String get setupStepTransactionBody => 'Add an expense or some income.';

  @override
  String get setupTitle => 'Getting started';

  @override
  String get splitAccount => 'Account';

  @override
  String get splitAddLine => 'Add line';

  @override
  String get splitAmount => 'Amount';

  @override
  String get splitBillTitle => 'Title (optional)';

  @override
  String get splitCategory => 'Category';

  @override
  String get splitCostItem => 'Cost item (optional)';

  @override
  String get splitErrAccount => 'Choose an account.';

  @override
  String get splitErrLine =>
      'Every line needs a category and an amount greater than zero.';

  @override
  String get splitIntro =>
      'Use this when one bill covers several categories, for example groceries and household items. Each line is saved as its own expense, all together or not at all.';

  @override
  String splitLine(int n) {
    return 'Line $n';
  }

  @override
  String get splitOpen => 'Split a bill';

  @override
  String get splitRemoveLine => 'Remove line';

  @override
  String get splitSave => 'Save split';

  @override
  String splitSaved(int n) {
    return '$n expenses saved';
  }

  @override
  String get splitSubCategory => 'Sub-category (optional)';

  @override
  String get splitTitle => 'Split a bill';

  @override
  String splitTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String subCategoriesActivateMessage(String name) {
    return '\"$name\" will be available again.';
  }

  @override
  String get subCategoriesActivateTitle => 'Activate sub-category?';

  @override
  String get subCategoriesAdd => 'Add sub-category';

  @override
  String get subCategoriesCategoryLabel => 'Category';

  @override
  String subCategoriesDeactivateMessage(String name) {
    return '\"$name\" will be hidden from new entries. Existing data is kept.';
  }

  @override
  String get subCategoriesDeactivateTitle => 'Deactivate sub-category?';

  @override
  String get subCategoriesEdit => 'Edit sub-category';

  @override
  String get subCategoriesEmpty => 'No sub-categories found.';

  @override
  String subCategoriesInactiveSubtitle(String category) {
    return '$category - inactive';
  }

  @override
  String subCategoriesLoadError(String error) {
    return 'Could not load sub-categories: $error';
  }

  @override
  String get subCategoriesNameLabel => 'Name';

  @override
  String get subCategoriesNameRequired => 'Name is required';

  @override
  String get subCategoriesSearchHint => 'Search sub-categories';

  @override
  String get subCategoriesSelectCategory => 'Select a category';

  @override
  String get subCategoriesSelectProfile => 'Select a profile first.';

  @override
  String get subCategoriesShowInactive => 'Show inactive';

  @override
  String get subCategoriesTitle => 'Sub-categories';

  @override
  String get tagsAdd => 'Add tag';

  @override
  String tagsArchiveMessage(String name) {
    return '\"$name\" stays on old transactions but can no longer be added to new ones.';
  }

  @override
  String get tagsArchiveTitle => 'Archive tag';

  @override
  String get tagsArchived => 'Archived';

  @override
  String tagsDateRange(String from, String to) {
    return '$from  to  $to';
  }

  @override
  String get tagsEdit => 'Edit tag';

  @override
  String get tagsEmpty => 'No tags yet. Tap + to create one.';

  @override
  String get tagsHideArchived => 'Hide archived';

  @override
  String get tagsName => 'Name';

  @override
  String get tagsNameRequired => 'Tag name is required.';

  @override
  String get tagsNew => 'New tag';

  @override
  String get tagsNewName => 'New tag name';

  @override
  String get tagsReportEmpty => 'No tagged transactions in this range.';

  @override
  String get tagsReportTitle => 'Tag report';

  @override
  String get tagsShowArchived => 'Show archived';

  @override
  String get tagsTitle => 'Tags';

  @override
  String tagsTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
    );
    return '$_temp0';
  }

  @override
  String get transactionsAccount => 'Account';

  @override
  String get transactionsAddExchangeRates => 'Add exchange rates';

  @override
  String get transactionsAmount => 'Amount';

  @override
  String get transactionsAmountPositive => 'Amount must be greater than zero';

  @override
  String get transactionsAuditCreated => 'Created';

  @override
  String get transactionsAuditDeleted => 'Deleted';

  @override
  String get transactionsAuditEdited => 'Edited';

  @override
  String get transactionsAuditRestored => 'Restored';

  @override
  String get transactionsCalculator => 'Calculator';

  @override
  String get transactionsCannotConvertSave =>
      'This amount cannot be converted at the selected rate (it rounds to zero or is too large). Change the amount or rate.';

  @override
  String get transactionsCategory => 'Category';

  @override
  String transactionsChangeAmount(String from, String to) {
    return 'amount: $from → $to';
  }

  @override
  String transactionsChangeGeneric(String field, String from, String to) {
    return '$field: $from → $to';
  }

  @override
  String transactionsChangeOriginalAmount(String from, String to) {
    return 'original amount: $from → $to';
  }

  @override
  String transactionsChangeOriginalCurrency(String from, String to) {
    return 'original currency: $from → $to';
  }

  @override
  String transactionsChangeRate(String from, String to) {
    return 'rate: $from → $to';
  }

  @override
  String get transactionsChooseDifferentAccount => 'Choose a different account';

  @override
  String get transactionsConvertFail =>
      'Amount cannot be converted (rounds to zero or too large).';

  @override
  String transactionsConvertedLine(String amount, String code, String rate) {
    return '= $amount at 1 $code = $rate';
  }

  @override
  String get transactionsCostItem => 'Cost item';

  @override
  String get transactionsCostItemOptional => 'Cost item (optional)';

  @override
  String get transactionsDate => 'Date';

  @override
  String get transactionsDeleteMessage =>
      'This transaction will be removed from balances, budgets and reports. You can undo this.';

  @override
  String get transactionsDeleteTitle => 'Delete transaction?';

  @override
  String get transactionsDeleteTransferMessage =>
      'This transfer will be removed from both accounts. You can undo this.';

  @override
  String get transactionsDeleted => 'Transaction deleted';

  @override
  String get transactionsDeletedCannotEdit =>
      'This transaction is deleted. Restore it to edit.';

  @override
  String get transactionsDescription => 'Description';

  @override
  String get transactionsDetailTitle => 'Transaction';

  @override
  String get transactionsEditTitle => 'Edit transaction';

  @override
  String get transactionsEnterAmount => 'Enter an amount';

  @override
  String get transactionsEnterIncomeSource => 'Enter an income source';

  @override
  String get transactionsExcludedNote =>
      'It is excluded from balances, budgets and reports.';

  @override
  String transactionsExtrasWarning(String problems) {
    return 'Warning: $problems. You can add them by editing the transaction.';
  }

  @override
  String get transactionsFieldDate => 'txnDate';

  @override
  String get transactionsFieldIncomeSource => 'incomeSource';

  @override
  String get transactionsFieldRemarks => 'remarks';

  @override
  String get transactionsFieldTitle => 'title';

  @override
  String get transactionsFieldType => 'type';

  @override
  String get transactionsFromAccount => 'From account';

  @override
  String get transactionsHistory => 'History';

  @override
  String transactionsHistoryLoadFailed(String error) {
    return 'Could not load history: $error';
  }

  @override
  String transactionsInactiveSuffix(String name) {
    return '$name (inactive)';
  }

  @override
  String get transactionsIncomeSource => 'Income source';

  @override
  String get transactionsInvalidAmount =>
      'Enter a valid amount, like 1250 or 1250.50 (max 2 decimals)';

  @override
  String get transactionsIsDeleted => 'This transaction is deleted';

  @override
  String get transactionsKeypadAmountPositive =>
      'Amount must be greater than zero.';

  @override
  String get transactionsKeypadUseAmount => 'Use amount';

  @override
  String get transactionsNoAccounts =>
      'No accounts yet.\nCreate an account in Settings > Accounts before adding transactions.';

  @override
  String get transactionsNoCategories =>
      'No categories yet. Create a category in Settings > Categories to record expenses.';

  @override
  String get transactionsNoHistory => 'No history yet.';

  @override
  String transactionsNoRate(String code) {
    return 'No exchange rate for $code. Add one in exchange rates.';
  }

  @override
  String get transactionsNotFound => 'Transaction not found.';

  @override
  String transactionsOriginalLine(
    String original,
    String code,
    String symbol,
    String rate,
  ) {
    return '$original at 1 $code = $symbol$rate';
  }

  @override
  String transactionsRateLine(String code, String symbol, String rate) {
    return '1 $code = $symbol$rate';
  }

  @override
  String get transactionsReceipts => 'Receipts';

  @override
  String transactionsReceiptsSaveFailed(String reason) {
    return 'receipts could not be saved ($reason)';
  }

  @override
  String get transactionsRemarks => 'Remarks';

  @override
  String get transactionsRemarksOptional => 'Remarks (optional)';

  @override
  String get transactionsRepeatLast => 'Repeat last';

  @override
  String get transactionsRestored => 'Transaction restored';

  @override
  String get transactionsSaveChanges => 'Save changes';

  @override
  String transactionsSaveFailed(String error) {
    return 'Could not save the transaction: $error';
  }

  @override
  String get transactionsSaved => 'Transaction saved';

  @override
  String transactionsSavedWithWarning(String warning) {
    return 'Transaction saved. $warning';
  }

  @override
  String get transactionsSelectAccount => 'Select an account';

  @override
  String get transactionsSelectCategory => 'Select a category';

  @override
  String get transactionsSelectProfileFirst => 'Select a profile first.';

  @override
  String get transactionsSource => 'Source';

  @override
  String get transactionsSourceBusiness => 'Business';

  @override
  String get transactionsSourceFreelance => 'Freelance';

  @override
  String get transactionsSourceOther => 'Other';

  @override
  String get transactionsSourceSalary => 'Salary';

  @override
  String get transactionsSubCategory => 'Sub-category';

  @override
  String get transactionsSubCategoryOptional => 'Sub-category (optional)';

  @override
  String get transactionsTags => 'Tags';

  @override
  String transactionsTagsSaveFailed(String reason) {
    return 'tags could not be saved ($reason)';
  }

  @override
  String get transactionsTitle => 'Title';

  @override
  String get transactionsTitleOptional => 'Title (optional)';

  @override
  String get transactionsToAccount => 'To account';

  @override
  String get transactionsTypeExpense => 'Expense';

  @override
  String get transactionsTypeIncome => 'Income';

  @override
  String get transactionsTypeTransfer => 'Transfer';

  @override
  String get transactionsUpdated => 'Transaction updated';

  @override
  String get transactionsWarningAnd => ' and ';

  @override
  String get upcomingCard => 'Card bill';

  @override
  String upcomingCount(int count) {
    return '$count payments';
  }

  @override
  String get upcomingDebt => 'Debt';

  @override
  String get upcomingDps => 'DPS installment';

  @override
  String upcomingDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get upcomingDueToday => 'Due today';

  @override
  String get upcomingDueTomorrow => 'Due tomorrow';

  @override
  String upcomingDueTotal(String amount, int days) {
    return 'Due in $days days: $amount';
  }

  @override
  String get upcomingLoan => 'Loan';

  @override
  String upcomingNextDays(int days) {
    return 'Next $days days';
  }

  @override
  String upcomingNothingDue(int days) {
    return 'Nothing due in the next $days days.';
  }

  @override
  String upcomingOverdueSince(String date) {
    return 'Overdue since $date';
  }

  @override
  String upcomingOverdueTotal(String amount) {
    return 'Overdue: $amount';
  }

  @override
  String get upcomingRecurring => 'Recurring';

  @override
  String upcomingShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get upcomingShowLess => 'Show less';

  @override
  String get upcomingTitle => 'Upcoming payments';

  @override
  String get walletsAddAccount => 'Add account';

  @override
  String get walletsAddMoney => 'Add money';

  @override
  String get walletsAmount => 'Amount';

  @override
  String walletsBalanceAfter(String amount) {
    return 'Balance after: $amount';
  }

  @override
  String get walletsCardsNote =>
      'Credit-card accounts are shown separately and are not part of the total.';

  @override
  String get walletsClosing => 'Closing';

  @override
  String get walletsCurrentBalance => 'Current balance';

  @override
  String get walletsDate => 'Date';

  @override
  String get walletsEmpty =>
      'No accounts yet. Add a cash, bank or mobile wallet account to start tracking balances.';

  @override
  String walletsInOut(String inAmount, String outAmount) {
    return 'In $inAmount · Out $outAmount';
  }

  @override
  String get walletsLedgerTitle => 'Ledger';

  @override
  String get walletsMoneyAdded => 'Money added';

  @override
  String get walletsMoneyIn => 'Money in';

  @override
  String get walletsMoneyOut => 'Money out';

  @override
  String get walletsNoMovements => 'No movements in this period.';

  @override
  String get walletsNoOtherAccount =>
      'Add another account first to transfer money.';

  @override
  String get walletsNotFound => 'Account not found.';

  @override
  String get walletsNote => 'Note (optional)';

  @override
  String get walletsOpening => 'Opening';

  @override
  String get walletsOpeningBalance => 'Opening balance';

  @override
  String get walletsPeriod3Months => 'Last 3 months';

  @override
  String get walletsPeriodAll => 'All';

  @override
  String get walletsPeriodMonth => 'This month';

  @override
  String get walletsPeriodYear => 'This year';

  @override
  String walletsPreviewAdd(String current, String added, String after) {
    return 'Current $current + $added = $after after';
  }

  @override
  String walletsPreviewMove(String name, String before, String after) {
    return '$name: $before → $after';
  }

  @override
  String get walletsSource => 'Source';

  @override
  String get walletsSourceDeposit => 'Deposit';

  @override
  String get walletsSourceGift => 'Gift';

  @override
  String get walletsSourceInterest => 'Interest';

  @override
  String get walletsSourceOther => 'Other';

  @override
  String get walletsSourceRequired => 'Enter the source of this money';

  @override
  String get walletsSourceSalary => 'Salary';

  @override
  String get walletsThisMonth => 'This month';

  @override
  String get walletsTitle => 'Wallets & balances';

  @override
  String get walletsTotalBalance => 'Total balance';

  @override
  String get walletsTotalIn => 'Total in';

  @override
  String get walletsTotalNote =>
      'Cash, bank, mobile and savings accounts (credit cards excluded)';

  @override
  String get walletsTotalOut => 'Total out';

  @override
  String get walletsTransferHint =>
      'Moving money from a bank to cash is a withdrawal.';

  @override
  String get walletsTransferSaved => 'Transfer saved';

  @override
  String get walletsTransferTo => 'Transfer to';

  @override
  String get walletsTransferWithdraw => 'Transfer / Withdraw';
}
