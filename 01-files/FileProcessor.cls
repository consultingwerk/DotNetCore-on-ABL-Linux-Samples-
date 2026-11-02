/* FileProcessor.cls - the "does stuff" worker from slide 17.
   Both walkers call it, so both can print the same number. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS FileProcessor:

    /* Number of ProcessFile calls, so the two walkers can be compared. */
    DEFINE PUBLIC PROPERTY FileCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

/* slide excerpt start */
    METHOD PUBLIC VOID ProcessFile (pcFile AS CHARACTER):
        /* does stuff */
        ASSIGN THIS-OBJECT:FileCount = THIS-OBJECT:FileCount + 1.
    END METHOD.
/* slide excerpt end */

END CLASS.
