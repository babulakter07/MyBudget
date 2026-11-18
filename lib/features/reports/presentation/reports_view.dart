import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

/// Reports tab body (no Scaffold). Routes: /reports/monthly, /reports/yearly,
/// /reports/range.
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportCard(
          icon: Icons.calendar_view_month,
          title: context.l10n.reportsMonthlyReport,
          subtitle: context.l10n.reportsMonthlyReportSubtitle,
          onTap: () => context.push('/reports/monthly'),
        ),
        _ReportCard(
          icon: Icons.bar_chart,
          title: context.l10n.reportsYearlyReport,
          subtitle: context.l10n.reportsYearlyReportSubtitle,
          onTap: () => context.push('/reports/yearly'),
        ),
        _ReportCard(
          icon: Icons.date_range,
          title: context.l10n.reportsCustomRange,
          subtitle: context.l10n.reportsCustomRangeSubtitle,
          onTap: () => context.push('/reports/range'),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
