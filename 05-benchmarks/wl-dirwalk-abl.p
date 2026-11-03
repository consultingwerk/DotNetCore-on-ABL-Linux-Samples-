/*------------------------------------------------------------------------
    File        : wl-dirwalk-abl.p
    Purpose     : Workload "dirwalk", ABL side: count all files below a folder
                  with INPUT FROM OS-DIR and a temp-table work queue
                  (same code as on the slide "Walking a Directory Tree").
    Notes       : DRAFT, not compiled yet. pcArg = root folder.
                  Check value = number of files; must match wl-dirwalk-net.p.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define temp-table ttDir no-undo
    field cPath as character.

define variable cDir   as character no-undo.
define variable cName  as character no-undo.
define variable cFull  as character no-undo.
define variable cAttr  as character no-undo.
define variable iCount as integer   no-undo.

define stream sDir.

create ttDir.
ttDir.cPath = pcArg.

do while can-find(first ttDir):
    find first ttDir.
    cDir = ttDir.cPath.
    delete ttDir.

    input stream sDir from os-dir(cDir).
    repeat:
        import stream sDir cName cFull cAttr.
        if cName = "." or cName = ".." then
            next.
        if index(cAttr, "D") > 0 then do:
            create ttDir.
            ttDir.cPath = cFull.
        end.
        else if index(cAttr, "F") > 0 then
            iCount = iCount + 1.
    end.
    input stream sDir close.
end.

pcCheck = string(iCount).
