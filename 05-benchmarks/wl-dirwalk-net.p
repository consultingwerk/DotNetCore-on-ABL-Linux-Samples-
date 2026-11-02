/*------------------------------------------------------------------------
    File        : wl-dirwalk-net.p
    Purpose     : Workload "dirwalk", .NET side: Directory.GetFiles with
                  SearchOption.AllDirectories - one bridge call.
    Notes       : DRAFT, not compiled yet. pcArg = root folder.
                  Check value must match wl-dirwalk-abl.p.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.IO.* from assembly.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable aFiles as "System.String[]" no-undo.

aFiles = Directory:GetFiles(pcArg, "*", SearchOption:AllDirectories).

pcCheck = string(aFiles:Length).
