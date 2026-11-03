DEFINE TEMP-TABLE ttDir NO-UNDO FIELD cPath AS CHARACTER.
DEFINE VARIABLE cDir AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFull AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAttr AS CHARACTER NO-UNDO.
DEFINE VARIABLE oProcessor AS FileProcessor NO-UNDO.
oProcessor = NEW FileProcessor().
CREATE ttDir. ttDir.cPath = "/data/tree".
DO WHILE CAN-FIND(FIRST ttDir):
  FIND FIRST ttDir.
  cDir = ttDir.cPath.
  DELETE ttDir.
  INPUT FROM OS-DIR(cDir).
  REPEAT:
    IMPORT cName cFull cAttr.
    IF cName = "." OR cName = ".."
      THEN NEXT.
    IF INDEX(cAttr, "D") > 0 THEN DO:
      CREATE ttDir. ttDir.cPath = cFull.
    END.
    ELSE IF cName MATCHES "*.xml" THEN
      oProcessor:ProcessFile(cFull).
  END.
  INPUT CLOSE.
END.
MESSAGE "slide 17 ABL box: files" oProcessor:FileCount.
