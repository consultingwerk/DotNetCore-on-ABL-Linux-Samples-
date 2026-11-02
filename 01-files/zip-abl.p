/* zip-abl.p - slide 18, left box: "ABL today" - shell out to zip/unzip.
   There is no zip or compression API in the ABL itself, so the archive is built
   by the zip(1) binary and listed by parsing unzip -l output.
   Parameters: 1 = directory to zip, 2 = zip file. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE cSource  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cZip     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLine    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName    AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLen     AS INTEGER   NO-UNDO.
DEFINE VARIABLE iEntries AS INTEGER   NO-UNDO.
DEFINE VARIABLE lInTable AS LOGICAL   NO-UNDO.

ASSIGN cSource = "/tmp/data/in"
       cZip    = "/tmp/data/in-abl.zip".

IF SESSION:PARAMETER <> "" THEN
    ASSIGN cSource = ENTRY(1, SESSION:PARAMETER)
           cZip    = ENTRY(2, SESSION:PARAMETER).

ETIME(TRUE).

/* slide excerpt start */
OS-DELETE VALUE(cZip).
OS-COMMAND SILENT VALUE("cd " + cSource + " && zip -r -q " + cZip + " .").

/* no API to read the archive either - parse unzip -l line by line */
INPUT THROUGH VALUE("unzip -l " + cZip).
REPEAT:
    IMPORT UNFORMATTED cLine.
    IF cLine MATCHES "*----*" THEN DO:
        ASSIGN lInTable = NOT lInTable.
        NEXT.
    END.
    IF NOT lInTable OR TRIM(cLine) = "" THEN NEXT.
    ASSIGN iLen     = INTEGER(ENTRY(1, TRIM(cLine), " ")) NO-ERROR.
    ASSIGN cName    = ENTRY(NUM-ENTRIES(TRIM(cLine), " "), TRIM(cLine), " ")
           iEntries = iEntries + 1.
    IF iEntries <= 10 THEN MESSAGE cName iLen.
END.
INPUT CLOSE.
/* slide excerpt end */

MESSAGE "zip-abl   entries:" iEntries "  ms:" ETIME "  archive:" cZip.
