## Every styling decision of the page, in one place: its two looks, its fonts, and the CSS of
## the blocks of `blocks.nim`. No other file of the page writes CSS or a colour.
##
## - **Munari** (the base rules: a page without JavaScript is Munari): tabelline's own look, after
##   Bruno Munari, flat paper, one geometric sans (Jost), the Haru palette, the red circle for a
##   place (headings), the square edge for a sheet set apart, the triangle for a warning.
## - **NimConf**, the look a reader sees first (`blocks.nim` sets it): dark, after conf.nim-lang.org as it is in 2026: its background `#1e202a`, its
##   yellow `#ffe953` for headings and links, `#2b2e3b` for every other row, Open Sans and
##   Titillium Web, and its `»` before every item of a list. Every rule of it is scoped by
##   `html[data-look="nimconf"]` and changes only what differs from Munari.
##
## Each look gives six values (paper, ink, primary, secondary, warning, success); every other
## colour is mixed from them. Tables take tabelline's `optCssTheme()`, which reads `--ink`,
## `--paper`, `--line`, `--shade`, `--primary` and `--font` by name, so they follow the look.
import std/[os, strformat, strutils, base64]

const fontDir = currentSourcePath().parentDir / "fonts"

func face(family, file, weight, style: string): string =
  &"@font-face{{font-family:'{family}';src:url(data:font/woff2;base64,{encode(staticRead(fontDir / file))}) format('woff2');" &
    &"font-weight:{weight};font-style:{style};font-display:swap}}\n"

const fonts = face("Jost", "jost-400-normal.woff2", "400", "normal") &
              face("Jost", "jost-400-italic.woff2", "400", "italic") &
              face("Jost", "jost-700-normal.woff2", "700", "normal") &
              face("Open Sans", "open-sans-latin-400-normal.woff2", "400", "normal") &
              face("Open Sans", "open-sans-latin-400-italic.woff2", "400", "italic") &
              face("Open Sans", "open-sans-latin-700-normal.woff2", "700", "normal") &
              face("Titillium Web", "titillium-web-latin-600-normal.woff2", "600", "normal") &
              face("Titillium Web", "titillium-web-latin-700-normal.woff2", "700", "normal")

type Look* = object
  paper*, ink*, primary*, secondary*, warning*, success*: string

const
  haru* = Look(paper: "#FCFAF2", ink: "#1C1C1C", primary: "#E16B8C", secondary: "#7DB9DE",
               warning: "#F7D94C", success: "#86C166")
    ## Munari's palette, Haru (spring), as in tabelline's pages: 白練, 墨, 紅梅, 勿忘草, 菜の花, 苗.
  nimconf* = Look(paper: "#1e202a", ink: "#ffffff", primary: "#ffe953", secondary: "#33C3F0",
                  warning: "#ffe953", success: "#50fa7b")
    ## conf.nim-lang.org's own colours (`variables.min.css`): background, text, the yellow of
    ## headings and links, the blue of its buttons; the green is its neighbour in that theme family.

func lookCss(l: Look): string =
  &"--paper: {l.paper}; --ink: {l.ink}; --primary: {l.primary}; --secondary: {l.secondary}; " &
    &"--warning: {l.warning}; --success: {l.success};"

const tokens = "html {\n" & lookCss(haru) & """
  --shade: color-mix(in oklab, var(--ink) 5%, var(--paper));
  --neutral-1: var(--shade);
  --line: color-mix(in oklab, var(--ink) 22%, var(--paper));
  --muted: color-mix(in oklab, var(--ink) 62%, var(--paper));
  --surface: color-mix(in oklab, #FFFFFF 60%, var(--paper));
  --primary-soft: color-mix(in oklab, var(--primary) 22%, var(--paper));
  --primary-text: color-mix(in oklab, var(--primary) 50%, var(--ink));
  --secondary-soft: color-mix(in oklab, var(--secondary) 22%, var(--paper));
  --secondary-text: color-mix(in oklab, var(--secondary) 50%, var(--ink));
  --warning-soft: color-mix(in oklab, var(--warning) 30%, var(--paper));
  --font: "Jost", "Futura", "Century Gothic", system-ui, sans-serif;
  --heading: var(--font);
  --mono: ui-monospace, "SF Mono", Menlo, Consolas, "DejaVu Sans Mono", monospace;
  --link: var(--primary-text);
  color-scheme: light;
}
html[data-look="nimconf"] {
""" & lookCss(nimconf) & """
  --shade: #2b2e3b;               /* the site's other row */
  --surface: #252834;
  --line: #444858;
  --muted: #a9adbb;
  --primary-text: var(--primary);
  --secondary-text: var(--secondary);
  --font: "Open Sans", system-ui, sans-serif;
  --heading: "Titillium Web", "Open Sans", sans-serif;
  --link: var(--primary);
  color-scheme: dark;
}
"""

