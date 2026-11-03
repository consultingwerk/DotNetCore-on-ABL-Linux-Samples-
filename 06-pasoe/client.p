/* client.p - calls the PASOE endpoint over APSV from a batch client.
   Each RUN is a separate request; with several connections the requests land
   in different ABL sessions of the same agent.
   Parameter: number of connections (default 3). */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE hServer     AS HANDLE    NO-UNDO EXTENT 5.
DEFINE VARIABLE hHold       AS HANDLE    NO-UNDO EXTENT 5.
DEFINE VARIABLE iAblCount   AS INTEGER   NO-UNDO.
DEFINE VARIABLE cFramework  AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPid        AS INTEGER   NO-UNDO.
DEFINE VARIABLE cSession    AS CHARACTER NO-UNDO.
DEFINE VARIABLE iCounter    AS INTEGER   NO-UNDO.
DEFINE VARIABLE iConn       AS INTEGER   NO-UNDO.
DEFINE VARIABLE iRound      AS INTEGER   NO-UNDO.
DEFINE VARIABLE iConns      AS INTEGER   NO-UNDO INITIAL 3.

IF SESSION:PARAMETER <> "" THEN ASSIGN iConns = INTEGER(SESSION:PARAMETER).

DO iConn = 1 TO iConns:
    CREATE SERVER hServer[iConn].
    hServer[iConn]:CONNECT("-URL http://localhost:8810/apsv -sessionModel Session-managed").
    /* a remote persistent procedure binds this connection to one agent session */
    RUN hold.p PERSISTENT SET hHold[iConn] ON hServer[iConn].
END.

DO iRound = 1 TO 2:
    DO iConn = 1 TO iConns:
        RUN net-info.p ON hServer[iConn]
            (OUTPUT cFramework, OUTPUT iPid, OUTPUT cSession, OUTPUT iCounter, OUTPUT iAblCount).
        MESSAGE "connection" iConn "->" cFramework " agent pid:" iPid
                " session:" cSession " .NET static:" iCounter " ABL static:" iAblCount.
    END.
END.

FINALLY:
    DO iConn = 1 TO iConns:
        IF VALID-HANDLE(hHold[iConn]) THEN DELETE PROCEDURE hHold[iConn] NO-ERROR.
        IF VALID-HANDLE(hServer[iConn]) THEN DO:
            hServer[iConn]:DISCONNECT() NO-ERROR.
            DELETE OBJECT hServer[iConn] NO-ERROR.
        END.
    END.
END FINALLY.
