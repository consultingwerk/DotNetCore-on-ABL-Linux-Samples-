# Benchmarks: .NET on Linux. Why bother?

Benchmark code for Peter Judge's talk at PUG Challenge 2026 Amsterdam (Wed 4 Nov, 3:00 PM, New York 3).
Feeds the slides "How We'll Measure", "Why Measure Again?" and "The Numbers".

Samples repo: https://github.com/consultingwerk/DotNetCore-on-ABL-Linux-Samples- (the benchmarks go into `05-benchmarks/` there).

**Status (21.10.2026): DRAFT.** Written without access to an OpenEdge 13.0 installation. Nothing here has been compiled or run yet. Expect small fixes on the first run, and record them below.

## Why measure again

The only numbers so far are Mike Fechner's, from ".NET Core and OpenEdge" (PUG Challenge Americas 2023):

| | 2023 (Mike Fechner) | 2026 (this talk) |
|---|---|---|
| OpenEdge | 12.7 | 13.0 |
| Platform | Windows | Linux (WSL) |
| Compared | .NET Framework 4.8 vs .NET 6 | ABL vs .NET 8 (and .NET 10) |
| Guid.Parse, 500,000 calls | ~6 s → ~5 s | `wl-guid-parse.p` |
| Distance (Haversine) | 2.4 s → 1.9 s **for 10,000 iterations** (not 500,000 — see below) | `wl-haversine.p` |

Three years, a new OpenEdge major, a different OS, two newer .NET LTS releases, and a different question: when does .NET beat plain ABL, and what does the bridge cost?

## Workloads

| Workload | ABL program | .NET program | Iterations | What it shows |
|---|---|---|---:|---|
| guid-parse | – | `wl-guid-parse.p` | 500,000 | Bridge overhead of many tiny calls (2023 repeat) |
| haversine | – | `wl-haversine.p` | 500,000 | `System.Math` (ABL has no trigonometry) (2023 repeat) |
| sha256 | `wl-sha256-abl.p` | `wl-sha256-net.p` | 100,000 | `MESSAGE-DIGEST` vs `SHA256.ComputeHash`, two bridge calls per string |
| dirwalk | `wl-dirwalk-abl.p` | `wl-dirwalk-net.p` | 1 | OS-DIR work queue vs one `Directory.GetFiles` call, 10,000 files |
| process | `wl-process-abl.p` | `wl-process-net.p` | 100 | `INPUT THROUGH` (shell per call) vs `Process.Start` (no shell) |
| zip | `wl-zip-shell.p` | `wl-zip-net.p` | 1 | `zip` via `OS-COMMAND` vs `ZipFile.CreateFromDirectory`, 10,000 files |
| CLR start | – | `clr-first-call.p` | 1 per session | First .NET call with and without `-preloadCLR` |

Every workload program has the same signature: `(input iterations, input argument, output check value)`. The check value (hash, file count, entry count) must be the same for the ABL and the .NET variant, which shows that both did the same work.

## Method

- `run-all.p` runs each workload once as warm-up (compiles the program on the fly, loads the CLR and the assemblies), then 5 timed runs.
- Timing with `ETIME` around the `RUN`. The median goes onto the slide.
- Same machine, same input, nothing else running.
- The CLR start is measured in fresh sessions (`run.sh` starts 5 sessions each with and without `-preloadCLR`).

## Environment

Proposed: WSL on the presentation PC (Peter, 21.10.2026). It doubles as the live-demo environment.