# ---------------------------------------------------------------------------------------- Munari

const munari = """
html { -webkit-text-size-adjust: 100%; }
body { margin: 0; background: var(--paper); color: var(--ink); font: 400 17px/1.6 var(--font); }
[hidden] { display: none !important; }
:root { padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left); }
main { max-width: 46rem; margin: 0 auto; padding: 0 1rem 3rem; }
a { color: var(--link); text-decoration-thickness: 1px; text-underline-offset: 2px; }
h1, h2, h3 { font-family: var(--heading); line-height: 1.2; }
h1 { font-size: 2.3rem; margin: .3rem 0 .6rem; letter-spacing: -.01em; }
h2 { font-size: 1.45rem; margin: 2.6rem 0 .6rem; display: flex; align-items: baseline; gap: .55rem; }
h2::before { content: ""; flex: none; width: .62em; height: .62em; border-radius: 50%; background: var(--primary);
  transform: translateY(-.04em); }
h3 { font-size: 1.12rem; margin: 1.8rem 0 .4rem; }
.kicker { margin: 1.6rem 0 0; color: var(--muted); font-size: .95rem; letter-spacing: .02em; }
.lede { font-size: 1.12rem; }
.lede p { margin: .4rem 0 1rem; }
ul { padding-left: 1.3rem; }

/* code: small, highlighted at build time, scrolling inside its own box */
pre { margin: 1rem 0; overflow-x: auto; }
pre > code, pre.nb-output { display: block; overflow-x: auto; padding: .75rem .9rem; }
body pre > code, body pre.nb-output { font: 13px/1.55 var(--mono); }
pre > code { background: var(--surface); border: 2px solid var(--ink); }
pre.nb-output { background: var(--shade); color: var(--ink); white-space: pre; }
pre.nb-output::before { content: "output"; display: block; color: var(--muted); font: 12px var(--font); }
:not(pre) > code { font: .86em var(--mono); background: var(--shade); padding: .05em .3em; }
.hljs-keyword, .hljs-meta { color: #a3365a; font-weight: 700; }
.hljs-string { color: #2f6f2a; }
.hljs-number, .hljs-literal { color: #1f5f8b; }
.hljs-comment { color: #6b6b6b; font-style: italic; }
.hljs-built_in, .hljs-title, .hljs-type { color: #6a3d9a; }

/* tables: the rules come from optCssTheme(); a wide one scrolls inside its box */
.tabella, div[id^="tb"] { overflow-x: auto; }
main table:not(.tb_table) { border-collapse: collapse; }

/* header and footer */
header.page { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: .6rem;
  max-width: 46rem; margin: 0 auto; padding: .8rem 1rem 0; font-size: .92rem; }
.looks { display: inline-flex; border: 1px solid var(--ink); }
.looks button { font: inherit; color: var(--ink); background: transparent; border: 0; min-height: 40px; padding: 0 .8rem; cursor: pointer; }
.looks button[aria-pressed="true"] { background: var(--ink); color: var(--paper); }
footer.page { max-width: 46rem; margin: 0 auto; padding: 1.4rem 1rem 3rem; border-top: 1px solid var(--line); color: var(--muted); font-size: .92rem; }

/* notes: a sheet set apart (its straight top edge); about the code, green; a gap, the triangle */
.note { margin: 1rem 0 1.4rem; padding: .7rem .9rem; background: var(--shade); border-top: 3px solid var(--ink); font-size: .96rem; }
.note > :first-child { margin-top: 0; } .note > :last-child { margin-bottom: 0; }
.note.code { border-top-color: var(--success); }
.note.gap { position: relative; padding-left: 2.6rem; border-top-color: var(--warning); }
.note.gap::before { content: ""; position: absolute; left: .85rem; top: .95rem; width: 0; height: 0;
  border-left: .65rem solid transparent; border-right: .65rem solid transparent; border-bottom: 1.1rem solid var(--warning); }

/* the tabs of the schedules: one button per edition, one table showing */
.tabs-bar { display: flex; flex-wrap: wrap; gap: .3rem; margin: 1rem 0 .4rem; }
.tabs-bar button { font: inherit; font-weight: 700; color: var(--ink); background: transparent; border: 1px solid var(--line);
  min-height: 44px; min-width: 4.2rem; padding: 0 .8rem; cursor: pointer; }
.tabs-bar button[aria-selected="true"] { border-color: var(--ink); box-shadow: inset 0 -4px 0 var(--primary); }
html:not(.js) .tabs-bar { display: none; }

/* code that is shown, not run: a proc of nimconf.nim, with the file it is in */
.source { margin: 1rem 0; }
.source .file { margin: 0 0 -.1rem; font: 12px var(--mono); color: var(--muted); }
.source pre { margin-top: .2rem; }

/* files folded under their name (nbFoldCode) */
details.foldcode { margin: 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
details.foldcode + details.foldcode { border-top: 0; }
details.foldcode:not(:has(+ details.foldcode)) { margin-bottom: 1.6rem; }
details.foldcode > summary { list-style: none; cursor: pointer; padding: .45rem 0; display: flex; gap: .6rem; align-items: baseline; min-height: 44px; box-sizing: border-box; }
details.foldcode > summary::-webkit-details-marker { display: none; }
details.foldcode > summary::before { content: "+"; font-weight: 700; width: .8rem; color: var(--secondary-text); }
details.foldcode[open] > summary::before { content: "−"; }
details.foldcode > summary > span { margin-left: auto; font-size: .8rem; color: var(--muted); white-space: nowrap; }
details.foldcode pre { margin: .2rem 0 .8rem; }
body details.foldcode pre > code { font-size: 12.5px; }
details.foldcode pre > code.language-text { white-space: pre-wrap; overflow-wrap: anywhere; }   /* prose: wrap it */

/* the editions as cards: a square edge each */
.editions { display: grid; grid-template-columns: repeat(auto-fill, minmax(8.5rem, 1fr)); gap: .5rem; margin: 1rem 0; padding: 0; list-style: none; }
.editions li { padding: .5rem .7rem; background: var(--surface); border-top: 3px solid var(--secondary); }
.editions b { display: block; font: 700 1.25rem/1.2 var(--heading); }
.editions span { color: var(--muted); font-size: .9rem; }
"""

