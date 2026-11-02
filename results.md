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

---

## 6. P2 — facts that change slides

### 6.1 The shipped runtimeconfig (slide 14)

`$DLC/bin/Progress.clrbridge.netcore.runtimeconfig.json` as installed by OpenEdge 13.0 on Linux,
verbatim and unedited:

```json
{
  "runtimeOptions": {
    "tfm": "net6.0",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "6.0.0"
    }
  }
}
```

- **tfm: `net6.0`** — not net8.0.
- **No `Microsoft.WindowsDesktop.App`** entry (as expected on Linux).
- File is dated 24 Jul 2025 while the rest of `bin/` is 23 Jan 2026: it looks carried forward
  rather than refreshed for 13.0.

The original is preserved at `~/src/runtimeconfig.ORIGINAL-13.0.json`. For the demos it was replaced
with the same structure using `net8.0` / `8.0.0`. **Editing this file is a required install step**,
not an optional tweak — OpenEdge ships neither .NET nor a config pointing at a supported version.

Note the file is `root:root` but `$DLC/bin` is mode 0777 on this box, so the edit needed no `sudo`.
On a properly locked-down installation it would.

### 6.2 hello.p on Linux (slide 15)

```
OS:     Ubuntu 26.04.1 LTS
FW:     .NET 8.0.33
Arch:   X64
```

`ProcessArchitecture:ToString()` returns **`X64`**, confirming the slide. Windows output not
captured: there is no OpenEdge installation on the Windows side of this PC (only a Windows .NET),
and the brief forbids changing the Windows installation.

### 6.3 hello-net.p (slide 9) — what the compiler rejects

**Nothing.** Every line on slide 9 compiles and runs:

```
files in /data: 1
Hello Linux
list count: 2
```

Confirmed working: `Directory:GetFiles`, `NEW StringBuilder()`, the chained
`oSb:Append("Hello"):Append(" Linux")`, a variable declared
`AS "System.Collections.Generic.List<CHARACTER>"`, and `CATCH e AS System.Exception`.
The generic type name must be **quoted**, both in `DEFINE VARIABLE` and in `NEW`.

### 6.4 Missing -clrnetcore (slide 11 banner)

```
The -clrnetcore start-up parameter must be used to enable ABL access to .NET objects. (20829)
** Could not understand line 4. (196)
** Unknown Field or Variable name - RuntimeInformation. (201)
** Unable to run startup procedure .../hello.p. (492)
```

The banner is right, and error **20829** names the parameter explicitly.

### 6.5 Configured .NET version not installed

With the stock `net6.0` config and only .NET 8/10 present — i.e. exactly what an attendee hits if
they skip the runtimeconfig edit:

```
You must install or update .NET to run this application.

App: /Progress/OpenEdge130_64/bin/_progres
Architecture: x64
Framework: 'Microsoft.NETCore.App', version '6.0.0' (x64)
.NET location: /home/peter/.dotnet

The following frameworks were found:
  8.0.33 at [/home/peter/.dotnet/shared/Microsoft.NETCore.App]
  10.0.14 at [/home/peter/.dotnet/shared/Microsoft.NETCore.App]

Unable to load .NET. The runtimeconfig.json file contains a reference to a .NET framework
which is not available: .../Progress.clrbridge.netcore.runtimeconfig.json. (20825)
```

Error **20825**. The message helpfully lists what *is* installed.

### 6.6 Do framework assemblies need assemblies.xml entries?

**It depends on the assembly, and the entry is simpler than expected.**

Resolve with a **completely empty** `assemblies.xml` (they live in System.Runtime /
System.Private.CoreLib): `Directory`, `File`, `StringBuilder`, `RuntimeInformation`, `Math`,
`Convert`, `Encoding`, `List<T>`, `Task<T>`.

Need an entry — without one you get `Could not find class or interface <type>. (12886)`:

```xml
<assembly name="System.IO.Compression"/>
<assembly name="System.IO.Compression.ZipFile"/>
<assembly name="System.Diagnostics.Process"/>
<assembly name="System.Security.Cryptography"/>
<assembly name="System.Security.Cryptography.X509Certificates"/>
<assembly name="System.Text.RegularExpressions"/>
```

**The simple name is sufficient.** All three of these were tested and behave identically:

```xml
<assembly name="System.IO.Compression.ZipFile"/>
<assembly name="System.IO.Compression.ZipFile, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"/>
<assembly name="System.IO.Compression.ZipFile, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"/>
```

No `assemblies.xsd` is shipped anywhere in `$DLC`, despite the `xsi:noNamespaceSchemaLocation` reference.

### 6.7 OS-ERROR and exit codes

`OS-ERROR` is **0** after every failing `OS-COMMAND` tested — a non-zero exit, a missing path and a
missing binary alike (see §3). The only way to see the exit code is to have the shell report it
(KB 000145783):

