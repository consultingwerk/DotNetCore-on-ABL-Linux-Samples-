#!/usr/bin/env bash
# Runs all benchmarks for one .NET configuration.
# Usage: ./run.sh <label>          e.g. ./run.sh net8   (after switching: ./run.sh net10)
# Needs: OpenEdge 13.0 (DLC, default /Progress/OpenEdge130_64), .NET runtime matching $DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json,
#        zip and unzip installed.
set -euo pipefail

# Batch mode refuses to write to a terminal (error 165): re-run through cat.
if [ -t 1 ]; then "$0" "$@" | cat; exit "${PIPESTATUS[0]}"; fi

export DLC=${DLC:-/Progress/OpenEdge130_64}
export DOTNET_ROOT=${DOTNET_ROOT:-$HOME/.dotnet}
LABEL=${1:-net8}
HERE=$(cd "$(dirname "$0")" && pwd)
ASSEMBLIES="$HERE/../assemblies"    # the repo's shared assemblies.xml
TREE=${TREE:-/tmp/bench-tree}
RUNS=${RUNS:-5}

[ -d "$TREE" ] || "$HERE/gen-tree.sh" "$TREE"
cd "$HERE"

grep -E '"(tfm|version)"' "$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json" | sed 's/^/runtimeconfig: /'

"$DLC/bin/_progres" -b -clrnetcore -assemblies "$ASSEMBLIES" \
    -p run-all.p -param "label=$LABEL;runs=$RUNS;tree=$TREE"

for preload in no yes; do
  for n in 1 2 3 4 5; do
    if [ "$preload" = yes ]; then P=-preloadCLR; else P=; fi
    "$DLC/bin/_progres" -b -clrnetcore $P -assemblies "$ASSEMBLIES" \
        -p clr-first-call.p -param "label=$LABEL;preload=$preload"
  done
done

echo "Results: results-$LABEL.md, results-$LABEL.csv, results-$LABEL-clr.csv"
