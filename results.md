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

## 5. Changes the deck needs

| # | Slide | Statement in the deck | What actually happens |
|---|---|---|---|
| D1 | 17 (note) | Recursion with the unnamed stream breaks | **False on 13.0.** See below. |
| D2 | 18 | Lists `Entries[i]:Length` on an Update-mode archive | **Throws.** Needs a second read-mode `Open`. |
| D3 | 14 | runtimeconfig shows net8.0 | Ships as **net6.0 / 6.0.0**; editing it is a required step |
| D4 | 19 | implies .NET is faster at walking files | **ABL is faster** (24 ms vs 37 ms / 10,000 files) |
| D5 | 24 | `ChainStatus:GetValue(i):Status` | Needs `CAST(..., X509ChainStatus)` |
| D6 | — | sslc needs proenv | **Not for x509/verify** on 13.0 Linux |
| D7 | Pitfalls | "Events: test first" | Tested: background-thread events **do not reach ABL** (15740), §8.2 |
| D8 | Pitfalls | (new) | Regex in ABL strings: `{n}` and `\d` are silently rewritten, differently on Linux and Windows, §8.1 |
| D9 | Pitfalls | `-casesensitiveclasses` | On Linux the filesystem decides; the parameter does not help, §6.12 |
| D10 | Production / 20–22 | `Process` gives you an exit code | **Not in a PASOE agent**: `WaitForExit` never returns, children stay zombies, §8.4 |
| D11 | Production | (new) | `Process:Start` avoids the KB 000207833 slowdown: flat vs ~6× for `OS-COMMAND` at 2 GB, §8.4 |
| D12 | Production | (new) | One CLR per agent, but assemblies load per ABL session; framework state shared, §8.4 |
| D13 | Production | (new) | PASOE 13.0 does not start on dash-based distros without a `setenv.sh` fix, §8.4 |
| D14 | 29 "Why Measure Again?" | Haversine 2023: 2.4 s → 1.9 s for 500,000 | Those were **10,000** iterations; same code now 550 ms, ~3.5× faster, §7.6 |

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

**Not in OpenEdge itself** — there is no ABL statement, system handle or shipped class for zip or
deflate in 13.0. So slide 18's premise holds *for the product*.

**But "ABL cannot do zip" is too strong, and the deck must not say it.** The SmartComponent Library
has a **pure ABL** implementation in `Consultingwerk/Framework/Compression/`:

```
Crc32.cls   Deflater.cls   Inflater.cls
ZipArchiveReader.cls   ZipArchiveWriter.cls   ZipEntry.cls   ZipFormat.cls
ZipCompressionMethodEnum.cls   Exceptions/...
```

(SCL-6170, Mike Fechner, created 28.10.2026 — new enough that it may post-date the deck draft.)

Its own class comment is the most useful thing here, because it makes the talk's argument
independently:

> *"Pure ABL implementation without .NET, so it can be used on every platform (including PASOE on
> Linux). […] Being implemented in ABL, the writer is considerably slower than native ZIP
> implementations. Applications that need performance integrate a platform specific solution
> (e.g. System.IO.Compression in the GUI client, OS tools or native libraries on the server)."*

It also documents real limits: intended for small files (a few MB), no Zip64, so no archives over
4 GB and no more than 65,535 entries.

**Recommended reframing of slide 18.** Rather than "ABL has no zip", say: zip in ABL means either
shelling out to `zip`/`unzip` (no API, parse the output) or a pure-ABL implementation such as the
SmartComponent Library's — which works everywhere but is explicitly documented as slower and
capped at small archives. `System.IO.Compression` gives you a maintained, Zip64-capable,
native-speed implementation for free. Saying this *strengthens* the case and pre-empts the
obvious objection from the room — especially given the implementation is Consultingwerk's own.

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

---

## 7. P3 — the benchmarks (slides 28–30)

Method as written in `05-benchmarks/README.md`: one warm-up run, then 5 timed runs, median
reported. Same machine, nothing else running, test tree `/data/tree` (10,000 files) on the Linux
filesystem — never `/mnt/c`. Workloads and iteration counts unchanged from the draft.
**Two bugs had to be fixed first — see §7.4; one of them was measuring the wrong thing entirely.**

