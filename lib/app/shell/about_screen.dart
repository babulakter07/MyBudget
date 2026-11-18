import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../app_constants.dart';

/// About the app and its developer: name, profession, current work, contact.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _portfolio = 'https://babulakter07.github.io/portfolio/';
  static const _github = 'https://github.com/babulakter07';
  static const _linkedin = 'https://www.linkedin.com/in/rjbabul/';
  static const _email = 'babul.170126@s.pust.ac.bd';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appShellAbout)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 44,
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
                          l10n.appShellAboutTagline,
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
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, child: Text('BA')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Md. Babul Akter',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.appShellAboutRole,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.appShellAboutCurrentWork, theme),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.business_outlined),
            title: const Text('TechnoNext Software Ltd'),
            subtitle: Text(l10n.appShellAboutJob),
          ),
          const SizedBox(height: 8),
          _SectionTitle(l10n.appShellAboutContact, theme),
          _CopyTile(
            icon: Icons.email_outlined,
            label: l10n.appShellAboutEmail,
            value: _email,
          ),
          _CopyTile(
            icon: Icons.language,
            label: l10n.appShellAboutPortfolio,
            value: _portfolio,
          ),
          const _CopyTile(icon: Icons.code, label: 'GitHub', value: _github),
          const _CopyTile(
            icon: Icons.work_outline,
            label: 'LinkedIn',
            value: _linkedin,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.appShellAboutTapToCopy,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.theme);
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      const Divider(),
    ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appShellAboutCopied(label))),
        );
      }
    },
  );
}
