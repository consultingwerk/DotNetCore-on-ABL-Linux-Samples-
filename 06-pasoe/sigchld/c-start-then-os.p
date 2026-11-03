/* C: one Process:Start, then OS-COMMAND */
DEFINE OUTPUT PARAMETER pcResult AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE oP AS System.Diagnostics.Process NO-UNDO.
oP = System.Diagnostics.Process:Start("/bin/true").
oP:WaitForExit().
ETIME(TRUE).
DO i = 1 TO 5: OS-COMMAND SILENT VALUE("/bin/true"). END.
pcResult = "Process:Start exit " + STRING(oP:ExitCode) + "; 5 x OS-COMMAND returned after " + STRING(ETIME) + " ms".
