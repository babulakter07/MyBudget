import 'package:material_ui/material_ui.dart';

import '../domain/manual_content.dart';
import '../domain/manual_content_bn.dart';

/// Manual topics in the requested language (falls back to English per topic).
List<ManualTopic> localizedManualTopics({required bool bn}) {
  if (!bn) return manualTopics;
  return [
    for (final t in manualTopics)
      if (manualTopicsBn[t.id] case final b?)
        ManualTopic(
          id: t.id,
          title: b.title,
          icon: t.icon,
          summary: b.summary,
          steps: b.steps,
          tips: b.tips,
        )
      else
        t,
  ];
}

/// In-app user manual: searchable list of expandable topics.
class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key, this.initialTopicId});

  /// Topic id (see `manualTopics`) to open expanded and scrolled into view.
  final String? initialTopicId;

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  String _query = '';

  bool _matches(ManualTopic t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.title.toLowerCase().contains(q) ||
        t.summary.toLowerCase().contains(q) ||
        t.steps.any((s) => s.toLowerCase().contains(q)) ||
        t.tips.any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final topics = localizedManualTopics(bn: bn).where(_matches).toList();
    // Opened from a screen's "?" button: show that topic first.
    final focus = topics.indexWhere((t) => t.id == widget.initialTopicId);
    if (focus > 0) topics.insert(0, topics.removeAt(focus));
    return Scaffold(
      appBar: AppBar(title: Text(bn ? 'ব্যবহার নির্দেশিকা' : 'User manual')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const ValueKey('manual-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: bn ? 'নির্দেশিকায় খুঁজুন' : 'Search the manual',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: topics.isEmpty
                ? Center(
                    child: Text(
                      bn ? 'কোনো বিষয় পাওয়া যায়নি' : 'No matching topics',
                    ),
                  )
                : ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, i) {
                      final t = topics[i];
                      return ExpansionTile(
                        key: PageStorageKey('manual-${t.id}'),
                        leading: Icon(t.icon, color: theme.colorScheme.primary),
                        title: Text(t.title),
                        initiallyExpanded:
                            _query.trim().isNotEmpty ||
                            t.id == widget.initialTopicId,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Text(t.summary, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          for (var n = 0; n < t.steps.length; n++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${n + 1}.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Expanded(child: Text(t.steps[n])),
                                ],
                              ),
                            ),
                          if (t.tips.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            for (final tip in t.tips)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 18,
                                      color: theme.colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(tip)),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
