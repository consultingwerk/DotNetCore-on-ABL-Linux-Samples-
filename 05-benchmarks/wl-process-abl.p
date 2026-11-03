/*------------------------------------------------------------------------
    File        : wl-process-abl.p
    Purpose     : Workload "process", ABL side: n times INPUT THROUGH echo,
                  reading the output. INPUT THROUGH starts a shell for every call.
    Notes       : DRAFT, not compiled yet. Check value = last line read.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable cLine as character no-undo.
define variable i     as integer   no-undo.

define stream sProc.

do i = 1 to piIterations:
    input stream sProc through value("echo " + string(i)).
    repeat:
        import stream sProc unformatted cLine.
        pcCheck = cLine.
    end.
    input stream sProc close.
end.
