/* hello.p - .NET runtime identification (slide 15) */
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING System.Runtime.InteropServices.RuntimeInformation FROM ASSEMBLY.

/* slide excerpt start */
MESSAGE "OS:    " RuntimeInformation:OSDescription.
MESSAGE "FW:    " RuntimeInformation:FrameworkDescription.
MESSAGE "Arch:  " RuntimeInformation:ProcessArchitecture:ToString().
/* slide excerpt end */
