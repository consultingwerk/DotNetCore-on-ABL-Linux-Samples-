/* check-cert.p - slide 24, right box: X.509 with System.Security.Cryptography.
   Reads the certificate, prints the interesting fields, and validates the chain
   against a CA we nominate ourselves - no OS trust store involved.
   Parameters: 1 = certificate path, 2 = CA path. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Security.Cryptography.X509Certificates.X509Certificate2    FROM ASSEMBLY.
USING System.Security.Cryptography.X509Certificates.X509Chain           FROM ASSEMBLY.
USING System.Security.Cryptography.X509Certificates.X509ChainTrustMode  FROM ASSEMBLY.
USING System.Security.Cryptography.X509Certificates.X509RevocationMode  FROM ASSEMBLY.
USING System.Security.Cryptography.X509Certificates.X509ChainStatus     FROM ASSEMBLY.

DEFINE INPUT PARAMETER pcCert AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcCA   AS CHARACTER NO-UNDO.

DEFINE VARIABLE oCert  AS CLASS X509Certificate2 NO-UNDO.
DEFINE VARIABLE oCA    AS CLASS X509Certificate2 NO-UNDO.
DEFINE VARIABLE oChain AS CLASS X509Chain        NO-UNDO.
DEFINE VARIABLE lValid AS LOGICAL   NO-UNDO.
DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
DEFINE VARIABLE oStatus AS CLASS X509ChainStatus NO-UNDO.

/* slide excerpt start */
ASSIGN oCert = NEW X509Certificate2(pcCert).

MESSAGE ".NET  subject   :" oCert:Subject.
MESSAGE ".NET  issuer    :" oCert:Issuer.
MESSAGE ".NET  notAfter  :" oCert:NotAfter.
MESSAGE ".NET  days left  :" INTERVAL(oCert:NotAfter, NOW, "days").

ASSIGN oCA    = NEW X509Certificate2(pcCA)
       oChain = NEW X509Chain().

ASSIGN oChain:ChainPolicy:TrustMode      = X509ChainTrustMode:CustomRootTrust
       oChain:ChainPolicy:RevocationMode = X509RevocationMode:NoCheck.
oChain:ChainPolicy:CustomTrustStore:Add(oCA).

ASSIGN lValid = oChain:Build(oCert).
MESSAGE ".NET  valid      :" STRING(lValid, "yes/no").

IF NOT lValid THEN
DO i = 0 TO oChain:ChainStatus:Length - 1:
    /* GetValue() is typed System.Object - the cast is required */
    ASSIGN oStatus = CAST(oChain:ChainStatus:GetValue(i), X509ChainStatus).
    MESSAGE "      reason     :" oStatus:Status:ToString()
            "-" TRIM(oStatus:StatusInformation).
END.
/* slide excerpt end */

CATCH e AS System.Exception:
    MESSAGE "check-cert FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
