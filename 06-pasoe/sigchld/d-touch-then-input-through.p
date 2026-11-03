/* D: touch System.Diagnostics.Process, then INPUT THROUGH */
DEFINE OUTPUT PARAMETER pcResult AS CHARACTER NO-UNDO.
DEFINE VARIABLE c AS CHARACTER NO-UNDO.
DEFINE VARIABLE iMB AS INT64 NO-UNDO.
iMB = System.Diagnostics.Process:GetCurrentProcess():WorkingSet64 / 1048576.
ETIME(TRUE).
INPUT THROUGH VALUE("echo hello").
IMPORT UNFORMATTED c.
INPUT CLOSE.
pcResult = "touched Process; INPUT THROUGH read '" + c + "' after " + STRING(ETIME) + " ms".
