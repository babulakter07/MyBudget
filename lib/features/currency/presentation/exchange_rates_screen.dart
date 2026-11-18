import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../../profiles/data/profile_providers.dart';
import '../domain/exchange_rate.dart';
import '../providers/currency_providers.dart';

/// Manual exchange-rate management (pushed screen, own Scaffold).
class ExchangeRatesScreen extends ConsumerWidget {
  const ExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    final profile = ref.watch(activeProfileProvider).asData?.value;
    final base = (profile?.currencyCode ?? 'BDT').toUpperCase();
    final rates = ref.watch(allExchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.currencyTitle)),
      floatingActionButton: profileId == null
          ? null
          : FloatingActionButton(
              tooltip: context.l10n.currencyAddRateTooltip,
              onPressed: () => showExchangeRateForm(context, base: base),
              child: const Icon(Icons.add),
            ),
      body: profileId == null
          ? EmptyState(
              icon: Icons.person_off,
              message: context.l10n.currencyNoProfile,
            )
          : rates.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(allExchangeRatesProvider),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  _BaseCard(base: base),
                  const _InfoCard(),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyRates(
                        onAdd: () => showExchangeRateForm(context, base: base),
                      ),
                    )
                  else
                    for (final r in items) _RateTile(rate: r, base: base),
                ],
              ),
            ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.base});
  final String base;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimaryContainer;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: theme.colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet_outlined, color: on),
        title: Text(
          context.l10n.currencyBaseCard(base, currencySymbol(base)),
          style: theme.textTheme.titleSmall?.copyWith(color: on),
        ),
        subtitle: Text(
          context.l10n.currencyBaseCardSub,
          style: TextStyle(color: on),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.currencyInfo,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRates extends StatelessWidget {
  const _EmptyRates({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.currency_exchange,
          size: 56,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.currencyEmptyTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.currencyEmptyBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.currencyAddRate),
        ),
      ],
    );
  }
}

class _RateTile extends ConsumerWidget {
  const _RateTile({required this.rate, required this.base});
  final ExchangeRate rate;
  final String base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dim = rate.isActive ? null : theme.disabledColor;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rate.isActive
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          rate.currencyCode,
          style: TextStyle(fontSize: 11, color: dim),
        ),
      ),
      title: Text(
        context.l10n.currencyRateEquals(
          rate.currencyCode,
          currencySymbol(base),
          formatRate(rate.rateMicro),
        ),
        style: TextStyle(color: dim),
      ),
      subtitle: Text(
        rate.isActive
            ? context.l10n.currencyUpdated(dateKey(rate.updatedAt))
            : context.l10n.currencyUpdatedInactive(dateKey(rate.updatedAt)),
        style: TextStyle(color: dim),
      ),
      onTap: () => showExchangeRateForm(context, base: base, existing: rate),
      trailing: Switch(
        value: rate.isActive,
        onChanged: (v) async {
          try {
            await ref
                .read(exchangeRateRepositoryProvider)
                .setActive(rate.profileId, rate.id, v);
          } on AppException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
      ),
    );
  }
}

Future<void> showExchangeRateForm(
  BuildContext context, {
  required String base,
  ExchangeRate? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExchangeRateFormSheet(base: base, existing: existing),
  );
}

class ExchangeRateFormSheet extends ConsumerStatefulWidget {
  const ExchangeRateFormSheet({super.key, required this.base, this.existing});
  final String base;
  final ExchangeRate? existing;

  @override
  ConsumerState<ExchangeRateFormSheet> createState() =>
      _ExchangeRateFormState();
}

const _otherOption = '__other__';

class _ExchangeRateFormState extends ConsumerState<ExchangeRateFormSheet> {
  late final TextEditingController _rate;
  final _other = TextEditingController();
  String? _choice;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _rate = TextEditingController(
      text: e == null ? '' : formatRate(e.rateMicro),
    );
    _choice = e?.currencyCode;
  }

  @override
  void dispose() {
    _rate.dispose();
    _other.dispose();
    super.dispose();
  }

  String? get _code {
    if (_editing) return widget.existing!.currencyCode;
    if (_choice == _otherOption) return normalizeCurrencyCode(_other.text);
    return _choice;
  }

  Future<void> _save() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    final code = _code;
    final micro = parseRateToMicro(_rate.text);
    if (code == null) {
      setState(
        () => _error = _choice == _otherOption
            ? context.l10n.currencyErrCode
            : context.l10n.currencyErrChoose,
      );
      return;
    }
    if (micro == null) {
      setState(() => _error = context.l10n.currencyErrRate);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(exchangeRateRepositoryProvider)
          .upsert(profileId: profileId, currencyCode: code, rateMicro: micro);
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      // ValidationException and any other AppException: show on the form.
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseUpper = widget.base.toUpperCase();
    final options = [
      for (final c in knownCurrencies)
        if (c.code != baseUpper) c,
    ];
    final code = _code;
    final micro = parseRateToMicro(_rate.text);
    final helper = (code != null && micro != null)
        ? context.l10n.currencyRateEquals(
            code,
            currencySymbol(baseUpper),
            formatRate(micro),
          )
        : context.l10n.currencyRateHelper;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing
                  ? context.l10n.currencyEditRate
                  : context.l10n.currencyAddRate,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_editing)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.currencyFieldCurrency,
                ),
                child: Text(
                  '${widget.existing!.currencyCode} '
                  '(${currencySymbol(widget.existing!.currencyCode)})',
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: const Key('currencyDropdown'),
                initialValue: _choice,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.currencyFieldCurrency,
                ),
                items: [
                  for (final c in options)
                    DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} - ${c.name}'),
                    ),
                  DropdownMenuItem(
                    value: _otherOption,
                    child: Text(context.l10n.currencyOtherCode),
                  ),
                ],
                onChanged: (v) => setState(() => _choice = v),
              ),
            if (!_editing && _choice == _otherOption) ...[
              const SizedBox(height: 8),
              TextField(
                key: const Key('otherCode'),
                controller: _other,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: context.l10n.currencyCodeLabel,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              key: const Key('rateField'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.currencyRateLabel(baseUpper),
                helperText: helper,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(context.l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(context.l10n.commonSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
