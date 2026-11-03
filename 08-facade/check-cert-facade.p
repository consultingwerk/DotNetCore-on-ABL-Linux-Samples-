/* check-cert-facade.p - the same certificate check as 03-security/check-cert.p,
   through a 40-line C# facade (Demo.Interop). One call, one JSON string back:
   no casts, no struct arrays, no X509Chain plumbing in ABL.
   Parameters: 1 = certificate path, 2 = CA path. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Demo.Interop.Certs              FROM ASSEMBLY.
USING Progress.Json.ObjectModel.*     FROM PROPATH.

DEFINE VARIABLE oParser AS CLASS ObjectModelParser NO-UNDO.
DEFINE VARIABLE oResult AS CLASS JsonObject        NO-UNDO.
DEFINE VARIABLE cJson   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPem    AS LONGCHAR  NO-UNDO.

/* slide excerpt start */
ASSIGN cJson   = Certs:Check(ENTRY(1, SESSION:PARAMETER), ENTRY(2, SESSION:PARAMETER))
       oParser = NEW ObjectModelParser()
       oResult = CAST(oParser:Parse(cJson), JsonObject).

MESSAGE "subject :" oResult:GetCharacter("subject").
MESSAGE "valid   :" oResult:GetLogical("valid").
/* slide excerpt end */

MESSAGE "raw JSON:" SKIP cJson.

/* the Span-only API, reachable through the facade */
COPY-LOB FROM FILE REPLACE(ENTRY(2, SESSION:PARAMETER), "ca.pem", "ca-key.pem") TO cPem.
MESSAGE "RSA key size via facade (ImportFromPem):" Certs:RsaKeySizeFromPem(STRING(cPem)).

CATCH e AS System.Exception:
    MESSAGE "facade FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
