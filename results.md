# .NET on Linux. Why bother? — demo results

Generated on the demo box for PUG Challenge 2026 Amsterdam (Wed 4 Nov 2026).
Everything below was produced by running the code in this repo on Linux. No results are estimated.

## 1. Environment

| Item | Value |
|---|---|
| WSL distro | Ubuntu 26.04.1 LTS ("Resolute Raccoon"), kernel 6.6.87.2-microsoft-standard-WSL2, x86_64 |
| OpenEdge | **13.0**, "as of Fri Jan 23 10:45:17 EST 2026", `$DLC=/Progress/OpenEdge130_64` |
| OE licence | 4GL Dev System, Client Networking, OE Enterprise RDBMS, ProdAS for OE — all expire 04/05/2027 |
| .NET (Linux) | **8.0.33** (target) and **10.0.14** (experiment), user install in `~/.dotnet` |
| .NET SDK | not installed (only needed for the optional 08-facade) |
| openssl | OpenSSL 3.5.5 (27 Jan 2026) |
| zip / unzip | Zip 3.0, UnZip 6.00 |

**Caveat: Ubuntu 26.04 is not a certified platform for OpenEdge 13.0** (OE 13.0 shipped Jan 2026,
Ubuntu 26.04 in Apr 2026). Everything works, but every number below comes off an uncertified distro.

### How to start

```bash
./env/run.sh 01-files/demo1.p -param /tmp/data/tree
```

`env/run.sh` sets `DLC`, `DOTNET_ROOT`, `PROPATH` and `-assemblies` itself, so it works from a fresh
terminal. It runs `_progres -b -clrnetcore -assemblies <repo>/assemblies -p <prog.p>`.

### Installing .NET (there is no distro package for .NET 8 on Ubuntu 26.04)

Ubuntu 26.04 ships only .NET 10 (`dotnet-runtime-10.0`). .NET 8 came from Microsoft's script,
which needs no root:

```bash
curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh && chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0 --runtime dotnet --install-dir "$HOME/.dotnet"
```

Then `export DOTNET_ROOT=$HOME/.dotnet`. Without `DOTNET_ROOT` the clrbridge does not find a
user-local runtime.

---

## 2. Demo 1 — files and zip (slides 17–19)

### Runbook

**Prerequisites:** `zip`, `unzip`; the 10,000-file tree.

```bash
./05-benchmarks/gen-tree.sh /tmp/data/tree     # 10,000 files, ~0.8 s
./env/run.sh 01-files/demo1.p -param /tmp/data/tree
```

**Duration:** under 1 second. **Reset:** nothing to undo; re-running regenerates `/tmp/data/in.zip`.

### Exact output

```
== Demo 1: files and zip ==
tree: /tmp/data/tree

walk-abl   files: 3400   ms: 24
walk-net   files: 3400   ms: 37

zip        entries: 10000   ms: 120   archive: /tmp/data/in.zip
first 10 entries:
   dir9/sub9/file99.xml 41
   dir9/sub9/file98.json 41
   dir9/sub9/file97.txt 41
   dir9/sub9/file96.xml 41
   dir9/sub9/file95.json 41
   dir9/sub9/file94.txt 41
   dir9/sub9/file93.xml 41
   dir9/sub9/file92.json 41
   dir9/sub9/file91.txt 41
   dir9/sub9/file90.xml 41
```

**Check value:** both walkers report **3400** `.xml` files, matching `find /tmp/data/tree -name '*.xml' | wc -l`.

Three fresh-terminal runs: walk-abl 33 / 28 / 24 ms, walk-net 47 / 36 / 37 ms, zip 160 / 132 / 120 ms.
Counts identical every time.

### Matches "You'll see"? 

Yes for file count, elapsed time and archive entries — **but the direction of the timing is the
opposite of what the slide implies**. See deck corrections D4.

---

## 3. Demo 2 — running a process (slides 20–22)

### Runbook

**Prerequisites:** `/data` must exist (`sudo mkdir -p /data/in && sudo chown -R $USER /data`).
GNU `ls` exits **2** for a missing operand, which is the exit code the demo shows.

```bash
./env/run.sh 02-process/demo2.p
```

**Duration:** under 1 second. **Reset:** none.

### Exact output

```
== Demo 2: running a process ==
command: ls /data /nope

---------- ABL today: INPUT THROUGH ----------
-- INPUT THROUGH: stdout and stderr arrive mixed --
   ls: cannot access '/nope': No such file or directory
   /data:
   in
   readme.txt
   tree
  lines: 5
  OS-ERROR after INPUT THROUGH: 0    <- no exit code anywhere

-- KB 000145783 workaround: let the shell echo $? --
  exit code recovered from echo $?: 2

---------- .NET: System.Diagnostics.Process ----------
exit code: 2
stdout: 
/data:
in
readme.txt
tree
stderr: 
ls: cannot access '/nope': No such file or directory
```

