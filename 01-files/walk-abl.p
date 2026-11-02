/* walk-abl.p - slide 17, left box: recursive directory walk in pure ABL.
   A temp-table work queue replaces recursion, because INPUT FROM OS-DIR uses
   the unnamed input stream: a nested INPUT FROM replaces the outer one.
   Parameter: directory to walk. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE TEMP-TABLE ttDir NO-UNDO
    FIELD cPath AS CHARACTER
    FIELD lDone AS LOGICAL
    INDEX idxDone IS PRIMARY lDone.

DEFINE BUFFER bNewDir FOR ttDir.

DEFINE VARIABLE oProcessor AS CLASS FileProcessor NO-UNDO.
DEFINE VARIABLE cRoot      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCurrent   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFull      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAttr      AS CHARACTER NO-UNDO.
DEFINE VARIABLE iStart     AS INTEGER   NO-UNDO.

ASSIGN cRoot = ENTRY(1, SESSION:PARAMETER) WHEN SESSION:PARAMETER <> "".
IF cRoot = "" THEN ASSIGN cRoot = "/tmp/data/in".

ASSIGN oProcessor = NEW FileProcessor()
       iStart     = ETIME(TRUE).

CREATE ttDir.
ASSIGN ttDir.cPath = cRoot.

/* slide excerpt start */
REPEAT:
    FIND FIRST ttDir WHERE ttDir.lDone = FALSE NO-ERROR.
    IF NOT AVAILABLE ttDir THEN LEAVE.
    ASSIGN ttDir.lDone = TRUE
           cCurrent    = ttDir.cPath.

    INPUT FROM OS-DIR(cCurrent).
    REPEAT:
        IMPORT cName cFull cAttr.
        IF cName = "." OR cName = ".." THEN NEXT.
        IF INDEX(cAttr, "D") > 0 THEN DO:
            CREATE bNewDir.
            ASSIGN bNewDir.cPath = cFull.
        END.
        ELSE IF cName MATCHES "*.xml" THEN
            oProcessor:ProcessFile(cFull).
    END.
    INPUT CLOSE.
END.
/* slide excerpt end */

MESSAGE "walk-abl   files:" oProcessor:FileCount
        "  ms:" ETIME.
