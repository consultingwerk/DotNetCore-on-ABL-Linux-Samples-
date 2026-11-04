# .NET on Linux. Why bother? — samples

Live demos, code samples and benchmarks for the PUG Challenge 2026 Amsterdam talk
".NET on Linux. Why bother?" (Peter Judge, Consultingwerk). ABL calling .NET from the
character/batch client and PASOE on Linux.

## Versions used

| | |
|---|---|
| OpenEdge | 13.0 for Linux (as of 23 Jan 2026) |
| .NET | 8.0.33 runtime (certified for 13.0); 10.0.14 for an uncertified comparison; SDK 8.0.427 only for `08-facade` |
| OS | Ubuntu 26.04.1 LTS on WSL2 (**not** a certified platform for OE 13.0) |
| Tools | zip 3.0, unzip 6.00, openssl 3.5.5 |

## Prerequisites

1. OpenEdge 13.0 for Linux with a valid licence.
2. A .NET 8 runtime. Ubuntu 26.04 only packages .NET 10, so use Microsoft's script (no root needed):
   ```bash
   curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh && chmod +x dotnet-install.sh
   ./dotnet-install.sh --channel 8.0 --runtime dotnet --install-dir "$HOME/.dotnet"
   ```
3. **Edit `$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json`.** OE 13.0 ships it pointing at
   `net6.0` / `6.0.0`; change both to `net8.0` / `8.0.0`. Keep a copy of the original.
4. `zip` and `unzip` (`sudo apt install zip unzip`).
5. A writable `/data` (`sudo mkdir -p /data/in && sudo chown -R $USER /data`).

## Run

Every program runs through one launcher, which sets `DLC`, `DOTNET_ROOT`, `PROPATH` and
`-assemblies` itself and works from a fresh terminal:

```bash
./05-benchmarks/gen-tree.sh /data/tree                       # 10,000-file test tree
./env/run.sh 01-files/demo1.p -param /data/tree              # demo 1: files and zip
./env/run.sh 02-process/demo2.p                              # demo 2: running a process
./03-security/make-certs.sh                                  # throw-away test certificates
./env/run.sh 03-security/demo3.p -param ./03-security/certs  # demo 3: X.509
```

Benchmarks: `cd 05-benchmarks && TREE=/data/tree ./run.sh net8` (see `05-benchmarks/README.md`).

## Reset

- Demo 1: nothing to undo; re-running recreates `/tmp/data/in.zip`.
- Demo 2: nothing to undo.
- Demo 3: `rm -rf 03-security/certs` (git-ignored, never commit it).
- After any .NET 10 experiment: restore the net8.0 runtimeconfig.

## Layout

| Folder | Contents |
|---|---|
| `env/` | `run.sh` launcher |
| `assemblies/` | `assemblies.xml` and the `Demo.Interop.dll` facade |
| `00-hello/` | runtime identification, basic .NET constructs |
| `01-files/` | directory walk ABL vs .NET, zip ABL vs .NET, demo 1 |
| `02-process/` | `INPUT THROUGH` vs `System.Diagnostics.Process`, demo 2 |
| `03-security/` | sslc vs `X509Certificate2`/`X509Chain`, demo 3 |
| `04-more/` | regex, Haversine, time zones |
| `05-benchmarks/` | the benchmark harness and workloads |
| `06-pasoe/` | running .NET in a PASOE agent: setup and sample programs |
| `08-facade/` | C# library `Demo.Interop` (net8.0) and its ABL caller |
| `09-events/` | subscribing to .NET events from ABL |

MIT licence, see `LICENSE`. All certificates are generated throw-away test material.
