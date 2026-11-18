import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../providers/tag_providers.dart';

/// Per-tag expense/income totals over a chosen date range.
class TagReportScreen extends ConsumerStatefulWidget {
  const TagReportScreen({super.key});

  @override
  ConsumerState<TagReportScreen> createState() => _TagReportScreenState();
}

class _TagReportScreenState extends ConsumerState<TagReportScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month, daysInMonth(now.year, now.month));
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (r != null) {
      setState(() {
        _from = DateTime(r.start.year, r.start.month, r.start.day);
        _to = DateTime(r.end.year, r.end.month, r.end.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(tagTotalsProvider((from: _from, to: _to)));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tagsReportTitle)),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(
              context.l10n.tagsDateRange(dateKey(_from), dateKey(_to)),
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickRange,
          ),
          const Divider(height: 1),
          Expanded(
            child: totals.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorState(error: e),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    message: context.l10n.tagsReportEmpty,
                    icon: Icons.sell_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: t.color == null
                            ? Theme.of(context).colorScheme.primary
                            : Color(t.color!),
                      ),
                      title: Text(t.name),
                      subtitle: Text(
                        context.l10n.tagsTransactionCount(t.count),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (t.expenseMinor > 0)
                            Text(
                              '-${formatMinor(t.expenseMinor)}',
                              style: const TextStyle(color: AppColors.expense),
                            ),
                          if (t.incomeMinor > 0)
                            Text(
                              '+${formatMinor(t.incomeMinor)}',
                              style: const TextStyle(color: AppColors.income),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