**Matches "You'll see"?** Yes, exactly: `/data` listing on stdout, the `/nope` error on stderr,
exit code 2. Identical across three fresh-terminal runs.

Note how well the mixed-stream problem demonstrates itself: under `INPUT THROUGH` the **error line
arrives first**, before the directory listing, because the two streams are interleaved by the shell.

### Deadlock avoidance in run-net.p

stdout and stderr are separate OS pipes with fixed buffers. Reading one to the end while the child
fills the other deadlocks once the second buffer fills. `run-net.p` starts the stdout read as a
Task and reads stderr on the ABL thread, so both pipes drain at once:

```
ASSIGN oOutTask = oProc:StandardOutput:ReadToEndAsync().
ASSIGN cErr     = oProc:StandardError:ReadToEnd().
ASSIGN cOut     = oOutTask:Result.
```

`DEFINE VARIABLE oOutTask AS "System.Threading.Tasks.Task<CHARACTER>"` — **ABL generics over a
.NET generic type work**, and `:Result` returns an ABL CHARACTER. This avoids needing .NET events
delivered into the ABL session (`BeginOutputReadLine`), which is the untested area in 09-events.

### Slide 21 — the two KB claims, verified on 13.0

`./env/run.sh 02-process/kb-checks.p`

```
KB 000139689 - OS-ERROR after a failing OS-COMMAND
   OS-ERROR after 'ls /nope'      : 0
   OS-ERROR after 'exit 42'       : 0
   OS-ERROR after missing binary  : 0

KB 000180173 - trailing & returns immediately
   OS-COMMAND with & returned after: 1 ms
   flag file exists right away     : no
   same command WITHOUT & took     : 3003 ms
```

**Both confirmed.** `OS-ERROR` is 0 even when the binary does not exist. The `&` case needs the
whole command in a sub-shell — `OS-COMMAND SILENT VALUE("(sleep 3; touch flag) &")` — because a
bare trailing `&` binds only to the last command in the list.

---

## 4. Demo 3 — X.509 certificates (slides 23–25)

### Runbook

```bash
./03-security/make-certs.sh                 # throw-away CA + leaf certs, git-ignored
./env/run.sh 03-security/demo3.p -param ./03-security/certs
```

**Duration:** ~2 s (cert generation ~1 s). **Reset:** `rm -rf 03-security/certs` — nothing else is touched.
No real certificate or key is used or committed; `.gitignore` excludes `03-security/certs/`.

### Exact output

```
== Demo 3: X.509 certificates ==

---------- ABL today: sslc via OS-COMMAND ----------
sslc  subject   : CN=partner.example, O=PUG Challenge Demo
sslc  notAfter  : Feb 4 16:09:56 2029 GMT
sslc  as DATETIME: 02/04/2029 16:09:56.000
sslc  days left  : 824
sslc  valid      : yes

---------- .NET: X509Certificate2 + X509Chain ----------
-- partner.pem (signed by our CA) --
.NET  subject   : O=PUG Challenge Demo, CN=partner.example
.NET  issuer    : O=PUG Challenge Demo, CN=Demo Root CA
.NET  notAfter  : 02/04/2029 17:09:56.000
.NET  days left  : 824
.NET  valid      : yes

-- stranger.pem (signed by an unrelated CA) --
.NET  subject   : O=PUG Challenge Demo, CN=stranger.example
.NET  issuer    : O=PUG Challenge Demo, CN=Unrelated Root CA
.NET  notAfter  : 02/04/2029 17:09:56.000
.NET  days left  : 824
.NET  valid      : no
      reason     : PartialChain - unable to get local issuer certificate
```

**Matches "You'll see"?** Yes: subject, issuer, expiry, days left; `valid: yes` then `valid: no`
with a reason. Identical across three fresh-terminal runs.

With `expired.pem` the reason is `NotTimeValid - certificate has expired` and days left is
negative (`-2496`), which is a good second example if you have time on stage.

---

## 5. Changes the deck needs (P1 findings so far)

| # | Slide | Statement in the deck | What actually happens |
|---|---|---|---|
| D1 | 17 (note) | Recursion with the unnamed stream breaks | **False on 13.0.** See below. |
| D2 | 18 | Lists `Entries[i]:Length` on an Update-mode archive | **Throws.** Needs a second read-mode `Open`. |
| D3 | 14 | runtimeconfig shows net8.0 | Ships as **net6.0 / 6.0.0**; editing it is a required step |
| D4 | 19 | implies .NET is faster at walking files | **ABL is faster** (24 ms vs 37 ms / 10,000 files) |
| D5 | 24 | `ChainStatus:GetValue(i):Status` | Needs `CAST(..., X509ChainStatus)` |
| D6 | — | sslc needs proenv | **Not for x509/verify** on 13.0 Linux |

### D1 — slide 17 speaker note: recursion with the unnamed stream

