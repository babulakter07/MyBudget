// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String accountsActivateMessage(String name) {
    return '\"$name\" আবার ব্যবহার করা যাবে।';
  }

  @override
  String get accountsActivateTitle => 'হিসাব সক্রিয় করবেন?';

  @override
  String get accountsAdd => 'হিসাব যোগ করুন';

  @override
  String get accountsAmountInvalid => 'সঠিক পরিমাণ লিখুন (সর্বোচ্চ ২ দশমিক)';

  @override
  String accountsDeactivateMessage(String name) {
    return 'নতুন এন্ট্রি থেকে \"$name\" লুকানো থাকবে। বিদ্যমান তথ্য সংরক্ষিত থাকবে।';
  }

  @override
  String get accountsDeactivateTitle => 'হিসাব নিষ্ক্রিয় করবেন?';

  @override
  String get accountsEdit => 'হিসাব সম্পাদনা';

  @override
  String get accountsEmpty => 'এখনও কোনো হিসাব নেই। যোগ করতে + চাপুন।';

  @override
  String get accountsNameLabel => 'নাম';

  @override
  String get accountsNameRequired => 'নাম দেওয়া আবশ্যক';

  @override
  String get accountsOpeningBalance => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get accountsOpeningDate => 'প্রারম্ভিক তারিখ';

  @override
  String get accountsSearchHint => 'হিসাব খুঁজুন';

  @override
  String get accountsSelectProfile =>
      'হিসাব পরিচালনা করতে একটি প্রোফাইল নির্বাচন করুন।';

  @override
  String get accountsShowInactive => 'নিষ্ক্রিয় দেখান';

  @override
  String get accountsTitle => 'হিসাব';

  @override
  String get accountsTypeBank => 'ব্যাংক';

  @override
  String get accountsTypeCash => 'নগদ';

  @override
  String get accountsTypeCreditCard => 'ক্রেডিট কার্ড';

  @override
  String get accountsTypeMobile => 'মোবাইল ব্যাংকিং';

  @override
  String get accountsTypeOther => 'অন্যান্য';

  @override
  String get accountsTypeSavings => 'সঞ্চয় হিসাব';

  @override
  String get appShellAbout => 'সম্পর্কে';

  @override
  String get appShellAboutContact => 'যোগাযোগ';

  @override
  String appShellAboutCopied(String label) {
    return '$label কপি হয়েছে';
  }

  @override
  String get appShellAboutCurrentWork => 'বর্তমান কাজ';

  @override
  String get appShellAboutEmail => 'ইমেইল';

  @override
  String get appShellAboutJob =>
      'সফটওয়্যার ইঞ্জিনিয়ার - জানুয়ারি ২০২৪ থেকে বর্তমান';

  @override
  String get appShellAboutPortfolio => 'পোর্টফোলিও';

  @override
  String get appShellAboutRole =>
      'সফটওয়্যার ইঞ্জিনিয়ার | ফুল স্ট্যাক .NET ডেভেলপার';

  @override
  String get appShellAboutTagline =>
      'অফলাইন-ফার্স্ট ব্যক্তিগত ও পারিবারিক বাজেট ম্যানেজার। আপনার ডেটা আপনার ডিভাইসেই থাকে।';

  @override
  String get appShellAboutTapToCopy => 'কপি করতে একটি যোগাযোগে ট্যাপ করুন';

  @override
  String get appShellAccounts => 'হিসাব';

  @override
  String get appShellBackupRestore => 'ব্যাকআপ ও রিস্টোর';

  @override
  String get appShellCategories => 'ক্যাটাগরি';

  @override
  String get appShellCostItems => 'খরচের আইটেম';

  @override
  String get appShellDebtsLoans => 'ঋণ ও ধার';

  @override
  String get appShellExchangeRates => 'বিনিময় হার';

  @override
  String get appShellImportCsv => 'CSV থেকে আমদানি';

  @override
  String get appShellInsights => 'বিশ্লেষণ';

  @override
  String get appShellNoErrorsLogged => 'কোনো ত্রুটি লগ করা হয়নি।';

  @override
  String get appShellNotifications => 'নোটিফিকেশন';

  @override
  String get appShellPreferences => 'পছন্দসমূহ';

  @override
  String get appShellProfiles => 'প্রোফাইল';

  @override
  String get appShellRecurring => 'পুনরাবৃত্ত লেনদেন';

  @override
  String get appShellSavingsGoals => 'সঞ্চয়ের লক্ষ্য';

  @override
  String get appShellSectionApp => 'অ্যাপ';

  @override
  String get appShellSectionData => 'ডেটা';

  @override
  String get appShellSectionMaster => 'মূল কনফিগারেশন';

  @override
  String get appShellSectionPlan => 'পরিকল্পনা';

  @override
  String get appShellSecurity => 'নিরাপত্তা';

  @override
  String get appShellSettings => 'সেটিংস';

  @override
  String get appShellShareErrorLog => 'ত্রুটির লগ শেয়ার করুন';

  @override
  String get appShellShareErrorLogSubtitle =>
      'আপনি না পাঠালে এটি আপনার ডিভাইসেই থাকে';

  @override
  String get appShellSubCategories => 'সাব-ক্যাটাগরি';

  @override
  String get appShellTabAdd => 'যোগ';

  @override
  String get appShellTabBudget => 'বাজেট';

  @override
  String get appShellTabHome => 'হোম';

  @override
  String get appShellTabLedger => 'লেজার';

  @override
  String get appShellTabReports => 'রিপোর্ট';

  @override
  String get appShellTagReport => 'ট্যাগ রিপোর্ট';

  @override
  String get appShellTags => 'ট্যাগ';

  @override
  String get attachmentsAddFailed => 'ছবি যোগ করা যায়নি।';

  @override
  String get attachmentsAddPhoto => 'ছবি যোগ করুন';

  @override
  String get attachmentsCamera => 'ক্যামেরা';

  @override
  String get attachmentsDeleteTitle => 'সংযুক্তি মুছুন';

  @override
  String get attachmentsGallery => 'গ্যালারি';

  @override
  String attachmentsHeader(int count, int max) {
    return 'সংযুক্তি ($count/$max)';
  }

  @override
  String get attachmentsNone => 'কোনো সংযুক্তি নেই';

  @override
  String get attachmentsRemoveMessage => 'এই ছবিটি সরাবেন?';

  @override
  String get attachmentsViewerTitle => 'সংযুক্তি';

  @override
  String get backupAutoBackup => 'স্বয়ংক্রিয় ব্যাকআপ';

  @override
  String get backupAutoNote =>
      'ব্যাকগ্রাউন্ড কাজ কখন চলবে তা অ্যান্ড্রয়েড ঠিক করে, তাই স্বয়ংক্রিয় ব্যাকআপ কয়েক ঘণ্টা দেরিতে হতে পারে (ব্যাটারি সেভার, ডোজ)। ব্যাকআপ এই ডিভাইসেই থাকে। ম্যানুয়াল ও সুরক্ষা ব্যাকআপ কখনো স্বয়ংক্রিয়ভাবে মুছে যায় না। স্বয়ংক্রিয় ব্যাকআপে পাসওয়ার্ড সুরক্ষা নেই এবং রসিদের ছবি থাকে না; এনক্রিপ্টেড কপি ও ছবি পেতে \"তৈরি করে শেয়ার করুন\" ব্যবহার করুন।';

  @override
  String get backupBackUpNow => 'এখনই ব্যাকআপ নিন';

  @override
  String get backupCannotRestoreTitle => 'ব্যাকআপ রিস্টোর করা যাবে না';

  @override
  String get backupConfirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get backupContains => 'যা আছে:';

  @override
  String backupContainsRow(int count, String label) {
    return '• $count $label';
  }

  @override
  String get backupCreateAndShare => 'তৈরি করে শেয়ার করুন';

  @override
  String get backupCreateBackup => 'ব্যাকআপ তৈরি করুন';

  @override
  String backupCreatedAt(String date) {
    return 'ব্যাকআপ তৈরি হয়েছে: $date';
  }

  @override
  String backupDeleteMessage(String name) {
    return '$name মুছবেন? এটি আর ফেরানো যাবে না।';
  }

  @override
  String get backupDeleteTitle => 'ব্যাকআপ মুছবেন?';

  @override
  String get backupEncrypt => 'পাসওয়ার্ড দিয়ে এনক্রিপ্ট করুন';

  @override
  String get backupEncryptNote =>
      'এইএস-২৫৬। পাসওয়ার্ড ভুলে গেলে আমরা সহ কেউই ব্যাকআপটি খুলতে পারবে না।';

  @override
  String get backupEncryptedPrompt =>
      'এই ব্যাকআপটি এনক্রিপ্টেড। এর পাসওয়ার্ড দিন।';

  @override
  String get backupEncryptedSuffix => ' (এনক্রিপ্টেড)';

  @override
  String get backupFreqDaily => 'প্রতিদিন';

  @override
  String get backupFreqOff => 'বন্ধ';

  @override
  String get backupFreqWeekly => 'প্রতি সপ্তাহে';

  @override
  String get backupFrequency => 'ব্যাকআপের ব্যবধান';

  @override
  String get backupHide => 'লুকান';

  @override
  String get backupIncludePhotos => 'রসিদের ছবি যুক্ত করুন';

  @override
  String get backupKeepLast => 'সর্বশেষ স্বয়ংক্রিয় ব্যাকআপ রাখুন';

  @override
  String get backupKindAuto => 'স্বয়ংক্রিয়';

  @override
  String get backupKindManual => 'ম্যানুয়াল';

  @override
  String get backupKindSafety => 'সুরক্ষা (রিস্টোরের আগে)';

  @override
  String get backupLastRunFailed => 'সর্বশেষ ব্যাকআপ ব্যর্থ হয়েছে';

  @override
  String get backupLastRunSucceeded => 'সর্বশেষ ব্যাকআপ সফল হয়েছে';

  @override
  String backupMissingPhotosSuffix(int count) {
    return '। $countটি রসিদের ছবি পাওয়া যায়নি, তাই বাদ দেওয়া হয়েছে।';
  }

  @override
  String backupMissingSkipped(int count) {
    return ' ($countটি অনুপস্থিত ফাইল বাদ যাবে)';
  }

  @override
  String get backupNoAutoRun => 'এখনও কোনো স্বয়ংক্রিয় ব্যাকআপ চলেনি।';

  @override
  String get backupNoBackupsYet =>
      'এখনও কোনো ব্যাকআপ নেই। প্রথমটি তৈরি করতে \"ব্যাকআপ তৈরি করুন\" চাপুন।';

  @override
  String get backupNoPhotos => 'যুক্ত করার মতো কোনো রসিদের ছবি নেই।';

  @override
  String get backupNothingChanged =>
      'কিছুই পরিবর্তন হয়নি। যেসব সমস্যা পাওয়া গেছে:';

  @override
  String get backupPassword => 'পাসওয়ার্ড';

  @override
  String backupPasswordMinLabel(int min) {
    return 'পাসওয়ার্ড (কমপক্ষে $min)';
  }

  @override
  String get backupPasswordMismatch => 'দুটি পাসওয়ার্ড মিলছে না।';

  @override
  String get backupPasswordRequired => 'পাসওয়ার্ড প্রয়োজন';

  @override
  String backupPasswordTooShort(int min) {
    return 'পাসওয়ার্ডে কমপক্ষে $minটি অক্ষর ব্যবহার করুন।';
  }

  @override
  String backupPhotoCount(int count, String size) {
    return '$countটি ছবি, প্রায় $size';
  }

  @override
  String get backupReminderAction => 'ব্যাকআপ নিন';

  @override
  String get backupReminderLater => 'পরে';

  @override
  String get backupReminderNone =>
      'এখনো কোনো ব্যাকআপ নেই। আপনার তথ্য শুধু এই ফোনেই আছে।';

  @override
  String backupReminderOld(int days) {
    return 'আপনার শেষ ব্যাকআপ $days দিন আগের।';
  }

  @override
  String get backupReminderTitle => 'আপনার তথ্যের ব্যাকআপ নিন';

  @override
  String get backupReplaceAllTitle => 'সব তথ্য প্রতিস্থাপন করবেন?';

  @override
  String get backupReplaceData => 'তথ্য প্রতিস্থাপন করুন';

  @override
  String get backupReplaceWarning =>
      'রিস্টোর করলে অ্যাপের বর্তমান সব তথ্য এই ব্যাকআপ দিয়ে প্রতিস্থাপিত হবে। আগে বর্তমান তথ্যের একটি সুরক্ষা ব্যাকআপ তৈরি হয়, তাই আপনি ফিরে যেতে পারবেন।';

  @override
  String get backupRestoreComplete =>
      'রিস্টোর সম্পন্ন হয়েছে। আগের তথ্যের একটি সুরক্ষা ব্যাকআপ সংরক্ষিত হয়েছে।';

  @override
  String get backupRestoreCompleteCleared =>
      'রিস্টোর সম্পন্ন হয়েছে। আপনার আগের প্রোফাইল এই ব্যাকআপে নেই; অনুগ্রহ করে একটি প্রোফাইল বেছে নিন।';

  @override
  String get backupRestoreFromFile => 'ফাইল থেকে রিস্টোর করুন';

  @override
  String get backupSavedBackups => 'সংরক্ষিত ব্যাকআপ';

  @override
  String backupSavedToast(String name) {
    return 'ব্যাকআপ সংরক্ষিত হয়েছে: $name';
  }

  @override
  String get backupShow => 'দেখান';

  @override
  String backupSomethingWrong(String error) {
    return 'কিছু ভুল হয়েছে: $error';
  }

  @override
  String backupStatusAt(String time) {
    return ' — $time';
  }

  @override
  String backupStatusMessage(String message) {
    return ' ($message)';
  }

  @override
  String get backupTableAccounts => 'হিসাব';

  @override
  String get backupTableCategories => 'ক্যাটাগরি';

  @override
  String get backupTableCategoryBudgets => 'ক্যাটাগরি বাজেট';

  @override
  String get backupTableCostItems => 'খরচের আইটেম';

  @override
  String get backupTableDebtPayments => 'ঋণ পরিশোধ';

  @override
  String get backupTableDebts => 'ঋণ';

  @override
  String get backupTableExchangeRates => 'বিনিময় হার';

  @override
  String get backupTableFinancialProfiles => 'আর্থিক প্রোফাইল';

  @override
  String get backupTableFinancialTransactions => 'লেনদেন';

  @override
  String get backupTableMonthlyBudgets => 'মাসিক বাজেট';

  @override
  String get backupTableRecurringRules => 'পুনরাবৃত্ত নিয়ম';

  @override
  String get backupTableSavingsGoals => 'সঞ্চয়ের লক্ষ্য';

  @override
  String get backupTableSubCategories => 'উপ-ক্যাটাগরি';

  @override
  String get backupTableTags => 'ট্যাগ';

  @override
  String get backupTableTransactionAttachments => 'লেনদেনের সংযুক্তি';

  @override
  String get backupTableTransactionAuditLogs => 'লেনদেনের অডিট লগ';

  @override
  String get backupTitle => 'ব্যাকআপ ও রিস্টোর';

  @override
  String get backupUnlock => 'আনলক করুন';

  @override
  String get backupUnreadableFile =>
      'এই ফাইলটি পড়ার মতো কোনো ব্যাকআপ ফাইল নয়।';

  @override
  String get budgetsAddAllocation => 'বরাদ্দ যোগ করুন';

  @override
  String budgetsAllocatedSummary(String allocated, String total) {
    return '$total-এর মধ্যে $allocated বরাদ্দ (মোটের ভেতরেই, আলাদা যোগ হয় না)।';
  }

  @override
  String get budgetsAllocation => 'বরাদ্দ';

  @override
  String get budgetsBudget => 'বাজেট';

  @override
  String budgetsCarriedOver(String amount) {
    return '+$amount আগের মাস থেকে এসেছে';
  }

  @override
  String get budgetsCarryOverUnspent => 'অব্যয়িত টাকা পরের মাসে নিন';

  @override
  String get budgetsCategory => 'ক্যাটাগরি';

  @override
  String get budgetsCategoryAllocations => 'ক্যাটাগরি বরাদ্দ';

  @override
  String get budgetsEditAllocation => 'বরাদ্দ সম্পাদনা';

  @override
  String get budgetsEditBudget => 'বাজেট সম্পাদনা';

  @override
  String get budgetsEmptyMessage =>
      'নতুন মাস: বাজেট ঠিক করুন; আগের মাস থেকে কিছু জমা হয় না।';

  @override
  String budgetsErrorWithDetail(String error) {
    return 'কিছু ভুল হয়েছে: $error';
  }

  @override
  String get budgetsInvalidAmount =>
      'সঠিক পরিমাণ লিখুন (দশমিকের পর সর্বোচ্চ ২ অঙ্ক)';

  @override
  String get budgetsMonthApril => 'এপ্রিল';

  @override
  String get budgetsMonthAugust => 'আগস্ট';

  @override
  String get budgetsMonthDecember => 'ডিসেম্বর';

  @override
  String get budgetsMonthFebruary => 'ফেব্রুয়ারি';

  @override
  String get budgetsMonthJanuary => 'জানুয়ারি';

  @override
  String get budgetsMonthJuly => 'জুলাই';

  @override
  String get budgetsMonthJune => 'জুন';

  @override
  String get budgetsMonthMarch => 'মার্চ';

  @override
  String get budgetsMonthMay => 'মে';

  @override
  String get budgetsMonthNovember => 'নভেম্বর';

  @override
  String get budgetsMonthOctober => 'অক্টোবর';

  @override
  String get budgetsMonthSeptember => 'সেপ্টেম্বর';

  @override
  String budgetsMonthYear(String month, String year) {
    return '$month $year';
  }

  @override
  String get budgetsMonthlyBudget => 'মাসিক বাজেট';

  @override
  String get budgetsNextMonth => 'পরের মাস';

  @override
  String get budgetsNoAllocations => 'এই মাসে কোনো ক্যাটাগরি বরাদ্দ নেই।';

  @override
  String get budgetsNoCategoriesLeft =>
      'বরাদ্দ দেওয়ার মতো কোনো সক্রিয় ক্যাটাগরি বাকি নেই।';

  @override
  String budgetsPercentUsed(String percent) {
    return '$percent% ব্যবহৃত';
  }

  @override
  String get budgetsPickMonthHelp => 'মাসের যেকোনো একটি দিন বেছে নিন';

  @override
  String get budgetsPreviousMonth => 'আগের মাস';

  @override
  String get budgetsRemaining => 'বাকি';

  @override
  String budgetsRemainingAmount(String amount) {
    return 'বাকি $amount';
  }

  @override
  String get budgetsRemoveAllocation => 'বরাদ্দ সরান';

  @override
  String budgetsRemoveAllocationMessage(String name) {
    return '\"$name\"-এর বরাদ্দ সরিয়ে ফেলবেন?';
  }

  @override
  String get budgetsRemoveAllocationTitle => 'বরাদ্দ সরাবেন?';

  @override
  String get budgetsSelectProfile =>
      'বাজেট পরিচালনা করতে একটি প্রোফাইল বেছে নিন।';

  @override
  String get budgetsSetBudget => 'বাজেট ঠিক করুন';

  @override
  String get budgetsSpent => 'খরচ হয়েছে';

  @override
  String budgetsSpentOf(String spent, String allowance) {
    return '$allowance-এর মধ্যে $spent খরচ হয়েছে';
  }

  @override
  String get budgetsTotalBudget => 'মোট বাজেট';

  @override
  String categoriesActivateMessage(String name) {
    return '\"$name\" আবার ব্যবহার করা যাবে।';
  }

  @override
  String get categoriesActivateTitle => 'ক্যাটাগরি সক্রিয় করবেন?';

  @override
  String get categoriesAdd => 'ক্যাটাগরি যোগ করুন';

  @override
  String get categoriesColorLabel => 'রঙ';

  @override
  String categoriesDeactivateMessage(String name) {
    return 'নতুন এন্ট্রি থেকে \"$name\" লুকানো থাকবে। বিদ্যমান তথ্য সংরক্ষিত থাকবে।';
  }

  @override
  String get categoriesDeactivateTitle => 'ক্যাটাগরি নিষ্ক্রিয় করবেন?';

  @override
  String get categoriesDescriptionLabel => 'বিবরণ';

  @override
  String get categoriesEdit => 'ক্যাটাগরি সম্পাদনা';

  @override
  String get categoriesEmpty => 'এখনও কোনো ক্যাটাগরি নেই। যোগ করতে + চাপুন।';

  @override
  String get categoriesIconLabel => 'আইকন';

  @override
  String categoriesLoadError(String error) {
    return 'কিছু ভুল হয়েছে: $error';
  }

  @override
  String get categoriesNameLabel => 'নাম';

  @override
  String get categoriesNameRequired => 'নাম দেওয়া আবশ্যক';

  @override
  String get categoriesSearchHint => 'ক্যাটাগরি খুঁজুন';

  @override
  String get categoriesSelectProfile =>
      'ক্যাটাগরি পরিচালনা করতে একটি প্রোফাইল নির্বাচন করুন।';

  @override
  String get categoriesShowInactive => 'নিষ্ক্রিয় দেখান';

  @override
  String get categoriesTitle => 'ক্যাটাগরি';

  @override
  String get commonActive => 'সক্রিয়';

  @override
  String get commonAdd => 'যোগ করুন';

  @override
  String get commonAll => 'সব';

  @override
  String get commonApply => 'প্রয়োগ করুন';

  @override
  String get commonArchive => 'আর্কাইভ';

  @override
  String get commonBack => 'পেছনে';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonClear => 'মুছে ফেলুন';

  @override
  String get commonClose => 'বন্ধ করুন';

  @override
  String get commonConfirm => 'নিশ্চিত করুন';

  @override
  String get commonCreate => 'তৈরি করুন';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonDone => 'সম্পন্ন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonInactive => 'নিষ্ক্রিয়';

  @override
  String get commonLoading => 'লোড হচ্ছে…';

  @override
  String get commonNext => 'পরবর্তী';

  @override
  String get commonNo => 'না';

  @override
  String get commonNoData => 'এখনও কোনো তথ্য নেই';

  @override
  String get commonNone => 'কিছু নয়';

  @override
  String get commonOk => 'ঠিক আছে';

  @override
  String get commonOptional => 'ঐচ্ছিক';

  @override
  String get commonRemove => 'সরান';

  @override
  String get commonRequired => 'আবশ্যক';

  @override
  String get commonRestore => 'পুনরুদ্ধার';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonSave => 'সংরক্ষণ করুন';

  @override
  String get commonSearch => 'অনুসন্ধান';

  @override
  String get commonSelectProfile => 'চালিয়ে যেতে একটি প্রোফাইল নির্বাচন করুন।';

  @override
  String get commonShare => 'শেয়ার করুন';

  @override
  String get commonSomethingWentWrong => 'কিছু ভুল হয়েছে';

  @override
  String get commonUndo => 'পূর্বাবস্থায় ফেরান';

  @override
  String get commonUpdate => 'আপডেট করুন';

  @override
  String get commonYes => 'হ্যাঁ';

  @override
  String get costItemsActivateAction => 'সক্রিয় করুন';

  @override
  String costItemsActivateMessage(String name) {
    return '\"$name\" আবার ব্যবহার করা যাবে।';
  }

  @override
  String get costItemsActivateTitle => 'খরচের আইটেম সক্রিয় করবেন?';

  @override
  String get costItemsAdd => 'খরচের আইটেম যোগ করুন';

  @override
  String get costItemsAmountInvalid => 'সঠিক পরিমাণ লিখুন (সর্বোচ্চ ২ দশমিক)';

  @override
  String get costItemsCategoryLabel => 'ক্যাটাগরি';

  @override
  String get costItemsDeactivateAction => 'নিষ্ক্রিয় করুন';

  @override
  String costItemsDeactivateMessage(String name) {
    return 'নতুন এন্ট্রি থেকে \"$name\" লুকানো থাকবে। বিদ্যমান তথ্য সংরক্ষিত থাকবে।';
  }

  @override
  String get costItemsDeactivateTitle => 'খরচের আইটেম নিষ্ক্রিয় করবেন?';

  @override
  String get costItemsDefaultAmountOptional => 'ডিফল্ট পরিমাণ (ঐচ্ছিক)';

  @override
  String get costItemsDescriptionOptional => 'বিবরণ (ঐচ্ছিক)';

  @override
  String get costItemsEdit => 'খরচের আইটেম সম্পাদনা';

  @override
  String get costItemsEmpty => 'কোনো খরচের আইটেম পাওয়া যায়নি।';

  @override
  String get costItemsFavAddTooltip => 'দ্রুত যোগে যোগ করুন';

  @override
  String get costItemsFavRemoveTooltip => 'দ্রুত যোগ থেকে সরান';

  @override
  String get costItemsInactiveSuffix => ' · নিষ্ক্রিয়';

  @override
  String costItemsLoadError(String error) {
    return 'খরচের আইটেম লোড করা যায়নি: $error';
  }

  @override
  String get costItemsNameLabel => 'নাম';

  @override
  String get costItemsNameRequired => 'নাম দেওয়া আবশ্যক';

  @override
  String get costItemsSearchHint => 'নাম বা বিবরণ খুঁজুন';

  @override
  String get costItemsSelectCategory => 'একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get costItemsSelectProfile => 'প্রথমে একটি প্রোফাইল নির্বাচন করুন।';

  @override
  String get costItemsSelectSubCategory => 'একটি সাব-ক্যাটাগরি নির্বাচন করুন';

  @override
  String get costItemsShowInactive => 'নিষ্ক্রিয় দেখান';

  @override
  String get costItemsSubCategoryLabel => 'সাব-ক্যাটাগরি';

  @override
  String get costItemsTitle => 'খরচের আইটেম';

  @override
  String get currencyAddRate => 'বিনিময় হার যোগ করুন';

  @override
  String get currencyAddRateTooltip => 'হার যোগ করুন';

  @override
  String currencyBaseCard(String code, String symbol) {
    return 'মূল মুদ্রা: $code ($symbol)';
  }

  @override
  String get currencyBaseCardSub =>
      'সব ব্যালেন্স, বাজেট ও রিপোর্টে এটি ব্যবহৃত হয়';

  @override
  String get currencyCodeLabel => '৩ অক্ষরের মুদ্রা কোড';

  @override
  String get currencyEditRate => 'বিনিময় হার সম্পাদনা';

  @override
  String get currencyEmptyBody =>
      'যে বিদেশি মুদ্রায় খরচ বা আয় করেন তার প্রতিটির জন্য হার যোগ করুন, যেমন ১ ইউনিট = আপনার মূল মুদ্রার পরিমাণ।';

  @override
  String get currencyEmptyTitle => 'এখনও কোনো বিনিময় হার নেই';

  @override
  String get currencyErrChoose => 'একটি মুদ্রা বেছে নিন।';

  @override
  String get currencyErrCode => 'মুদ্রা কোড ৩টি অক্ষরের হতে হবে, যেমন USD।';

  @override
  String get currencyErrRate =>
      'শূন্যের বেশি হার লিখুন, দশমিকের পরে সর্বোচ্চ ৬ ঘর, যেমন 122.5।';

  @override
  String get currencyFieldCurrency => 'মুদ্রা';

  @override
  String get currencyInfo =>
      'হারগুলো আপনি নিজে দেন, অনলাইন থেকে আনা হয় না। বিদেশি মুদ্রায় লেনদেন লেখার সময়ই কেবল এগুলো ব্যবহৃত হয়। আগে সংরক্ষিত লেনদেন যে হারে সংরক্ষিত হয়েছিল সেটিই থাকে, তাই এখানে হার বদলালে পুরোনো হিসাব বদলায় না।';

  @override
  String get currencyNoProfile =>
      'বিনিময় হার পরিচালনা করতে একটি প্রোফাইল বেছে নিন।';

  @override
  String get currencyOtherCode => 'অন্য কোড';

  @override
  String currencyRateEquals(String code, String symbol, String rate) {
    return '১ $code = $symbol$rate';
  }

  @override
  String get currencyRateHelper =>
      'বিদেশি মুদ্রার ১ ইউনিটের জন্য মূল মুদ্রার পরিমাণ';

  @override
  String currencyRateLabel(String base) {
    return 'হার ($base এ)';
  }

  @override
  String get currencyTitle => 'বিনিময় হার';

  @override
  String currencyUpdated(String date) {
    return 'হালনাগাদ $date';
  }

  @override
  String currencyUpdatedInactive(String date) {
    return 'হালনাগাদ $date - নিষ্ক্রিয়';
  }

  @override
  String get dashboardAverageDailyExpense => 'দৈনিক গড় খরচ';

  @override
  String get dashboardAverageMonthlyExpense => 'মাসিক গড় খরচ';

  @override
  String get dashboardBudgetUtilization => 'বাজেট ব্যবহার';

  @override
  String get dashboardCashBalance => 'নগদ ব্যালেন্স (সক্রিয় হিসাব)';

  @override
  String get dashboardCategoryDistribution => 'ক্যাটাগরি অনুযায়ী বণ্টন';

  @override
  String get dashboardCurrentMonth => 'চলতি মাস';

  @override
  String get dashboardHighestSpendingDay => 'সর্বোচ্চ খরচের দিন';

  @override
  String get dashboardHighestSpendingMonth => 'সর্বোচ্চ খরচের মাস';

  @override
  String get dashboardLowestSpendingMonth => 'সর্বনিম্ন খরচের মাস';

  @override
  String get dashboardMonthExpense => 'মাসের খরচ';

  @override
  String get dashboardMonthIncome => 'মাসের আয়';

  @override
  String get dashboardMonthlyBudget => 'মাসিক বাজেট';

  @override
  String get dashboardMonthlyExpenseTrend => 'মাসিক খরচের ধারা';

  @override
  String get dashboardNoCategoryExpenses => 'এই মাসে কোনো ক্যাটাগরির খরচ নেই।';

  @override
  String get dashboardNoCostItemExpenses => 'এই মাসে কোনো আইটেমের খরচ নেই।';

  @override
  String get dashboardNoExpensesToChart => 'এই মাসে চার্টের জন্য কোনো খরচ নেই।';

  @override
  String get dashboardNoProfile => 'প্রোফাইল নেই';

  @override
  String get dashboardPreviousMonth => 'আগের মাস';

  @override
  String get dashboardRemainingBudget => 'অবশিষ্ট বাজেট';

  @override
  String get dashboardSelectMonth => 'মাস বাছাই';

  @override
  String get dashboardSpendingHighlights => 'খরচের হাইলাইট';

  @override
  String get dashboardSwitch => 'পরিবর্তন';

  @override
  String get dashboardTop5Categories => 'শীর্ষ ৫ ক্যাটাগরি';

  @override
  String get dashboardTop5CostItems => 'শীর্ষ ৫ খরচের আইটেম';

  @override
  String get dashboardTotalExpense => 'মোট খরচ';

  @override
  String get dashboardTotalIncome => 'মোট আয়';

  @override
  String dashboardYear(int year) {
    return 'বছর $year';
  }

  @override
  String get dashboardYearlyOverview => 'বার্ষিক সারসংক্ষেপ';

  @override
  String get debtsAddDebt => 'ঋণ যোগ করুন';

  @override
  String get debtsAddPayment => 'পরিশোধ যোগ করুন';

  @override
  String get debtsAmount => 'পরিমাণ';

  @override
  String get debtsAmountPositive => 'পরিমাণ শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get debtsArchived => 'আর্কাইভ করা';

  @override
  String get debtsBorrowed => 'নেওয়া';

  @override
  String debtsClearField(String label) {
    return '$label মুছুন';
  }

  @override
  String debtsDue(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get debtsDueDate => 'মেয়াদের তারিখ';

  @override
  String debtsDueWithPrincipal(String due, String principal) {
    return '$due  •  মূল $principal';
  }

  @override
  String get debtsEditDebt => 'ঋণ সম্পাদনা';

  @override
  String get debtsGroupByPerson => 'ব্যক্তি অনুযায়ী সাজান';

  @override
  String get debtsIAmOwed => 'আমি পাব';

  @override
  String get debtsIBorrowed => 'আমি ধার নিয়েছি';

  @override
  String get debtsILent => 'আমি ধার দিয়েছি';

  @override
  String get debtsIOwe => 'আমি দেব';

  @override
  String get debtsInvalidAmount =>
      'সঠিক পরিমাণ লিখুন (দশমিকের পর সর্বোচ্চ ২ অঙ্ক)';

  @override
  String get debtsLent => 'দেওয়া';

  @override
  String get debtsListTitle => 'ঋণ ও দেনা-পাওনা';

  @override
  String get debtsMarkSettled => 'সম্পূর্ণ পরিশোধিত হিসেবে চিহ্নিত করুন';

  @override
  String debtsMaxAmount(String amount) {
    return 'সর্বোচ্চ $amount';
  }

  @override
  String get debtsNet => 'নিট';

  @override
  String get debtsNoBorrowed => 'এখনও কারও কাছ থেকে টাকা ধার নেওয়া হয়নি।';

  @override
  String get debtsNoDueDate => 'কোনো মেয়াদ নেই';

  @override
  String get debtsNoLent => 'এখনও কাউকে টাকা ধার দেওয়া হয়নি।';

  @override
  String get debtsNoPayments => 'এখনও কোনো পরিশোধ নেই।';

  @override
  String get debtsNotFound => 'ঋণটি পাওয়া যায়নি।';

  @override
  String get debtsNotSet => 'দেওয়া হয়নি';

  @override
  String get debtsNote => 'নোট';

  @override
  String get debtsOutstanding => 'বকেয়া';

  @override
  String debtsOutstandingAmount(String amount) {
    return 'বকেয়া: $amount';
  }

  @override
  String get debtsOverdue => 'মেয়াদোত্তীর্ণ';

  @override
  String get debtsOwedToMe => 'আমার পাওনা';

  @override
  String get debtsPaid => 'পরিশোধিত';

  @override
  String get debtsPaymentDate => 'পরিশোধের তারিখ';

  @override
  String get debtsPayments => 'পরিশোধসমূহ';

  @override
  String get debtsPerson => 'ব্যক্তি';

  @override
  String get debtsPersonRequired => 'ব্যক্তির নাম দেওয়া আবশ্যক';

  @override
  String get debtsPrincipal => 'মূল টাকা';

  @override
  String debtsReminderBorrowed(
    String person,
    String outstanding,
    String principal,
  ) {
    return 'রিমাইন্ডার: আমি $person-কে $outstanding দেব (মূল $principal)।';
  }

  @override
  String debtsReminderBorrowedDue(
    String person,
    String outstanding,
    String principal,
    String date,
  ) {
    return 'রিমাইন্ডার: আমি $person-কে $outstanding দেব (মূল $principal)। মেয়াদ: $date।';
  }

  @override
  String debtsReminderLent(
    String person,
    String outstanding,
    String principal,
  ) {
    return 'রিমাইন্ডার: $person আমাকে $outstanding দেবে (মূল $principal)।';
  }

  @override
  String debtsReminderLentDue(
    String person,
    String outstanding,
    String principal,
    String date,
  ) {
    return 'রিমাইন্ডার: $person আমাকে $outstanding দেবে (মূল $principal)। মেয়াদ: $date।';
  }

  @override
  String get debtsSettle => 'পরিশোধ করুন';

  @override
  String debtsSettleMessage(String amount) {
    return '$amount পরিশোধ হিসেবে যোগ করবেন?';
  }

  @override
  String get debtsShareReminder => 'রিমাইন্ডার শেয়ার করুন';

  @override
  String get debtsShowFlatList => 'সাধারণ তালিকা দেখান';

  @override
  String get debtsStartDate => 'শুরুর তারিখ';

  @override
  String debtsStarted(String date) {
    return 'শুরু $date';
  }

  @override
  String get debtsStatusOpen => 'চলমান';

  @override
  String get debtsStatusOverdue => 'মেয়াদোত্তীর্ণ';

  @override
  String get debtsStatusSettled => 'পরিশোধিত';

  @override
  String get debtsTitle => 'ঋণ';

  @override
  String get debtsUnarchive => 'আর্কাইভ থেকে ফেরান';

  @override
  String get debtsVoid => 'বাতিল করুন';

  @override
  String debtsVoidMessage(String amount) {
    return '$amount-এর এই পরিশোধ বাতিল করবেন? বকেয়া বেড়ে যাবে।';
  }

  @override
  String get debtsVoidPayment => 'পরিশোধ বাতিল করুন';

  @override
  String get debtsVoided => 'বাতিল করা';

  @override
  String goalsAccountLine(String account) {
    return 'হিসাব: $account';
  }

  @override
  String goalsAccountLineArchived(String account) {
    return 'হিসাব: $account - আর্কাইভ করা';
  }

  @override
  String get goalsAchieved => 'অর্জিত';

  @override
  String get goalsAddGoal => 'লক্ষ্য যোগ করুন';

  @override
  String get goalsArchiveGoal => 'লক্ষ্য আর্কাইভ করুন';

  @override
  String goalsArchiveMessage(String name) {
    return '\"$name\" আপনার লক্ষ্যের তালিকা থেকে লুকানো হবে। আপনার হিসাব ও লেনদেনে কোনো প্রভাব পড়বে না।';
  }

  @override
  String get goalsArchiveTitle => 'লক্ষ্য আর্কাইভ করবেন?';

  @override
  String get goalsChooseAccount => 'যে হিসাবে সঞ্চয় রাখা হয় সেটি বেছে নিন।';

  @override
  String get goalsClearDate => 'তারিখ মুছুন';

  @override
  String goalsDaysLeft(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন বাকি ($date)',
      one: '1 দিন বাকি ($date)',
    );
    return '$_temp0';
  }

  @override
  String goalsDueToday(String date) {
    return 'আজ শেষ দিন ($date)';
  }

  @override
  String get goalsEditGoal => 'লক্ষ্য সম্পাদনা';

  @override
  String get goalsEmpty => 'এখনও কোনো সঞ্চয় লক্ষ্য নেই। যোগ করতে + চাপুন।';

  @override
  String get goalsGoalName => 'লক্ষ্যের নাম';

  @override
  String get goalsGoalReached => 'লক্ষ্যে পৌঁছেছেন';

  @override
  String get goalsInvalidAmount =>
      'সঠিক পরিমাণ লিখুন (দশমিকের পর সর্বোচ্চ ২ অঙ্ক)';

  @override
  String get goalsNameRequired => 'নাম দেওয়া আবশ্যক';

  @override
  String get goalsNoAccounts =>
      'কোনো সক্রিয় হিসাব নেই। আগে একটি হিসাব যোগ করুন।';

  @override
  String get goalsNoDeadline => 'কোনো সময়সীমা নেই';

  @override
  String get goalsNoteOptional => 'নোট (ঐচ্ছিক)';

  @override
  String goalsOverdueBy(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন',
      one: '1 দিন',
    );
    return '$_temp0 দেরি হয়েছে ($date)';
  }

  @override
  String goalsProgressOf(String current, String target) {
    return '$target-এর মধ্যে $current';
  }

  @override
  String goalsRemaining(String amount) {
    return '$amount বাকি';
  }

  @override
  String get goalsRestoreGoal => 'লক্ষ্য ফিরিয়ে আনুন';

  @override
  String goalsSavePerMonth(String amount) {
    return 'প্রতি মাসে $amount সঞ্চয় করুন';
  }

  @override
  String get goalsSavingsAccount => 'সঞ্চয়ের হিসাব';

  @override
  String get goalsSelectProfile =>
      'লক্ষ্য পরিচালনা করতে একটি প্রোফাইল বেছে নিন।';

  @override
  String get goalsShowArchived => 'আর্কাইভ করা দেখান';

  @override
  String get goalsTargetAmount => 'লক্ষ্যমাত্রা';

  @override
  String goalsTargetDate(String date) {
    return 'লক্ষ্যের তারিখ $date';
  }

  @override
  String get goalsTargetDateOptional => 'লক্ষ্যের তারিখ (ঐচ্ছিক)';

  @override
  String get goalsTargetPositive => 'লক্ষ্যমাত্রা শূন্যের চেয়ে বেশি হতে হবে';

  @override
  String get goalsTitle => 'সঞ্চয় লক্ষ্য';

  @override
  String get importChooseFile => 'সিএসভি ফাইল বেছে নিন';

  @override
  String get importColAmount => 'পরিমাণ *';

  @override
  String get importColCategory => 'ক্যাটাগরি';

  @override
  String get importColDate => 'তারিখ *';

  @override
  String get importColDescription => 'বিবরণ';

  @override
  String get importColType => 'ধরন (খরচ/আয়)';

  @override
  String get importColTypeNone => 'পরিমাণের +/- চিহ্ন ব্যবহার করুন';

  @override
  String importCouldNotRead(String error) {
    return 'ফাইলটি পড়া যায়নি: $error';
  }

  @override
  String get importDateFormat => 'তারিখের ফরম্যাট';

  @override
  String get importDefaultCategory => 'খরচের ডিফল্ট ক্যাটাগরি';

  @override
  String get importDefaultCategoryHelp =>
      'কোনো সারিতে ক্যাটাগরি না থাকলে বা নাম বিদ্যমান ক্যাটাগরির সাথে হুবহু না মিললে এটি ব্যবহার হয়। ক্যাটাগরি কখনো স্বয়ংক্রিয়ভাবে তৈরি হয় না।';

  @override
  String get importDefaultCategoryNone =>
      'কোনোটি নয় (যে সারির মিল নেই তা অবৈধ)';

  @override
  String get importDelimiterTab => 'ট্যাব';

  @override
  String get importFinished => 'ইম্পোর্ট সম্পন্ন';

  @override
  String get importFirstRowHeader => 'প্রথম সারিটি হেডার';

  @override
  String importImportFailed(String error) {
    return 'ইম্পোর্ট ব্যর্থ হয়েছে: $error';
  }

  @override
  String importImportRows(int count) {
    return '$countটি সারি ইম্পোর্ট করুন';
  }

  @override
  String importImported(int count) {
    return 'ইম্পোর্ট হয়েছে: $count';
  }

  @override
  String get importIntoAccount => 'যে হিসাবে ইম্পোর্ট হবে *';

  @override
  String get importIntro =>
      'ব্যাংক বা ই-ওয়ালেটের সিএসভি থেকে খরচ ও আয় ইম্পোর্ট করুন। একই ফাইল আবার ইম্পোর্ট করলে ডুপ্লিকেট তৈরি হয় না।';

  @override
  String get importInvalidNote =>
      'অবৈধ সারি বাদ যাবে; বৈধ সারিগুলো হয় সব ইম্পোর্ট হবে, নয়তো একটিও হবে না।';

  @override
  String importInvalidRows(int count) {
    return 'অবৈধ সারি: $count';
  }

  @override
  String get importKindExpense => 'খরচ';

  @override
  String get importKindIncome => 'আয়';

  @override
  String get importNoDescription => '(কোনো বিবরণ নেই)';

  @override
  String get importNotMapped => '(মেলানো হয়নি)';

  @override
  String importRowDuplicate(int number) {
    return 'সারি $number: আগেই ইম্পোর্ট করা';
  }

  @override
  String importRowInvalid(int number, String cells) {
    return 'সারি $number: $cells';
  }

  @override
  String importRowValid(int number, String kind, String amount) {
    return 'সারি $number: $kind $amount';
  }

  @override
  String importSkippedDuplicates(int count) {
    return 'বাদ দেওয়া ডুপ্লিকেট: $count';
  }

  @override
  String get importStep1 => '১. ফাইল বেছে নিন';

  @override
  String importStep2(int rows, String delimiter) {
    return '২. কলাম মিলিয়ে নিন  ($rowsটি সারি, বিভাজক \"$delimiter\")';
  }

  @override
  String get importStep3 => '৩. প্রিভিউ';

  @override
  String importSummary(int valid, int duplicate, int invalid, int shown) {
    return '$validটি ইম্পোর্ট হবে · $duplicateটি আগেই ইম্পোর্ট করা · $invalidটি অবৈধ (প্রথম $shownটি সারি দেখানো হচ্ছে)';
  }

  @override
  String get importTitle => 'সিএসভি ইম্পোর্ট';

  @override
  String insightsCategoryDown(String name, String amount, String percent) {
    return 'গত মাসের তুলনায় $name $amount$percent কমেছে';
  }

  @override
  String insightsCategoryNew(String name, String amount) {
    return 'এই মাসে $name নতুন: $amount';
  }

  @override
  String insightsCategoryUp(String name, String amount, String percent) {
    return 'গত মাসের তুলনায় $name $amount$percent বেড়েছে';
  }

  @override
  String insightsForecastAtRisk(String projected, String budget) {
    return 'ঝুঁকিতে: আনুমানিক $projected আপনার $budget বাজেটের কাছাকাছি';
  }

  @override
  String insightsForecastDetail(String spent, String average, int days) {
    return 'এ পর্যন্ত খরচ $spent · দৈনিক গড় $average · আর $days দিন বাকি';
  }

  @override
  String insightsForecastNoBudget(String projected) {
    return 'মাস শেষে আনুমানিক খরচ: $projected (বাজেট নির্ধারিত নেই)';
  }

  @override
  String insightsForecastOnTrack(String projected, String budget) {
    return 'ঠিক পথে: আপনার $budget বাজেটের মধ্যে আনুমানিক $projected';
  }

  @override
  String insightsForecastOver(String over, String projected, String budget) {
    return 'আনুমানিক বাজেট ছাড়িয়ে যাবে $over ($projected, বাজেট $budget)';
  }

  @override
  String insightsForecastRecurring(String amount) {
    return 'আসন্ন পুনরাবৃত্ত খরচের $amount ধরা হয়েছে';
  }

  @override
  String get insightsForecastTitle => 'মাস শেষের পূর্বাভাস';

  @override
  String get insightsNextMonth => 'পরের মাস';

  @override
  String get insightsNoData => 'এই মাসে এখনও কোনো খরচের তথ্য নেই।';

  @override
  String get insightsNoExpenses => 'এই মাসে কোনো খরচ নেই।';

  @override
  String get insightsNoIncome => 'এই মাসে কোনো আয় নেই।';

  @override
  String get insightsNothingUnusual => 'এই মাসে অস্বাভাবিক কিছু নেই।';

  @override
  String get insightsPreviousMonth => 'আগের মাস';

  @override
  String insightsSavingsOverspent(int percent) {
    return 'এই মাসে আপনি আয়ের চেয়ে $percent% বেশি খরচ করেছেন';
  }

  @override
  String get insightsSavingsRate => 'সঞ্চয়ের হার';

  @override
  String insightsSavingsSaved(int percent) {
    return 'এই মাসে আপনি আয়ের $percent% সঞ্চয় করেছেন';
  }

  @override
  String get insightsTitle => 'ইনসাইটস';

  @override
  String get insightsTopItems => 'এই মাসের শীর্ষ আইটেম';

  @override
  String insightsTotalDown(String amount, String percent) {
    return 'গত মাসের তুলনায় মোট খরচ $amount$percent কমেছে';
  }

  @override
  String insightsTotalNoPrevious(String amount) {
    return 'গত মাসে খরচ ছিল না, এই মাসে আপনি $amount খরচ করেছেন';
  }

  @override
  String get insightsTotalNone => 'এই মাসে বা গত মাসে কোনো খরচ নেই';

  @override
  String get insightsTotalSame => 'খরচ গত মাসের সমান';

  @override
  String insightsTotalUp(String amount, String percent) {
    return 'গত মাসের তুলনায় মোট খরচ $amount$percent বেড়েছে';
  }

  @override
  String insightsUnusual(
    String amount,
    String label,
    String excess,
    String usual,
  ) {
    return 'অস্বাভাবিক: $label-এ $amount খরচ আপনার স্বাভাবিক $usual থেকে $excess বেশি';
  }

  @override
  String get insightsUnusualSpending => 'অস্বাভাবিক খরচ';

  @override
  String get insightsVsLastMonth => 'গত মাসের তুলনায়';

  @override
  String get insightsWeekdayCardTitle =>
      'সপ্তাহের দিন অনুযায়ী খরচ (গত ৯০ দিন)';

  @override
  String get insightsWeekdayMostFri => 'আপনি সবচেয়ে বেশি খরচ করেন শুক্রবারে';

  @override
  String get insightsWeekdayMostMon => 'আপনি সবচেয়ে বেশি খরচ করেন সোমবারে';

  @override
  String get insightsWeekdayMostSat => 'আপনি সবচেয়ে বেশি খরচ করেন শনিবারে';

  @override
  String get insightsWeekdayMostSun => 'আপনি সবচেয়ে বেশি খরচ করেন রবিবারে';

  @override
  String get insightsWeekdayMostThu =>
      'আপনি সবচেয়ে বেশি খরচ করেন বৃহস্পতিবারে';

  @override
  String get insightsWeekdayMostTue => 'আপনি সবচেয়ে বেশি খরচ করেন মঙ্গলবারে';

  @override
  String get insightsWeekdayMostWed => 'আপনি সবচেয়ে বেশি খরচ করেন বুধবারে';

  @override
  String get ledgerAccount => 'হিসাব';

  @override
  String ledgerAccountInactive(String name) {
    return '$name (নিষ্ক্রিয়)';
  }

  @override
  String get ledgerAccountTab => 'হিসাব লেজার';

  @override
  String get ledgerBudgetTab => 'বাজেট লেজার';

  @override
  String get ledgerClearSearch => 'খোঁজা মুছুন';

  @override
  String get ledgerColBalance => 'ব্যালেন্স';

  @override
  String get ledgerColCategory => 'ক্যাটাগরি';

  @override
  String get ledgerColCostItem => 'খরচের আইটেম';

  @override
  String get ledgerColDate => 'তারিখ';

  @override
  String get ledgerColDescription => 'বিবরণ';

  @override
  String get ledgerColExpense => 'খরচ';

  @override
  String get ledgerColIncome => 'আয়';

  @override
  String get ledgerColRemainingBudget => 'অবশিষ্ট বাজেট';

  @override
  String get ledgerColTransferIn => 'ট্রান্সফার ইন';

  @override
  String get ledgerColTransferOut => 'ট্রান্সফার আউট';

  @override
  String ledgerMonthlyBudget(String amount) {
    return 'মাসিক বাজেট: $amount';
  }

  @override
  String get ledgerNextMonth => 'পরের মাস';

  @override
  String get ledgerNextYear => 'পরের বছর';

  @override
  String get ledgerNoAccounts =>
      'এখনও কোনো হিসাব নেই। লেজার দেখতে একটি হিসাব যোগ করুন।';

  @override
  String get ledgerNoBudget => 'বাজেট নেই';

  @override
  String get ledgerNoBudgetSet => 'এই মাসে কোনো বাজেট নির্ধারিত নেই।';

  @override
  String get ledgerNoExpenses => 'এই মাসে কোনো খরচ নেই।';

  @override
  String get ledgerNoTransactions => 'এই সময়ে কোনো লেনদেন নেই।';

  @override
  String get ledgerOpeningBalance => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get ledgerPreviousMonth => 'আগের মাস';

  @override
  String get ledgerPreviousYear => 'আগের বছর';

  @override
  String get ledgerSearchHint => 'শিরোনাম, মন্তব্য, ক্যাটাগরি, আইটেম খুঁজুন';

  @override
  String get ledgerSelect => 'নির্বাচন';

  @override
  String get ledgerTotal => 'মোট';

  @override
  String get notificationsBudgetAlerts => 'বাজেট সতর্কতা';

  @override
  String get notificationsBudgetAlertsSubtitle =>
      '৮০% হলে এবং বাজেট ছাড়ালে সতর্ক করুন';

  @override
  String notificationsBudgetWarningBody(String spent, String budget) {
    return 'আপনি বাজেটের ৮০% ব্যবহার করেছেন ($budget-এর মধ্যে $spent)।';
  }

  @override
  String notificationsBudgetWarningTitle(String label) {
    return 'বাজেট সতর্কতা: $label';
  }

  @override
  String get notificationsCategoryFallback => 'ক্যাটাগরি';

  @override
  String get notificationsCollectTitle => 'আদায়যোগ্য টাকা';

  @override
  String get notificationsDebtDueTitle => 'ঋণ পরিশোধের সময়';

  @override
  String notificationsDueInDays(
    String title,
    String amount,
    int days,
    String date,
  ) {
    return '$title ($amount) $days দিন পরে ($date) দেয়।';
  }

  @override
  String notificationsDueToday(String title, String amount) {
    return '$title ($amount) আজ দেয়।';
  }

  @override
  String notificationsDueTomorrow(String title, String amount) {
    return '$title ($amount) আগামীকাল দেয়।';
  }

  @override
  String get notificationsMonthlyBudget => 'মাসিক বাজেট';

  @override
  String notificationsOverBudgetBody(String spent, String budget) {
    return 'এই মাসে $budget-এর মধ্যে $spent খরচ হয়েছে এবং বাজেট ছাড়িয়ে গেছে।';
  }

  @override
  String notificationsOverBudgetTitle(String label) {
    return 'বাজেট ছাড়িয়েছে: $label';
  }

  @override
  String notificationsOwesYouToday(String person, String amount) {
    return '$person আপনাকে $amount দেবেন, আজ শেষ তারিখ।';
  }

  @override
  String notificationsOwesYouTomorrow(String person, String amount) {
    return '$person আপনাকে $amount দেবেন, আগামীকাল শেষ তারিখ।';
  }

  @override
  String get notificationsPermissionDenied =>
      'নোটিফিকেশনের অনুমতি দেওয়া হয়নি। সিস্টেম সেটিংসে MyBudget-এর নোটিফিকেশন অনুমতি দিন, তারপর এটি আবার চালু করুন।';

  @override
  String get notificationsReminderTime => 'রিমাইন্ডারের সময়';

  @override
  String get notificationsReminders => 'বিল ও ঋণের রিমাইন্ডার';

  @override
  String get notificationsRemindersSubtitle =>
      'পুনরাবৃত্ত বিল ও ঋণের শেষ তারিখের আগে মনে করিয়ে দিন';

  @override
  String get notificationsSendTest => 'টেস্ট নোটিফিকেশন পাঠান';

  @override
  String get notificationsTestBody => 'নোটিফিকেশন কাজ করছে।';

  @override
  String get notificationsTestDenied => 'অনুমতি নেই - পাঠানো যাচ্ছে না';

  @override
  String get notificationsTestSent => 'টেস্ট নোটিফিকেশন পাঠানো হয়েছে';

  @override
  String get notificationsTestTitle => 'MyBudget টেস্ট নোটিফিকেশন';

  @override
  String get notificationsTitle => 'নোটিফিকেশন';

  @override
  String notificationsUpcomingTitle(String title) {
    return 'আসন্ন: $title';
  }

  @override
  String notificationsYouOweToday(String person, String amount) {
    return 'আপনি $person-কে $amount দেবেন, আজ শেষ তারিখ।';
  }

  @override
  String notificationsYouOweTomorrow(String person, String amount) {
    return 'আপনি $person-কে $amount দেবেন, আগামীকাল শেষ তারিখ।';
  }

  @override
  String get preferencesLanguage => 'ভাষা';

  @override
  String get preferencesLanguageSystem => 'সিস্টেমের ডিফল্ট';

  @override
  String get preferencesTheme => 'থিম';

  @override
  String get preferencesThemeDark => 'ডার্ক';

  @override
  String get preferencesThemeLight => 'লাইট';

  @override
  String get preferencesThemeSystem => 'সিস্টেম';

  @override
  String get preferencesTitle => 'পছন্দসমূহ';

  @override
  String get profilesCurrencyLabel => 'মুদ্রা';

  @override
  String get profilesDeactivate => 'নিষ্ক্রিয় করুন';

  @override
  String profilesDeactivateMessage(String name) {
    return '\"$name\" নির্বাচন তালিকা থেকে লুকানো হবে। কোনো ডেটা মুছবে না এবং যেকোনো সময় আবার সক্রিয় করতে পারবেন।';
  }

  @override
  String get profilesDeactivateTitle => 'প্রোফাইল নিষ্ক্রিয় করবেন?';

  @override
  String get profilesEmpty =>
      'এখনও কোনো প্রোফাইল নেই।\nশুরু করতে একটি তৈরি করুন।';

  @override
  String profilesInactiveSubtitle(String currency) {
    return '$currency - নিষ্ক্রিয়';
  }

  @override
  String get profilesNameLabel => 'প্রোফাইলের নাম';

  @override
  String get profilesNameRequired => 'নাম দিতে হবে';

  @override
  String get profilesNew => 'নতুন প্রোফাইল';

  @override
  String get profilesReactivate => 'আবার সক্রিয় করুন';

  @override
  String profilesReactivateMessage(String name) {
    return '\"$name\" আবার ব্যবহার করা যাবে।';
  }

  @override
  String get profilesReactivateTitle => 'প্রোফাইল আবার সক্রিয় করবেন?';

  @override
  String get profilesSelectTitle => 'প্রোফাইল নির্বাচন';

  @override
  String get recurringAddTooltip => 'পুনরাবৃত্ত নিয়ম যোগ করুন';

  @override
  String get recurringClearEndDate => 'শেষের তারিখ মুছুন';

  @override
  String get recurringCreateRule => 'নিয়ম তৈরি করুন';

  @override
  String recurringDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count দিন আগে',
      one: '$count দিন আগে',
    );
    return '$_temp0';
  }

  @override
  String get recurringDifferentAccount => 'অন্য একটি হিসাব বেছে নিন';

  @override
  String get recurringEmpty =>
      'এখনও কোনো পুনরাবৃত্ত নিয়ম নেই। যোগ করতে + চাপুন।';

  @override
  String get recurringEnterAmount => 'সঠিক পরিমাণ লিখুন';

  @override
  String get recurringEnterIncomeSource => 'আয়ের উৎস লিখুন';

  @override
  String get recurringEnterTitle => 'একটি শিরোনাম লিখুন';

  @override
  String recurringEveryN(String frequency, int count) {
    return '$frequency (প্রতি $count)';
  }

  @override
  String get recurringFieldAccount => 'হিসাব';

  @override
  String get recurringFieldAmount => 'পরিমাণ';

  @override
  String get recurringFieldCategory => 'ক্যাটাগরি';

  @override
  String get recurringFieldCostItem => 'খরচের আইটেম (ঐচ্ছিক)';

  @override
  String get recurringFieldEndDate => 'শেষের তারিখ (ঐচ্ছিক)';

  @override
  String get recurringFieldEveryN => 'প্রতি N';

  @override
  String get recurringFieldFrequency => 'পুনরাবৃত্তি';

  @override
  String get recurringFieldFromAccount => 'যে হিসাব থেকে';

  @override
  String get recurringFieldIncomeSource => 'আয়ের উৎস';

  @override
  String get recurringFieldRemarks => 'মন্তব্য (ঐচ্ছিক)';

  @override
  String get recurringFieldReminder => 'রিমাইন্ডার';

  @override
  String get recurringFieldStartDate => 'শুরুর তারিখ';

  @override
  String get recurringFieldSubCategory => 'সাব-ক্যাটাগরি (ঐচ্ছিক)';

  @override
  String get recurringFieldTitle => 'শিরোনাম';

  @override
  String get recurringFieldToAccount => 'যে হিসাবে';

  @override
  String get recurringFormEdit => 'পুনরাবৃত্ত নিয়ম সম্পাদনা';

  @override
  String get recurringFormNew => 'নতুন পুনরাবৃত্ত নিয়ম';

  @override
  String get recurringFreqDaily => 'প্রতিদিন';

  @override
  String get recurringFreqMonthly => 'মাসিক';

  @override
  String get recurringFreqWeekly => 'সাপ্তাহিক';

  @override
  String get recurringFreqYearly => 'বার্ষিক';

  @override
  String get recurringMin1 => 'সর্বনিম্ন ১';

  @override
  String get recurringNoEnd => 'শেষ নেই';

  @override
  String get recurringNoProfile =>
      'পুনরাবৃত্ত লেনদেন পরিচালনা করতে একটি প্রোফাইল বেছে নিন।';

  @override
  String get recurringNoReminder => 'কোনো রিমাইন্ডার নেই';

  @override
  String get recurringOnTheDay => 'সেদিনই';

  @override
  String get recurringPause => 'বিরতি দিন';

  @override
  String get recurringResume => 'চালু করুন';

  @override
  String get recurringSaveChanges => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get recurringSelectAccount => 'একটি হিসাব বেছে নিন';

  @override
  String get recurringSelectCategory => 'একটি ক্যাটাগরি বেছে নিন';

  @override
  String get recurringSelectDestination => 'গন্তব্য বেছে নিন';

  @override
  String get recurringStatusEnded => 'শেষ হয়েছে';

  @override
  String recurringStatusNext(String date) {
    return 'পরবর্তী: $date';
  }

  @override
  String get recurringStatusPaused => 'বিরতিতে';

  @override
  String get recurringTitle => 'পুনরাবৃত্ত লেনদেন';

  @override
  String get recurringTypeExpense => 'খরচ';

  @override
  String get recurringTypeIncome => 'আয়';

  @override
  String get recurringTypeTransfer => 'ট্রান্সফার';

  @override
  String get reportsAccount => 'হিসাব';

  @override
  String reportsAccountFlow(
    String name,
    String income,
    String expense,
    String transferIn,
    String transferOut,
  ) {
    return '$name\n+$income  -$expense  আসা $transferIn  যাওয়া $transferOut';
  }

  @override
  String get reportsAccountMovements => 'হিসাবের লেনদেন';

  @override
  String get reportsAmount => 'পরিমাণ';

  @override
  String get reportsAvgMonthlyExpense => 'গড় মাসিক খরচ';

  @override
  String get reportsBudget => 'বাজেট';

  @override
  String get reportsCategory => 'ক্যাটাগরি';

  @override
  String get reportsCategoryComparison => 'ক্যাটাগরি তুলনা';

  @override
  String get reportsCategoryWiseExpense => 'ক্যাটাগরি অনুযায়ী খরচ';

  @override
  String get reportsClosing => 'সমাপনী';

  @override
  String get reportsCustomRange => 'কাস্টম সময়সীমা';

  @override
  String get reportsCustomRangeReport => 'কাস্টম সময়সীমার রিপোর্ট';

  @override
  String get reportsCustomRangeSubtitle => 'যেকোনো শুরু ও শেষের তারিখ বেছে নিন';

  @override
  String get reportsDailyExpenditure => 'দৈনিক খরচ';

  @override
  String get reportsExpense => 'খরচ';

  @override
  String get reportsExportCsv => 'সিএসভি এক্সপোর্ট';

  @override
  String reportsExportFailed(String error) {
    return 'এক্সপোর্ট ব্যর্থ হয়েছে: $error';
  }

  @override
  String get reportsExportPdf => 'পিডিএফ এক্সপোর্ট';

  @override
  String get reportsHighestMonth => 'সর্বোচ্চ খরচের মাস';

  @override
  String get reportsIncome => 'আয়';

  @override
  String get reportsIncomeVsExpense => 'আয় বনাম খরচ';

  @override
  String get reportsItem => 'আইটেম';

  @override
  String get reportsItems => 'আইটেম';

  @override
  String get reportsLowestMonth => 'সর্বনিম্ন খরচের মাস';

  @override
  String get reportsMonth => 'মাস';

  @override
  String get reportsMonth01Full => 'জানুয়ারি';

  @override
  String get reportsMonth01Short => 'জানুয়ারি';

  @override
  String get reportsMonth02Full => 'ফেব্রুয়ারি';

  @override
  String get reportsMonth02Short => 'ফেব্রুয়ারি';

  @override
  String get reportsMonth03Full => 'মার্চ';

  @override
  String get reportsMonth03Short => 'মার্চ';

  @override
  String get reportsMonth04Full => 'এপ্রিল';

  @override
  String get reportsMonth04Short => 'এপ্রিল';

  @override
  String get reportsMonth05Full => 'মে';

  @override
  String get reportsMonth05Short => 'মে';

  @override
  String get reportsMonth06Full => 'জুন';

  @override
  String get reportsMonth06Short => 'জুন';

  @override
  String get reportsMonth07Full => 'জুলাই';

  @override
  String get reportsMonth07Short => 'জুলাই';

  @override
  String get reportsMonth08Full => 'আগস্ট';

  @override
  String get reportsMonth08Short => 'আগস্ট';

  @override
  String get reportsMonth09Full => 'সেপ্টেম্বর';

  @override
  String get reportsMonth09Short => 'সেপ্টেম্বর';

  @override
  String get reportsMonth10Full => 'অক্টোবর';

  @override
  String get reportsMonth10Short => 'অক্টোবর';

  @override
  String get reportsMonth11Full => 'নভেম্বর';

  @override
  String get reportsMonth11Short => 'নভেম্বর';

  @override
  String get reportsMonth12Full => 'ডিসেম্বর';

  @override
  String get reportsMonth12Short => 'ডিসেম্বর';

  @override
  String get reportsMonthlyComparison => 'মাসভিত্তিক তুলনা';

  @override
  String get reportsMonthlyReport => 'মাসিক রিপোর্ট';

  @override
  String get reportsMonthlyReportSubtitle =>
      'আয়, খরচ, বাজেট, ক্যাটাগরি ও দৈনিক খরচ';

  @override
  String get reportsNet => 'নিট';

  @override
  String get reportsNext => 'পরেরটি';

  @override
  String get reportsNoData => 'কোনো তথ্য নেই';

  @override
  String get reportsNoDataMonth => 'এই মাসের কোনো তথ্য নেই।';

  @override
  String get reportsNoDataYear => 'এই বছরের কোনো তথ্য নেই।';

  @override
  String get reportsNoExpensesMonth => 'এই মাসে কোনো খরচ নেই।';

  @override
  String get reportsNoExpensesRange => 'এই সময়সীমায় কোনো খরচ নেই।';

  @override
  String get reportsNoTransactionsRange => 'এই সময়সীমায় কোনো লেনদেন নেই।';

  @override
  String get reportsNotSet => 'নির্ধারণ করা হয়নি';

  @override
  String get reportsOpening => 'প্রারম্ভিক';

  @override
  String get reportsOverBudget => 'বাজেটের চেয়ে বেশি';

  @override
  String get reportsPrevious => 'আগেরটি';

  @override
  String get reportsPrint => 'প্রিন্ট';

  @override
  String reportsRangeFromTo(String from, String to) {
    return '$from  থেকে  $to';
  }

  @override
  String get reportsRemaining => 'অবশিষ্ট';

  @override
  String get reportsSelectDayHelp => 'মাসের যেকোনো একটি দিন বেছে নিন';

  @override
  String get reportsSelectYear => 'বছর বেছে নিন';

  @override
  String get reportsSubCategories => 'উপ-ক্যাটাগরি';

  @override
  String get reportsSubCategory => 'উপ-ক্যাটাগরি';

  @override
  String get reportsTotal => 'মোট';

  @override
  String get reportsUtilization => 'ব্যবহারের হার';

  @override
  String get reportsYearlyReport => 'বার্ষিক রিপোর্ট';

  @override
  String get reportsYearlyReportSubtitle =>
      '১২ মাসের হিসাব, তুলনা, সর্বোচ্চ ও সর্বনিম্ন খরচের মাস';

  @override
  String get searchChipAccount => 'হিসাব';

  @override
  String get searchChipCategory => 'ক্যাটাগরি';

  @override
  String searchChipFrom(String date) {
    return '$date থেকে';
  }

  @override
  String searchChipTag(String name) {
    return '#$name';
  }

  @override
  String searchChipTo(String date) {
    return '$date পর্যন্ত';
  }

  @override
  String get searchClearAll => 'সব মুছুন';

  @override
  String get searchClearFilters => 'ফিল্টার মুছুন';

  @override
  String get searchClearText => 'লেখা মুছুন';

  @override
  String get searchEmptyHint =>
      'শিরোনাম, মন্তব্য, ক্যাটাগরি, হিসাব, ট্যাগ দিয়ে খুঁজুন…';

  @override
  String get searchErrDateOrder => 'শুরুর তারিখ শেষ তারিখের পরে';

  @override
  String get searchErrInvalidMax => 'সর্বোচ্চ পরিমাণ সঠিক নয়';

  @override
  String get searchErrInvalidMin => 'সর্বনিম্ন পরিমাণ সঠিক নয়';

  @override
  String get searchErrMinGreater => 'সর্বনিম্ন পরিমাণ সর্বোচ্চের চেয়ে বেশি';

  @override
  String get searchFilters => 'ফিল্টার';

  @override
  String get searchFrom => 'থেকে';

  @override
  String get searchHint => 'লেনদেন খুঁজুন';

  @override
  String get searchMax => 'সর্বোচ্চ';

  @override
  String get searchMin => 'সর্বনিম্ন';

  @override
  String get searchNoResults => 'কোনো মিলে যাওয়া লেনদেন নেই।';

  @override
  String get searchNoneAvailable => 'কিছু নেই';

  @override
  String get searchRecent => 'সাম্প্রতিক খোঁজা';

  @override
  String get searchRemove => 'সরান';

  @override
  String get searchReset => 'রিসেট';

  @override
  String get searchResults => 'ফলাফল';

  @override
  String get searchSectionAccounts => 'হিসাব';

  @override
  String get searchSectionAmount => 'পরিমাণ';

  @override
  String get searchSectionCategories => 'ক্যাটাগরি';

  @override
  String get searchSectionDateRange => 'তারিখের সীমা';

  @override
  String get searchSectionSortBy => 'সাজানোর ক্রম';

  @override
  String get searchSectionTags => 'ট্যাগ';

  @override
  String get searchSectionType => 'ধরন';

  @override
  String get searchSortHighest => 'বেশি আগে';

  @override
  String get searchSortLowest => 'কম আগে';

  @override
  String get searchSortNewest => 'নতুন আগে';

  @override
  String get searchSortOldest => 'পুরনো আগে';

  @override
  String get searchTagFallback => 'ট্যাগ';

  @override
  String get searchTo => 'পর্যন্ত';

  @override
  String get searchTypeExpense => 'খরচ';

  @override
  String get searchTypeIncome => 'আয়';

  @override
  String get searchTypeTransfer => 'ট্রান্সফার';

  @override
  String get securityAppLock => 'অ্যাপ লক';

  @override
  String get securityAppLockSubtitle => 'MyBudget খুলতে পিন লাগবে';

  @override
  String get securityAutoLock => 'অটো-লক';

  @override
  String get securityAutoLockSubtitle => 'অ্যাপ ব্যাকগ্রাউন্ডে গেলে লক হবে';

  @override
  String get securityBiometric => 'বায়োমেট্রিক দিয়ে আনলক';

  @override
  String get securityBiometricConfirm =>
      'বায়োমেট্রিক আনলক চালু করতে নিশ্চিত করুন';

  @override
  String get securityBiometricUnlock => 'MyBudget আনলক করুন';

  @override
  String get securityChangePin => 'পিন পরিবর্তন';

  @override
  String get securityConfirmNewPinLabel => 'নতুন পিন নিশ্চিত করুন';

  @override
  String get securityConfirmPinLabel => 'পিন নিশ্চিত করুন';

  @override
  String get securityCurrentPinLabel => 'বর্তমান পিন';

  @override
  String get securityDelay1m => '১ মিনিট পরে';

  @override
  String get securityDelay30s => '৩০ সেকেন্ড পরে';

  @override
  String get securityDelay5m => '৫ মিনিট পরে';

  @override
  String get securityDelayImmediately => 'সঙ্গে সঙ্গে';

  @override
  String get securityEnterPin => 'আনলক করতে পিন দিন';

  @override
  String get securityForgotPin => 'পিন ভুলে গেছেন?';

  @override
  String get securityIncorrectPin => 'ভুল পিন।';

  @override
  String get securityIncorrectPinShort => 'ভুল পিন';

  @override
  String securityLockout(int seconds) {
    return 'অনেকবার ভুল হয়েছে। $seconds সেকেন্ড পরে আবার চেষ্টা করুন।';
  }

  @override
  String securityLockoutShort(int seconds) {
    return 'অনেকবার ভুল হয়েছে। $seconds সেকেন্ড পরে আবার চেষ্টা করুন';
  }

  @override
  String get securityNewPinLabel => 'নতুন পিন (৪-৬ অঙ্ক)';

  @override
  String get securityNewPinsMismatch => 'নতুন পিন দুটি মিলছে না।';

  @override
  String get securityNewRecoveryCode => 'নতুন রিকভারি কোড';

  @override
  String get securityNewRecoveryCodeSubtitle =>
      'পুরনো কোডের জায়গায় নতুন কোড বসবে';

  @override
  String get securityNotEnabled => 'অ্যাপ লক চালু নেই।';

  @override
  String get securityPinChanged => 'পিন পরিবর্তন হয়েছে';

  @override
  String get securityPinInvalid => 'পিন অবশ্যই ৪ থেকে ৬ অঙ্কের হতে হবে।';

  @override
  String get securityPinsMismatch => 'পিন দুটি মিলছে না।';

  @override
  String get securityRecoverAction => 'রিসেট';

  @override
  String get securityRecoverBody =>
      'আপনার রিকভারি কোড লিখুন। অ্যাপ লক বন্ধ হয়ে যাবে এবং আপনি সেটিংস > সিকিউরিটি থেকে নতুন পিন দিতে পারবেন।';

  @override
  String get securityRecoverCancel => 'ফিরে যান';

  @override
  String get securityRecoverInvalid => 'রিকভারি কোডটি সঠিক নয়।';

  @override
  String get securityRecoverLabel => 'রিকভারি কোড';

  @override
  String get securityRecoverTitle => 'রিকভারি কোড দিয়ে রিসেট';

  @override
  String get securityRecoveryBody =>
      'পিন ভুলে গেলে এই কোডই অ্যাপে ঢোকার একমাত্র উপায়। এটি লিখে নিরাপদ জায়গায় রাখুন। কোডটি শুধু একবারই দেখানো হয়।';

  @override
  String get securityRecoveryCopied => 'কোড কপি হয়েছে';

  @override
  String get securityRecoveryCopy => 'কপি';

  @override
  String get securityRecoverySaved => 'আমি সংরক্ষণ করেছি';

  @override
  String get securityRecoveryTitle => 'আপনার রিকভারি কোড';

  @override
  String get securitySetPin => 'পিন সেট করুন';

  @override
  String get securityTitle => 'নিরাপত্তা';

  @override
  String get securityTurnOff => 'অ্যাপ লক বন্ধ করুন';

  @override
  String get setupAllDone =>
      'সব ঠিক আছে! আপনি MyBudget ব্যবহারের জন্য প্রস্তুত।';

  @override
  String get setupCardAction => 'চালিয়ে যান';

  @override
  String get setupCardTitle => 'সেটআপ শেষ করুন';

  @override
  String get setupDismiss => 'এই নির্দেশনা লুকান';

  @override
  String get setupDone => 'সম্পন্ন';

  @override
  String get setupGo => 'যান';

  @override
  String get setupOpenManual => 'ব্যবহার নির্দেশিকা পড়ুন';

  @override
  String setupProgress(int done, int total) {
    return '$totalটির মধ্যে $doneটি ধাপ সম্পন্ন';
  }

  @override
  String get setupStepAccount => 'একটি অ্যাকাউন্ট যোগ করুন';

  @override
  String get setupStepAccountBody =>
      'আপনার টাকা যেখানে আছে, যেমন নগদ বা ব্যাংক। শুরুর ব্যালেন্স দিন।';

  @override
  String get setupStepBudget => 'এই মাসের বাজেট ঠিক করুন';

  @override
  String get setupStepBudgetBody => 'এই মাসে কত খরচ করার পরিকল্পনা করছেন।';

  @override
  String get setupStepCategory => 'একটি ক্যাটাগরি তৈরি করুন';

  @override
  String get setupStepCategoryBody =>
      'যেমন খাবার বা যাতায়াত। সাব-ক্যাটাগরি ও আইটেম পরে যোগ করা যাবে।';

  @override
  String get setupStepTransaction => 'প্রথম লেনদেন লিখুন';

  @override
  String get setupStepTransactionBody => 'একটি খরচ বা আয় যোগ করুন।';

  @override
  String get setupTitle => 'শুরু করুন';

  @override
  String get splitAccount => 'অ্যাকাউন্ট';

  @override
  String get splitAddLine => 'লাইন যোগ করুন';

  @override
  String get splitAmount => 'অঙ্ক';

  @override
  String get splitBillTitle => 'শিরোনাম (ঐচ্ছিক)';

  @override
  String get splitCategory => 'ক্যাটাগরি';

  @override
  String get splitCostItem => 'কস্ট আইটেম (ঐচ্ছিক)';

  @override
  String get splitErrAccount => 'একটি অ্যাকাউন্ট বেছে নিন।';

  @override
  String get splitErrLine =>
      'প্রতিটি লাইনে ক্যাটাগরি ও শূন্যের বেশি অঙ্ক লাগবে।';

  @override
  String get splitIntro =>
      'একটি বিলে একাধিক ক্যাটাগরির খরচ থাকলে এটি ব্যবহার করুন, যেমন বাজার ও ঘরের জিনিস। প্রতিটি লাইন আলাদা খরচ হিসেবে সংরক্ষিত হয়, সব একসাথে নয়তো কিছুই নয়।';

  @override
  String splitLine(int n) {
    return 'লাইন $n';
  }

  @override
  String get splitOpen => 'বিল ভাগ করুন';

  @override
  String get splitRemoveLine => 'লাইন সরান';

  @override
  String get splitSave => 'ভাগ সংরক্ষণ করুন';

  @override
  String splitSaved(int n) {
    return '$nটি খরচ সংরক্ষিত হয়েছে';
  }

  @override
  String get splitSubCategory => 'সাব-ক্যাটাগরি (ঐচ্ছিক)';

  @override
  String get splitTitle => 'বিল ভাগ করুন';

  @override
  String splitTotal(String amount) {
    return 'মোট: $amount';
  }

  @override
  String subCategoriesActivateMessage(String name) {
    return '\"$name\" আবার ব্যবহার করা যাবে।';
  }

  @override
  String get subCategoriesActivateTitle => 'সাব-ক্যাটাগরি সক্রিয় করবেন?';

  @override
  String get subCategoriesAdd => 'সাব-ক্যাটাগরি যোগ করুন';

  @override
  String get subCategoriesCategoryLabel => 'ক্যাটাগরি';

  @override
  String subCategoriesDeactivateMessage(String name) {
    return 'নতুন এন্ট্রি থেকে \"$name\" লুকানো থাকবে। বিদ্যমান তথ্য সংরক্ষিত থাকবে।';
  }

  @override
  String get subCategoriesDeactivateTitle => 'সাব-ক্যাটাগরি নিষ্ক্রিয় করবেন?';

  @override
  String get subCategoriesEdit => 'সাব-ক্যাটাগরি সম্পাদনা';

  @override
  String get subCategoriesEmpty => 'কোনো সাব-ক্যাটাগরি পাওয়া যায়নি।';

  @override
  String subCategoriesInactiveSubtitle(String category) {
    return '$category - নিষ্ক্রিয়';
  }

  @override
  String subCategoriesLoadError(String error) {
    return 'সাব-ক্যাটাগরি লোড করা যায়নি: $error';
  }

  @override
  String get subCategoriesNameLabel => 'নাম';

  @override
  String get subCategoriesNameRequired => 'নাম দেওয়া আবশ্যক';

  @override
  String get subCategoriesSearchHint => 'সাব-ক্যাটাগরি খুঁজুন';

  @override
  String get subCategoriesSelectCategory => 'একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get subCategoriesSelectProfile =>
      'প্রথমে একটি প্রোফাইল নির্বাচন করুন।';

  @override
  String get subCategoriesShowInactive => 'নিষ্ক্রিয় দেখান';

  @override
  String get subCategoriesTitle => 'সাব-ক্যাটাগরি';

  @override
  String get tagsAdd => 'ট্যাগ যোগ করুন';

  @override
  String tagsArchiveMessage(String name) {
    return '\"$name\" পুরনো লেনদেনে থাকবে, তবে নতুন লেনদেনে আর যোগ করা যাবে না।';
  }

  @override
  String get tagsArchiveTitle => 'ট্যাগ আর্কাইভ করুন';

  @override
  String get tagsArchived => 'আর্কাইভ করা';

  @override
  String tagsDateRange(String from, String to) {
    return '$from  থেকে  $to';
  }

  @override
  String get tagsEdit => 'ট্যাগ সম্পাদনা';

  @override
  String get tagsEmpty => 'এখনো কোনো ট্যাগ নেই। তৈরি করতে + চাপুন।';

  @override
  String get tagsHideArchived => 'আর্কাইভ করাগুলো লুকান';

  @override
  String get tagsName => 'নাম';

  @override
  String get tagsNameRequired => 'ট্যাগের নাম দিতে হবে।';

  @override
  String get tagsNew => 'নতুন ট্যাগ';

  @override
  String get tagsNewName => 'নতুন ট্যাগের নাম';

  @override
  String get tagsReportEmpty => 'এই সময়সীমায় ট্যাগ করা কোনো লেনদেন নেই।';

  @override
  String get tagsReportTitle => 'ট্যাগ রিপোর্ট';

  @override
  String get tagsShowArchived => 'আর্কাইভ করাগুলো দেখান';

  @override
  String get tagsTitle => 'ট্যাগ';

  @override
  String tagsTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি লেনদেন',
      one: '$countটি লেনদেন',
    );
    return '$_temp0';
  }

  @override
  String get transactionsAccount => 'হিসাব';

  @override
  String get transactionsAddExchangeRates => 'বিনিময় হার যোগ করুন';

  @override
  String get transactionsAmount => 'পরিমাণ';

  @override
  String get transactionsAmountPositive => 'পরিমাণ অবশ্যই শূন্যের বেশি হতে হবে';

  @override
  String get transactionsAuditCreated => 'তৈরি হয়েছে';

  @override
  String get transactionsAuditDeleted => 'মুছে ফেলা হয়েছে';

  @override
  String get transactionsAuditEdited => 'সম্পাদিত';

  @override
  String get transactionsAuditRestored => 'পুনরুদ্ধার হয়েছে';

  @override
  String get transactionsCalculator => 'ক্যালকুলেটর';

  @override
  String get transactionsCannotConvertSave =>
      'নির্বাচিত হারে এই পরিমাণ রূপান্তর করা যাচ্ছে না (শূন্য হয়ে যায় বা খুব বড়)। পরিমাণ বা হার পরিবর্তন করুন।';

  @override
  String get transactionsCategory => 'ক্যাটাগরি';

  @override
  String transactionsChangeAmount(String from, String to) {
    return 'পরিমাণ: $from → $to';
  }

  @override
  String transactionsChangeGeneric(String field, String from, String to) {
    return '$field: $from → $to';
  }

  @override
  String transactionsChangeOriginalAmount(String from, String to) {
    return 'মূল পরিমাণ: $from → $to';
  }

  @override
  String transactionsChangeOriginalCurrency(String from, String to) {
    return 'মূল মুদ্রা: $from → $to';
  }

  @override
  String transactionsChangeRate(String from, String to) {
    return 'হার: $from → $to';
  }

  @override
  String get transactionsChooseDifferentAccount => 'অন্য একটি হিসাব বেছে নিন';

  @override
  String get transactionsConvertFail =>
      'পরিমাণ রূপান্তর করা যাচ্ছে না (শূন্য হয়ে যায় বা খুব বড়)।';

  @override
  String transactionsConvertedLine(String amount, String code, String rate) {
    return '= $amount, 1 $code = $rate হারে';
  }

  @override
  String get transactionsCostItem => 'খরচের খাত';

  @override
  String get transactionsCostItemOptional => 'খরচের খাত (ঐচ্ছিক)';

  @override
  String get transactionsDate => 'তারিখ';

  @override
  String get transactionsDeleteMessage =>
      'এই লেনদেন ব্যালেন্স, বাজেট ও রিপোর্ট থেকে সরে যাবে। আপনি এটি ফিরিয়ে আনতে পারবেন।';

  @override
  String get transactionsDeleteTitle => 'লেনদেন মুছবেন?';

  @override
  String get transactionsDeleteTransferMessage =>
      'এই ট্রান্সফার দুটি হিসাব থেকেই সরে যাবে। আপনি এটি ফিরিয়ে আনতে পারবেন।';

  @override
  String get transactionsDeleted => 'লেনদেন মুছে ফেলা হয়েছে';

  @override
  String get transactionsDeletedCannotEdit =>
      'এই লেনদেন মুছে ফেলা হয়েছে। সম্পাদনা করতে পুনরুদ্ধার করুন।';

  @override
  String get transactionsDescription => 'বিবরণ';

  @override
  String get transactionsDetailTitle => 'লেনদেন';

  @override
  String get transactionsEditTitle => 'লেনদেন সম্পাদনা';

  @override
  String get transactionsEnterAmount => 'পরিমাণ লিখুন';

  @override
  String get transactionsEnterIncomeSource => 'আয়ের উৎস লিখুন';

  @override
  String get transactionsExcludedNote =>
      'এটি ব্যালেন্স, বাজেট ও রিপোর্টের হিসাবে ধরা হয় না।';

  @override
  String transactionsExtrasWarning(String problems) {
    return 'সতর্কতা: $problems। লেনদেন সম্পাদনা করে সেগুলো যোগ করতে পারবেন।';
  }

  @override
  String get transactionsFieldDate => 'তারিখ';

  @override
  String get transactionsFieldIncomeSource => 'আয়ের উৎস';

  @override
  String get transactionsFieldRemarks => 'মন্তব্য';

  @override
  String get transactionsFieldTitle => 'শিরোনাম';

  @override
  String get transactionsFieldType => 'ধরন';

  @override
  String get transactionsFromAccount => 'যে হিসাব থেকে';

  @override
  String get transactionsHistory => 'ইতিহাস';

  @override
  String transactionsHistoryLoadFailed(String error) {
    return 'ইতিহাস লোড করা যায়নি: $error';
  }

  @override
  String transactionsInactiveSuffix(String name) {
    return '$name (নিষ্ক্রিয়)';
  }

  @override
  String get transactionsIncomeSource => 'আয়ের উৎস';

  @override
  String get transactionsInvalidAmount =>
      'সঠিক পরিমাণ লিখুন, যেমন 1250 বা 1250.50 (সর্বোচ্চ ২ দশমিক)';

  @override
  String get transactionsIsDeleted => 'এই লেনদেন মুছে ফেলা হয়েছে';

  @override
  String get transactionsKeypadAmountPositive =>
      'পরিমাণ অবশ্যই শূন্যের বেশি হতে হবে।';

  @override
  String get transactionsKeypadUseAmount => 'পরিমাণ ব্যবহার করুন';

  @override
  String get transactionsNoAccounts =>
      'এখনো কোনো হিসাব নেই।\nলেনদেন যোগ করার আগে সেটিংস > হিসাব থেকে একটি হিসাব তৈরি করুন।';

  @override
  String get transactionsNoCategories =>
      'এখনো কোনো ক্যাটাগরি নেই। খরচ লিখতে সেটিংস > ক্যাটাগরি থেকে একটি ক্যাটাগরি তৈরি করুন।';

  @override
  String get transactionsNoHistory => 'এখনো কোনো ইতিহাস নেই।';

  @override
  String transactionsNoRate(String code) {
    return '$code-এর কোনো বিনিময় হার নেই। বিনিময় হার থেকে একটি যোগ করুন।';
  }

  @override
  String get transactionsNotFound => 'লেনদেন পাওয়া যায়নি।';

  @override
  String transactionsOriginalLine(
    String original,
    String code,
    String symbol,
    String rate,
  ) {
    return '$original, 1 $code = $symbol$rate হারে';
  }

  @override
  String transactionsRateLine(String code, String symbol, String rate) {
    return '1 $code = $symbol$rate';
  }

  @override
  String get transactionsReceipts => 'রসিদ';

  @override
  String transactionsReceiptsSaveFailed(String reason) {
    return 'রসিদ সংরক্ষণ করা যায়নি ($reason)';
  }

  @override
  String get transactionsRemarks => 'মন্তব্য';

  @override
  String get transactionsRemarksOptional => 'মন্তব্য (ঐচ্ছিক)';

  @override
  String get transactionsRepeatLast => 'আগেরটি আবার';

  @override
  String get transactionsRestored => 'লেনদেন পুনরুদ্ধার হয়েছে';

  @override
  String get transactionsSaveChanges => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String transactionsSaveFailed(String error) {
    return 'লেনদেন সংরক্ষণ করা যায়নি: $error';
  }

  @override
  String get transactionsSaved => 'লেনদেন সংরক্ষিত হয়েছে';

  @override
  String transactionsSavedWithWarning(String warning) {
    return 'লেনদেন সংরক্ষিত হয়েছে। $warning';
  }

  @override
  String get transactionsSelectAccount => 'একটি হিসাব বেছে নিন';

  @override
  String get transactionsSelectCategory => 'একটি ক্যাটাগরি বেছে নিন';

  @override
  String get transactionsSelectProfileFirst => 'প্রথমে একটি প্রোফাইল বেছে নিন।';

  @override
  String get transactionsSource => 'উৎস';

  @override
  String get transactionsSourceBusiness => 'ব্যবসা';

  @override
  String get transactionsSourceFreelance => 'ফ্রিল্যান্স';

  @override
  String get transactionsSourceOther => 'অন্যান্য';

  @override
  String get transactionsSourceSalary => 'বেতন';

  @override
  String get transactionsSubCategory => 'সাব-ক্যাটাগরি';

  @override
  String get transactionsSubCategoryOptional => 'সাব-ক্যাটাগরি (ঐচ্ছিক)';

  @override
  String get transactionsTags => 'ট্যাগ';

  @override
  String transactionsTagsSaveFailed(String reason) {
    return 'ট্যাগ সংরক্ষণ করা যায়নি ($reason)';
  }

  @override
  String get transactionsTitle => 'শিরোনাম';

  @override
  String get transactionsTitleOptional => 'শিরোনাম (ঐচ্ছিক)';

  @override
  String get transactionsToAccount => 'যে হিসাবে';

  @override
  String get transactionsTypeExpense => 'খরচ';

  @override
  String get transactionsTypeIncome => 'আয়';

  @override
  String get transactionsTypeTransfer => 'ট্রান্সফার';

  @override
  String get transactionsUpdated => 'লেনদেন হালনাগাদ হয়েছে';

  @override
  String get transactionsWarningAnd => ' এবং ';
}
