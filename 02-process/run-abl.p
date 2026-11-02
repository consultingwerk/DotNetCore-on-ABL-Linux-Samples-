/* run-abl.p - slide 20, left box: running a process the way ABL has always done it.
   Shows the two things you do not get: separated streams, and an exit code. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE cLine  AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLines AS INTEGER   NO-UNDO.
DEFINE VARIABLE iRc    AS INTEGER   NO-UNDO.

MESSAGE "-- INPUT THROUGH: stdout and stderr arrive mixed --".

/* slide excerpt start */
INPUT THROUGH VALUE("ls /data /nope 2>&1").
REPEAT:
    IMPORT UNFORMATTED cLine.
    ASSIGN iLines = iLines + 1.
    MESSAGE "  " cLine.
END.
INPUT CLOSE.
/* slide excerpt end */

MESSAGE "  lines:" iLines.
MESSAGE "  OS-ERROR after INPUT THROUGH:" OS-ERROR "   <- no exit code anywhere".
MESSAGE "".

/* The Knowledge Base workaround (KB 000145783): have the shell echo $? as the
   last line, then read it back. It is the only way to see the exit code. */
MESSAGE "-- KB 000145783 workaround: let the shell echo $? --".
INPUT THROUGH VALUE("ls /data /nope > /dev/null 2>&1; echo $?").
REPEAT:
    IMPORT UNFORMATTED cLine.
    ASSIGN iRc = INTEGER(TRIM(cLine)) NO-ERROR.
END.
INPUT CLOSE.
MESSAGE "  exit code recovered from echo $?:" iRc.
