# 06-pasoe — .NET from a PASOE agent

Tested on OpenEdge 13.0 PASOE, .NET 8.0.33, Ubuntu 26.04 (WSL), instance created as a normal
user in `~/pasoe/demo`, one agent (`maxAgents=1`), APSV transport.

## Setting it up

### 1. Create the instance as a non-root user

`$DLC/servers/pasoe` must be readable (it was `0770 root:root` here). `pasman create` also wants
to write its instance registry and temp files *inside* `$DLC`. Both have environment overrides:

```bash
export PSC_AS_INSTANCE_DIR=$HOME/pasoe/registry   # instance registry (default: $DLC/servers/pasoe/conf)
export CATALINA_TMPDIR=$HOME/pasoe/tmp            # temp files     (default: $DLC/servers/pasoe/temp)
mkdir -p $PSC_AS_INSTANCE_DIR $CATALINA_TMPDIR
pasman create -v -f -p 8810 -P 8811 -s 8812 -N demo ~/pasoe/demo
```

### 2. Ubuntu / Debian only: fix one line in setenv.sh

`$DLC/servers/pasoe/bin/setenv.sh` is `#!/bin/bash` and uses `${_trustfile:0:1}` (line 202), but
`catalina.sh` is `#!/bin/sh` and *sources* it. On Ubuntu `/bin/sh` is `dash`, so Tomcat does not
start:

```
/Progress/OpenEdge130_64/servers/pasoe/bin/catalina.sh: 202: /Progress/OpenEdge130_64/servers/pasoe/bin/setenv.sh: Bad substitution
```

The branch always runs, because `psc.as.https.trustfile=conf/tomcat-certstore.p12` is set by
default. `catalina.sh` prefers `$CATALINA_BASE/bin/setenv.sh`, so put a copy there with the line
replaced by POSIX syntax — no change to `$DLC`:

```sh
case "$_trustfile" in
    /*) ;;
    *)  _trustfile="${CATALINA_BASE}/${_trustfile}" ;;
esac
```

### 3. Enable the APSV transport

All four transports are off in a new instance (`adapterEnabled=0`):

```bash
cd ~/pasoe/demo/bin && ./oeprop.sh demo.ROOT.APSV.adapterEnabled=1
```

### 4. -clrnetcore and -assemblies go on the agent, in [AppServer.SessMgr.<instance>]

Not under `[demo.ROOT.APSV]`. Use `oeprop.sh`, and keep the default `-T`:

```bash
./oeprop.sh AppServer.SessMgr.demo.agentStartupParam='-T "${catalina.base}/temp" -clrnetcore -assemblies /path/to/assemblies'
```

Resulting section of `conf/openedge.properties`:

```ini
[AppServer.SessMgr.demo]
    agentLogEntryTypes=ASPlumbing,DB.Connects
    agentLogFile=${catalina.base}/logs/demo.agent.{yyyy-mm-dd}.log
    agentStartupParam=-T "${catalina.base}/temp" -clrnetcore -assemblies /home/peter/src/DotNetCore-on-ABL-Linux-Samples-/assemblies
    maxAgents=1
    numInitialAgents=1
```

### 5. DOTNET_ROOT for the agent process

Every `*_setenv.sh` in `$CATALINA_BASE/bin` is sourced at start-up, so add `bin/dotnet_setenv.sh`:

```sh
DOTNET_ROOT="$HOME/.dotnet"; export DOTNET_ROOT
```

Without it the client gets only this — which blames the runtimeconfig, although that file is fine:

```
Unable to load .NET. The runtimeconfig.json file contains a reference to a .NET framework
which is not available: /Progress/OpenEdge130_64/bin/Progress.clrbridge.netcore.runtimeconfig.json. (20825)
```

(In a batch client .NET also prints which frameworks it *did* find; under PASOE that part is lost.)

## Results

Programs: `net-info.p` (endpoint), `client.p`, `clr-identity.p`, `appcontext.p`,
`spawn-timing.p` / `spawn-client.p`, and `sigchld/` (one test per file).

### .NET works in the agent

