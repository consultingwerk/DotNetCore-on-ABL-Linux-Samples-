/* events-waitfor.p - same FileSystemWatcher test, but the main thread blocks in
   WAIT-FOR ... PAUSE instead of polling with PROCESS EVENTS. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.FileSystemWatcher FROM ASSEMBLY.
USING System.IO.File              FROM ASSEMBLY.
USING System.IO.Directory         FROM ASSEMBLY.

DEFINE VARIABLE oWatcher    AS CLASS FileSystemWatcher NO-UNDO.
DEFINE VARIABLE glFileEvent AS LOGICAL NO-UNDO.

IF Directory:Exists("/tmp/evt2") THEN Directory:Delete("/tmp/evt2", TRUE).
Directory:CreateDirectory("/tmp/evt2").

ASSIGN oWatcher = NEW FileSystemWatcher("/tmp/evt2")
       oWatcher:EnableRaisingEvents = TRUE.
oWatcher:Created:Subscribe("OnFileCreated").

File:WriteAllText("/tmp/evt2/trigger.txt", "hello").

WAIT-FOR "U1" OF THIS-PROCEDURE PAUSE 2.
MESSAGE "WAIT-FOR ... PAUSE 2 returned. handler called:" STRING(glFileEvent, "yes/no").

PROCEDURE OnFileCreated:
    DEFINE INPUT PARAMETER sender AS System.Object NO-UNDO.
    DEFINE INPUT PARAMETER args   AS System.IO.FileSystemEventArgs NO-UNDO.
    ASSIGN glFileEvent = TRUE.
END PROCEDURE.
