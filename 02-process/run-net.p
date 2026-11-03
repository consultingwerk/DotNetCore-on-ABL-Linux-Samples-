/* run-net.p - slide 20, right box: System.Diagnostics.Process.
   Separate stdout and stderr, a real exit code, and a timeout.

   Deadlock avoidance: stdout and stderr are separate OS pipes with a fixed
   buffer. Reading one to the end while the child is still filling the other
   blocks forever once that second buffer is full. We therefore start the stdout
   read as a Task (ReadToEndAsync) and read stderr on this thread, so both
   pipes drain concurrently. The async-event route (BeginOutputReadLine) would
   need .NET events to be delivered into the ABL session - see 09-events. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Diagnostics.Process          FROM ASSEMBLY.
USING System.Diagnostics.ProcessStartInfo FROM ASSEMBLY.

DEFINE VARIABLE oProc    AS CLASS Process          NO-UNDO.
DEFINE VARIABLE oInfo    AS CLASS ProcessStartInfo NO-UNDO.
DEFINE VARIABLE oOutTask AS "System.Threading.Tasks.Task<CHARACTER>" NO-UNDO.
DEFINE VARIABLE cOut     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErr     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCmd     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cArgs    AS CHARACTER NO-UNDO.

ASSIGN cCmd  = "ls"
       cArgs = "/data /nope".

/* slide excerpt start */
ASSIGN oInfo                         = NEW ProcessStartInfo(cCmd, cArgs)
       oInfo:RedirectStandardOutput  = TRUE
       oInfo:RedirectStandardError   = TRUE
       oInfo:UseShellExecute         = FALSE.

ASSIGN oProc = Process:Start(oInfo).

/* drain both pipes at once, or a full buffer deadlocks the child */
ASSIGN oOutTask = oProc:StandardOutput:ReadToEndAsync().
ASSIGN cErr     = oProc:StandardError:ReadToEnd().
ASSIGN cOut     = oOutTask:Result.

IF NOT oProc:WaitForExit(5000) THEN DO:
    oProc:Kill().
    MESSAGE "timeout - child killed".
END.

MESSAGE "exit code:" oProc:ExitCode.
MESSAGE "stdout:"  SKIP cOut.
MESSAGE "stderr:"  SKIP cErr.
/* slide excerpt end */

oProc:Dispose().

CATCH e AS System.Exception:
    MESSAGE "run-net FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
