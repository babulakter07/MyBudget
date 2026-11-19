import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../domain/wallet_models.dart';
import '../providers/wallet_providers.dart';

Future<void> showAddMoneyDialog(BuildContext context, WalletItem wallet) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AddMoneyDialog(wallet: wallet),
    );

Future<void> showTransferDialog(BuildContext context, WalletItem wallet) =>
    showDialog<void>(
      context: context,
      builder: (_) => _TransferDialog(wallet: wallet),
    );

int? _parsePositive(String text) {
  final v = parseMajorToMinor(text.trim());
  return (v == null || v <= 0) ? null : v;
}

/// Date row shared by both dialogs.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.firstDate,
    required this.onChanged,
  });
  final String date;
  final String firstDate;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = parseDateKey(date);
    return ListTile(
      key: const ValueKey('wallet-date'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event),
      title: Text(context.l10n.walletsDate),
      subtitle: Text(date),
      onTap: () async {
        final first = parseDateKey(firstDate);
        final picked = await showDatePicker(
          context: context,
          initialDate: current.isBefore(first) ? first : current,
          firstDate: first,
          lastDate: DateTime(current.year + 5),
        );
        if (picked != null) onChanged(dateKey(picked));
      },
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String? message;
  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message!,
        key: const ValueKey('wallet-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _AddMoneyDialog extends ConsumerStatefulWidget {
  const _AddMoneyDialog({required this.wallet});
  final WalletItem wallet;

  @override
  ConsumerState<_AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends ConsumerState<_AddMoneyDialog> {
  final _amount = TextEditingController();
  final _source = TextEditingController();
  final _note = TextEditingController();
  late String _date;
  bool _saving = false;
  String? _error;
  String? _chip;

  @override
  void initState() {
    super.initState();
    _date = dateKey(ref.read(walletClockProvider)());
    if (_date.compareTo(widget.wallet.account.openingDate) < 0) {
      _date = widget.wallet.account.openingDate;
    }
    _amount.addListener(_refresh);
  }

  void _refresh() => setState(() => _error = null);

  @override
  void dispose() {
    _amount.dispose();
    _source.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final amount = _parsePositive(_amount.text);
    final source = _source.text.trim();
    if (amount == null) {
      setState(() => _error = l10n.accountsAmountInvalid);
      return;
    }
    if (source.isEmpty) {
      setState(() => _error = l10n.walletsSourceRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = l10n.walletsMoneyAdded;
    try {
      await ref
          .read(transactionRepositoryProvider)
          .createIncome(
            profileId: widget.wallet.account.profileId,
            accountId: widget.wallet.account.id,
            incomeSource: source,
            amountMinor: amount,
            date: _date,
            remarks: _note.text,
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = widget.wallet.balanceMinor;
    final amount = _parsePositive(_amount.text);
    final sources = {
      'deposit': l10n.walletsSourceDeposit,
      'salary': l10n.walletsSourceSalary,
      'interest': l10n.walletsSourceInterest,
      'gift': l10n.walletsSourceGift,
      'other': l10n.walletsSourceOther,
    };
    return AlertDialog(
      title: Text('${l10n.walletsAddMoney} · ${widget.wallet.account.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('wallet-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.walletsAmount),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final e in sources.entries)
                  ChoiceChip(
                    key: ValueKey('wallet-source-${e.key}'),
                    label: Text(e.value),
                    selected: _chip == e.key,
                    onSelected: (_) => setState(() {
                      _chip = e.key;
                      _source.text = e.key == 'other' ? '' : e.value;
                    }),
                  ),
              ],
            ),
            TextField(
              key: const ValueKey('wallet-source'),
              controller: _source,
              decoration: InputDecoration(labelText: l10n.walletsSource),
            ),
            _DateField(
              date: _date,
              firstDate: widget.wallet.account.openingDate,
              onChanged: (d) => setState(() => _date = d),
            ),
            TextField(
              key: const ValueKey('wallet-note'),
              controller: _note,
              decoration: InputDecoration(labelText: l10n.walletsNote),
            ),
            const SizedBox(height: 12),
            Text(
              key: const ValueKey('wallet-preview'),
              l10n.walletsPreviewAdd(
                formatMinor(current),
                formatMinor(amount ?? 0),
                formatMinor(current + (amount ?? 0)),
              ),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: AppColors.income),
            ),
            _ErrorText(_error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('wallet-save'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _TransferDialog extends ConsumerStatefulWidget {
  const _TransferDialog({required this.wallet});
  final WalletItem wallet;

  @override
  ConsumerState<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<_TransferDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _date;
  int? _toId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = dateKey(ref.read(walletClockProvider)());
    if (_date.compareTo(widget.wallet.account.openingDate) < 0) {
      _date = widget.wallet.account.openingDate;
    }
    _amount.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final amount = _parsePositive(_amount.text);
    if (amount == null) {
      setState(() => _error = l10n.accountsAmountInvalid);
      return;
    }
    final toId = _toId;
    if (toId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = l10n.walletsTransferSaved;
    try {
      await ref
          .read(transactionRepositoryProvider)
          .createTransfer(
            profileId: widget.wallet.account.profileId,
            fromAccountId: widget.wallet.account.id,
            toAccountId: toId,
            amountMinor: amount,
            date: _date,
            remarks: _note.text,
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overview = ref.watch(walletOverviewProvider).value;
    final others = [
      for (final g in overview?.groups ?? const <WalletGroup>[])
        for (final i in g.items)
          if (i.account.id != widget.wallet.account.id) i,
    ];
    if (_toId == null && others.isNotEmpty) _toId = others.first.account.id;
    final to = others.where((o) => o.account.id == _toId).firstOrNull;
    final amount = _parsePositive(_amount.text) ?? 0;
    final from = widget.wallet;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('${l10n.walletsTransferWithdraw} · ${from.account.name}'),
      content: SingleChildScrollView(
        child: overview == null
            ? const Center(child: CircularProgressIndicator())
            : others.isEmpty
            ? Text(l10n.walletsNoOtherAccount)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walletsTransferHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.walletsTransferTo,
                    style: theme.textTheme.labelLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final o in others)
                        ChoiceChip(
                          key: ValueKey('wallet-to-${o.account.id}'),
                          label: Text(o.account.name),
                          selected: _toId == o.account.id,
                          onSelected: (_) =>
                              setState(() => _toId = o.account.id),
                        ),
                    ],
                  ),
                  TextField(
                    key: const ValueKey('wallet-amount'),
                    controller: _amount,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l10n.walletsAmount),
                  ),
                  _DateField(
                    date: _date,
                    firstDate: from.account.openingDate,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  TextField(
                    key: const ValueKey('wallet-note'),
                    controller: _note,
                    decoration: InputDecoration(labelText: l10n.walletsNote),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    key: const ValueKey('wallet-preview-from'),
                    l10n.walletsPreviewMove(
                      from.account.name,
                      formatMinor(from.balanceMinor),
                      formatMinor(from.balanceMinor - amount),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: from.balanceMinor - amount < 0
                          ? AppColors.expense
                          : null,
                    ),
                  ),
                  if (to != null)
                    Text(
                      key: const ValueKey('wallet-preview-to'),
                      l10n.walletsPreviewMove(
                        to.account.name,
                        formatMinor(to.balanceMinor),
                        formatMinor(to.balanceMinor + amount),
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.income,
                      ),
                    ),
                  _ErrorText(_error),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        if (others.isNotEmpty)
          FilledButton(
            key: const ValueKey('wallet-save'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.commonSave),
          ),
      ],
    );
  }
}
