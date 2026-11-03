/* check-cert-sslc.p - slide 24, left box: the way banking customers do it today.
   Shell out to sslc, write to a temp file, read it back, parse notAfter by hand.
   Parameters: 1 = certificate path, 2 = CA path. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE INPUT PARAMETER pcCert AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcCA   AS CHARACTER NO-UNDO.

DEFINE VARIABLE cSslc    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLine    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSubject AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNotAfter AS CHARACTER NO-UNDO.
DEFINE VARIABLE dtExpiry AS DATETIME  NO-UNDO.
DEFINE VARIABLE lValid   AS LOGICAL   NO-UNDO.
DEFINE VARIABLE cMonths  AS CHARACTER NO-UNDO INITIAL "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec".
DEFINE VARIABLE cTime    AS CHARACTER NO-UNDO.

ASSIGN cSslc = OS-GETENV("DLC") + "/bin/sslc".

/* slide excerpt start */
OS-COMMAND SILENT VALUE(cSslc + " x509 -in " + pcCert +
                        " -noout -subject -enddate > /tmp/cert.txt 2>&1").

INPUT FROM "/tmp/cert.txt".
REPEAT:
    IMPORT UNFORMATTED cLine.
    IF cLine BEGINS "subject="  THEN ASSIGN cSubject  = SUBSTRING(cLine, 9).
    IF cLine BEGINS "notAfter=" THEN ASSIGN cNotAfter = SUBSTRING(cLine, 10).
END.
INPUT CLOSE.

/* "Feb  4 16:09:56 2029 GMT" -> DATETIME, by hand */
ASSIGN cNotAfter = TRIM(REPLACE(cNotAfter, "  ", " "))
       cTime     = ENTRY(3, cNotAfter, " ")
       dtExpiry  = DATETIME(LOOKUP(ENTRY(1, cNotAfter, " "), cMonths),  /* month */
                            INTEGER(ENTRY(2, cNotAfter, " ")),          /* day   */
                            INTEGER(ENTRY(4, cNotAfter, " ")),          /* year  */
                            INTEGER(ENTRY(1, cTime, ":")),
                            INTEGER(ENTRY(2, cTime, ":")),
                            INTEGER(ENTRY(3, cTime, ":"))).

OS-COMMAND SILENT VALUE(cSslc + " verify -CAfile " + pcCA + " " + pcCert +
                        " > /tmp/v.txt 2>&1").
INPUT FROM "/tmp/v.txt".
REPEAT:
    IMPORT UNFORMATTED cLine.
    IF cLine MATCHES "*: OK" THEN ASSIGN lValid = TRUE.
END.
INPUT CLOSE.
/* slide excerpt end */

MESSAGE "sslc  subject   :" cSubject.
MESSAGE "sslc  notAfter  :" cNotAfter.
MESSAGE "sslc  as DATETIME:" dtExpiry.
MESSAGE "sslc  days left  :" INTERVAL(dtExpiry, NOW, "days").
MESSAGE "sslc  valid      :" STRING(lValid, "yes/no").
