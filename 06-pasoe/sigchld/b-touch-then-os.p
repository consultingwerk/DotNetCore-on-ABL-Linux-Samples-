/* B: touch System.Diagnostics.Process (no child started), then OS-COMMAND */
DEFINE OUTPUT PARAMETER pcResult AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE iMB AS INT64 NO-UNDO.
iMB = System.Diagnostics.Process:GetCurrentProcess():WorkingSet64 / 1048576.
ETIME(TRUE).
DO i = 1 TO 5: OS-COMMAND SILENT VALUE("/bin/true"). END.
pcResult = "touched Process (" + STRING(iMB) + " MB); 5 x OS-COMMAND returned after " + STRING(ETIME) + " ms".
