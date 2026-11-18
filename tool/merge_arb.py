#!/usr/bin/env python3
"""Merge per-module ARB parts into lib/l10n/app_en.arb and app_bn.arb.

Parts live in l10n_parts/<module>_en.arb and l10n_parts/<module>_bn.arb so
parallel agents never edit the same file. Rules enforced (exit code 1 on any
violation):
  * a key may exist in only one module part per locale,
  * every English key has a Bangla key and vice versa,
  * placeholders ({name}) match between English and Bangla,
  * keys are lowerCamelCase and prefixed with the module name.
Metadata entries ("@key": {...}) are taken from the English part only.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARTS = os.path.join(ROOT, 'l10n_parts')
OUT = os.path.join(ROOT, 'lib', 'l10n')
PLACEHOLDER = re.compile(r'\{(\w+)')
KEY = re.compile(r'^[a-z][A-Za-z0-9]*$')


def load(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def main():
    errors = []
    merged = {'en': {}, 'bn': {}}
    owner = {'en': {}, 'bn': {}}
    for locale in ('en', 'bn'):
        for path in sorted(glob.glob(os.path.join(PARTS, '*_%s.arb' % locale))):
            module = os.path.basename(path)[: -len('_%s.arb' % locale)]
            for key, value in load(path).items():
                if key.startswith('@@'):
                    continue
                if key.startswith('@'):
                    if locale == 'en':
                        merged['en'][key] = value
                    continue
                if not KEY.match(key):
                    errors.append('%s: bad key %r' % (path, key))
                words = module.split('_')
                prefix = words[0] + ''.join(w.capitalize() for w in words[1:])
                if not key.startswith(prefix):
                    errors.append(
                        '%s: key %r must start with %r'
                        % (os.path.basename(path), key, prefix)
                    )
                if key in merged[locale]:
                    errors.append('duplicate key %r in %s and %s' % (key, owner[locale][key], module))
                merged[locale][key] = value
                owner[locale][key] = module

    en_keys = {k for k in merged['en'] if not k.startswith('@')}
    bn_keys = {k for k in merged['bn'] if not k.startswith('@')}
    for k in sorted(en_keys - bn_keys):
        errors.append('missing Bangla translation: %s' % k)
    for k in sorted(bn_keys - en_keys):
        errors.append('Bangla key without English: %s' % k)
    for k in sorted(en_keys & bn_keys):
        pe = sorted(set(PLACEHOLDER.findall(merged['en'][k])))
        pb = sorted(set(PLACEHOLDER.findall(merged['bn'][k])))
        if pe != pb:
            errors.append('placeholder mismatch in %s: en=%s bn=%s' % (k, pe, pb))
        if not str(merged['bn'][k]).strip():
            errors.append('empty Bangla translation: %s' % k)

    if errors:
        print('ARB merge FAILED:')
        for e in errors:
            print('  - ' + e)
        return 1

    os.makedirs(OUT, exist_ok=True)
    for locale in ('en', 'bn'):
        data = {'@@locale': locale}
        for k in sorted(merged[locale], key=lambda s: (s.lstrip('@'), s.startswith('@'))):
            data[k] = merged[locale][k]
        with open(os.path.join(OUT, 'app_%s.arb' % locale), 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print('ARB merged: %d keys (en) / %d keys (bn)' % (len(en_keys), len(bn_keys)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
