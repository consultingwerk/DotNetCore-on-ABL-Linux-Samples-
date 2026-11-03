#!/usr/bin/env bash
# Runs all benchmarks for one .NET configuration.
# Usage: ./run.sh <label>          e.g. ./run.sh net8   (after switching: ./run.sh net10)
# Needs: DLC set, OpenEdge 13.0, .NET runtime matching $DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json,
#        zip and unzip installed.
set -euo pipefail
: "${DLC:?set DLC to the OpenEdge 13.0 installation}"
LABEL=${1:-net8}
HERE=$(cd "$(dirname "$0")" && pwd)
TREE=${TREE:-/tmp/bench-tree}
RUNS=${RUNS:-5}

[ -d "$TREE" ] || "$HERE/gen-tree.sh" "$TREE"
cd "$HERE"

grep -E '"(tfm|version)"' "$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json" | sed 's/^/runtimeconfig: /'

"$DLC/bin/_progres" -b -clrnetcore -assemblies "$HERE/assemblies" \
    -p run-all.p -param "label=$LABEL;runs=$RUNS;tree=$TREE"

for preload in no yes; do
  for n in 1 2 3 4 5; do
    if [ "$preload" = yes ]; then P=-preloadCLR; else P=; fi
    "$DLC/bin/_progres" -b -clrnetcore $P -assemblies "$HERE/assemblies" \
        -p clr-first-call.p -param "label=$LABEL;preload=$preload"
  done
done

echo "Results: results-$LABEL.md, results-$LABEL.csv, results-$LABEL-clr.csv"
