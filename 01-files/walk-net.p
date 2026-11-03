/* walk-net.p - slide 17, right box: the same walk with System.IO.Directory.
   One call does the recursion; no work queue, no stream handling.
   Parameter: directory to walk. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.Directory      FROM ASSEMBLY.
USING System.IO.SearchOption   FROM ASSEMBLY.

DEFINE VARIABLE oProcessor AS CLASS FileProcessor NO-UNDO.
DEFINE VARIABLE aFiles     AS "System.String[]"   NO-UNDO.
DEFINE VARIABLE cRoot      AS CHARACTER NO-UNDO.
DEFINE VARIABLE i          AS INTEGER   NO-UNDO.

ASSIGN cRoot = ENTRY(1, SESSION:PARAMETER) WHEN SESSION:PARAMETER <> "".
IF cRoot = "" THEN ASSIGN cRoot = "/tmp/data/in".

ASSIGN oProcessor = NEW FileProcessor()
       i          = ETIME(TRUE).

/* slide excerpt start */
ASSIGN aFiles = Directory:GetFiles(cRoot, "*.xml", SearchOption:AllDirectories).

DO i = 0 TO aFiles:Length - 1:
    oProcessor:ProcessFile(aFiles:GetValue(i):ToString()).
END.
/* slide excerpt end */

MESSAGE "walk-net   files:" oProcessor:FileCount
        "  ms:" ETIME.
