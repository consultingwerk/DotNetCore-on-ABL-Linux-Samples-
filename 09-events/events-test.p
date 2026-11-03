/* events-test.p - are .NET events delivered into a batch ABL session on Linux?
   The Pitfalls slide says "Events: test first". This is the test.
     1. FileSystemWatcher:Created
     2. Process:Exited  (EnableRaisingEvents = TRUE)
   Both subscribe an ABL handler, trigger the event, then try to let the
   session process it with PROCESS EVENTS and WAIT-FOR ... PAUSE. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.FileSystemWatcher         FROM ASSEMBLY.
USING System.IO.File                      FROM ASSEMBLY.
USING System.IO.Directory                 FROM ASSEMBLY.
USING System.Diagnostics.Process          FROM ASSEMBLY.
USING System.Diagnostics.ProcessStartInfo FROM ASSEMBLY.

DEFINE VARIABLE oWatcher AS CLASS FileSystemWatcher NO-UNDO.
DEFINE VARIABLE oProc    AS CLASS Process           NO-UNDO.
DEFINE VARIABLE oInfo    AS CLASS ProcessStartInfo  NO-UNDO.
DEFINE VARIABLE cDir     AS CHARACTER NO-UNDO INITIAL "/tmp/evt".
DEFINE VARIABLE iWait    AS INTEGER   NO-UNDO.

DEFINE VARIABLE glFileEvent AS LOGICAL NO-UNDO.
DEFINE VARIABLE glExitEvent AS LOGICAL NO-UNDO.

IF Directory:Exists(cDir) THEN Directory:Delete(cDir, TRUE).
Directory:CreateDirectory(cDir).

/* ---------- 1. FileSystemWatcher ---------- */
MESSAGE "-- FileSystemWatcher:Created --".
ASSIGN oWatcher = NEW FileSystemWatcher(cDir)
       oWatcher:EnableRaisingEvents = TRUE.
oWatcher:Created:Subscribe("OnFileCreated").

File:WriteAllText(cDir + "/trigger.txt", "hello").

DO iWait = 1 TO 20:
    PROCESS EVENTS.
    PAUSE 0.1 NO-MESSAGE.
    IF glFileEvent THEN LEAVE.
END.
MESSAGE "   handler called:" STRING(glFileEvent, "yes/no") "after" iWait "polls".

/* ---------- 2. Process:Exited ---------- */
MESSAGE "-- Process:Exited --".
ASSIGN oInfo = NEW ProcessStartInfo("/bin/sleep", "1")
       oInfo:UseShellExecute = FALSE
       oProc = NEW Process()
       oProc:StartInfo = oInfo
       oProc:EnableRaisingEvents = TRUE.
oProc:Exited:Subscribe("OnProcessExited").
oProc:Start().

DO iWait = 1 TO 40:
    PROCESS EVENTS.
    PAUSE 0.1 NO-MESSAGE.
    IF glExitEvent THEN LEAVE.
END.
MESSAGE "   handler called:" STRING(glExitEvent, "yes/no") "after" iWait "polls".
MESSAGE "   process HasExited:" oProc:HasExited.

PROCEDURE OnFileCreated:
    DEFINE INPUT PARAMETER sender AS System.Object NO-UNDO.
    DEFINE INPUT PARAMETER args   AS System.IO.FileSystemEventArgs NO-UNDO.
    ASSIGN glFileEvent = TRUE.
    MESSAGE "   >> FileSystemWatcher handler ran:" args:Name.
END PROCEDURE.

PROCEDURE OnProcessExited:
    DEFINE INPUT PARAMETER sender AS System.Object NO-UNDO.
    DEFINE INPUT PARAMETER args   AS System.EventArgs NO-UNDO.
    ASSIGN glExitEvent = TRUE.
    MESSAGE "   >> Process:Exited handler ran".
END PROCEDURE.

CATCH e AS System.Exception:
    MESSAGE "events-test FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
