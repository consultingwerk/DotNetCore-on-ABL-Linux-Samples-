/* F: Process:Start and WaitForExit(5000) only - no OS-COMMAND / INPUT THROUGH at all */
DEFINE OUTPUT PARAMETER pcResult AS CHARACTER NO-UNDO.
DEFINE VARIABLE oP AS System.Diagnostics.Process NO-UNDO.
DEFINE VARIABLE lExited AS LOGICAL NO-UNDO.
oP = System.Diagnostics.Process:Start("/bin/true").
ETIME(TRUE).
lExited = oP:WaitForExit(5000).
pcResult = "WaitForExit(5000) returned " + STRING(lExited) + " after " + STRING(ETIME)
         + " ms; HasExited=" + STRING(oP:HasExited).