### 7.1 The Numbers (ms, median of 5)

| Workload | ABL | .NET 8 | .NET 10 ¹ |
|---|---:|---:|---:|
| Guid.Parse, 500,000 calls | – | 1668 | 1292 |
| Distance (Haversine), 500,000 calls | – | 29818 ² | 25630 |
| SHA-256, 100,000 strings | **56** | 1161 | 915 |
| Directory walk, 10,000 files | 23 | **4** | **5** |
| 100 process starts | 221 | 224 | 209 |
| Zip, 10,000 files | shell: **130** · SCL pure ABL: 97060 ³ | 171 | 166 |
| First .NET call (CLR start) | – | ~120–215 ⁴ | ~190 ⁴ |

¹ **.NET 10: not certified for OpenEdge 13.0.** Experiment only. Runtimeconfig backed up,
switched to `net10.0`, restored to `net8.0` afterwards (verified: `hello.p` reports `.NET 8.0.33`).
² Safe to use. The apparent "15× slower than 2023" was a mistake in the draft README: the 2023
run was 10,000 iterations, not 500,000. Per iteration it is ~3.5× *faster* now — see §7.6.
³ Median of 5. Run 4 is invalid — the PC went to sleep during it (54,801,453 ms ≈ 15 h). The four
valid runs were 96,560 / 96,897 / 97,060 / 105,815 ms; the median is unaffected by the outlier.
⁴ Wall-clock of a whole session minus a session that makes no .NET call. Depends heavily on
machine state: .NET 8 measured 130 ms one evening and 214 ms the next morning on the same box.
Same-day comparison (03.11.): .NET 8 235 − 21 = **214 ms**, .NET 10 213 − 23 = **190 ms**.
Treat as "0.1–0.2 s, once per session"; .NET 8 and 10 do not differ meaningfully.

**The ABL rows are the control.** The .NET 8 suite ran on the evening of 02.11., the .NET 10
suite on the morning of 03.11. The ABL-side numbers barely moved between them (SHA-256 56 → 57,
dirwalk 23 → 23, shell zip 130 → 138, process 221 → 239), so the .NET 8 vs .NET 10 differences
are not machine drift.

### What .NET 10 changes

- **Bridge-heavy workloads get ~20 % faster**: Guid.Parse −23 %, SHA-256 −21 %, Haversine −14 %.
  The per-call cost of crossing into .NET drops; the CLR itself did not get slower to start.
- **Bulk workloads do not change**: dirwalk, process, zip are within noise. They spend their time
  in the OS, not in the bridge.
- **None of it changes a single conclusion.** ABL still wins SHA-256 by 16×, the shell still
  matches .NET on zip, and process starts are still a dead heat. That is the useful message for a
  conservative audience: *stay on certified .NET 8; 10 is faster but not different*.

Check values, which prove both sides did the same work:

| Workload | Check value | ABL | .NET |
|---|---|:-:|:-:|
| sha256 | `12daeeea9fc134ad4ecd9ba331035035158bbbdfbca5e84d6c5c7ca7737ed253` | ✔ | ✔ |
| dirwalk | `10000` files | ✔ | ✔ |
| process | `100` successful starts | ✔ | ✔ |
| zip | `10000` entries (all three variants) | ✔ | ✔ |
| guid-parse | `5f8e2c1a-3b4d-4e6f-8a9b-0c1d2e3f4a5b` | – | ✔ |
| haversine | `5747` km | – | ✔ |

### 7.2 One line per row

- **Guid.Parse, 1668 ms / 500,000** — ~3.3 µs per call. This is almost entirely *bridge* cost, not
  parsing: it is the price of crossing from ABL into .NET half a million times. ABL has no GUID
  parsing to compare against, so read it as "what a tiny .NET call costs", not as a win.
- **Haversine, 29818 ms / 500,000** — ~60 µs per distance, of which ~41 µs is 13 bridge
  crossings at ~3.2 µs each and ~15 µs is ABL function-call and DECIMAL arithmetic (§7.6). ABL
  has no trigonometry, so there is no ABL column. The same formula as **one** call into a C#
  method takes 3.9 µs — 14× faster.