# --------------------------------------------------------------------------------------- NimConf

const nimconfLook = """
body { font-size: 16.5px; }
h1, h2, h3 { color: var(--primary); font-weight: 700; }
h2::before { content: "»"; width: auto; height: auto; border-radius: 0; background: none; color: var(--primary); transform: none; }
a { text-decoration: none; }
a:hover { text-decoration: underline; }
ul { list-style: none; padding-left: .2rem; }
ul > li::before { content: "» "; font-weight: 700; margin-right: .3rem; color: var(--primary); }
.editions li::before, .looks li::before { content: none; }
pre > code { border: 1px solid var(--line); border-radius: 4px; }
pre.nb-output { border-radius: 4px; }
.hljs-keyword, .hljs-meta { color: #ff79c6; }
.hljs-string { color: #f1fa8c; }
.hljs-number, .hljs-literal { color: #bd93f9; }
.hljs-comment { color: #8b90a5; }
.hljs-built_in, .hljs-title, .hljs-type { color: #8be9fd; }
.looks { border-color: var(--line); border-radius: 4px; overflow: hidden; }
.looks button[aria-pressed="true"] { background: var(--primary); color: var(--paper); }
.tabs-bar button { border-radius: 4px; }
.tabs-bar button[aria-selected="true"] { border-color: var(--primary); box-shadow: none; background: var(--primary); color: var(--paper); }
.note { border-radius: 2px; }
.note.code { border-top-color: var(--secondary); }     /* the site's blue: green is not of its palette */
.note.gap { background: color-mix(in oklab, var(--warning) 16%, var(--paper)); }
.note.gap strong { color: var(--primary); }
details.foldcode > summary::before { color: var(--primary); }
.editions li { border-top-color: var(--primary); border-radius: 2px; }
"""

func scoped(rules, scope: string): string =
  ## Every rule of `rules` under `scope` (rules are one per line or block, as written above).
  for line in rules.splitLines:
    if line.strip.len == 0: continue
    if line.startsWith(" ") or line.startsWith("/*"): result.add line & "\n"
    else:
      let brace = line.find('{')
      result.add scope & " " & line[0 ..< brace].replace(", ", ", " & scope & " ") & line[brace .. ^1] & "\n"

const pageCss* = fonts & tokens & munari & scoped(nimconfLook, "html[data-look=\"nimconf\"]")
  ## The whole stylesheet of the page.
