/*------------------------------------------------------------------------
    File        : wl-sha256-net.p
    Purpose     : Workload "sha256", .NET side: SHA256.ComputeHash over n strings.
                  Two bridge calls per string (GetBytes, ComputeHash).
    Notes       : DRAFT, not compiled yet. Check value must match
                  wl-sha256-abl.p (case-insensitive).
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.Security.Cryptography.* from assembly.
using System.Text.* from assembly.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable oSha  as SHA256           no-undo.
define variable oHash as "System.Byte[]"  no-undo.
define variable i     as integer          no-undo.

oSha = SHA256:Create().

do i = 1 to piIterations:
    oHash = oSha:ComputeHash(Encoding:UTF8:GetBytes("PUG Challenge 2026 " + string(i))).
end.

pcCheck = lc(System.Convert:ToHexString(oHash)).

finally:
    if valid-object(oSha) then
        oSha:Dispose().
end finally.
