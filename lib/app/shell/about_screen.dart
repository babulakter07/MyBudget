import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_constants.dart';

/// About the app and its developer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _github = 'https://github.com/babulakter07';
  static const _linkedin = 'https://www.linkedin.com/in/rjbabul/';
  static const _email = 'babul.170126@s.pust.ac.bd';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AppCard(theme: theme),
          const SizedBox(height: 16),
          _DeveloperCard(theme: theme),
          const SizedBox(height: 16),
          _Section(
            title: 'About me',
            child: const Text(
              'Full Stack .NET developer with 3+ years of experience building '
              'cloud-ready digital solutions. I enjoy designing reliable, '
              'well-structured systems and working in agile teams across '
              'development, testing, deployment and support.',
            ),
          ),
          _Section(
            title: 'Experience',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Role(
                  company: 'TechnoNext Software Ltd',
                  role: 'Software Engineer',
                  period: 'Jan 2024 - Present',
                  points: [
                    'Online Travel Agency (OTA) B2B platform using .NET 8, '
                        'Angular and MSSQL, serving 6 enterprise clients and '
                        '30,000+ users.',
                    'Real-time booking updates with SignalR, JWT-secured APIs '
                        'and multithreaded processing that cut ticket '
                        'processing time by 40%.',
                    'Multi-tenant B2B/B2C platform with Redis distributed '
                        'locking and idempotent booking/payment APIs.',
                    'Team Lead of an automated financial reconciliation '
                        'engine for airline ticketing (60% less manual '
                        'auditing); mentored 6+ developers.',
                    'MSSQL to PostgreSQL migration (custom ETL, stored '
                        'procedures to PL/pgSQL) and a Redis Streams based '
                        'distributed logging pipeline.',
                  ],
                ),
                SizedBox(height: 12),
                _Role(
                  company: 'Bdjobs.com Ltd',
                  role: 'Junior Software Engineer',
                  period: 'May 2023 - Jan 2024',
                  points: [
                    'Backend APIs for Bangladesh\'s leading job portal using '
                        'ASP.NET Core, DDD and the Generic Repository pattern.',
                    'Secure authentication and role-based authorization, '
                        'Entity Framework and MSSQL for postings, candidates '
                        'and dashboards.',
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Skills',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in [
                  'C#',
                  '.NET 8/10',
                  'ASP.NET Core',
                  'Angular',
                  'TypeScript',
                  'JavaScript',
                  'Python',
                  'Java',
                  'C++',
                  'Laravel',
                  'Flutter',
                  'MSSQL',
                  'PostgreSQL',
                  'MySQL',
                  'MongoDB',
                  'Entity Framework',
                  'Dapper',
                  'Redis',
                  'Docker',
                  'Git',
                  'Clean Architecture',
                  'DDD',
                  'Microservices',
                  'Multi-tenant',
                  'Idempotency',
                  'SignalR',
                  'gRPC',
                  'xUnit',
                  'Agile / Scrum',
                ])
                  Chip(label: Text(s)),
              ],
            ),
          ),
          _Section(
            title: 'Problem solving',
            child: const Text(
              '1,800+ problems solved on LeetCode, Codeforces, UVA, Toph, '
              'HackerRank and GeeksforGeeks, with a strong grasp of data '
              'structures and algorithms.',
            ),
          ),
          _Section(
            title: 'Education',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Edu(
                  title: 'B.Sc. in Computer Science and Engineering',
                  detail:
                      'Pabna University of Science & Technology\n'
                      'CGPA 3.38 / 4.00 - 2023',
                ),
                _Edu(
                  title: 'HSC (Science)',
                  detail:
                      'Mawlana Saif Uddin Yahia Degree College, '
                      'Shahjadpur, Sirajganj\nGPA 5.00 / 5.00 - 2016',
                ),
                _Edu(
                  title: 'SSC (Science)',
                  detail:
                      'Habibullah Nagar High School\n'
                      'GPA 5.00 / 5.00 - 2013',
                ),
              ],
            ),
          ),
          _Section(
            title: 'Contact',
            child: Column(
              children: [
                _CopyTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _email,
                ),
                _CopyTile(icon: Icons.code, label: 'GitHub', value: _github),
                _CopyTile(
                  icon: Icons.work_outline,
                  label: 'LinkedIn',
                  value: _linkedin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Made in Dhaka, Bangladesh',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offline-first personal and family budget manager. All '
                    'your data stays on your device - no account, no cloud, '
                    'no internet required.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 32, child: Text('BA')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Md. Babul Akter', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Software Engineer | Full Stack .NET Developer',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text('Dhaka, Bangladesh', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }
}

class _Role extends StatelessWidget {
  const _Role({
    required this.company,
    required this.role,
    required this.period,
    required this.points,
  });
  final String company;
  final String role;
  final String period;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(company, style: theme.textTheme.titleSmall),
        Text('$role  |  $period', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 2),
                  child: Text('•'),
                ),
                Expanded(child: Text(p)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Edu extends StatelessWidget {
  const _Edu({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Text(detail),
      ],
    ),
  );
}

/// Tap to copy (keeps the app free of extra link-launching dependencies).
class _CopyTile extends StatelessWidget {
  const _CopyTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.copy, size: 18),
    onTap: () async {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$label copied')));
      }
    },
  );
}
