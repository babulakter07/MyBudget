import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// AppBar "?" button that opens the user manual at [topicId]
/// (an id from `manualTopics`, e.g. `security`, `budget`, `backup`).
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    return IconButton(
      key: ValueKey('help-$topicId'),
      tooltip: bn ? 'সাহায্য' : 'Help',
      icon: const Icon(Icons.help_outline),
      onPressed: () => context.push('/help?topic=$topicId'),
    );
  }
}