- **SHA-256, ABL 56 ms vs .NET 1161 ms — ABL wins by 20×.** `MESSAGE-DIGEST` is native ABL;
  the .NET path crosses the bridge twice per string (encode, hash) — 200,000 crossings.
  **If you only show one number that complicates the story, show this one.**
- **Directory walk, ABL 23 ms vs .NET 4 ms — .NET wins by ~6×.** One `Directory:GetFiles` call
  returns 10,000 paths across a single bridge crossing; the ABL queue walker makes an `OS-DIR`
  round trip per directory.
- **100 process starts, 221 vs 224 ms — a dead heat.** Process creation is dominated by the OS
  `fork`/`exec`, not by who asked for it. The .NET win here is not speed, it is *control*:
  separated stdout/stderr, a real exit code and a timeout (demo 2).
- **Zip, shell 130 ms vs .NET 171 ms vs SCL pure ABL ~95 s.** See §7.3 — this row needs care.
- **CLR start ~130 ms, paid once per session.** See §7.5.

### 7.3 The zip row, honestly

Three implementations, same tree, same check value (10,000 entries):

| Variant | 10,000 files | 500 files / 2 MB |
|---|---:|---:|
| `zip` via OS-COMMAND | 130 ms | 42 ms |
| `System.IO.Compression` | 171 ms | 27 ms |
| **SCL `ZipArchiveWriter` (pure ABL)** | **~95,400 ms** | **~31,000 ms** |

- **The shell is not slower than .NET.** On the big tree `zip` actually beats
  `ZipFile:CreateFromDirectory`. So "zip is faster in .NET" is **not** a claim the deck can make.
  The .NET argument for zip is *API*, not speed: no shell, no output parsing, no quoting, a real
  object model, Zip64, and errors as exceptions instead of exit codes you cannot see (§3).
- **The pure-ABL implementation is ~560× slower than .NET on the large tree and ~1,100× slower on
  the small one.** The small tree is 2 MB of base64 random data, i.e. ~65 KB/s for SCL against
  ~74 MB/s for .NET. This is *expected and fair*: ABL has no byte-level primitives, so a Deflate
  written in ABL pays for every byte in interpreted code.
- **This is inside SCL's documented envelope for the 500-file case** (a few MB), so it is not a
  strawman. SCL's own class comment predicts it: *"the writer is considerably slower than native
  ZIP implementations. Applications that need performance integrate a platform specific
  solution (e.g. System.IO.Compression …)."*
- **Fair framing for the slide:** SCL's writer exists for *portability* — it runs anywhere,
  including PASOE on Linux with no .NET at all — not for throughput. The honest headline is
  "you can do zip in pure ABL, and for configuration exports and attachments you should; for
  10,000 files you want the native implementation."

### 7.4 What had to be fixed before any number was trustworthy

The benchmark code had never been compiled. Full detail in `05-benchmarks/README.md`; the short
version, because one of these is a methodology story worth telling on stage:

1. **`run-all.p`: `Check` is a reserved word.** `field Check as character` does not compile
   (errors 247 / 267 / 725). Renamed to `CheckValue`.

2. **`wl-zip-shell.p`: `SUBSTITUTE` collapsed `&&` into a single `&`.**

   ```
   substitute("cd &1 && zip -q -r &2 .", quoter(pcArg), quoter(cZip))
   ```

   `SUBSTITUTE` treats `&` as its placeholder marker, so the command executed was:

   ```
   cd "/data/tree" & zip -q -r "/tmp/bench-shell.zip" .
   ```

   That **backgrounds the `cd`** and runs `zip` in the *current* directory. The workload archived
   the `05-benchmarks` folder — 19 files — and compared it against the .NET side's 10,000.

   **The check values caught it.** The row read `19` against `10000`, which is impossible to miss.
   Without them the slide would have carried "ABL zip is ~20× faster than .NET", measured on 19
   files against 10,000, and it would have looked entirely plausible.

   Fixed with plain concatenation. **Never build a shell command containing `&&` with
   `SUBSTITUTE`.** This is worth a line on "How We'll Measure": the check values earned their
   keep on the first real run.

