/* stream-recursion-test.p - does recursion with the UNNAMED stream really break?
   (slide 17 speaker note). Walks recursively via an internal procedure, each
   level opening INPUT FROM OS-DIR on the unnamed stream. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE iFiles AS INTEGER NO-UNDO.

RUN WalkDir ("/tmp/rec").
MESSAGE "recursive, unnamed stream -> xml files found:" iFiles.

PROCEDURE WalkDir:
    DEFINE INPUT PARAMETER pcDir AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFull AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAttr AS CHARACTER NO-UNDO.

    INPUT FROM OS-DIR(pcDir).
    REPEAT:
        IMPORT cName cFull cAttr.
        IF cName = "." OR cName = ".." THEN NEXT.
        IF INDEX(cAttr, "D") > 0 THEN
            RUN WalkDir (cFull).          /* nested INPUT FROM on same stream */
        ELSE IF cName MATCHES "*.xml" THEN
            ASSIGN iFiles = iFiles + 1.
    END.
    INPUT CLOSE.
END PROCEDURE.
