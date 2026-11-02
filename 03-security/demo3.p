/* demo3.p - slide 25: checking an X.509 certificate, both ways.
   partner.pem is signed by our demo CA, stranger.pem by an unrelated one. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE cDir AS CHARACTER NO-UNDO.

ASSIGN cDir = ENTRY(1, SESSION:PARAMETER) WHEN SESSION:PARAMETER <> "".
IF cDir = "" THEN ASSIGN cDir = "./03-security/certs/".
IF SUBSTRING(cDir, LENGTH(cDir)) <> "/" THEN ASSIGN cDir = cDir + "/".

MESSAGE "== Demo 3: X.509 certificates ==".
MESSAGE "".
MESSAGE "---------- ABL today: sslc via OS-COMMAND ----------".
RUN check-cert-sslc.p (cDir + "partner.pem", cDir + "ca.pem").
MESSAGE "".
MESSAGE "---------- .NET: X509Certificate2 + X509Chain ----------".
MESSAGE "-- partner.pem (signed by our CA) --".
RUN check-cert.p (cDir + "partner.pem", cDir + "ca.pem").
MESSAGE "".
MESSAGE "-- stranger.pem (signed by an unrelated CA) --".
RUN check-cert.p (cDir + "stranger.pem", cDir + "ca.pem").