### 7.5 CLR start-up, measured properly

The draft's `clr-first-call.p` reports 4–7 ms for the first `NEW System.Object()`, which is
misleading: by the time it runs, compiling a program containing `USING … FROM ASSEMBLY` has
already loaded the CLR. The cost is real but is paid earlier in the session.

Measured instead as **total session wall-clock**, 5 runs each, `date +%s%N` around `_progres`:

| Session | Mean wall-clock |
|---|---:|
| plain ABL, no `-clrnetcore` | 13 ms |
| `-clrnetcore`, no .NET call made | **13 ms** |
| `-clrnetcore` + one `NEW System.Object()` | **143 ms** |
| `-clrnetcore -preloadCLR` + one `NEW System.Object()` | 132 ms |

(Evening of 02.11. Repeated the next morning: 21 / 235 / 214 ms for .NET 8, 23 / 213 / 231 ms
for .NET 10. Absolute values move with machine state; the pattern does not.)

Three conclusions, all slide-worthy:

- **`-clrnetcore` costs nothing on its own.** A session that never touches .NET is as fast as one
  started without the flag. The CLR is loaded lazily, on first use. You can put `-clrnetcore` in
  a shared startup file without taxing sessions that do not use it.
- **The first .NET call costs ~130 ms**, once per session. For a batch job or a PASOE agent that
  is irrelevant; for a short-lived script invoked in a loop it dominates everything else.
- **`-preloadCLR` barely helps in a batch session** (132 vs 143 ms, within noise of each other).
  It moves the cost to session start rather than removing it. If the deck implies `-preloadCLR` is
  a fix for CLR start-up cost, soften that.


### 7.6 The Haversine row, explained

The draft README compared the 500,000-iteration result with Mike Fechner's 2023 figures
(2.4 s → 1.9 s) and it looked ~15× *slower*. The 2023 deck (`2023 .Net Core/.NET Core with
OpenEdge.pptx`, slides 54 and 71) shows the actual 2023 code and run:

```
DO i = 1 TO 10000:
   ASSIGN deDistance = getDistanceFromLatLonInKm (50.9692156, 7.0129187,   /* Consultingwerk HQ */
                                                  42.4848118, -71.1934179 /* Progress Software HQ */).
END.
MESSAGE ETIME .
```

```
_progres -b -p distance.p                  -> 2402   (.NET Framework 4.8)
_progres -b -p distance.p -clrnetcore      -> 1921   (.NET 6)
```

**10,000 iterations, not 500,000.** The function is the same shape as `wl-haversine.p`
(13 .NET calls per distance). Same loop, 10,000 iterations, on this box
(`05-benchmarks/haversine-analysis.p`, median of 5):

| | 10,000 distances | per distance |
|---|---:|---:|
| 2023: OE 12.7, .NET Framework 4.8, Windows | 2402 ms | 240 µs |
| 2023: OE 12.7, .NET 6, Windows | 1921 ms | 192 µs |
| 2026: OE 13.0, .NET 8, Linux (WSL) | **550 ms** | **55 µs** |

About **3.5× faster** — consistent with Guid.Parse, which went from ~5 s to 1.7 s for 500,000
calls (~3×). Machine, OS and OpenEdge release all changed, so present it as "the same code three
years later", not as a pure .NET 6 → 8 gain.

**Where the 55 µs go** (100,000 distances, median of 5):

