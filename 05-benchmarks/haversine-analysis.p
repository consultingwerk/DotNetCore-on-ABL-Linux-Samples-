/*------------------------------------------------------------------------
    File        : haversine-analysis.p
    Purpose     : Where do the ~60 µs per Haversine iteration go?
                  Not part of run-all.p; does not change the benchmark.
                  V1  wl-haversine.p as is: 13 .NET calls per distance
                      (Math:PI x4 via deg2rad, Sin x4, Cos x2, Sqrt x2, Atan2 x1)
                  V2  Math:PI read once outside the loop: 9 .NET calls
                  V3  same ABL functions and arithmetic, no .NET at all
                      (stand-ins return their argument): the pure ABL cost
                  V4  one call per distance into Demo.Interop.Geo:DistanceKm
                  Each variant 5 runs, median reported.
    Parameter   : iterations (default 100000)
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.Math from assembly.
using Demo.Interop.Geo from assembly.

define variable iIter   as integer no-undo initial 100000.
define variable dPi     as decimal no-undo.
define variable dKm     as decimal no-undo.
define variable i       as integer no-undo.
define variable iRun    as integer no-undo.
define variable iV      as integer no-undo.
define variable iMs     as int64   no-undo extent 5.
define variable iStart  as int64   no-undo.
define variable iMedian as int64   no-undo.
define variable cName   as character no-undo extent 4 initial
    ["V1 13 .NET calls / distance", "V2  9 .NET calls (PI cached)",
     "V3  0 .NET calls (ABL only)", "V4  1 .NET call (C# facade)"].

if session:parameter <> "" then iIter = integer(session:parameter).

function deg2rad returns decimal (pdDeg as decimal):
    return pdDeg * Math:PI / 180.
end function.

function distanceKm returns decimal (pdLat1 as decimal, pdLon1 as decimal,
                                     pdLat2 as decimal, pdLon2 as decimal):
    define variable dLat as decimal no-undo.
    define variable dLon as decimal no-undo.
    define variable dA   as decimal no-undo.
    assign dLat = deg2rad(pdLat2 - pdLat1)
           dLon = deg2rad(pdLon2 - pdLon1)
           dA   = Math:Sin(dLat / 2) * Math:Sin(dLat / 2)
                + Math:Cos(deg2rad(pdLat1)) * Math:Cos(deg2rad(pdLat2))
                * Math:Sin(dLon / 2) * Math:Sin(dLon / 2).
    return 6371 * 2 * Math:Atan2(Math:Sqrt(dA), Math:Sqrt(1 - dA)).
end function.

/* V2: identical, but PI is an ABL variable */
function deg2radCached returns decimal (pdDeg as decimal):
    return pdDeg * dPi / 180.
end function.

function distanceKmCached returns decimal (pdLat1 as decimal, pdLon1 as decimal,
                                           pdLat2 as decimal, pdLon2 as decimal):
    define variable dLat as decimal no-undo.
    define variable dLon as decimal no-undo.
    define variable dA   as decimal no-undo.
    assign dLat = deg2radCached(pdLat2 - pdLat1)
           dLon = deg2radCached(pdLon2 - pdLon1)
           dA   = Math:Sin(dLat / 2) * Math:Sin(dLat / 2)
                + Math:Cos(deg2radCached(pdLat1)) * Math:Cos(deg2radCached(pdLat2))
                * Math:Sin(dLon / 2) * Math:Sin(dLon / 2).
    return 6371 * 2 * Math:Atan2(Math:Sqrt(dA), Math:Sqrt(1 - dA)).
end function.

/* V3: identical ABL shape, every .NET call replaced by an ABL stand-in */
function fSin   returns decimal (d as decimal): return d. end function.
function fCos   returns decimal (d as decimal): return d. end function.
function fSqrt  returns decimal (d as decimal): return d. end function.
function fAtan2 returns decimal (y as decimal, x as decimal): return y. end function.

function deg2radAbl returns decimal (pdDeg as decimal):
    return pdDeg * 3.14159265358979 / 180.
end function.

function distanceKmAbl returns decimal (pdLat1 as decimal, pdLon1 as decimal,
                                        pdLat2 as decimal, pdLon2 as decimal):
    define variable dLat as decimal no-undo.
    define variable dLon as decimal no-undo.
    define variable dA   as decimal no-undo.
    assign dLat = deg2radAbl(pdLat2 - pdLat1)
           dLon = deg2radAbl(pdLon2 - pdLon1)
           dA   = fSin(dLat / 2) * fSin(dLat / 2)
                + fCos(deg2radAbl(pdLat1)) * fCos(deg2radAbl(pdLat2))
                * fSin(dLon / 2) * fSin(dLon / 2).
    return 6371 * 2 * fAtan2(fSqrt(dA), fSqrt(1 - dA)).
end function.

dPi = Math:PI.
dKm = distanceKm(1, 1, 2, 2).          /* warm-up: CLR, assembly, r-code */
dKm = Geo:DistanceKm(1, 1, 2, 2).

message substitute("Haversine, &1 iterations, median of 5 runs", iIter).
do iV = 1 to 4:
    do iRun = 1 to 5:
        iStart = etime.
        do i = 1 to iIter:
            case iV:
                when 1 then dKm = distanceKm      (42.5048, -71.1956, 50.9375, 6.9603).
                when 2 then dKm = distanceKmCached(42.5048, -71.1956, 50.9375, 6.9603).
                when 3 then dKm = distanceKmAbl   (42.5048, -71.1956, 50.9375, 6.9603).
                when 4 then dKm = Geo:DistanceKm  (42.5048, -71.1956, 50.9375, 6.9603).
            end case.
        end.
        iMs[iRun] = etime - iStart.
    end.
    /* median of 5: sort the five values */
    run sort5 (input-output iMs).
    iMedian = iMs[3].
    message substitute("&1   &2 ms   &3 µs/distance   check: &4 km",
                       string(cName[iV], "x(30)"), string(iMedian, ">>>>>9"),
                       string(iMedian * 1000 / iIter, ">>9.9"),
                       (if iV = 3 then "n/a" else string(round(dKm, 0)))).
end.

procedure sort5:
    define input-output parameter piMs as int64 no-undo extent 5.
    define variable a as integer no-undo.
    define variable b as integer no-undo.
    define variable t as int64   no-undo.
    do a = 1 to 4:
        do b = a + 1 to 5:
            if piMs[b] < piMs[a] then assign t = piMs[a] piMs[a] = piMs[b] piMs[b] = t.
        end.
    end.
end procedure.
