/*------------------------------------------------------------------------
    File        : run-all.p
    Purpose     : Benchmark harness for ".NET on Linux. Why bother?"
                  (PUG Challenge 2026 Amsterdam, Peter Judge)
                  Runs every workload once as warm-up, then n timed runs,
                  writes raw timings to results-<label>.csv and medians to
                  results-<label>.md

    Syntax      : _progres -b -clrnetcore -assemblies <dir> -p run-all.p
                      -param "label=net8;runs=5;tree=/tmp/bench-tree;only=sha256"

                  label : name of this run, e.g. net8 or net10 (default: default)
                  runs  : timed runs per workload, odd number (default: 5)
                  tree  : test tree from gen-tree.sh (default: /tmp/bench-tree)
                  only  : comma-separated workload names to run (default: all)

    Notes       : DRAFT 21.10.2026 - written without access to an OpenEdge 13.0
                  installation, not compiled or run yet.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define temp-table ttWorkload no-undo
    field Seq        as integer
    field Workload   as character
    field Variant    as character
    field Program    as character
    field Iterations as integer
    field Arg        as character
    index ixSeq is primary unique Seq.

define temp-table ttRun no-undo
    field Workload as character
    field Variant  as character
    field RunNo    as integer
    field Ms       as int64
    field Check    as character
    index ixRun Workload Variant Ms.

define variable cLabel   as character no-undo initial "default".
define variable iRuns    as integer   no-undo initial 5.
define variable cTree    as character no-undo initial "/tmp/bench-tree".
define variable cOnly    as character no-undo.
define variable cEntry   as character no-undo.
define variable cCheck   as character no-undo.
define variable iEntry   as integer   no-undo.
define variable iRun     as integer   no-undo.
define variable iStart   as int64     no-undo.
define variable iMs      as int64     no-undo.
define variable iMedian  as integer   no-undo.
define variable iPos     as integer   no-undo.

define stream sCsv.
define stream sMd.

/* ---------------------------------------------------------------- parameters */
do iEntry = 1 to num-entries(session:parameter, ";"):
    cEntry = entry(iEntry, session:parameter, ";").
    case trim(entry(1, cEntry, "=")):
        when "label" then cLabel = trim(entry(2, cEntry, "=")).
        when "runs"  then iRuns  = integer(trim(entry(2, cEntry, "="))).
        when "tree"  then cTree  = trim(entry(2, cEntry, "=")).
        when "only"  then cOnly  = trim(entry(2, cEntry, "=")).
    end case.
end.

/* ---------------------------------------------------------------- workloads
   name, variant, program, iterations, argument                              */
run addWorkload ("guid-parse", "net", "wl-guid-parse.p",  500000, "").
run addWorkload ("haversine",  "net", "wl-haversine.p",   500000, "").
run addWorkload ("sha256",     "abl", "wl-sha256-abl.p",  100000, "").
run addWorkload ("sha256",     "net", "wl-sha256-net.p",  100000, "").
run addWorkload ("dirwalk",    "abl", "wl-dirwalk-abl.p",      1, cTree).
run addWorkload ("dirwalk",    "net", "wl-dirwalk-net.p",      1, cTree).
run addWorkload ("process",    "abl", "wl-process-abl.p",    100, "").
run addWorkload ("process",    "net", "wl-process-net.p",    100, "").
run addWorkload ("zip",        "abl", "wl-zip-shell.p",        1, cTree).
run addWorkload ("zip",        "net", "wl-zip-net.p",          1, cTree).

/* ---------------------------------------------------------------- run */
output stream sCsv to value(substitute("results-&1.csv", cLabel)) append.

for each ttWorkload by ttWorkload.Seq:
    if cOnly > "" and lookup(ttWorkload.Workload, cOnly) = 0 then
        next.

    /* warm-up: compiles the program on the fly, loads the CLR and assemblies */
    run value(ttWorkload.Program) (ttWorkload.Iterations, ttWorkload.Arg, output cCheck).

    do iRun = 1 to iRuns:
        iStart = etime.
        run value(ttWorkload.Program) (ttWorkload.Iterations, ttWorkload.Arg, output cCheck).
        iMs = etime - iStart.

        create ttRun.
        assign ttRun.Workload = ttWorkload.Workload
               ttRun.Variant  = ttWorkload.Variant
               ttRun.RunNo    = iRun
               ttRun.Ms       = iMs
               ttRun.Check    = cCheck.

        export stream sCsv delimiter ","
            cLabel ttWorkload.Workload ttWorkload.Variant ttWorkload.Iterations iRun iMs cCheck.
    end.
end.

output stream sCsv close.

/* ---------------------------------------------------------------- medians */
output stream sMd to value(substitute("results-&1.md", cLabel)).
put stream sMd unformatted
    substitute("# Benchmark results: &1 (&2)", cLabel, string(now)) skip(1)
    "| Workload | Variant | Iterations | Median ms | Runs | Check |" skip
    "|---|---|---:|---:|---:|---|" skip.

for each ttWorkload by ttWorkload.Seq:
    if not can-find(first ttRun where ttRun.Workload = ttWorkload.Workload
                                  and ttRun.Variant  = ttWorkload.Variant) then
        next.

    iMedian = integer(truncate(iRuns / 2, 0)) + 1.
    iPos    = 0.
    for each ttRun where ttRun.Workload = ttWorkload.Workload
                     and ttRun.Variant  = ttWorkload.Variant
                     by ttRun.Ms:
        iPos = iPos + 1.
        if iPos = iMedian then
            put stream sMd unformatted
                substitute("| &1 | &2 | &3 | &4 | &5 | &6 |",
                           ttWorkload.Workload, ttWorkload.Variant, ttWorkload.Iterations,
                           ttRun.Ms, iRuns, ttRun.Check) skip.
    end.
end.

output stream sMd close.

message substitute("Done: results-&1.csv, results-&1.md", cLabel).

/* ---------------------------------------------------------------- helpers */
procedure addWorkload:
    define input parameter pcWorkload   as character no-undo.
    define input parameter pcVariant    as character no-undo.
    define input parameter pcProgram    as character no-undo.
    define input parameter piIterations as integer   no-undo.
    define input parameter pcArg        as character no-undo.

    define variable iSeq as integer no-undo.

    find last ttWorkload no-error.
    iSeq = (if available ttWorkload then ttWorkload.Seq else 0) + 1.

    create ttWorkload.
    assign ttWorkload.Seq        = iSeq
           ttWorkload.Workload   = pcWorkload
           ttWorkload.Variant    = pcVariant
           ttWorkload.Program    = pcProgram
           ttWorkload.Iterations = piIterations
           ttWorkload.Arg        = pcArg.
end procedure.
