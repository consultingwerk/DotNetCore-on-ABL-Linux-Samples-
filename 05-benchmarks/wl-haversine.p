/*------------------------------------------------------------------------
    File        : wl-haversine.p
    Purpose     : Workload "haversine" - repeat of Mike Fechner's 2023 benchmark
                  GetDistanceFromLatLonInKm (2.4 s on .NET Framework 4.8,
                  1.9 s on .NET 6, OpenEdge 12.7 on Windows - for 10,000
                  iterations, not the 500,000 run here; see README).
                  ABL has no SIN, COS, ATAN2, SQRT or PI, so System.Math is used.
                  Distance between Progress HQ (Burlington, MA) and
                  Consultingwerk HQ (Cologne).
    Notes       : DRAFT, not compiled yet. If the compiler does not accept
                  DECIMAL arguments for System.Double parameters, pass them
                  with the AS DOUBLE option.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using System.Math from assembly.

define input  parameter piIterations as integer   no-undo.
define input  parameter pcArg        as character no-undo.
define output parameter pcCheck      as character no-undo.

define variable dKm as decimal no-undo.
define variable i   as integer no-undo.

function deg2rad returns decimal (input pdDeg as decimal):
    return pdDeg * Math:PI / 180.
end function.

function distanceKm returns decimal (input pdLat1 as decimal, input pdLon1 as decimal,
                                     input pdLat2 as decimal, input pdLon2 as decimal):
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

do i = 1 to piIterations:
    dKm = distanceKm(42.5048, -71.1956, 50.9375, 6.9603).
end.

pcCheck = string(round(dKm, 0)).
