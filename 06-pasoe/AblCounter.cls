/* AblCounter.cls - an ABL static, as the control for the .NET static in
   Demo.Interop.Counter. ABL statics live per ABL session. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS AblCounter:
    DEFINE PRIVATE STATIC VARIABLE iValue AS INTEGER NO-UNDO.

    METHOD PUBLIC STATIC INTEGER Next ():
        ASSIGN iValue = iValue + 1.
        RETURN iValue.
    END METHOD.
END CLASS.
