#!/usr/bin/env python3
"""List user-facing string literals that are not localized yet.

Usage: python tool/find_hardcoded.py [path ...]   (default: lib/features lib/app)
Looks at Text('...'), labelText/hintText/helperText/tooltip/semanticLabel
named args, SnackBar/AlertDialog style literals, and prints file:line: text.
Ignores lines marked `// l10n-ignore`, generated files and tests.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATTERNS = [
    re.compile(r"""\bText\(\s*(?:const\s+)?(['"])((?:\\.|(?!\1).)*[A-Za-z](?:\\.|(?!\1).)*)\1"""),
    re.compile(r"""\b(?:labelText|hintText|helperText|errorText|tooltip|semanticLabel|title|subtitle|label|content|message|prefixText|suffixText)\s*:\s*(?:const\s+)?(?:Text\(\s*(?:const\s+)?)?(['"])((?:\\.|(?!\1).)*[A-Za-z](?:\\.|(?!\1).)*)\1"""),
]
SKIP_VALUE = re.compile(r'^[\s\d\W]*$|^\$\{?\w+\}?$|^[a-z_]+/[a-z_/:]+$|^package:|^assets/|\.(dart|png|jpg|json|csv|pdf)$')


def scan(path):
    out = []
    with open(path, encoding='utf-8') as f:
        for n, line in enumerate(f, 1):
            if 'l10n-ignore' in line or line.lstrip().startswith(('//', 'import ', 'export ', 'part ')):
                continue
            seen = set()
            for pat in PATTERNS:
                for m in pat.finditer(line):
                    text = m.group(2)
                    if SKIP_VALUE.search(text) or text in seen:
                        continue
                    seen.add(text)
                    out.append((n, text))
    return out


def main():
    roots = sys.argv[1:] or ['lib/features', 'lib/app']
    total = 0
    for r in roots:
        base = r if os.path.isabs(r) else os.path.join(ROOT, r)
        files = [base] if os.path.isfile(base) else [
            os.path.join(d, f) for d, _, fs in os.walk(base) for f in fs
        ]
        for p in sorted(files):
            if not p.endswith('.dart') or p.endswith('.g.dart') or '/generated/' in p.replace('\\', '/'):
                continue
            hits = scan(p)
            for n, text in hits:
                print('%s:%d: %s' % (os.path.relpath(p, ROOT).replace('\\', '/'), n, text))
            total += len(hits)
    print('TOTAL hardcoded literals: %d' % total)
    return 0


if __name__ == '__main__':
    sys.exit(main())
