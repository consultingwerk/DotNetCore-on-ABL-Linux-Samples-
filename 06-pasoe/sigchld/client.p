/* client.p - runs one test program (SESSION:PARAMETER) on the PASOE instance */
DEFINE VARIABLE hServer AS HANDLE NO-UNDO.
DEFINE VARIABLE cResult AS CHARACTER NO-UNDO.
CREATE SERVER hServer.
hServer:CONNECT("-URL http://localhost:8810/apsv").
RUN VALUE(SESSION:PARAMETER) ON hServer (OUTPUT cResult).
MESSAGE SESSION:PARAMETER ":" cResult.
hServer:DISCONNECT().
