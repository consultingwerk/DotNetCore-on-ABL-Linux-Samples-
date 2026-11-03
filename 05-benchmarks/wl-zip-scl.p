/*------------------------------------------------------------------------
    File        : wl-zip-scl.p
    Purpose     : Workload "zip", pure-ABL side: build the archive with the
                  SmartComponent Library's ZipArchiveWriter
                  (Consultingwerk/Framework/Compression, SCL-6170).
    Notes       : Needs the SCL ABL tree on PROPATH.
                  SCL documents this writer as intended for small archives
                  (a few MB, no Zip64). A 10,000-file tree is deliberately
                  outside that envelope - see README.
                  pcArg = folder to zip. Check value = number of file entries.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Consultingwerk.Framework.Compression.* from propath.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define temp-table ttDir no-undo
    field cPath as character
    field lDone as logical
    index ixDone is primary lDone.

define buffer bNewDir for ttDir.

define variable oWriter  as class ZipArchiveWriter no-undo.
define variable cZip     as character no-undo initial "/tmp/bench-scl.zip".
define variable cCurrent as character no-undo.
define variable cName    as character no-undo.
define variable cFull    as character no-undo.
define variable cAttr    as character no-undo.
define variable iFiles   as integer   no-undo.

os-delete value(cZip).

assign oWriter = new ZipArchiveWriter().

create ttDir.
assign ttDir.cPath = pcArg.

repeat:
    find first ttDir where ttDir.lDone = false no-error.
    if not available ttDir then leave.
    assign ttDir.lDone = true
           cCurrent    = ttDir.cPath.

    input from os-dir(cCurrent).
    repeat:
        import cName cFull cAttr.
        if cName = "." or cName = ".." then next.
        if index(cAttr, "D") > 0 then do:
            create bNewDir.
            assign bNewDir.cPath = cFull.
        end.
        else do:
            /* entry name relative to the root, as zip -r would store it */
            oWriter:AddFile(substring(cFull, length(pcArg) + 2), cFull).
            assign iFiles = iFiles + 1.
        end.
    end.
    input close.
end.

oWriter:WriteToFile(cZip).
assign pcCheck = string(iFiles).

finally:
    if valid-object(oWriter) then delete object oWriter no-error.
end finally.
