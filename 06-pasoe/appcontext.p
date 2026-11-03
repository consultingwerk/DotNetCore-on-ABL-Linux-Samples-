/* appcontext.p - framework-level state (System.AppContext) across sessions.
   Parameter: value to store ("" = only read). Returns what was there before. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.AppContext FROM ASSEMBLY.

DEFINE INPUT  PARAMETER pcSet    AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcBefore AS CHARACTER NO-UNDO.

DEFINE VARIABLE oValue AS System.Object NO-UNDO.

ASSIGN oValue   = AppContext:GetData("pug.demo")
       pcBefore = (IF VALID-OBJECT(oValue) THEN oValue:ToString() ELSE "<nothing>")
                  + "  (read in session " + STRING(SESSION:CURRENT-REQUEST-INFO:SessionId) + ")".
IF pcSet <> "" THEN AppContext:SetData("pug.demo", pcSet).
