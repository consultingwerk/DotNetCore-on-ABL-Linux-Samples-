/*------------------------------------------------------------------------
    File        : wl-zip-shell.p
    Purpose     : Workload "zip", ABL side: zip a folder by shelling out to
                  the zip command, then count the file entries with unzip -Z1.
    Notes       : DRAFT, not compiled yet. Needs zip and unzip
                  (apt install zip unzip). pcArg = folder to zip.
                  zip -r also stores directory entries; they are not counted.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable cZip  as character no-undo initial "/tmp/bench-shell.zip".
define variable cLine as character no-undo.

define stream sProc.

os-delete value(cZip).
/* NOTE: do NOT build this with SUBSTITUTE. SUBSTITUTE treats "&" as its
   placeholder marker and collapses "&&" to "&", which backgrounds the cd and
   runs zip in the CURRENT directory instead of pcArg. Plain concatenation. */
os-command silent value("cd " + quoter(pcArg) + " && zip -q -r " + quoter(cZip) + " .").

input stream sProc through value("unzip -Z1 " + quoter(cZip) + " | grep -v '/$' | wc -l").
repeat:
    import stream sProc unformatted cLine.
    pcCheck = trim(cLine).
end.
input stream sProc close.
