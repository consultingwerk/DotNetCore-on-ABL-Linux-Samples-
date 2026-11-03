/* E: one Process:Start, then INPUT THROUGH */
DEFINE OUTPUT PARAMETER pcResult AS CHARACTER NO-UNDO.
DEFINE VARIABLE c AS CHARACTER NO-UNDO.
DEFINE VARIABLE oP AS System.Diagnostics.Process NO-UNDO.
oP = System.Diagnostics.Process:Start("/bin/true").
oP:WaitForExit().
ETIME(TRUE).
INPUT THROUGH VALUE("echo hello").
IMPORT UNFORMATTED c.
INPUT CLOSE.
pcResult = "Process:Start, then INPUT THROUGH read '" + c + "' after " + STRING(ETIME) + " ms".
