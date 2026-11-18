#!/usr/bin/env bash
# Usage: tool/l10n.sh
# Merges l10n_parts/*.arb into lib/l10n/app_{en,bn}.arb, then regenerates
# lib/l10n/generated/*. Serialised through tool/locked.sh so parallel agents
# never run it at the same time. Run it from anywhere.
cd "$(dirname "$0")/.." || exit 1
exec tool/locked.sh bash -c 'python tool/merge_arb.py && flutter gen-l10n'
