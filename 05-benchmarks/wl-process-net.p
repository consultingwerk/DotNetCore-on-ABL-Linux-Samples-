/*------------------------------------------------------------------------
    File        : wl-process-net.p
    Purpose     : Workload "process", .NET side: n times Process.Start("echo")
                  without a shell, stdout redirected, exit code available.
    Notes       : DRAFT, not compiled yet. Check value = last line read.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.Diagnostics.* from assembly.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable oPsi  as ProcessStartInfo no-undo.
define variable oProc as Process          no-undo.
define variable i     as integer          no-undo.

do i = 1 to piIterations:
    oPsi = new ProcessStartInfo("echo", string(i)).
    assign oPsi:UseShellExecute        = false
           oPsi:RedirectStandardOutput = true.

    oProc   = Process:Start(oPsi).
    pcCheck = trim(oProc:StandardOutput:ReadToEnd()).
    oProc:WaitForExit().
    oProc:Dispose().
end.