| Variant | µs / distance |
|---|---:|
| V1 as benchmarked — 13 .NET calls | 56.1 |
| V2 `Math:PI` read once — 9 .NET calls | 43.1 |
| V3 identical ABL code, no .NET (stand-ins) | 14.8 |
| V4 one call into `Demo.Interop.Geo.DistanceKm` (C#) | **3.9** |

- One bridge crossing costs **~3.2 µs**: (56.1 − 14.8) / 13 from V1/V3, 13 µs / 4 calls from V1/V2,
  and 3.3 µs per call from Guid.Parse. Three independent measurements agree.
- **The bridge, not the maths, is the cost.** 75 % of V1 is crossing into .NET.
- **Cross once, not thirteen times:** moving the whole formula into a C# method is **14× faster**
  than calling `System.Math` from ABL, and even ~4× faster than the ABL function calls alone (V3).
  Same check value (5747 km).

Slide line: *"A .NET call from ABL costs ~3 µs. Call .NET for a result, not for every step."*

---

## 8. P4 — nice to have

### 8.1 04-more — regex, Haversine, time zones

```bash
./env/run.sh 04-more/regex.p
./env/run.sh 04-more/haversine.p
./env/run.sh 04-more/timezone.p
```

```
IBAN looks valid : yes
date   : 2026-11-04
time   : 15:00:12
level  : ERROR
agent  : 7

Amsterdam -> Manchester: 494.6 km

zone         : (UTC+01:00) Central European Time (Amsterdam)
UTC 12:00 in January -> 01/15/2026 13:00:00.000
UTC 12:00 in July    -> 07/15/2026 14:00:00.000
ABL TIMEZONE (fixed) : 60
```

All correct: 494.6 km is the real great-circle distance, and `TimeZoneInfo` applies daylight
saving (+1 h in January, +2 h in July) where ABL only knows a fixed offset of 60 minutes.
`FindSystemTimeZoneById("Europe/Amsterdam")` needs `tzdata` on the box (present).

**New pitfall found here: regex patterns in ABL string literals are silently rewritten.**

```
MESSAGE "^[A-Z]{2}[0-9]{2}x".        ->  ^[A-Z][0-9]x          (no error)
MESSAGE "(\d{4})\w+".                ->  (d)w+                 (no error, Linux only)
"...([A-Z0-9]?){0,16}$"              ->  error 21104: "0,16" included ... was not found
```

- `{n}` is an include-argument reference to the ABL preprocessor, so `{2}` becomes an empty string
  even inside a string literal. Escape as `~{2~}`.
- `\` is an escape character in ABL strings **on UNIX but not on Windows**, so `\d` arrives as `d`.
  Write `\\d`.
- So the same source line hands .NET a **different regex on Linux than on Windows**, with no
  compile error and no runtime error — the match simply fails or matches the wrong thing.
  Working form: `"(\\d~{4~})\\w+"`.

### 8.2 09-events — are .NET events delivered on Linux?

**No, not for the events tested.** Both events fire, but the bridge refuses to call the ABL handler:

```
-- FileSystemWatcher:Created --
You are trying to use a multi-threaded .NET object in a way that is not supported.
The ABL cannot be called on a thread other than the main thread. (15740)
   at Progress.ClrBridge.BrgClrToPro.IsSessionThreadId(Boolean throwException)
   at Progress.ClrBridge.BrgClrToPro.HandleEvent(...)
   at SystemIOFileSystemWatcherCreatedReceiver.OnCreated(Object, FileSystemEventArgs)
   at System.IO.FileSystemWatcher.RunningInstance.ProcessEvents()
   handler called: no  after 21 polls
-- Process:Exited --
... (15740) ...
   at System.Diagnostics.Process.RaiseOnExited()
   at System.Threading.PortableThreadPool.WorkerThread.WorkerThreadStart()
   handler called: no  after 41 polls
   process HasExited: yes
```

| Main thread waits with | Handler runs? | Error shown? |
|---|---|---|
| `PROCESS EVENTS` + `PAUSE 0.1` loop (`events-test.p`) | no | yes, 15740 |
| `WAIT-FOR "U1" OF THIS-PROCEDURE PAUSE 2` (`events-waitfor.p`) | no | **no — silent** (3 of 3 runs) |

Both `FileSystemWatcher` and `Process.Exited` raise their events on a .NET worker thread, and the
bridge only calls ABL on the session's main thread. Nothing the main thread does changes that.
The same applies by construction to `Process.OutputDataReceived` (`BeginOutputReadLine`),
`System.Threading.Timer` and async callbacks.

Note the handler must be subscribed by **name as a string** for an internal procedure:
`oWatcher:Created:Subscribe("OnFileCreated")`. Unquoted gives error 201.

**For the Pitfalls slide** ("Events: test first"): *events raised on a .NET background thread do
not reach ABL — error 15740, or nothing at all under WAIT-FOR. Poll instead (`HasExited`,
`WaitForExit(ms)`), or use a Task and read `:Result` on the main thread.* This is why
`run-net.p` drains stdout with `ReadToEndAsync()` + `:Result` rather than `BeginOutputReadLine`.

### 8.3 08-facade — a C# library called from ABL

`08-facade/Demo.Interop` (net8.0): two static methods, ~40 lines.

- `Certs.Check(string certPath, string caPath)` → JSON with subject, issuer, notAfterUtc,
  daysLeft, valid, reasons.
- `Certs.RsaKeySizeFromPem(string pem)` → wraps the Span-only `RSA.ImportFromPem`.

```bash
cd 08-facade/Demo.Interop && dotnet build -c Release      # needs the .NET 8 SDK (8.0.427 used)
cp bin/Release/net8.0/Demo.Interop.dll ../../assemblies/
./env/run.sh 08-facade/check-cert-facade.p -param "03-security/certs/partner.pem,03-security/certs/ca.pem"
```

```
subject : O=PUG Challenge Demo, CN=partner.example
valid   : yes
raw JSON:
{"subject":"O=PUG Challenge Demo, CN=partner.example","issuer":"O=PUG Challenge Demo, CN=Demo Root CA","notAfterUtc":"2029-02-04T16:09:56.0000000Z","daysLeft":824,"valid":true,"reasons":[]}
RSA key size via facade (ImportFromPem): 2048
```

And for `stranger.pem`: `valid : no`, `"reasons":["PartialChain - unable to get local issuer certificate"]`.

Registration is one line in `assemblies.xml` with the DLL in the same folder:
`<assembly name="Demo.Interop"/>`. Build: 2 s, 0 warnings.

Speaker-note material: the facade removes every ABL-side wrinkle found in this project at once —
the `ChainStatus` cast (D5), the Span overload (14457), the GMT/local-time mismatch (it returns
UTC) — and leaves ABL with one call and a `JsonObject`. The cost is a build step and a DLL to
deploy.

### 8.4 06-pasoe — .NET in a PASOE agent

Full setup steps, all raw output and the test programs: `06-pasoe/README.md`. One instance
(`~/pasoe/demo`), one agent, APSV transport, created and run as a normal user.

**Setup findings (each cost time; all slide- or speaker-note-worthy):**

- **`agentStartupParam` belongs in `[AppServer.SessMgr.<instance>]`**, set with `oeprop.sh`:
  ```ini
  [AppServer.SessMgr.demo]
      agentStartupParam=-T "${catalina.base}/temp" -clrnetcore -assemblies /home/peter/src/DotNetCore-on-ABL-Linux-Samples-/assemblies
  ```
- **Without `DOTNET_ROOT` in the agent's environment** the client gets error **20825**, which
  blames the runtimeconfig file although the file is correct. The batch client's extra .NET message
  listing the frameworks it found does not appear under PASOE. Fix: `bin/dotnet_setenv.sh` in the
  instance (every `*_setenv.sh` there is sourced at start-up).
- **PASOE 13.0 does not start out of the box where `/bin/sh` is dash (Ubuntu, Debian):**
  `setenv.sh: Bad substitution`. `$DLC/servers/pasoe/bin/setenv.sh` is a bash script sourced by the
  `#!/bin/sh` `catalina.sh`; line 202 uses `${_trustfile:0:1}`. Fixed by an instance-local
  `setenv.sh` with POSIX syntax; `$DLC` untouched. (Certified Linux distributions are RHEL-family,
  where `/bin/sh` is bash — which is presumably why this has not surfaced.)
- New instances have **all transports disabled** (`adapterEnabled=0`).
- Non-root instance creation needs `PSC_AS_INSTANCE_DIR` and `CATALINA_TMPDIR`, because `pasman`
  otherwise writes into `$DLC/servers/pasoe`.

**Does one agent share one CLR across sessions? Yes for the CLR, no for your assemblies.**

```
connection 1 : session 6  AppDomain id 1  ALC 'AS-6'
connection 2 : session 9  AppDomain id 1  ALC 'AS-9'
connection 3 : session 4  AppDomain id 1  ALC 'AS-4'
```

One CLR and AppDomain per agent process, but **one AssemblyLoadContext per ABL session**. A static
in our own assembly counted 1, 2 in each new session (and 7, 8 in a session that had served six
earlier requests) — the same per-session behaviour as the ABL static used as control. Framework
state *is* shared: `System.AppContext` data written in session 4 was read in session 9.
Slide wording: *"One CLR per agent. Your assemblies load per session — a .NET static is no more
shared than an ABL static. Framework state is shared by every session of the agent."*

**Is `Process:Start` from an agent spared the KB 000207833 slowdown? Yes — but it has a worse problem.**

100 × `/bin/echo`, agent grown by touching a MEMPTR, 3 runs per size:

| Agent RSS | `OS-COMMAND` | `Process:Start` + `ReadToEnd` |
|---:|---:|---:|
| ~75 MB | 401 / 427 / 438 ms | 181 / 192 / 180 ms |
| ~1.1 GB | 1503 / 1451 / 1516 ms | 161 / 164 / 169 ms |
| ~2.1 GB | 2460 / 2697 / 2585 ms | 183 / 229 / 184 ms |

KB 000207833 confirmed: `OS-COMMAND` gets ~6× slower at 2 GB; `Process:Start` stays flat.

**But in a PASOE agent, .NET never sees a child process exit.** One request per freshly started
agent, 30 s limit:

| Test | PASOE agent | Batch client |
|---|---|---|
| `OS-COMMAND` ×5, no .NET | 9 ms | – |
| touch `Process` class, then `OS-COMMAND` ×5 | 14 ms | – |
| `Process:Start` + `WaitForExit()`, then `OS-COMMAND` | **hangs**, child `[true] <defunct>` | 14 ms |
| touch `Process`, then `INPUT THROUGH` | 2 ms | – |
| `Process:Start` + `WaitForExit()`, then `INPUT THROUGH` | **hangs**, zombie | 2 ms |
| `Process:Start` + `WaitForExit(5000)` only | `returned no after 5003 ms; HasExited=no`, zombie | – |

- `WaitForExit()` never returns; `WaitForExit(ms)` always times out; `HasExited` stays false; no
  exit code. The same code works in a batch client.
- `OS-COMMAND` and `INPUT THROUGH` are not affected.
- A request stuck in `WaitForExit()` makes the agent **ignore `tcman.sh stop`** (SIGKILL needed).
- Every child stays a **zombie** until the agent stops (900 after the timing runs; 0 after stop).
  Zombies count against the per-user process limit (63,057 here) — an agent that started ~63,000
  children without a restart would leave its user unable to start processes (inferred, not tested).
- Supporting observation, not a proven cause: 11 of the agent's 12 threads block `SIGCHLD`.
- What does work: redirect stdout and `ReadToEnd()` (EOF = child exited); that is how the timing
  above was taken. You get the output, but not the exit code.

**Consequence for the talk:** demo 2's `run-net.p` (`WaitForExit(5000)`, `Kill()`, `ExitCode`)
works in the batch client on stage but **would not work in a PASOE agent**. The exit code — the
main advertised win of `System.Diagnostics.Process` over `OS-COMMAND` — is exactly what an agent
cannot get. Production slide: *"In PASOE, use `Process` for speed and stream capture, not for
exit codes — and restart agents to clear zombies. Test this on your release before relying on
it."*

---

## 9. Open problems

1. **Why .NET cannot see child exits in a PASOE agent** (§8.4). Behaviour reproduced on fresh
   agents; cause not proven (SIGCHLD blocked on 11 of 12 agent threads is the lead). Worth a
   Progress support case before the talk mentions it as a defect — and worth checking on a
   certified RHEL-family system, since this box is Ubuntu.
2. **Why there is no 15740 message under `WAIT-FOR … PAUSE`** (§8.2) — observed 3/3, not explained.
3. **Ubuntu 26.04 is not on the OpenEdge 13.0 Platform Compatibility Guide** (not checked against
   the guide itself). All numbers come from an uncertified distribution.
4. **Screenshots are SVG, not PNG** — no ImageMagick or PIL on the box.
