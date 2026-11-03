/*------------------------------------------------------------------------
    File        : clr-first-call.p
    Purpose     : Cost of the first .NET call in a fresh session (CLR start).
                  Run in separate sessions with and without -preloadCLR
                  (see run.sh). Appends one line to results-<label>-clr.csv.
    Syntax      : _progres -b -clrnetcore [-preloadCLR] -assemblies <dir>
                      -p clr-first-call.p -param "label=net8;preload=yes"
    Notes       : DRAFT, not compiled yet.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define variable cLabel   as character     no-undo initial "default".
define variable cPreload as character     no-undo initial "no".
define variable cEntry   as character     no-undo.
define variable iEntry   as integer       no-undo.
define variable iStart   as int64         no-undo.
define variable iFirst   as int64         no-undo.
define variable oObject  as System.Object no-undo.

define stream sCsv.

do iEntry = 1 to num-entries(session:parameter, ";"):
    cEntry = entry(iEntry, session:parameter, ";").
    case trim(entry(1, cEntry, "=")):
        when "label"   then cLabel   = trim(entry(2, cEntry, "=")).
        when "preload" then cPreload = trim(entry(2, cEntry, "=")).
    end case.
end.

iStart  = etime.
oObject = new System.Object().
iFirst  = etime - iStart.

output stream sCsv to value(substitute("results-&1-clr.csv", cLabel)) append.
/* label, preload, ms for the first .NET call, ms since session start */
export stream sCsv delimiter "," cLabel cPreload iFirst etime.
output stream sCsv close.
