/* demo1.p - slide 19: files and zip, both ways on the same tree.
   Walks 10,000 files with the ABL queue walker and with System.IO.Directory,
   then builds and lists a zip archive with System.IO.Compression.
   Parameter: tree to walk (default /tmp/data/tree). */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.IO.Compression.ZipFile        FROM ASSEMBLY.
USING System.IO.Compression.ZipArchive     FROM ASSEMBLY.
USING System.IO.Compression.ZipArchiveMode FROM ASSEMBLY.
USING System.IO.File                       FROM ASSEMBLY.

DEFINE VARIABLE oZip   AS CLASS ZipArchive NO-UNDO.
DEFINE VARIABLE cTree  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cZip   AS CHARACTER NO-UNDO.
DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
DEFINE VARIABLE iCount AS INTEGER   NO-UNDO.
DEFINE VARIABLE iMs    AS INTEGER   NO-UNDO.

ASSIGN cTree = ENTRY(1, SESSION:PARAMETER) WHEN SESSION:PARAMETER <> "".
IF cTree = "" THEN ASSIGN cTree = "/tmp/data/tree".
ASSIGN cZip = "/tmp/data/in.zip".

MESSAGE "== Demo 1: files and zip ==".
MESSAGE "tree:" cTree.
MESSAGE "".

/* same tree, same FileProcessor, two walkers */
RUN walk-abl.p.
RUN walk-net.p.
MESSAGE "".

/* zip the tree with .NET and list what came out */
IF File:Exists(cZip) THEN File:Delete(cZip).
ASSIGN iMs = ETIME(TRUE).
ZipFile:CreateFromDirectory(cTree, cZip).
ASSIGN iMs = ETIME.

ASSIGN oZip   = ZipFile:Open(cZip, ZipArchiveMode:Read)
       iCount = oZip:Entries:Count.

MESSAGE "zip        entries:" iCount "  ms:" iMs "  archive:" cZip.
MESSAGE "first 10 entries:".
DO i = 0 TO MINIMUM(9, iCount - 1):
    MESSAGE "  " oZip:Entries[i]:FullName oZip:Entries[i]:Length.
END.
oZip:Dispose().

CATCH e AS System.Exception:
    MESSAGE "demo1 FAILED:" e:GetType():FullName SKIP e:Message.
END CATCH.
