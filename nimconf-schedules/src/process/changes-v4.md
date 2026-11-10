# Changes in version 4, after the review of version 3

Published 10 November 2026.

1. The footer says where the source is, as nimib pages do: *Show source* opens `index.nim`,
   folded at the end with the other files, and GitHub has them all with the data. (The review
   mode reads only the page's `<main>`, so a comment cannot be put on the footer.)
2. The first code block prints the first three slots before making a table of them: each is a
   Nim object (`Slot`), and `slots` is a plain `seq[Slot]`, not a data frame.
3. The text says where the length of each video comes from: the YouTube playlist of each
   edition, read by `fetch.nim` into `data/videos.tsv` (step 6 of *How the data was downloaded*).
4. *Every one-track schedule* says that the buttons above the table are tabs, a block of this
   page (`nbTabs`), and that the page's blocks are in `blocks.nim`, folded at the end.
5. A note at the start of *The first schedule* says that this part is about tabelline's code:
   the data's types and procs (`Slot`, `Edition`, `editions`, ...) come from `nimconf.nim`, and
   every file is folded at the end for reference.
