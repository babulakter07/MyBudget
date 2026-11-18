import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  final en = _load('app_en.arb');
  final bn = _load('app_bn.arb');
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();

  test('Bangla has every English key and no extras', () {
    final bnKeys = bn.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys.difference(bnKeys), isEmpty, reason: 'missing in app_bn.arb');
    expect(bnKeys.difference(keys), isEmpty, reason: 'extra in app_bn.arb');
  });

  test('placeholders match and translations are not empty', () {
    for (final k in keys) {
      final e = en[k] as String;
      final b = bn[k] as String;
      expect(b.trim(), isNotEmpty, reason: k);
      expect(_placeholders(b), _placeholders(e), reason: 'placeholders of $k');
    }
  });

  test('every key with placeholders declares metadata', () {
    for (final k in keys) {
      if (_placeholders(en[k] as String).isNotEmpty) {
        expect(en['@$k'], isNotNull, reason: 'missing @$k metadata');
      }
    }
  });

  test('no untranslated copies (Bangla differs from English)', () {
    // Allowed to be identical: brand/technical tokens.
    const allowed = {'commonOk'};
    final same = [
      for (final k in keys)
        if (en[k] == bn[k] &&
            !allowed.contains(k) &&
            RegExp(r'[A-Za-z]{3,}').hasMatch(
              (en[k] as String).replaceAll(RegExp(r'\{[^}]*\}'), ''),
            ) &&
            !(en[k] as String).startsWith('{'))
          k,
    ];
    expect(same, isEmpty, reason: 'English text left in app_bn.arb');
  });
}
