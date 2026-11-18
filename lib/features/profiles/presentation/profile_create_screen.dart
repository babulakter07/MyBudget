import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/profile_providers.dart';

class ProfileCreateScreen extends ConsumerStatefulWidget {
  const ProfileCreateScreen({super.key});

  @override
  ConsumerState<ProfileCreateScreen> createState() =>
      _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends ConsumerState<ProfileCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(profileRepositoryProvider)
          .create(_name.text);
      // First profile (or none selected): select it automatically.
      if (ref.read(activeProfileIdProvider) == null) {
        await ref.read(activeProfileIdProvider.notifier).select(created.id);
      }
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profiles');
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilesNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.profilesNameLabel,
                border: const OutlineInputBorder(),
                errorText: _serverError,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.profilesNameRequired
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: 'BDT',
              enabled: false,
              decoration: InputDecoration(
                labelText: l10n.profilesCurrencyLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonCreate),
            ),
          ],
        ),
      ),
    );
  }
}