`03-security`-style proof in `01-files/stream-recursion-test.p`: an internal procedure that recurses,
each level opening `INPUT FROM OS-DIR` on the **unnamed** stream, on a 4-level tree with 50 `.xml` files.

```
recursive, unnamed stream -> xml files found: 50
walk-abl   files: 50   ms: 0      (queue version, same tree)
walk-net   files: 50   ms: 10     (.NET version, same tree)
```

All three agree. It still returns 50 with `INPUT CLOSE` removed. OpenEdge 13.0 scopes the unnamed
input stream **per procedure invocation**, so the inner `INPUT FROM` does not clobber the outer one.

Suggested rewording: *"A work queue avoids unbounded recursion and is easier to reason about.
Recursion does work — the unnamed stream is scoped per procedure — but the queue keeps the
traversal explicit."* Do not claim it is broken; someone in the room has shipped it.

### D2 — slide 18 zip listing throws

As written, listing entry lengths while the archive is open in `ZipArchiveMode:Update`, after
adding an entry, raises:

```
System.InvalidOperationException: Length properties are unavailable once an entry
has been opened for writing.
```

Fix used in `01-files/zip-net.p`: `oZip:Dispose()` after `CreateEntryFromFile`, then
`ZipFile:Open(cZip, ZipArchiveMode:Read)` to list. Slide 18 needs that second `Open` or it crashes live.

Everything else on slide 18 is confirmed working: `CreateFromDirectory`, `ExtractToDirectory`,
`ZipFileExtensions:CreateEntryFromFile(oZip, ...)` called as a static method, and the indexer
**`oZip:Entries[i]` compiles and works**.

### D4 — the directory-walk timing

10,000 files, 3,400 of them `.xml`, median of three fresh runs: **walk-abl 24–33 ms,
walk-net 36–47 ms**. The ABL queue walker is consistently faster. `Directory:GetFiles` wins on
*lines of code*, not speed. The honest framing for slide 19 is "one line instead of twenty",
and to keep the speed argument for the workloads where ABL has no API at all.

### D5 — ChainStatus needs a cast

`oChain:ChainStatus:GetValue(i)` is typed `System.Object`, so the slide's direct member access fails:

```
Could not locate element 'Status' in class 'System.Object'. (12927)
```

Working form:

```
ASSIGN oStatus = CAST(oChain:ChainStatus:GetValue(i), X509ChainStatus).
MESSAGE oStatus:Status:ToString() "-" TRIM(oStatus:StatusInformation).
```

### D6 — "always invoke sslc with proenv"

On 13.0 Linux, `sslc` runs correctly from a **completely empty environment** (`env -i`) for
`version`, `x509 -noout -subject -enddate` and `verify -CAfile`:

```
$ env -i PATH=/usr/bin:/bin $DLC/bin/sslc version
OpenSSL 3.5.2 5 Aug 2025 (Library: OpenSSL 3.5.2 5 Aug 2025)
```

So there is **no error to record** for the "without proenv" case for these operations — the binary
resolves its own libraries. `proenv` sets `OPENSSL_CONF=$DLC/keys/policy/pscpki.cnf`, which may
matter for key generation or policy-dependent commands, but not for reading or verifying a
certificate. Soften the slide from "always" to "needed for policy-dependent commands".

### Smaller corrections

- **`aFiles[i]` does not compile** on a .NET array: *"aFiles is not an ABL array or an indexed
  property, therefore using a subscript is not valid. (13809)"*. The slide's `GetValue(i)` is right.
  `EXTENT()` on a .NET array returns **0** — do not use it. (Note `oZip:Entries[i]` *does* work,
  because `Entries` is an indexed property, not an array — worth knowing why they differ.)
- **`sslc` reports OpenSSL 3.5.2**, while the distro `openssl` is 3.5.5. If the deck names a
  version, use 3.5.2 for sslc.
- **`NotAfter` is local time, `sslc` prints GMT.** Same certificate shows `16:09:56 GMT` via sslc
  and `17:09:56` via `oCert:NotAfter` (CET). Days-left agrees (824). Worth one line so nobody
  thinks the two disagree.
- **`ProcessStartInfo:ArgumentList` works from ABL** and is the safer form — no quoting rules:
  `oInfo:ArgumentList:Add("/data").` Recommended over a single argument string on slide 20.
- **`USING System.Security.Cryptography.X509Certificates.* FROM ASSEMBLY`** (wildcard) compiles,
  which shortens the slide considerably.
- **`MESSAGE "valid:" oChain:Build(oCert)` compiles** and prints `yes` — the literal slide form is fine.
- **`zip -r` yields 27 entries where .NET yields 25** on the same tree, because `zip` stores
  directory entries and `CreateFromDirectory` does not. Mention it if both counts are on screen.
- **assemblies.xml needs only the simple name.** `<assembly name="System.IO.Compression.ZipFile"/>`
  — Version / Culture / PublicKeyToken are accepted but unnecessary.

