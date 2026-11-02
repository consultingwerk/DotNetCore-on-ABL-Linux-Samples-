/* zip-net.p - slide 18, right box: zip archives with System.IO.Compression.
   Parameters: 1 = directory to zip, 2 = zip file, 3 = extract target.

   NOTE (deck correction): the archive is listed from a SECOND, read-mode Open.
   Reading Entry:Length on an archive still open in Update mode throws
   System.InvalidOperationException "Length properties are unavailable once an
   entry has been opened for writing." */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.Compression.ZipFile           FROM ASSEMBLY.
USING System.IO.Compression.ZipArchive        FROM ASSEMBLY.
USING System.IO.Compression.ZipArchiveMode    FROM ASSEMBLY.
USING System.IO.Compression.ZipFileExtensions FROM ASSEMBLY.
USING System.IO.File                          FROM ASSEMBLY.
USING System.IO.Directory                     FROM ASSEMBLY.

DEFINE VARIABLE oZip     AS CLASS ZipArchive NO-UNDO.
DEFINE VARIABLE cSource  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cZip     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cExtract AS CHARACTER NO-UNDO.
DEFINE VARIABLE cReadme  AS CHARACTER NO-UNDO.
DEFINE VARIABLE i        AS INTEGER   NO-UNDO.
DEFINE VARIABLE iCount   AS INTEGER   NO-UNDO.

ASSIGN cSource  = "/tmp/data/in"
       cZip     = "/tmp/data/in.zip"
       cExtract = "/tmp/data/out"
       cReadme  = "/tmp/data/readme.txt".

IF SESSION:PARAMETER <> "" THEN
    ASSIGN cSource  = ENTRY(1, SESSION:PARAMETER)
           cZip     = ENTRY(2, SESSION:PARAMETER)
           cExtract = ENTRY(3, SESSION:PARAMETER).

/* clean slate, so the demo can be run again */
IF File:Exists(cZip)          THEN File:Delete(cZip).
IF Directory:Exists(cExtract) THEN Directory:Delete(cExtract, TRUE).
IF NOT File:Exists(cReadme)   THEN File:WriteAllText(cReadme, "PUG Challenge 2026").

/* slide excerpt start */
ZipFile:CreateFromDirectory(cSource, cZip).
ZipFile:ExtractToDirectory(cZip, cExtract).

ASSIGN oZip = ZipFile:Open(cZip, ZipArchiveMode:Update).
/* C# extension method, called as the static method it really is */
ZipFileExtensions:CreateEntryFromFile(oZip, cReadme, "docs/readme.txt").
oZip:Dispose().

ASSIGN oZip   = ZipFile:Open(cZip, ZipArchiveMode:Read)
       iCount = oZip:Entries:Count.
DO i = 0 TO iCount - 1:
    MESSAGE oZip:Entries[i]:FullName oZip:Entries[i]:Length.
END.
oZip:Dispose().
/* slide excerpt end */

MESSAGE "zip-net   entries:" iCount "  archive:" cZip.

CATCH e AS System.Exception:
    MESSAGE "zip-net FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
