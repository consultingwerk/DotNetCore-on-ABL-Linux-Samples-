/* spawn-timing.p - KB 000207833 says OS-COMMAND gets slower as the agent grows.
   Grows this agent by piGrowMB of touched memory, then times piCount starts of
   /bin/echo via OS-COMMAND and via System.Diagnostics.Process.
   NOTE: in a PASOE agent Process:WaitForExit() never sees the child exit
   (see sigchld/). Completion is therefore detected by reading stdout to EOF,
   and the exit code is not available. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Diagnostics.Process          FROM ASSEMBLY.
USING System.Diagnostics.ProcessStartInfo FROM ASSEMBLY.

DEFINE INPUT  PARAMETER piCount  AS INTEGER NO-UNDO.
DEFINE INPUT  PARAMETER piGrowMB AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piOsMs   AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piNetMs  AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piRssMB  AS INTEGER NO-UNDO.

DEFINE VARIABLE mBallast AS MEMPTR  NO-UNDO.
DEFINE VARIABLE oInfo    AS CLASS ProcessStartInfo NO-UNDO.
DEFINE VARIABLE oProc    AS CLASS Process          NO-UNDO.
DEFINE VARIABLE i        AS INT64   NO-UNDO.
DEFINE VARIABLE iStart   AS INT64   NO-UNDO.
DEFINE VARIABLE cOut     AS CHARACTER NO-UNDO.

/* grow the agent: allocate and touch every page so it is really resident */
IF piGrowMB > 0 THEN DO:
    SET-SIZE(mBallast) = piGrowMB * 1048576.
    DO i = 1 TO piGrowMB * 1048576 BY 4096:
        PUT-BYTE(mBallast, i) = 1.
    END.
END.
ASSIGN piRssMB = INTEGER(System.Diagnostics.Process:GetCurrentProcess():WorkingSet64 / 1048576).

ASSIGN iStart = ETIME.
DO i = 1 TO piCount:
    OS-COMMAND SILENT VALUE("/bin/echo x > /dev/null").
END.
ASSIGN piOsMs = ETIME - iStart.

ASSIGN oInfo = NEW ProcessStartInfo("/bin/echo", "x")
       oInfo:UseShellExecute        = FALSE
       oInfo:RedirectStandardOutput = TRUE
       iStart = ETIME.
DO i = 1 TO piCount:
    ASSIGN oProc   = Process:Start(oInfo)
           cOut    = oProc:StandardOutput:ReadToEnd().   /* EOF = child has exited */
    IF TRIM(cOut) <> "x" THEN UNDO, THROW NEW Progress.Lang.AppError("unexpected output: " + cOut, 0).
    oProc:Dispose().
END.
ASSIGN piNetMs = ETIME - iStart.

FINALLY:
    SET-SIZE(mBallast) = 0.
END FINALLY.
