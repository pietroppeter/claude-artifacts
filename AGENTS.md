# claude-artifacts

Static pages made with Claude, served by GitHub Pages from `main` (root). No build step.

## Adding a page
- One folder per page, kebab-case slug: `<slug>/index.html`.
- `index.html` must be a complete standalone document (`<!doctype html>`, `<html lang>`, `<head>` with charset + viewport meta, `<title>`, `<body>`).
  claude.ai artifact sources are fragments (no doctype/head/body) — wrap them; include the small reset the artifact skeleton provides
  (`body{margin:0}`, `[hidden]{display:none!important}`, safe-area padding on `:root`).
- No runtime dependency on claude.ai: no `window.claude.*` capabilities. If a page relied on them, replace with static data or drop the feature.
- Put any scripts/data used to generate the page in `<slug>/src/` so it can be regenerated.
- Add an entry (newest first) to both the root `index.html` list and the `README.md` table.
- After adding or regenerating any page, run the post-build tools, in this order:
  ```
  pip install pygments              # once
  python3 tools/codeblocks.py       # highlight every code block, make it scroll inside its box
  python3 tools/backlink.py         # "← Claude artifacts" link + -webkit-text-size-adjust
  node tools/phonecheck.js          # check code blocks at 390px; must print only ✓
  ```
  `backlink.py` adds the small link back to the index before `</body>`, plus `-webkit-text-size-adjust:100%` on `html`;
  `codeblocks.py` adds a style block before `</head>` and highlights blocks at build time (both between marker comments; re-running replaces, never duplicates).
  Page generators (`src/build.py`, nimib `index.nim`) overwrite `index.html`, so run them again after every rebuild.
  Don't hand-edit or restyle the link inside a page: change `tools/backlink.py` and re-run it on all pages.
- Keep the root `index.html` in its basic style: a card grid with one `<li>` per page (link to `<slug>/index.html`, not `<slug>/`, so branch previews and local files work too; `<time>`, short description `<p>`; the card clamps it to four lines), no per-page theming.
- CI (`.github/workflows/check-pages.yml`) fails if any page lacks the current back-link, has an unhighlighted code block,
  or is missing from `index.html` or `README.md`. Run `python3 tools/backlink.py --check && python3 tools/codeblocks.py --check` before pushing.
- Pages here are public: check with Pietro before adding anything with personal or private data.

## Review mode
- A page with a **✎ Review** button uses the one copy in `shared/review/` (tabelline's review mode, copied unchanged;
  `shared/review/README.md` says how a page imports it). Don't copy it into a page or edit it here: change it in
  tabelline, run `sh shared/review/sync.sh`, then rebuild every page listed in that README and republish them.

## Sharing a page with Pietro
- Every reply that delivers or updates a page links to it, rendered. Don't send only the PR.
- Publish the built `<slug>/index.html` as a claude.ai Artifact, and republish to the same artifact whenever the page changes.
  Put the artifact link in the reply, along with the PR and the GitHub Pages URL
  (`https://pietroppeter.github.io/claude-artifacts/<slug>/`, which is live after merge).
- If the artifact can't be published, link a branch preview instead:
  `https://raw.githack.com/pietroppeter/claude-artifacts/<branch>/<slug>/index.html`.

## Page style
- Pick a visual style that fits each explainer's subject: palette, typefaces, motifs. Don't reuse the previous page's theme by default.
- Code blocks are where pages keep breaking on a phone. `tools/phonecheck.js` checks all of this; the rules behind it:
  - Keep code small: 12.5–13px for code blocks and outputs, smaller than body text. nimib's own head style sets
    `pre > code {font-size:1.2em}` *after* your theme, so a theme rule `pre code {font: 13px ...}` loses (that gave 20px code).
    Write code rules as `body pre > code` (and `body pre.nb-output`). Water.css and other base themes do the same thing.
  - Every block scrolls sideways inside its own box. Put `overflow-x:auto` on `pre` (including `pre.nb-output`, which has
    no `<code>` inside) and on `pre > code`: if `code` is `display:block` with its own background or border and only `pre`
    scrolls, the box stops at the screen edge and the text runs on past it. `codeblocks.py` adds both rules.
  - Highlight every code block, at build time. claude.ai artifacts may block CDN scripts and styles, and the CDN highlight.js has no Nim
    grammar, so client-side highlighting shows plain text there. nimib's `nbCode` blocks are already highlighted
    (`highlightNim`); markdown fences, raw `<pre>`, and non-nimib pages are done by `codeblocks.py` (Pygments, emitting the same
    `hljs-*` classes). Give non-Nim blocks a `language-X` class on `<code>`; mark output blocks `pre.out`, `pre.nb-output`
    or `code.language-text` so they are left plain. If the page has no `.hljs-*` colours, `codeblocks.py` adds a light theme;
    a dark-code page should bring its own.
  - Check a phone-width screenshot before publishing, and publish only after `phonecheck.js` passes.

## When a source can't be read
- If a site is blocked by the environment's network policy, tell Pietro what couldn't be read and give him a copy-pastable
  list of the hosts to allow, one per line in a code block. He decides whether to add them.
