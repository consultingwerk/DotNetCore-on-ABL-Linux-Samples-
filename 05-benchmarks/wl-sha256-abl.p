/*------------------------------------------------------------------------
    File        : wl-sha256-abl.p
    Purpose     : Workload "sha256", ABL side: MESSAGE-DIGEST over n strings.
    Notes       : DRAFT, not compiled yet. Check value = hex hash of the last
                  string; must match wl-sha256-net.p (case-insensitive).
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable rHash as raw     no-undo.
define variable i     as integer no-undo.

do i = 1 to piIterations:
    rHash = message-digest("SHA-256", "PUG Challenge 2026 " + string(i)).
end.

pcCheck = lc(string(hex-encode(rHash))).
