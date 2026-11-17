import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
          title: 'Monthly report',
          subtitle: 'Income, expense, budget, categories, daily spending',
          onTap: () => context.push('/reports/monthly'),
        ),
        _ReportCard(
          icon: Icons.bar_chart,
          title: 'Yearly report',
          subtitle: 'All 12 months, comparison, highest and lowest month',
          onTap: () => context.push('/reports/yearly'),
        ),
        _ReportCard(
          icon: Icons.date_range,
          title: 'Custom range',
          subtitle: 'Pick any start and end date',
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
