# Changes in version 2, after the review of version 1

Published 10 November 2026, PR #15 (merged with it).

1. Dark mode: the page's own CSS striped every other row of every table, which made the plain
   first table dark text on dark rows. Stripes now come from tabelline (`optRowStriping()` in
   each themed table); the plain table stays white in both looks.
2. NimConf is the look a reader sees first; Munari is one tap away.
3. The notes about code are the site's blue in the NimConf look (green is not of its palette).
4. The note on missing data has a warm yellow tint and a yellow heading in the NimConf look.
5. *How this page is built* ends with the prompt and each review, as they were pasted.
6. Every source file of the page is folded below them (`nbFoldCode`, after tabelline's).