1. A WSL distribution that the OpenEdge 13 Platform Compatibility Guide lists as supported.
2. OpenEdge 13.0 for Linux (batch client is enough; a development licence).
3. The .NET 8 runtime (certified for 13.0 per *What's New in OpenEdge 13.0*); the SDK is not needed.
4. `zip` and `unzip` for the shell variant of the zip workload.
5. Copy this folder into the Linux file system (e.g. `~/bench`), not under `/mnt/c`; file-system timings across the Windows boundary are meaningless.

**Alternative:** Progress's 13.0 PASOE Docker image (UBI 9 Minimal) under Docker in WSL, with the .NET runtime added. This is closer to the "Docker" slide, but needs a registry login and a licence in the image.

## Running

```bash
cd ~/bench
export DLC=/usr/dlc            # your 13.0 installation
./gen-tree.sh                  # once: 10,000 files under /tmp/bench-tree
./run.sh net8                  # results-net8.md, results-net8.csv, results-net8-clr.csv
```

Optional .NET 10 run, only as an experiment unless the KB certifies .NET 10 for 13.0:

1. Install the .NET 10 runtime.
2. Back up `$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json`, then set `"tfm": "net10.0"` and every `"version"` to `"10.0.0"`.
3. `./run.sh net10`. The programs are compiled on the fly, so there is no separate recompile step.
4. Restore the backup.

Put the medians from `results-*.md` into the slide "The Numbers".

## To check on the first run (record the answers here)

- [ ] Do the framework assemblies (`System.IO.Compression.ZipFile`, `System.Diagnostics.Process`, `System.Security.Cryptography`) need entries in `assemblies/assemblies.xml`? If so, which exact names?
- [ ] `wl-haversine.p`: does the compiler accept `DECIMAL` arguments for the `System.Double` parameters of `Math:Sin` etc.? (If not: `AS DOUBLE`.)
- [ ] `wl-guid-parse.p`: a `System.Guid` (value type) in an ABL variable.
- [ ] `wl-sha256-net.p`: overload resolution for `ComputeHash(byte[])` and `Encoding.UTF8.GetBytes(string)` (both also have Span overloads).
- [ ] Check values equal for ABL and .NET in sha256, dirwalk and zip.
- [ ] Content of `$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json` on Linux: paste it here. It goes onto the slide "The Linux File That Picks the .NET Version".

## Results

(to be filled in)

---

## Fixes made on the first real run (02.11.2026, OpenEdge 13.0 / .NET 8.0.33, Ubuntu 26.04 WSL)

The draft had never been compiled. Three things needed changing; workloads and iteration
counts were **not** touched.

### 1. `run-all.p` — `Check` is a reserved word

```
** Unable to understand after -- "as int64  field". (247)
** Unable to understand DEFINE statement. (267)
Unknown or ambiguous table ttRun. (725)
```

`field Check as character` in `ttRun` does not compile. Renamed to **`CheckValue`**
(definition plus the two references).

### 2. `wl-zip-shell.p` — SUBSTITUTE collapsed `&&` into `&`

The serious one: it silently measured and checked the wrong thing.

```
substitute("cd &1 && zip -q -r &2 .", quoter(pcArg), quoter(cZip))
```

`SUBSTITUTE` treats `&` as its placeholder marker, so `&&` came out as a single `&`:

```
cd "/data/tree" & zip -q -r "/tmp/bench-shell.zip" .
```

That **backgrounds the `cd`** and runs `zip` in the *current* directory. The workload therefore
archived the `05-benchmarks` folder and reported a check value of **19** against the .NET side's
**10000** — the mismatch is what exposed it.

Fixed by building the command with plain concatenation instead of `SUBSTITUTE`:

```
os-command silent value("cd " + quoter(pcArg) + " && zip -q -r " + quoter(cZip) + " .").
```

The same change was applied to the `unzip -Z1 ... | grep -v '/$' | wc -l` pipeline.

**Lesson worth repeating on a slide:** never build a shell command containing `&&` or `&` with
`SUBSTITUTE`. The check values are what caught this — without them the zip row would have gone on
the slide as "ABL zip is 20x faster than .NET", measured on 19 files against 10,000.

### 3. `-assemblies` and PROPATH

Run with the repo's shared `assemblies/` folder (`../assemblies`), which needs entries for
`System.IO.Compression`, `System.IO.Compression.ZipFile`, `System.Diagnostics.Process`,
`System.Security.Cryptography`, `System.Security.Cryptography.X509Certificates` and
`System.Text.RegularExpressions`. The simple assembly name is sufficient — no Version or
PublicKeyToken. Types in System.Runtime (Directory, File, Math, StringBuilder, List<T>, Task<T>)
need no entry at all.

### Added workload: `wl-zip-scl.p`

A third zip variant was added at Peter's request: the SmartComponent Library's **pure ABL**
`ZipArchiveWriter` (`Consultingwerk/Framework/Compression`, SCL-6170). This gives the zip row a
genuine ABL implementation instead of only a shell-out. It needs the SCL ABL tree on PROPATH.
SCL documents the writer as intended for small archives (a few MB, no Zip64), so the 10,000-file
tree is deliberately outside its design envelope; the README table reports it as such.

### Correction: the 2023 Haversine figures were for 10,000 iterations

The table at the top originally implied 2.4 s / 1.9 s for 500,000 iterations. The 2023 deck
(slides 54 and 71) shows `DO i = 1 TO 10000`. `wl-haversine.p` still runs 500,000 iterations
(unchanged); for a like-for-like comparison run `haversine-analysis.p -param 10000`
(550 ms on OE 13.0 / .NET 8 / Linux vs 1921 ms on OE 12.7 / .NET 6 / Windows in 2023).
`haversine-analysis.p` also splits the cost into bridge and ABL parts; it is not part of
`run-all.p`.
