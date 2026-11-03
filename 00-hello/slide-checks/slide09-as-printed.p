USING System.IO.* FROM ASSEMBLY.
USING System.Text.* FROM ASSEMBLY.
DEFINE VARIABLE aFiles AS "System.String[]" NO-UNDO.
DEFINE VARIABLE oSb    AS StringBuilder    NO-UNDO.
DEFINE VARIABLE oList  AS
  "System.Collections.Generic.List<CHARACTER>" NO-UNDO.
aFiles = Directory:GetFiles("/data", "*.xml").
oSb = NEW StringBuilder().
oSb:Append("Hello"):Append(" Linux").
MESSAGE oSb:Length oSb:ToString().
CATCH e AS System.Exception:
  MESSAGE e:Message.
END CATCH.
