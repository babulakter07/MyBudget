import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String route) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Master Configuration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          tile(Icons.category_outlined, 'Categories', '/config/categories'),
          tile(
            Icons.account_tree_outlined,
            'Sub-categories',
            '/config/sub-categories',
          ),
          tile(Icons.list_alt_outlined, 'Cost Items', '/config/cost-items'),
          tile(Icons.people_outline, 'Profiles', '/profiles'),
        ],
      ),
    );
  }
}
