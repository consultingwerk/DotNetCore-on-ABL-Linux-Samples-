#!/usr/bin/env bash
# Creates the deterministic test tree for the dirwalk and zip workloads:
# 10 x 10 folders with 100 files each = 10,000 small files (.xml, .txt, .json).
# Usage: ./gen-tree.sh [root]     (default root: /tmp/bench-tree)
set -euo pipefail
ROOT=${1:-/tmp/bench-tree}
rm -rf "$ROOT"
mkdir -p "$ROOT"
for a in $(seq -w 0 9); do
  for b in $(seq -w 0 9); do
    d="$ROOT/dir$a/sub$b"
    mkdir -p "$d"
    for c in $(seq -w 0 99); do
      case $((10#$c % 3)) in
        0) ext=xml ;;
        1) ext=txt ;;
        *) ext=json ;;
      esac
      printf 'PUG Challenge 2026 benchmark file %s %s %s\n' "$a" "$b" "$c" > "$d/file$c.$ext"
    done
  done
done
echo "$(find "$ROOT" -type f | wc -l) files in $ROOT"
