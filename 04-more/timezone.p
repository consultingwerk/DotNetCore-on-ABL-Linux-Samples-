/* timezone.p - TimeZoneInfo: real IANA time zones with DST, which ABL cannot do.
   ABL only knows a fixed numeric offset (TIMEZONE), not "Europe/Amsterdam". */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.TimeZoneInfo FROM ASSEMBLY.
USING System.DateTime     FROM ASSEMBLY.

DEFINE VARIABLE oZone   AS CLASS TimeZoneInfo NO-UNDO.
DEFINE VARIABLE dtWinter AS DATETIME NO-UNDO INITIAL 01/15/2026.
DEFINE VARIABLE dtSummer AS DATETIME NO-UNDO INITIAL 07/15/2026.

/* slide excerpt start */
ASSIGN oZone = TimeZoneInfo:FindSystemTimeZoneById("Europe/Amsterdam").

MESSAGE "zone         :" oZone:DisplayName.
MESSAGE "UTC 12:00 in January ->"
        TimeZoneInfo:ConvertTimeFromUtc(DATETIME(1, 15, 2026, 12, 0, 0, 0), oZone).
MESSAGE "UTC 12:00 in July    ->"
        TimeZoneInfo:ConvertTimeFromUtc(DATETIME(7, 15, 2026, 12, 0, 0, 0), oZone).
MESSAGE "ABL TIMEZONE (fixed) :" TIMEZONE.
/* slide excerpt end */

CATCH e AS System.Exception:
    MESSAGE "timezone FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
