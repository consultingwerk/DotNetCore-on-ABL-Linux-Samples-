# 05-benchmarks — ABL vs .NET timings

Benchmark harness for the talk ".NET on Linux. Why bother?" (PUG Challenge 2026 Amsterdam).
`guid-parse` and `haversine` repeat the measurements from Mike Fechner's ".NET Core and OpenEdge"
(PUG Challenge Americas 2023); the 2023 Haversine run used 10,000 iterations.

## Workloads

| Workload | ABL program | .NET program | Iterations | What it shows |
|---|---|---|---:|---|
| guid-parse | – | `wl-guid-parse.p` | 500,000 | Bridge overhead of many tiny calls |
| haversine | – | `wl-haversine.p` | 500,000 | `System.Math` (ABL has no trigonometry) |
| sha256 | `wl-sha256-abl.p` | `wl-sha256-net.p` | 100,000 | `MESSAGE-DIGEST` vs `SHA256.ComputeHash`, two bridge calls per string |
| dirwalk | `wl-dirwalk-abl.p` | `wl-dirwalk-net.p` | 1 | OS-DIR work queue vs one `Directory.GetFiles` call, 10,000 files |
| process | `wl-process-abl.p` | `wl-process-net.p` | 100 | `INPUT THROUGH` (shell per call) vs `Process.Start` (no shell) |
| zip | `wl-zip-shell.p` | `wl-zip-net.p` | 1 | `zip` via `OS-COMMAND` vs `ZipFile.CreateFromDirectory`, 10,000 files |
| CLR start | – | `clr-first-call.p` | 1 per session | First .NET call with and without `-preloadCLR` |

Every workload program has the same signature: `(input iterations, input argument, output check value)`.
The check value (hash, file count, entry count) must be the same for the ABL and the .NET variant,
which shows that both did the same work.

`wl-zip-scl.p` is an optional third zip variant using the SmartComponent Library's pure-ABL
`ZipArchiveWriter`. It is not part of `run-all.p` and needs the SCL ABL tree on PROPATH.

## Method

- `run-all.p` runs each workload once as warm-up (compiles the program, loads the CLR and the
  assemblies), then `RUNS` timed runs (default 5). Timing is `ETIME` around the `RUN`; report the median.
- Same machine, same input, nothing else running.
- The CLR start is measured in fresh sessions: `run.sh` starts 5 sessions each with and without
  `-preloadCLR`.
- Run in the Linux file system (e.g. `~/src`), never under `/mnt/c`.

## Running

Prerequisites as in the root `README.md` (OpenEdge 13.0, .NET 8 runtime, net8.0 runtimeconfig,
`zip`/`unzip`). `run.sh` uses the repo's shared `assemblies/` folder.

```bash
cd 05-benchmarks
./gen-tree.sh /data/tree              # once: 10,000 files
TREE=/data/tree ./run.sh net8         # writes results-net8.md, results-net8.csv, results-net8-clr.csv
```

`DLC` defaults to `/Progress/OpenEdge130_64` and `DOTNET_ROOT` to `~/.dotnet`. A single workload:

```bash
export DLC=/Progress/OpenEdge130_64 DOTNET_ROOT=~/.dotnet
$DLC/bin/_progres -b -clrnetcore -assemblies ../assemblies -p run-all.p \
    -param "label=test;runs=5;tree=/data/tree;only=sha256" | cat
```

The results files are git-ignored.

### Optional: .NET 10 (not certified for OpenEdge 13.0)

1. Install the .NET 10 runtime.
2. Back up `$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json`, then set `"tfm": "net10.0"`
   and every `"version"` to `"10.0.0"`.
3. `TREE=/data/tree ./run.sh net10`. Programs compile on the fly; no recompile step.
4. Restore the backup.
