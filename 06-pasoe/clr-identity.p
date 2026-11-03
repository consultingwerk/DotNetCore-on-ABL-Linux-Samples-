/* clr-identity.p - which AppDomain and AssemblyLoadContext does this ABL
   session's copy of Demo.Interop live in? Explains per-session .NET statics. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.AppDomain                              FROM ASSEMBLY.
USING System.Runtime.Loader.AssemblyLoadContext      FROM ASSEMBLY.

DEFINE OUTPUT PARAMETER pcInfo AS CHARACTER NO-UNDO.

DEFINE VARIABLE oAsm AS CLASS System.Reflection.Assembly NO-UNDO.

ASSIGN oAsm   = Progress.Util.TypeHelper:GetType("Demo.Interop.Counter"):Assembly
       pcInfo = SUBSTITUTE("session &1  AppDomain id &2  ALC '&3'  ALC hash &4",
                           SESSION:CURRENT-REQUEST-INFO:SessionId,
                           AppDomain:CurrentDomain:Id,
                           AssemblyLoadContext:GetLoadContext(oAsm):Name,
                           AssemblyLoadContext:GetLoadContext(oAsm):GetHashCode()).
