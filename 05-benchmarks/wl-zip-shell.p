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
os-command silent value(substitute("cd &1 && zip -q -r &2 .", quoter(pcArg), quoter(cZip))).

input stream sProc through value(substitute("unzip -Z1 &1 | grep -v '/$' | wc -l", quoter(cZip))).
repeat:
    import stream sProc unformatted cLine.
    pcCheck = trim(cLine).
end.
input stream sProc close.
