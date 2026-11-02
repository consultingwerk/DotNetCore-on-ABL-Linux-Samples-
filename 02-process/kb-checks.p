/* kb-checks.p - verifies the two Knowledge Base claims quoted on slide 21
   against OpenEdge 13.0 on Linux.
     KB 000139689  OS-ERROR is 0 after a failing OS-COMMAND
     KB 000180173  a trailing & returns before the command has finished */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE iBefore AS INTEGER NO-UNDO.
DEFINE VARIABLE iAfter  AS INTEGER NO-UNDO.
DEFINE VARIABLE cLine   AS CHARACTER NO-UNDO.

MESSAGE "KB 000139689 - OS-ERROR after a failing OS-COMMAND".
OS-COMMAND SILENT VALUE("ls /nope").
MESSAGE "   OS-ERROR after 'ls /nope'      :" OS-ERROR.
OS-COMMAND SILENT VALUE("exit 42").
MESSAGE "   OS-ERROR after 'exit 42'       :" OS-ERROR.
OS-COMMAND SILENT VALUE("/no/such/binary").
MESSAGE "   OS-ERROR after missing binary  :" OS-ERROR.
MESSAGE "".

MESSAGE "KB 000180173 - trailing & returns immediately".
OS-DELETE VALUE("/tmp/kb-async.flag").
/* the & must apply to the whole command, hence the sub-shell */
ASSIGN iBefore = ETIME(TRUE).
OS-COMMAND SILENT VALUE("(sleep 3; touch /tmp/kb-async.flag) &").
ASSIGN iAfter = ETIME.
MESSAGE "   OS-COMMAND with & returned after:" iAfter "ms".
MESSAGE "   flag file exists right away     :" (SEARCH("/tmp/kb-async.flag") <> ?).

ASSIGN iBefore = ETIME(TRUE).
OS-COMMAND SILENT VALUE("sleep 3").
MESSAGE "   same command WITHOUT & took     :" ETIME "ms".
