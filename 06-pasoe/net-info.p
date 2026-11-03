/* net-info.p - PASOE endpoint (APSV) that calls .NET.
   Returns which runtime the agent runs, the agent's process id, the ABL session
   it ran in, and the next value of a .NET static counter (per ABL session -
   see README) and of an ABL static counter as the control. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Runtime.InteropServices.RuntimeInformation FROM ASSEMBLY.
USING System.Environment                                FROM ASSEMBLY.
USING Demo.Interop.Counter                              FROM ASSEMBLY.

DEFINE OUTPUT PARAMETER pcFramework AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER piPid       AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER pcSession   AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER piCounter   AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER piAblCount  AS INTEGER   NO-UNDO.

/* slide excerpt start */
ASSIGN pcFramework = RuntimeInformation:FrameworkDescription
       piPid       = Environment:ProcessId
       pcSession   = STRING(SESSION:CURRENT-REQUEST-INFO:SessionId)
       piCounter   = Counter:Next()
       piAblCount  = AblCounter:Next().
/* slide excerpt end */
