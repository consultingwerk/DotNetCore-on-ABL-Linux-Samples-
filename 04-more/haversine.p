/* haversine.p - System.Math: ABL has no trigonometry at all.
   Great-circle distance Amsterdam -> Manchester. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Math FROM ASSEMBLY.

DEFINE VARIABLE dLat1 AS DECIMAL NO-UNDO INITIAL 52.3676.   /* Amsterdam  */
DEFINE VARIABLE dLon1 AS DECIMAL NO-UNDO INITIAL 4.9041.
DEFINE VARIABLE dLat2 AS DECIMAL NO-UNDO INITIAL 53.4808.   /* Manchester */
DEFINE VARIABLE dLon2 AS DECIMAL NO-UNDO INITIAL -2.2426.
DEFINE VARIABLE dDLat AS DECIMAL NO-UNDO.
DEFINE VARIABLE dDLon AS DECIMAL NO-UNDO.
DEFINE VARIABLE dA    AS DECIMAL NO-UNDO.
DEFINE VARIABLE dC    AS DECIMAL NO-UNDO.

/* slide excerpt start */
ASSIGN dDLat = (dLat2 - dLat1) * Math:PI / 180.0
       dDLon = (dLon2 - dLon1) * Math:PI / 180.0
       dA    = Math:Sin(dDLat / 2) * Math:Sin(dDLat / 2)
             + Math:Cos(dLat1 * Math:PI / 180.0) * Math:Cos(dLat2 * Math:PI / 180.0)
             * Math:Sin(dDLon / 2) * Math:Sin(dDLon / 2)
       dC    = 2 * Math:Atan2(Math:Sqrt(dA), Math:Sqrt(1 - dA)).

MESSAGE "Amsterdam -> Manchester:" ROUND(6371.0 * dC, 1) "km".
/* slide excerpt end */

CATCH e AS System.Exception:
    MESSAGE "haversine FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
