/*------------------------------------------------------------------------
    File        : wl-zip-net.p
    Purpose     : Workload "zip", .NET side: ZipFile.CreateFromDirectory, then
                  count the entries with ZipFile.OpenRead.
    Notes       : DRAFT, not compiled yet. pcArg = folder to zip.
                  Default compression levels differ (zip -6 vs .NET Optimal);
                  compare the archive sizes as well.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.IO.Compression.* from assembly.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable cZip as character  no-undo initial "/tmp/bench-net.zip".
define variable oZip as ZipArchive no-undo.

os-delete value(cZip).
ZipFile:CreateFromDirectory(pcArg, cZip).

oZip    = ZipFile:OpenRead(cZip).
pcCheck = string(oZip:Entries:Count).

finally:
    if valid-object(oZip) then
        oZip:Dispose().
end finally.
