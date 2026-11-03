# 06-pasoe — .NET from a PASOE agent

## The one thing that matters: agentStartupParam

The ABL agent is what loads the CLR, so `-clrnetcore` and `-assemblies` go on the **agent**
startup parameters, not on the Tomcat JVM. In
`$CATALINA_BASE/conf/openedge.properties`, in the `[<instance>.ROOT.APSV]` section:

```ini
[oepas1.ROOT.APSV]
# ... existing settings ...
agentStartupParam=-s 1024 -clrnetcore -assemblies /home/peter/src/DotNetCore-on-ABL-Linux-Samples-/assemblies
```

Notes that cost people time:

- `$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json` is **installation-wide**. Every PASOE
  instance and every batch client on the box shares that one file and therefore one .NET version.
- `DOTNET_ROOT` must be visible to the **agent process**, not just to your login shell. With a
  user-local .NET (`~/.dotnet`) set it in the instance environment
  (`$CATALINA_BASE/bin/setenv.sh`), or install .NET somewhere the agent user finds by default.
  This is the most likely cause of a "works in `_progres`, fails in PASOE" report.
- Restart the instance after changing `openedge.properties`; agents re-read it only on start.

## Status in this repo

**Not verified on a running instance.** See results.md "Open problems". The two questions worth
answering if an instance is available:

1. Does one agent process share one CLR across sessions? Test with a static counter incremented
   from two different sessions — if the second session sees 2, the CLR (and its statics) are
   shared for the life of the agent, which matters for anything cached in a .NET static.
2. Is `Process:Start` from an agent as slow as `OS-COMMAND`? KB 000207833 reports `OS-COMMAND`
   getting slower as the agent's memory grows, because the fork duplicates the agent's address
   space. `Process:Start` goes through `posix_spawn`/`vfork` in .NET rather than the shell, so it
   should not degrade the same way — that is the claim to test, and it would be a strong slide.
