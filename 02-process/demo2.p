/* demo2.p - slide 22: running a process, both ways.
   Same command, same arguments: ls /data /nope (GNU ls exits 2). */
BLOCK-LEVEL ON ERROR UNDO, THROW.

MESSAGE "== Demo 2: running a process ==".
MESSAGE "command: ls /data /nope".
MESSAGE "".
MESSAGE "---------- ABL today: INPUT THROUGH ----------".
RUN run-abl.p.
MESSAGE "".
MESSAGE "---------- .NET: System.Diagnostics.Process ----------".
RUN run-net.p.
