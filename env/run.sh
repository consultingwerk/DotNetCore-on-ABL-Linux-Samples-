#!/usr/bin/env bash
# One-command launcher for every demo in this repo.
# Usage:  ./env/run.sh 01-files/demo1.p [extra _progres args]
# Works from a fresh terminal: it sets DLC, DOTNET_ROOT, PROPATH and -assemblies itself.
set -euo pipefail

export DLC=${DLC:-/Progress/OpenEdge130_64}
export DOTNET_ROOT=${DOTNET_ROOT:-$HOME/.dotnet}
export PATH="$DLC/bin:$DOTNET_ROOT:$PATH"

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG=${1:?usage: run.sh <prog.p> [extra _progres args]}
shift || true

# Every demo folder on PROPATH, so classes resolve from anywhere.
export PROPATH="$REPO,$(find "$REPO" -maxdepth 1 -type d -name '[0-9]*' | sort | paste -sd,)"

exec "$DLC/bin/_progres" -b -clrnetcore -assemblies "$REPO/assemblies" -p "$REPO/$PROG" "$@"
