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

## Programs

Add this folder to the agent's PROPATH (`PROPATH` in `[AppServer.Agent.demo]`, e.g. with
`oeprop.sh`) and start the instance. `Demo.Interop.dll` in `assemblies/` is the built `08-facade`.
The clients connect to `http://localhost:8810/apsv`; run them from the repo root:

```bash
./env/run.sh 06-pasoe/client.p -param 3
./env/run.sh 06-pasoe/spawn-client.p
```

| Program | Runs in | What it does |
|---|---|---|
| `net-info.p` | agent | Endpoint: .NET version, agent pid, ABL session, a .NET static counter (`Demo.Interop.Counter`) and an ABL static counter (`AblCounter.cls`) |
| `client.p` | client | Calls `net-info.p` over several connections (parameter: number of connections, default 3) |
| `hold.p` | agent | Run PERSISTENT to bind a connection to one agent session |
| `clr-identity.p` | agent | Which AppDomain and AssemblyLoadContext the session's `Demo.Interop` lives in |
| `appcontext.p` | agent | Writes and reads `System.AppContext` data across sessions |
| `spawn-timing.p` | agent | Times `OS-COMMAND` vs `Process:Start` as the agent grows (KB 000207833) |
| `spawn-client.p` | client | Calls `spawn-timing.p` at several agent sizes |

In an agent, `spawn-timing.p` detects child completion by reading stdout to EOF (`ReadToEnd()`)
rather than `WaitForExit()`, which does not return there.