```
INPUT THROUGH VALUE("ls /data /nope > /dev/null 2>&1; echo $?").
```

With `System.Diagnostics.Process` the exit code is simply `oProc:ExitCode` — **2** in the demo.

### 6.8 Is there a built-in zip/compression API in ABL 13.0?

**No.** Slide 18's premise holds. There is no ABL statement or system handle for zip or deflate;
`zip`/`unzip` via `OS-COMMAND` and `INPUT THROUGH` is the only route without .NET.

### 6.9 X.509 specifics

- **`NEW X509Certificate2(path)` loads a PEM file on Linux under .NET 8.** No conversion to PFX/DER
  needed. (In .NET 9+ this constructor is obsolete in favour of `X509CertificateLoader`; on .NET 8
  it is fine, which is another argument for staying on the certified 8.)
- **`NotAfter` arrives as an ABL DATETIME** and works directly in `INTERVAL(...)`:
  `INTERVAL(oCert:NotAfter, NOW, "days")` → `824`. It is **local time**; `sslc` prints GMT
  (`16:09:56 GMT` vs `17:09:56` CET for the same certificate).
- **`MESSAGE "valid:" oChain:Build(oCert)` compiles** and prints `yes`.
- **ChainStatus needs a cast** — see D5.
- Exact `ChainStatus` output for `stranger.pem`:
  `PartialChain - unable to get local issuer certificate`
  and for `expired.pem`: `NotTimeValid - certificate has expired`.
- **`sslc version` on 13.0: `OpenSSL 3.5.2 5 Aug 2025`** (the distro `openssl` is 3.5.5).

### 6.10 Span-based overloads (pitfalls slide) — confirmed

```
oRsa:ImportFromPem(STRING(cPem)).
->
Could not locate method 'ImportFromPem' with matching signature
in class 'System.Security.Cryptography.RSA'. (14457)
```

`ImportFromPem` takes `ReadOnlySpan<char>`, and ABL cannot bind to it. **Error 14457.**

This is specifically about spans, not about the class: non-span members of the very same `RSA`
instance work fine (`oRsa:KeySize` → 2048, `oRsa:ExportParameters(FALSE)` → OK).

Workaround: put the span-using call in a small C# facade and expose an ordinary `string`/`byte[]`
signature to ABL — which is exactly the case for 08-facade.

### 6.11 MESSAGE-DIGEST and ENCRYPT algorithms in 13.0 (slide 23)

Tested, not taken from documentation:

| MESSAGE-DIGEST | Result |
|---|---|
| CRC-32 | **not supported** |
| MD5 | OK (16 bytes) |
| SHA-1 | OK (20 bytes) |
| SHA-256 | OK (32 bytes) |
| **SHA-384** | **not supported** |
| SHA-512 | OK (64 bytes) |
| HMAC-SHA-1 / -256 / -512 | OK with the 3-argument form (data + key) |

| SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM | Result |
|---|---|
| DES, DES3, RC4 | **not supported** |
| AES_CBC_128 / 192 / 256 | OK |
| AES_ECB_128 / 256 | OK |
| AES_GCM_256 | OK |

Slide 23's list (SHA-256, SHA-512, HMAC, AES) is accurate. Two things worth adding:

- **SHA-384 is missing from ABL but present in .NET** — a crisp one-line example of the gap.
  `SHA384:Create():ComputeHash(...)` on "abc" returns 48 bytes,
  `CB00753F45A35E8B…` (matches the published SHA-384 test vector).
- DES/DES3/RC4 are gone, which is good news and worth saying out loud to a banking audience.

### 6.12 -casesensitiveclasses (pitfalls slide)

Not set in `$DLC/startup.pf`, so the installed default applies.

**On Linux the question is largely moot, and the pitfall is worse than the slide suggests.** A class
reference with the wrong capitalisation fails **regardless of the setting**:

```
DEFINE VARIABLE o AS CLASS fileprocessor NO-UNDO.   /* file is FileProcessor.cls */

default                     -> Could not find class or interface fileprocessor. (12886)
-casesensitiveclasses 1     -> Could not find class or interface fileprocessor. (12886)
-casesensitiveclasses 0     -> Could not find class or interface fileprocessor. (12886)
```

The `.cls` lookup goes through a case-sensitive filesystem, so `-casesensitiveclasses 0` cannot
rescue it. The same applies to .NET type names: `USING system.io.directory FROM ASSEMBLY` fails
with 12886 under every setting.

**This is the single most likely thing to bite a developer moving code from Windows to Linux**, and
it is not a startup-parameter problem — it is a filesystem problem. Recommended slide wording:
*"On Linux, class and type names must match exactly. `-casesensitiveclasses` does not change this:
the filesystem decides."*

