/* regex.p - System.Text.RegularExpressions, which ABL has no equivalent for.
   MATCHES only knows * and ., so anything structured ends up as hand-written parsing.

   PITFALL - regex patterns in ABL string literals:
     {n}  is an include-argument reference to the preprocessor: "{2}" silently
          becomes "" and "{0,16}" fails to compile (error 21104). Write ~{ and ~}.
     \   is an escape character in ABL strings on UNIX (not on Windows):
          "\d" arrives as "d". Write \\d.
   So "(\d{4})" must be written "(\\d~{4~})" - and the unescaped version gives a
   DIFFERENT regex on Linux than on Windows, without any error. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Text.RegularExpressions.Regex   FROM ASSEMBLY.
USING System.Text.RegularExpressions.Match   FROM ASSEMBLY.

DEFINE VARIABLE oMatch AS CLASS Match NO-UNDO.
DEFINE VARIABLE cIban  AS CHARACTER NO-UNDO INITIAL "NL91ABNA0417164300".
DEFINE VARIABLE cLog   AS CHARACTER NO-UNDO INITIAL "2026-11-04 15:00:12 ERROR agent 7 timed out".

/* slide excerpt start */
MESSAGE "IBAN looks valid :"
        Regex:IsMatch(cIban, "^[A-Z]~{2~}[0-9]~{2~}[A-Z0-9]~{4~}[0-9]~{7~}([A-Z0-9]?)~{0,16~}$").

ASSIGN oMatch = Regex:Match(cLog, "^(\\d~{4~}-\\d~{2~}-\\d~{2~}) (\\d~{2~}:\\d~{2~}:\\d~{2~}) (\\w+) agent (\\d+)").

IF oMatch:Success THEN DO:
    MESSAGE "date   :" oMatch:Groups:Item[1]:Value.
    MESSAGE "time   :" oMatch:Groups:Item[2]:Value.
    MESSAGE "level  :" oMatch:Groups:Item[3]:Value.
    MESSAGE "agent  :" oMatch:Groups:Item[4]:Value.
END.
/* slide excerpt end */

CATCH e AS System.Exception:
    MESSAGE "regex FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
