import 'package:material_ui/material_ui.dart' show IconData, Icons;

/// One topic of the in-app user manual.
class ManualTopic {
  const ManualTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.steps,
    this.tips = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final List<String> steps;
  final List<String> tips;
}

/// Manual text (English). Kept as plain data so it is easy to review/edit.
const manualTopics = <ManualTopic>[
  ManualTopic(
    id: 'start',
    title: 'Getting started',
    icon: Icons.rocket_launch_outlined,
    summary:
        'MyBudget keeps your personal or family money records on your phone. '
        'Nothing is uploaded; there is no account or internet needed.',
    steps: [
      'Create a profile (for example "Personal" or "Family"). Each profile has its own categories, accounts, budgets and transactions.',
      'Add at least one account (Cash, Bank or Mobile banking) with its opening balance. Every transaction belongs to an account.',
      'Create categories, then sub-categories, then cost items under them (Settings > Master Configuration). Example: Food > Groceries > Rice.',
      'Set this month\'s budget in the Budget tab.',
      'Record your first expense or income in the Add tab.',
    ],
    tips: [
      'Bottom tabs: Home (dashboard), Budget, Add, Ledger and Reports.',
      'The magnifier at the top opens Search. The gear opens Settings, where everything else lives.',
      'Money is stored exactly (no rounding errors) and the default currency is BDT.',
    ],
  ),
  ManualTopic(
    id: 'profiles',
    title: 'Profiles',
    icon: Icons.people_outline,
    summary: 'Profiles keep different money worlds fully separate, such as you and your family.',
    steps: [
      'Open Settings > Profiles to create, switch or deactivate a profile.',
      'Switching profile refreshes every screen to that profile\'s data.',
    ],
    tips: [
      'Data never mixes between profiles; you cannot transfer between accounts of different profiles.',
      'Deactivating a profile keeps its history.',
    ],
  ),
  ManualTopic(
    id: 'master',
    title: 'Categories, sub-categories and cost items',
    icon: Icons.category_outlined,
    summary: 'Your own spending structure: Category > Sub-category > Cost item. Nothing is preset.',
    steps: [
      'Settings > Categories: add a category such as "Food". Pick an icon and colour if offered.',
      'Settings > Sub-categories: add one under a category, such as "Groceries".',
      'Settings > Cost items: add the item you actually buy, such as "Rice". You can set an optional default amount and mark favourites for quick add.',
      'Use the search box to find items quickly. Names must be unique within their parent (upper/lower case is ignored).',
    ],
    tips: [
      'Items are never deleted, only made inactive, so old reports stay correct. Inactive items do not appear when adding new expenses.',
      'Renaming is safe: past transactions keep the name they were saved with.',
    ],
  ),
  ManualTopic(
    id: 'accounts',
    title: 'Accounts',
    icon: Icons.account_balance_wallet_outlined,
    summary: 'Where your money sits: cash, bank, mobile banking or other.',
    steps: [
      'Settings > Accounts > add. Enter a name, type, opening balance and opening date.',
      'Balance = opening balance + income - expense + transfers in - transfers out.',
    ],
    tips: [
      'You cannot record a transaction dated before the account\'s opening date.',
      'Budget remaining is not the same as your cash balance: the budget is a spending plan, the balance is real money.',
    ],
  ),
  ManualTopic(
    id: 'add',
    title: 'Adding expenses, income and transfers',
    icon: Icons.add_circle_outline,
    summary: 'The Add tab records every money movement.',
    steps: [
      'Expense: choose account, then Category > Sub-category > Cost item (only active ones are shown), amount, date, title and remarks.',
      'Income: choose account, income source, amount and date. Income raises your balance but does not change the budget.',
      'Transfer: pick a source and a destination account of the same profile. It moves money without counting as income or expense.',
      'Amount must be greater than zero. The on-screen keypad can do simple arithmetic such as 120+80.',
      'Favourite cost items appear as chips for one-tap entry with their default amount, and "repeat last" refills your previous expense.',
      'Optionally add tags and attach receipt photos before saving.',
      'If you enter a foreign currency amount, the exchange rate you set in Exchange rates is used.',
    ],
    tips: ['Saving twice by accident will not create a duplicate row.'],
  ),
  ManualTopic(
    id: 'split',
    title: 'Splitting a bill',
    icon: Icons.call_split,
    summary: 'One shop bill can cover several categories. Split it so each part lands in the right category.',
    steps: [
      'Open the Add tab and tap "Split a bill".',
      'Choose the account and date, and optionally a title.',
      'For each line pick a category (sub-category and cost item are optional) and type its amount. Use "Add line" for more lines.',
      'The total of all lines is shown. Tap "Save split".',
    ],
    tips: [
      'Each line is saved as its own expense, all together or not at all.',
      'Edit or delete each line separately afterwards, like any other expense.',
    ],
  ),
  ManualTopic(
    id: 'setup',
    title: 'Setup guide and reminders',
    icon: Icons.checklist_rtl,
    summary: 'A short checklist for new users, plus a reminder to back up your data.',
    steps: [
      'Settings > Getting started shows four steps: add an account, create a category, set this month\'s budget and record your first transaction.',
      'Finished steps are ticked off. Tap Go on a step to open the right screen.',
      'While steps remain, a "Finish setting up" card also appears at the top of the Home tab. Tap the X to hide it; the guide stays in Settings.',
      'If your last backup is 30 or more days old (or you never made one), Home shows a backup reminder. Tap Back up, or Later to hide it for a week.',
    ],
  ),
  ManualTopic(
    id: 'edit',
    title: 'Viewing, editing and deleting transactions',
    icon: Icons.edit_note,
    summary: 'Tap any transaction in the Ledger or search results to open it.',
    steps: [
      'Edit: change any field and save. Balances and budgets update everywhere, including when the date moves to another month.',
      'Delete: the transaction is removed from totals and reports. A transfer is reversed on both accounts together.',
      'Undo: right after deleting, use Undo in the message at the bottom to restore it.',
      'Details show the change history so you can see what was edited and when.',
    ],
    tips: ['Deleted items are kept in the audit history, never lost silently.'],
  ),
  ManualTopic(
    id: 'budget',
    title: 'Monthly budgets',
    icon: Icons.pie_chart_outline,
    summary:
        'Plan how much you will spend in a month, and optionally per category.',
    steps: [
      'Open the Budget tab, choose the month, and enter the total budget.',
      'Optionally split it across categories. Category amounts are parts of the total, not added to it.',
      'Remaining = budget - expenses. Utilization = expenses / budget. Overspending is allowed and shown as negative.',
    ],
    tips: [
      'Each month is independent: unused or negative amounts do not carry forward. Set up each new month yourself.',
      'Turn on Notifications > Budget alerts to be warned at 80% and when you go over.',
    ],
  ),
  ManualTopic(
    id: 'dashboard',
    title: 'Home dashboard',
    icon: Icons.dashboard_outlined,
    summary: 'Your month at a glance.',
    steps: [
      'See monthly budget, expense, remaining, utilization, cash balance and income.',
      'Analytics: top 5 items and categories, highest spending day, average daily expense and category chart.',
      'Yearly section: income, expense, average month, highest and lowest month and the trend.',
      'Change the month or year with the filters on the screen.',
    ],
  ),
  ManualTopic(
    id: 'ledger',
    title: 'Ledger',
    icon: Icons.receipt_long_outlined,
    summary: 'A running statement, like a bank passbook.',
    steps: [
      'Account ledger: date, description, income, expense, transfers in/out and the running balance.',
      'Budget ledger: each expense with the budget remaining after it.',
      'Filter by date and search by text. Tap a row for details.',
    ],
  ),
  ManualTopic(
    id: 'reports',
    title: 'Reports and export',
    icon: Icons.bar_chart_outlined,
    summary: 'Monthly, yearly and custom-range reports.',
    steps: [
      'Reports tab: choose Monthly, Yearly or Custom range.',
      'Monthly covers income, expense, budget, category and item breakdowns and daily spending.',
      'Yearly always shows all 12 months and compares them.',
      'Export a report as PDF or CSV and share it from the screen.',
    ],
    tips: [
      'PDFs print money as "BDT 12,000.50" because the default PDF fonts lack the taka sign.',
    ],
  ),
  ManualTopic(
    id: 'search',
    title: 'Search',
    icon: Icons.search,
    summary: 'Find any transaction fast.',
    steps: [
      'Tap the magnifier at the top of the Home screen.',
      'Type text and use the filter sheet to narrow by date, type, account, category, tag or amount.',
    ],
  ),
  ManualTopic(
    id: 'tags',
    title: 'Tags',
    icon: Icons.sell_outlined,
    summary: 'Free labels such as "Trip" or "Eid" that cut across categories.',
    steps: [
      'Settings > Tags: create tags.',
      'Attach tags when adding or editing a transaction.',
      'Settings > Tag report shows totals per tag.',
    ],
  ),
  ManualTopic(
    id: 'recurring',
    title: 'Recurring transactions',
    icon: Icons.repeat,
    summary: 'Rules for regular items such as rent, salary or subscriptions.',
    steps: [
      'Settings > Recurring transactions > add a rule: what, amount, account and how often.',
      'Due items are created for you on schedule. You can pause or change a rule at any time.',
    ],
    tips: ['Android may run background work late; open the app to catch up.'],
  ),
  ManualTopic(
    id: 'goals',
    title: 'Savings goals',
    icon: Icons.savings_outlined,
    summary: 'Track progress toward something you are saving for.',
    steps: [
      'Settings > Savings goals > add a goal with a target amount and optional date.',
      'Add contributions as you save and watch the progress bar.',
    ],
  ),
  ManualTopic(
    id: 'debts',
    title: 'Debts and loans',
    icon: Icons.handshake_outlined,
    summary: 'Keep track of money you owe and money owed to you.',
    steps: [
      'Settings > Debts & loans > Add debt. Choose "I borrowed" or "I lent", the person, amount and optional due date.',
      'Use Add payment as instalments are paid or received. Mark fully settled when done.',
      'Group by person to see the net amount for each one.',
    ],
    tips: ['Turn on Notifications to be reminded of due dates.'],
  ),
  ManualTopic(
    id: 'wallets',
    title: 'Cash, bank and wallet balances',
    icon: Icons.account_balance_wallet_outlined,
    summary: 'See how much money you hold in cash, bank accounts, mobile wallets and savings, and how every balance changed.',
    steps: [
      'Settings > Wallets & balances. Your accounts are grouped by type (Cash, Bank, Mobile wallet, Savings) with a subtotal for each group and a total balance.',
      'Tap an account to open it. At the top you see the current balance and this month\'s money in and money out.',
      'Add money: choose Deposit, Salary, Interest, Gift or Other, enter the amount and date. The dialog shows the balance before and after, for example 10,000 + 2,000 = 12,000.',
      'Transfer / Withdraw: move money to another account. Withdrawing cash from the bank is a transfer from the Bank account to the Cash account; both balances update.',
      'The ledger below lists every movement with a "Balance after" column. Pick This month, Last 3 months, This year or All. The Opening balance row is the starting point.',
    ],
    tips: [
      'Add accounts (name, type, opening balance) in Settings > Accounts first.',
      'Credit-card accounts are shown separately and are not counted in the total balance. Track real card bills in Credit cards.',
      'Expenses are still recorded in the Add tab; they appear in the account ledger automatically.',
    ],
  ),
  ManualTopic(
    id: 'loans',
    title: 'Loan tracking',
    icon: Icons.account_balance_outlined,
    summary: 'Track a loan from a bank or institution: installment schedule, interest, what you have paid and what remains.',
    steps: [
      'Settings > Bank loans > add. Enter the bank name, loan type, loan account number (optional), loan (principal) amount, yearly interest rate, interest method, repayment frequency (weekly, monthly or yearly), number of installments, processing fee, disbursement date and the first installment date.',
      'The app calculates the installment, total interest and total payable. If your bank gives a different installment amount, type the bank\'s figure to override it.',
      'Open a loan to see: principal, rate, tenure, installment per period, total interest, total payable, paid so far, remaining and progress.',
      'Schedule tab: every installment with due date, principal and interest parts, balance after it and a status (Paid, Partly paid, Due, Overdue). On the next unpaid installment tap Mark paid and pick the date you actually paid (for example it is due on 8 November but you paid on 4 November). The installment then shows "Paid on 4 November" and the next settlement date moves to the following installment.',
      'Payments tab: tap Record payment each time you pay (the next installment is prefilled). Every settlement is listed with its date and note; a wrong entry can be voided.',
      'Close early: open a loan and tap Close early. You see what is still owed (remaining principal, interest and installments). Pick the closing date, optionally enter the amount you paid the bank and a remark. The rest of the schedule is waived and the loan moves to history: it can no longer be edited or paid.',
      'Adjust / top-up: tap Adjust / top-up when the bank replaces your loan with a new one (a top-up or a refinance). The old loan is closed as Adjusted and a new loan, linked to it, is created. Its amount is prefilled with the principal you still owed, so add any new money. Each loan shows a link to the other.',
    ],
    tips: [
      'Reducing balance: interest is charged on what you still owe, so interest falls as you pay. Flat: interest is charged on the original loan for the whole tenure.',
      'An extra payment simply covers the following installments. You cannot pay more than the remaining total.',
      'After the first payment you can still edit the interest rate and installment (for example when the bank revises a variable rate); other terms are locked, but notes and bank details can always be changed. Archive a loan instead of deleting it.',
      'Loans are a separate ledger: they do not change your account balances or budgets.',
    ],
  ),
  ManualTopic(
    id: 'fixed_deposits',
    title: 'Fixed deposits (FDR)',
    icon: Icons.lock_clock_outlined,
    summary: 'Track an FDR, DPS or savings certificate: maturity date, interest received, and what happens at maturity (encash or reissue).',
    steps: [
      'More > Fixed deposits > add. Choose the scheme type (FDR, DPS, Sanchaypatra or your own text), bank, beneficiary name, instrument number, issue date, tenure in days, yearly interest rate and the principal. Maturity date = issue date + tenure days (30 days = 1 month).',
      'The list shows each deposit with its status: Active, Matured (maturity date reached) or Closed. The summary on top shows how many deposits are open, how much money is placed and the next maturity.',
      'Open a deposit to see the running instrument and the expected interest (an estimate: simple interest on 365 days). The real figures are entered when you close it.',
      'Encash: when the bank pays you, tap Encash. Enter the closing date, the interest received, tax deducted and bank charge. Net received = principal + interest - tax - charge; if the bank paid a different amount, type it in Final net received. The deposit is then closed.',
      'Reissue: when the bank renews the deposit, tap Reissue. Enter the same closing figures for the old instrument, then the new instrument number, reissue date, tenure in days and interest rate. The new principal is the net received amount of the old instrument. The old instrument becomes history and is linked to the new one.',
      'The Instrument history lists every instrument of the deposit (original and each reissue) with its dates, rate, principal and what was received when it was closed.',
    ],
    tips: [
      'The instrument number must be different for every instrument; the bank gives a new one on each reissue.',
      'A closed (encashed or reissued) instrument cannot be edited. Only the running instrument can be corrected with Edit instrument.',
      'Reminders arrive 7 days before, 1 day before and on the maturity date (see the reminder schedule).',
      'Deposits are a separate ledger: they do not change your account balances or budgets. Archive a deposit instead of deleting it.',
    ],
  ),
  ManualTopic(
    id: 'cards',
    title: 'Credit card tracking',
    icon: Icons.credit_card,
    summary: 'Record each monthly card bill, see the minimum payment, what is still unpaid and how much interest and late fee is added.',
    steps: [
      'Settings > Credit cards > add. Enter the card name, bank, last 4 digits (optional), credit limit, statement day, days to pay after the statement, yearly interest rate (APR), minimum payment % and minimum amount, late fee % and minimum fee. Copy these from your card agreement.',
      'Open the card and tap Add bill each month. Enter the NEW charges of that statement only (do not include the unpaid amount of an earlier bill). Dates and the minimum payment are filled from the card settings and can be edited.',
      'Open a bill to see: bill amount, minimum due, paid, interest, late fee, total payable and remaining. It also shows what percentage has been added to the bill.',
      'Tap Pay and choose Minimum due, Full remaining or your own amount. Each payment is recorded and can be voided.',
    ],
    tips: [
      'Pay the full bill by the due date: no interest and no late fee.',
      'If the minimum is not paid by the due date, a late fee is added (the larger of the minimum fee and the late-fee % of the unpaid minimum).',
      'Interest is simple daily interest (APR / 365) on the unpaid bill. By default it starts after the due date. If your bank removes the interest-free period when you do not pay in full, turn on "Interest from statement date".',
      'The bill screen shows what the bill would cost if you leave it unpaid for 30 more days.',
      'Available credit = credit limit minus everything still unpaid. Keep use under about 30% of the limit.',
      'These are estimates from the policy you entered; the bank statement is always the final word.',
    ],
  ),
  ManualTopic(
    id: 'insights',
    title: 'Insights',
    icon: Icons.insights_outlined,
    summary: 'Plain-language observations about your spending.',
    steps: [
      'Settings > Insights. Check it monthly to spot trends and unusual spending.',
    ],
  ),
  ManualTopic(
    id: 'currency',
    title: 'Exchange rates',
    icon: Icons.currency_exchange,
    summary: 'For spending or earning in a foreign currency.',
    steps: [
      'Settings > Exchange rates > add a rate: 1 unit of the foreign currency = how much of your base currency.',
      'Rates are typed by you and never fetched online.',
    ],
    tips: [
      'Changing a rate never rewrites old transactions; they keep the rate they were saved with.',
    ],
  ),
  ManualTopic(
    id: 'import',
    title: 'Import from CSV',
    icon: Icons.upload_file_outlined,
    summary: 'Bring in transactions from a spreadsheet.',
    steps: [
      'Settings > Import from CSV > Choose CSV file.',
      'Pick the target account and map the columns (Date and Amount are required).',
      'Choose the date format and a default category for rows without a matching one.',
      'Review the preview, then import. Invalid rows are reported and skipped.',
    ],
    tips: [
      'Categories are never created automatically; names must match existing ones exactly.',
    ],
  ),
  ManualTopic(
    id: 'backup',
    title: 'Backup and restore',
    icon: Icons.backup_outlined,
    summary: 'Protect your data. It exists only on this phone.',
    steps: [
      'Settings > Backup & Restore > Create backup to save a file, and share it to keep a copy off the phone.',
      'You can include receipt photos in a shared backup.',
      'Automatic backup: choose how often. Android may delay it by hours. These stay on the phone and are not password protected.',
      'Backup folder: choose a folder and a password to keep encrypted copies outside the app. A copy is saved when you open or leave the app after your data changes.',
      'Restore: choose a backup file. The app validates it, asks you to confirm, makes a safety backup first, and rolls back if anything fails.',
    ],
    tips: [
      'Make a manual backup before changing phones or reinstalling the app.',
      'A folder on the phone does not protect you if the phone is lost. Keep a copy somewhere else, and remember the password.',
    ],
  ),
  ManualTopic(
    id: 'security',
    title: 'App lock (PIN and biometrics)',
    icon: Icons.lock_outline,
    summary: 'Keep your financial data private.',
    steps: [
      'Settings > Security > turn on App lock and choose a 4 to 6 digit PIN.',
      'Change PIN or turn the lock off from the same screen; both ask for your current PIN.',
      'Biometric unlock (fingerprint or face) can be turned on if your phone supports it.',
      'Auto-lock: choose to lock immediately, or after 30 seconds, 1 minute or 5 minutes in the background.',
    ],
    tips: [
      'After 5 wrong PINs you are locked out for 30 seconds, and the wait doubles with more failures.',
      'When you set a PIN you get a one-time recovery code. Write it down and keep it safe: on the lock screen, Forgot PIN? plus that code turns the lock off so you can set a new PIN. Create a fresh code any time in Settings > Security > New recovery code.',
    ],
  ),
  ManualTopic(
    id: 'prefs',
    title: 'Preferences and notifications',
    icon: Icons.palette_outlined,
    summary: 'Look and reminders.',
    steps: [
      'Settings > Preferences: choose Light, Dark or System theme.',
      'Settings > Notifications: budget alerts and debt due reminders. Allow notifications when Android asks.',
    ],
  ),
  ManualTopic(
    id: 'help',
    title: 'Troubleshooting',
    icon: Icons.build_outlined,
    summary: 'Common questions.',
    steps: [
      'A category does not show when adding an expense: it or its parent is inactive. Reactivate it in Settings.',
      'Balance looks different from budget remaining: they measure different things (real money vs plan).',
      'A transaction is missing: check it was not deleted, and that the right profile and month are selected.',
      'Something went wrong: Settings > Share error log sends the log only if you choose to share it.',
    ],
  ),
];
