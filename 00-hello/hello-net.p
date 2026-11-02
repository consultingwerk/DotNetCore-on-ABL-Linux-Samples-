/* hello-net.p - slide 9: the small .NET things, exactly as the slide shows them. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.Directory FROM ASSEMBLY.
USING System.Text.StringBuilder FROM ASSEMBLY.

DEFINE VARIABLE aFiles AS "System.String[]" NO-UNDO.
DEFINE VARIABLE oSb    AS CLASS StringBuilder NO-UNDO.
DEFINE VARIABLE oList  AS "System.Collections.Generic.List<CHARACTER>" NO-UNDO.

/* slide excerpt start */
ASSIGN aFiles = Directory:GetFiles("/data").
MESSAGE "files in /data:" aFiles:Length.

ASSIGN oSb = NEW StringBuilder().
oSb:Append("Hello"):Append(" Linux").
MESSAGE oSb:ToString().

ASSIGN oList = NEW "System.Collections.Generic.List<CHARACTER>"().
oList:Add("one").
oList:Add("two").
MESSAGE "list count:" oList:Count.
/* slide excerpt end */

CATCH e AS System.Exception:
    MESSAGE "hello-net FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
