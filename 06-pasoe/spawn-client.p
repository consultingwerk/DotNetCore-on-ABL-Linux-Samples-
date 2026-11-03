/* spawn-client.p - calls spawn-timing.p with growing agent sizes, 3 runs each. */
DEFINE VARIABLE hServer AS HANDLE  NO-UNDO.
DEFINE VARIABLE iOs     AS INTEGER NO-UNDO.
DEFINE VARIABLE iNet    AS INTEGER NO-UNDO.
DEFINE VARIABLE iRss    AS INTEGER NO-UNDO.
DEFINE VARIABLE iGrow   AS INTEGER NO-UNDO.
DEFINE VARIABLE iRun    AS INTEGER NO-UNDO.
DEFINE VARIABLE cSizes  AS CHARACTER NO-UNDO INITIAL "0,1024,2000".

IF SESSION:PARAMETER <> "" THEN cSizes = SESSION:PARAMETER.
CREATE SERVER hServer.
hServer:CONNECT("-URL http://localhost:8810/apsv").
MESSAGE "100 x /bin/echo from a PASOE agent  (ms)".
DO iGrow = 1 TO NUM-ENTRIES(cSizes):
    DO iRun = 1 TO 3:
        RUN spawn-timing.p ON hServer (100, INTEGER(ENTRY(iGrow, cSizes)),
                                       OUTPUT iOs, OUTPUT iNet, OUTPUT iRss).
        MESSAGE "agent RSS" STRING(iRss, ">>>>9") "MB   OS-COMMAND" STRING(iOs, ">>>>9")
                "   Process:Start" STRING(iNet, ">>>>9").
    END.
END.
hServer:DISCONNECT().
