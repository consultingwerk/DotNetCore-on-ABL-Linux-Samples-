/*------------------------------------------------------------------------
    File        : wl-guid-parse.p
    Purpose     : Workload "guid-parse" - repeat of Mike Fechner's 2023 benchmark
                  (".NET Core and OpenEdge", PUG Challenge Americas 2023:
                  Guid.Parse 500,000 times, ~6 s on .NET Framework 4.8,
                  ~5 s on .NET 6, OpenEdge 12.7 on Windows).
                  Many tiny calls across the bridge: mostly bridge overhead.
    Notes       : DRAFT, not compiled yet.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable oGuid as System.Guid no-undo.
define variable cGuid as character   no-undo initial "5f8e2c1a-3b4d-4e6f-8a9b-0c1d2e3f4a5b".
define variable i     as integer     no-undo.

do i = 1 to piIterations:
    oGuid = System.Guid:Parse(cGuid).
end.

pcCheck = oGuid:ToString().
