## The style module of the moiré page: every colour and CSS rule, from named tokens.
## The motif is a glacier on a survey sheet: snow-white paper, slate and glacier-blue inks
## (the two gratings, multiplied where they overlap like two transparencies), rock grey,
## and the red of a surveyor's pin. Under each section title, two striped bars of slightly
## different periods make a little moiré of their own. Fonts: Instrument Serif, Public Sans,
## IBM Plex Mono.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Public+Sans:ital,wght@0,400;0,600;0,700;1,400&family=IBM+Plex+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens* = {
    "--paper": "#f5f8fa", "--snow": "#ffffff", "--ice": "#e3eef3", "--ice-2": "#cfe2ea",
    "--slate": "#16263b", "--muted": "#5a6b7d", "--line": "#c8d6df",
    "--ink-a": "#16263b", "--ink-b": "#155e7d", "--rock": "#8d9095", "--mark": "#d9412f",
    "--mark-soft": "#fbe3de", "--blue-soft": "#dcedf4",
    "--link": "#17698a", "--code-bg": "#eef4f7", "--out-bg": "#16263b", "--out-ink": "#e3eef3",
    "--kw": "#a8336b", "--str": "#2d7a3e", "--num": "#b4521c", "--com": "#7b8a99", "--type": "#1f6c8c",
    # the names the review mode (shared/review, tabelline's) reads, from this page's own
    "--ink": "#16263b", "--surface": "#ffffff", "--shade": "#dbe7ee",
    "--secondary": "#1f7a9c", "--secondary-soft": "#dcedf4", "--primary-text": "#d9412f", "--neutral-1": "#e3eef3",
    "--serif": "\"Instrument Serif\", Georgia, serif",
    "--font": "\"Public Sans\", system-ui, sans-serif", "--mono": "\"IBM Plex Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%;background:var(--paper)}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--slate);font:400 17px/1.62 var(--font)}
h1{font:400 2.6rem/1.05 var(--serif);margin:1.2rem 0 .5rem;letter-spacing:-.01em}
h1 em{color:var(--ink-b)}
h2{font:400 1.85rem/1.15 var(--serif);margin:3rem 0 .7rem;padding-bottom:.55rem;position:relative}
h2::after{content:"";position:absolute;left:0;bottom:0;width:min(100%,18rem);height:7px;
  background:repeating-linear-gradient(90deg,var(--ink-a) 0 2px,transparent 2px 4px),
             repeating-linear-gradient(90deg,var(--ink-b) 0 2px,transparent 2px 4.3px);opacity:.75}
h3{font:600 1.05rem/1.3 var(--font);margin:1.8rem 0 .4rem}
a{color:var(--link);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--code-bg);padding:0 .25em;border-radius:3px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0;color:inherit}
hr{border:0;border-top:1px solid var(--line)}
.lede{font-size:1.12rem;line-height:1.55}
.lede p:first-child{margin-top:.2rem}

/* the widgets */
.widget{margin:1.2rem -.4rem;padding:.6rem .6rem .8rem;background:var(--snow);border:1px solid var(--line);border-radius:10px;
  box-shadow:0 1px 0 var(--line)}
.widget canvas{display:block;width:100%;height:auto;border-radius:6px;background:var(--paper)}
.widget canvas.drag-x{touch-action:pan-y;cursor:ew-resize}
.widget canvas.drag-xy{touch-action:none;cursor:crosshair}
.widget .out{margin:.55rem .2rem .2rem;font:14px/1.4 var(--mono);color:var(--slate);min-height:1.4em}
.widget .out b{color:var(--mark)}
.widget figcaption{margin:.4rem .2rem 0;font-size:.88rem;line-height:1.45;color:var(--muted)}
.ctl{display:flex;align-items:center;gap:.6rem;margin:.55rem .2rem 0;flex-wrap:wrap}
.ctl label{font-size:.9rem;min-width:5.5rem}
.ctl output{font:13px var(--mono);min-width:4.5rem;text-align:right}
.ctl input[type=range]{flex:1;min-width:9rem;height:2.2rem;accent-color:var(--ink-b)}
.btns{display:flex;gap:.45rem;flex-wrap:wrap;margin:.55rem .2rem 0}
.btns button{font:600 .88rem var(--font);padding:.6rem .85rem;min-height:2.75rem;border-radius:999px;
  border:1px solid var(--ink-b);background:var(--snow);color:var(--ink-b);cursor:pointer}
.btns button[aria-pressed=true]{background:var(--ink-b);color:var(--snow)}
.hint{font-size:.8rem;color:var(--muted);margin:.35rem .2rem 0}

/* notes */
.note{margin:1.2rem 0;padding:.75rem 1rem;border-left:4px solid var(--ink-b);background:var(--blue-soft);border-radius:0 8px 8px 0}
.note.careful{border-color:var(--mark);background:var(--mark-soft)}
.note.nim{border-color:var(--ink-a);background:var(--ice)}
.note-label{display:block;font:600 .72rem/1 var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-bottom:.35rem}
.note p{margin:.3rem 0}

/* formulas, shown big and plain */
.formula{font:400 1.35rem/1.3 var(--serif);text-align:center;margin:1rem 0;padding:.6rem;background:var(--ice);border-radius:8px}
.formula small{display:block;font:13px/1.4 var(--font);color:var(--muted);margin-top:.2rem}

/* code: small, scrolls inside its box, highlighted at build time */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:8px;padding:.7rem .8rem;margin:.8rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.5 var(--mono);background:none;padding:0;color:var(--slate)}
body pre.nb-output{background:var(--out-bg);color:var(--out-ink);font:13px/1.5 var(--mono);border:0;margin-top:-.4rem}
.hljs-keyword,.hljs-built_in,.hljs-literal{color:var(--kw)}
.hljs-string{color:var(--str)}
.hljs-number{color:var(--num)}
.hljs-comment{color:var(--com);font-style:italic}
.hljs-type,.hljs-title{color:var(--type)}
details{margin:.6rem 0}
details summary{cursor:pointer;font-weight:600}

/* tables are tabelline's (shared look): only its variables are set here, to the glacier palette */
.tabella{--tb-table-background-color:var(--snow);--tb-table-font-color:var(--slate);--tb-table-font-names:var(--font);--tb-table-font-size:14.5px;
  --tb-heading-color:var(--slate);--tb-column-labels-color:var(--slate);
  --tb-row-striping-background-color:var(--paper);
  --tb-table-border-top-color:var(--ink-b);--tb-table-border-bottom-color:var(--ink-b);
  --tb-column-labels-border-bottom-color:var(--ink-b);--tb-table-body-hlines-color:var(--line);margin:.9rem 0}
.tabella td,.tabella th{vertical-align:top;line-height:1.4}
.table-wrap{overflow-x:auto}
td code,th code{font-size:12px}
"""

proc useMoireStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's own
  ## CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  var root = ":root{color-scheme:light;"
  for (name, value) in tokens:
    root.add name & ":" & value & ";"
  root.add "}"
  nb.doc.context["stylesheet"] = %(fonts & "<style>" & root & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