```
connection 1 -> .NET 8.0.33  agent pid: 95988  session: 4  .NET static: 7  ABL static: 1
connection 2 -> .NET 8.0.33  agent pid: 95988  session: 9  .NET static: 1  ABL static: 1
connection 3 -> .NET 8.0.33  agent pid: 95988  session: 6  .NET static: 1  ABL static: 1
connection 1 -> .NET 8.0.33  agent pid: 95988  session: 4  .NET static: 8  ABL static: 2
connection 2 -> .NET 8.0.33  agent pid: 95988  session: 9  .NET static: 2  ABL static: 2
connection 3 -> .NET 8.0.33  agent pid: 95988  session: 6  .NET static: 2  ABL static: 2
```

### One CLR per agent, but your assemblies per session

Same process, three sessions, and a static in our own assembly (`Demo.Interop.Counter`) counts
**per session** (session 4 had served six earlier requests, hence 7, 8). Why:

```
connection 1 : session 6  AppDomain id 1  ALC 'AS-6'  ALC hash 59487907
connection 2 : session 9  AppDomain id 1  ALC 'AS-9'  ALC hash 34678979
connection 3 : session 4  AppDomain id 1  ALC 'AS-4'  ALC hash 20390146
```

One CLR / AppDomain per agent process, and **one AssemblyLoadContext per ABL session**, named
`AS-<session id>`. Assemblies from `-assemblies` are loaded per session. Framework state is
shared, though — `System.AppContext` data written in one session is read in another:

```
conn 1 writes; before: <nothing>  (read in session 4)
conn 2 reads        : written by connection 1  (read in session 9)
```

So: a static cache in *your* .NET code is per ABL session (like an ABL static); anything held by
the framework (AppContext, `Environment`, process-wide singletons) is shared by all sessions of
the agent.

### Process:Start in an agent never sees its child exit

Each test on a freshly started agent, one request, 30 s limit:

| Test | PASOE agent | Batch client |
|---|---|---|
| A `OS-COMMAND` ×5, no .NET | 9 ms | – |
| B touch `Process` class, then `OS-COMMAND` ×5 | 14 ms | – |
| C `Process:Start` + `WaitForExit()`, then `OS-COMMAND` | **hangs**, zombie `[true] <defunct>` | 14 ms |
| D touch `Process`, then `INPUT THROUGH` | 2 ms | – |
| E `Process:Start` + `WaitForExit()`, then `INPUT THROUGH` | **hangs**, zombie | 2 ms |
| F `Process:Start` + `WaitForExit(5000)` only | `returned no after 5003 ms; HasExited=no`, zombie | – |

F isolates it: `/bin/true` exits at once, but .NET never learns that it did. `WaitForExit()` blocks
forever, `WaitForExit(ms)` always times out, `HasExited` stays `no`, there is no exit code, and the
child stays a zombie. `OS-COMMAND` and `INPUT THROUGH` are not affected (A, B, D). The batch
client runs the same code correctly.

A request stuck in `WaitForExit()` also makes the agent ignore `tcman.sh stop`; it had to be
killed with SIGKILL.

Supporting observation, not a proven cause: in the agent 11 of 12 threads block `SIGCHLD`,
which .NET relies on to notice child exits.

Usable pattern in an agent: redirect stdout and read it to EOF (`ReadToEnd()` returns when the
child closes it), and do not call `WaitForExit`, `HasExited` or `ExitCode`. Every child still
remains a zombie until the agent stops — 900 after the timing runs below, all gone after
`tcman.sh stop`. Zombies count against the per-user process limit (`ulimit -u` = 63,057 here), so
an agent that started ~63,000 children without a restart would leave its user unable to start
any process — inferred, not tested.

### KB 000207833 confirmed: OS-COMMAND slows as the agent grows, Process:Start does not

100 × `/bin/echo` from one agent, memory grown by touching a MEMPTR, 3 runs per size:

| Agent RSS | `OS-COMMAND` | `Process:Start` + `ReadToEnd` |
|---:|---:|---:|
| ~75 MB | 401 / 427 / 438 ms | 181 / 192 / 180 ms |
| ~1.1 GB | 1503 / 1451 / 1516 ms | 161 / 164 / 169 ms |
| ~2.1 GB | 2460 / 2697 / 2585 ms | 183 / 229 / 184 ms |

`OS-COMMAND` cost grows roughly in line with agent size (~6× at 2 GB); `Process:Start` is flat.
(MEMPTR `SET-SIZE` takes a 32-bit INTEGER, so 2 GB is the largest single allocation — error 15747
above that.)
