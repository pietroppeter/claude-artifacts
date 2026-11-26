## The style module of the Puščica page: every colour and CSS rule, from named tokens.
## Six looks, picked at the top of the page (widgets.nim sets <html data-theme=...>). Each one
## borrows the palette, textures and lettering mood of a Slovenian illustrator or artist;
## none copies a picture:
##   reichman  Jelka Reichman: watercolour washes on white paper, rose, sky, leaf (the default)
##   stupica   Marlenka Stupica: storybook cream, brick red, ochre, forest green, old serif type
##   prap      Lila Prap: flat, bold, saturated shapes with thick black outlines
##   gaspari   Maksim Gaspari: folk ornament, carnation red and deep green on linen
##   mancek    Marjan Manček: black ink line on white, one spot colour, wobbly hand-drawn boxes
##   cernigoj  Avgust Černigoj: Trieste constructivism, red, black and cream, hard diagonals
## Fonts (Google Fonts, all with č š ž): Caveat, Nunito, EB Garamond, Fredoka, Alegreya,
## Kalam, Archivo Black, Space Grotesk, JetBrains Mono.
import std/[json, strutils]
import nimib

type Theme* = object
  id*, name*, who*, blurb*: string
  vars*: seq[(string, string)]
  extra*: string                ## theme-only rules (decorations), every selector under the theme

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Caveat:wght@500;700&family=Nunito:ital,wght@0,400;0,700;1,400&family=EB+Garamond:ital,wght@0,400;0,600;1,400&family=Fredoka:wght@500;600&family=Alegreya:ital,wght@0,400;0,700;1,400&family=Kalam:wght@400;700&family=Archivo+Black&family=Space+Grotesk:wght@400;600&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""

  # what every theme starts from (and what the code highlighting and the review mode read)
  base = @{
    "--paper": "#fffdf8", "--surface": "#ffffff", "--ink": "#33404d", "--muted": "#6b7682", "--line": "#dfe3e6",
    "--a1": "#6f9fcf", "--a2": "#e59a9a", "--a3": "#8fbf7f", "--a4": "#e8c46a",
    "--a1-soft": "#e6f0f9", "--a2-soft": "#fbeaea", "--a3-soft": "#ebf4e6", "--a4-soft": "#fbf2da",
    "--sel": "#f4c86a", "--sel-ink": "#2a2a2a", "--link": "#3f78b0",
    "--code-bg": "#f6f7f8", "--out-bg": "#33404d", "--out-ink": "#f2f4f5",
    "--kw": "#b0426e", "--str": "#3d7f42", "--num": "#b4621c", "--com": "#8a949c", "--type": "#2f6f9f",
    "--head": "\"Caveat\", cursive", "--head-size": "1.25", "--font": "\"Nunito\", system-ui, sans-serif",
    "--mono": "\"JetBrains Mono\", ui-monospace, monospace",
    "--radius": "14px", "--bw": "1px", "--shadow": "0 2px 10px rgba(60,80,100,.08)",
    # the names the review mode (shared/review, tabelline's) reads
    "--shade": "#e8eef2", "--secondary": "#3f78b0", "--secondary-soft": "#e6f0f9", "--primary-text": "#b0426e",
    "--neutral-1": "#f1f3f4"}

  themes* = [
    Theme(id: "reichman", name: "Reichman", who: "Jelka Reichman",
      blurb: "soft watercolour washes, lots of white paper",
      vars: @{"--paper": "#fffdf8", "--a1": "#7fb0db", "--a2": "#eba3a8", "--a3": "#9cc98a", "--a4": "#f0cf7a",
              "--sel": "#f6d27e", "--link": "#3d77ad"},
      extra: """
html[data-theme=reichman] body{background:
  radial-gradient(38rem 26rem at 105% -4%, rgba(235,163,168,.26), transparent 70%),
  radial-gradient(30rem 22rem at -10% 18%, rgba(127,176,219,.22), transparent 70%),
  radial-gradient(34rem 24rem at 110% 55%, rgba(156,201,138,.20), transparent 70%),
  radial-gradient(28rem 22rem at -8% 85%, rgba(240,207,122,.22), transparent 70%), var(--paper);background-attachment:scroll}
html[data-theme=reichman] h2::after{background:radial-gradient(closest-side, rgba(127,176,219,.55), transparent);height:14px;border-radius:50%}
html[data-theme=reichman] h1{color:#3d5f86}
"""),
    Theme(id: "stupica", name: "Stupica", who: "Marlenka Stupica",
      blurb: "storybook cream, brick red, ochre and forest green",
      vars: @{"--paper": "#f7efdc", "--surface": "#fffaf0", "--ink": "#2e241b", "--muted": "#76624b", "--line": "#e2d3b4",
              "--a1": "#a8432f", "--a2": "#c99a35", "--a3": "#4b6b43", "--a4": "#7c5a8a",
              "--a1-soft": "#f3ddd3", "--a2-soft": "#f6ead0", "--a3-soft": "#e2ead8", "--a4-soft": "#ece2f0",
              "--sel": "#e7b54a", "--link": "#9a3a28", "--code-bg": "#fbf5e8", "--out-bg": "#3b2e22",
              "--head": "\"EB Garamond\", Georgia, serif", "--head-size": "1", "--font": "\"EB Garamond\", Georgia, serif",
              "--radius": "6px", "--shadow": "0 1px 0 #e2d3b4"},
      extra: """
html[data-theme=stupica] body{font-size:18.5px}
html[data-theme=stupica] h1,html[data-theme=stupica] h2{font-style:italic;color:#7a2f20}
html[data-theme=stupica] h2::after{height:8px;background:
  repeating-linear-gradient(90deg,#a8432f 0 6px,transparent 6px 9px,#c99a35 9px 12px,transparent 12px 15px,#4b6b43 15px 21px,transparent 21px 24px)}
"""),
    Theme(id: "prap", name: "Prap", who: "Lila Prap",
      blurb: "flat bold colours, thick black outlines",
      vars: @{"--paper": "#fff8e1", "--surface": "#ffffff", "--ink": "#161616", "--muted": "#4b4b4b", "--line": "#161616",
              "--a1": "#1e6fd9", "--a2": "#e8392b", "--a3": "#23a24d", "--a4": "#ffcf1f",
              "--a1-soft": "#d6e6fb", "--a2-soft": "#fbdcd8", "--a3-soft": "#d6f0de", "--a4-soft": "#fff1b8",
              "--sel": "#ffcf1f", "--link": "#1e6fd9",
              "--head": "\"Fredoka\", system-ui, sans-serif", "--head-size": "1.05",
              "--radius": "18px", "--bw": "3px", "--shadow": "5px 5px 0 #161616"},
      extra: """
html[data-theme=prap] h1{color:#e8392b;text-shadow:3px 3px 0 #ffcf1f}
html[data-theme=prap] h2::after{height:12px;border-radius:6px;background:linear-gradient(90deg,#1e6fd9 0 25%,#e8392b 25% 50%,#23a24d 50% 75%,#ffcf1f 75%)}
"""),
    Theme(id: "gaspari", name: "Gaspari", who: "Maksim Gaspari",
      blurb: "folk ornament, carnation red and deep green on linen",
      vars: @{"--paper": "#f3eee2", "--surface": "#fbf8f0", "--ink": "#2b2620", "--muted": "#6f6555", "--line": "#d9cfb9",
              "--a1": "#b8322a", "--a2": "#2f5e3f", "--a3": "#c98b2b", "--a4": "#2c5a86",
              "--a1-soft": "#f2d9d5", "--a2-soft": "#dbe6dc", "--a3-soft": "#f3e4c9", "--a4-soft": "#d9e4ef",
              "--sel": "#e9b04f", "--link": "#a12b23",
              "--head": "\"Alegreya\", Georgia, serif", "--head-size": "1", "--font": "\"Alegreya\", Georgia, serif",
              "--radius": "10px"},
      extra: """
html[data-theme=gaspari] body{font-size:18px}
html[data-theme=gaspari] h1,html[data-theme=gaspari] h2{color:#2f5e3f;font-weight:700}
html[data-theme=gaspari] h2::after{height:12px;background:
  radial-gradient(circle at 6px 6px,#b8322a 0 4px,transparent 4.5px) 0 0/24px 12px,
  radial-gradient(circle at 18px 6px,#2f5e3f 0 2.5px,transparent 3px) 0 0/24px 12px}
"""),
    Theme(id: "mancek", name: "Manček", who: "Marjan Manček",
      blurb: "black ink line, one spot colour, hand-drawn boxes",
      vars: @{"--paper": "#ffffff", "--surface": "#ffffff", "--ink": "#111111", "--muted": "#555555", "--line": "#111111",
              "--a1": "#4aa3df", "--a2": "#111111", "--a3": "#4aa3df", "--a4": "#9a9a9a",
              "--a1-soft": "#e3f1fb", "--a2-soft": "#eeeeee", "--a3-soft": "#e3f1fb", "--a4-soft": "#f2f2f2",
              "--sel": "#4aa3df", "--sel-ink": "#ffffff", "--link": "#1c6fa8",
              "--head": "\"Kalam\", cursive", "--head-size": "1.05", "--font": "\"Kalam\", cursive",
              "--radius": "255px 15px 225px 15px / 15px 225px 15px 255px", "--bw": "2px", "--shadow": "none"},
      extra: """
html[data-theme=mancek] body{font-size:17.5px;line-height:1.55}
html[data-theme=mancek] h2::after{height:4px;border-radius:50%;background:#111;transform:rotate(-.6deg)}
"""),
    Theme(id: "cernigoj", name: "Černigoj", who: "Avgust Černigoj",
      blurb: "constructivist red, black and cream (Kosovel's Konsi)",
      vars: @{"--paper": "#efe7d4", "--surface": "#f8f3e6", "--ink": "#121212", "--muted": "#5a554b", "--line": "#121212",
              "--a1": "#d3261c", "--a2": "#121212", "--a3": "#7d7a70", "--a4": "#e0a01e",
              "--a1-soft": "#f3d3cf", "--a2-soft": "#e2ddd0", "--a3-soft": "#e8e4d8", "--a4-soft": "#f4e3bd",
              "--sel": "#d3261c", "--sel-ink": "#ffffff", "--link": "#b81f17",
              "--head": "\"Archivo Black\", Impact, sans-serif", "--head-size": ".82",
              "--font": "\"Space Grotesk\", system-ui, sans-serif",
              "--radius": "0", "--bw": "2px", "--shadow": "none"},
      extra: """
html[data-theme=cernigoj] h1,html[data-theme=cernigoj] h2{text-transform:uppercase;letter-spacing:.02em}
html[data-theme=cernigoj] h1{border-left:14px solid #d3261c;padding-left:.5rem}
html[data-theme=cernigoj] h2::after{height:10px;background:linear-gradient(100deg,#121212 0 60%,transparent 60% 64%,#d3261c 64%)}
html[data-theme=cernigoj] body{background:linear-gradient(115deg,transparent 0 82%,rgba(211,38,28,.10) 82% 86%,transparent 86%) fixed,var(--paper)}
""")]

  css = """
html{-webkit-text-size-adjust:100%;background:var(--paper)}
body{margin:0 auto;max-width:44rem;padding:.6rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 17px/1.62 var(--font)}
h1{font:700 calc(2.7rem * var(--head-size))/1.05 var(--head);margin:1.1rem 0 .5rem}
h2{font:700 calc(2rem * var(--head-size))/1.15 var(--head);margin:2.8rem 0 .7rem;padding-bottom:.6rem;position:relative}
h2::after{content:"";position:absolute;left:0;bottom:0;width:min(100%,16rem);height:8px}
h3{font:700 1.08rem/1.3 var(--font);margin:1.8rem 0 .4rem}
a{color:var(--link);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--code-bg);padding:0 .25em;border-radius:3px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0;color:inherit}
hr{border:0;border-top:1px solid var(--line)}
.lede{font-size:1.12rem;line-height:1.55}
.lede p:first-child{margin-top:.2rem}
[hidden]{display:none!important}

/* the illustrator picker */
.themes{margin:.4rem 0 .2rem;padding:.55rem .6rem;background:var(--surface);border:var(--bw) solid var(--line);border-radius:var(--radius)}
.themes p{margin:0 0 .4rem;font-size:.82rem;color:var(--muted)}
.themes .row{display:flex;gap:.4rem;overflow-x:auto;padding-bottom:.2rem;scrollbar-width:thin}
.themes button{flex:0 0 auto;font:600 .85rem var(--font);padding:.5rem .75rem;min-height:2.75rem;border-radius:999px;
  border:var(--bw) solid var(--line);background:var(--paper);color:var(--ink);cursor:pointer}
.themes button[aria-pressed=true]{background:var(--ink);color:var(--paper)}
.themes button small{display:block;font-weight:400;font-size:.7rem;opacity:.8}

/* poems */
.poem{margin:1.2rem 0;padding:.9rem 1.1rem;background:var(--surface);border:var(--bw) solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow)}
.poem h4{margin:0 0 .4rem;font:700 calc(1.4rem * var(--head-size))/1.2 var(--head)}
.poem .verse{white-space:pre-wrap;font:italic 400 1.02rem/1.55 var(--font)}
.poem .src{margin:.5rem 0 0;font-size:.78rem;color:var(--muted)}

/* the layout explorer */
.explorer{margin:1.2rem -.4rem;padding:.7rem .7rem .9rem;background:var(--surface);border:var(--bw) solid var(--line);
  border-radius:var(--radius);box-shadow:var(--shadow)}
.explorer select{width:100%;font:600 .95rem var(--font);padding:.55rem .5rem;min-height:2.75rem;border-radius:10px;
  border:var(--bw) solid var(--line);background:var(--paper);color:var(--ink)}
.btns{display:flex;gap:.4rem;flex-wrap:wrap;margin:.55rem 0 0}
.btns button{font:600 .85rem var(--font);padding:.5rem .75rem;min-height:2.75rem;border-radius:999px;
  border:var(--bw) solid var(--a1);background:var(--surface);color:var(--ink);cursor:pointer}
.btns button[aria-pressed=true]{background:var(--a1);color:#fff;border-color:var(--a1)}
.btns .sep{flex-basis:100%;height:0}
.ctl{display:flex;align-items:center;gap:.6rem;margin:.5rem 0 0;flex-wrap:wrap}
.ctl label{font-size:.88rem;min-width:4.5rem}
.ctl output{font:13px var(--mono);min-width:2.5rem;text-align:right}
.ctl input[type=range]{flex:1;min-width:8rem;height:2.2rem;accent-color:var(--a1)}
.sec{margin:.8rem 0 .2rem;font:700 .72rem/1 var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
.values{display:flex;flex-wrap:wrap;gap:.3rem;max-height:13rem;overflow-y:auto;padding:.1rem}
.chip{font:400 .86rem/1.25 var(--font);padding:.35rem .55rem;min-height:2.2rem;border-radius:10px;border:1px solid var(--line);
  background:var(--paper);color:var(--ink);cursor:pointer;text-align:left}
.chip small{font:11px var(--mono);color:var(--muted);margin-right:.35rem}
.chip.null{font-style:italic;color:var(--muted);border-style:dashed}
.chip.sel{background:var(--sel);color:var(--sel-ink);border-color:var(--sel)}
.chip.sel small{color:inherit}
.chip.dim{opacity:.35}
.lay{margin:.6rem 0 0}
.lay-h{font:700 .9rem var(--font);margin:.2rem 0}
.lay-h code{font-size:12px}
.buf{margin:.35rem 0 .55rem;padding:.4rem .45rem;border-radius:10px;background:var(--a1-soft)}
.buf:nth-of-type(3n+2){background:var(--a3-soft)}
.buf:nth-of-type(3n){background:var(--a4-soft)}
.buf-h{font:12px var(--mono);color:var(--muted);margin-bottom:.25rem}
.buf-h b{color:var(--ink)}
.cells{display:flex;flex-wrap:wrap;gap:2px;max-height:17rem;overflow-y:auto;overscroll-behavior:contain}
.cell{display:inline-flex;flex-direction:column;align-items:center;justify-content:center;min-width:1.35rem;height:1.9rem;padding:0 .2rem;
  font:13px/1 var(--mono);background:var(--surface);border-radius:4px;color:var(--ink);cursor:pointer;box-sizing:border-box}
.cell small{font-size:8.5px;color:var(--muted);margin-top:2px;white-space:nowrap}
.cell i{font-style:normal}
.cell.int{min-width:2.4rem;font-weight:600}
.cell.bit{min-width:1.1rem}
.cell.b0{color:var(--a2);font-weight:700}
.cell.mb{background:var(--a2-soft);outline:1px dashed var(--a2)}
.cell.mb2{min-width:2.3rem}.cell.mb3{min-width:3.2rem}.cell.mb4{min-width:4.1rem}
.cell.ch{min-width:1.35rem}
.cell.view{flex-direction:row;gap:.25rem;min-width:9.5rem;justify-content:flex-start;padding:0 .35rem}
.cell .vlen{font-weight:700;color:var(--a1)}
.cell .vinl{white-space:pre}
.cell .vpad{color:var(--muted);letter-spacing:-.15em}
.cell .vpre{white-space:pre}
.cell .vref{font-size:11px;color:var(--a2)}
.cell.pad{color:var(--muted);cursor:default}
.cell.sel{background:var(--sel);color:var(--sel-ink);outline:2px solid var(--ink)}
.cell.sel small{color:inherit}
.cell.dim{opacity:.3}
.empty{font:12px var(--mono);color:var(--muted);font-style:italic}
.explorer .out{margin:.6rem 0 0;font-size:.92rem;line-height:1.45;min-height:1.4em}
.sizes{margin:.5rem 0 0;display:grid;gap:.2rem}
.size{display:grid;grid-template-columns:6.2rem 1fr 3.6rem;align-items:center;gap:.4rem;font:12px var(--mono)}
.size i{display:block;height:.7rem;border-radius:4px;background:var(--a1);opacity:.45}
.size.on i{opacity:1}
.size.on span{font-weight:700}
.size b{text-align:right}
.explorer figcaption{margin:.55rem 0 0;font-size:.86rem;line-height:1.45;color:var(--muted)}
.hint{font-size:.8rem;color:var(--muted);margin:.35rem 0 0}

/* notes */
.note{margin:1.2rem 0;padding:.75rem 1rem;border-left:5px solid var(--a1);background:var(--a1-soft);border-radius:0 var(--radius) var(--radius) 0}
.note.careful{border-color:var(--a2);background:var(--a2-soft)}
.note.nim{border-color:var(--a3);background:var(--a3-soft)}
.note.people{border-color:var(--a4);background:var(--a4-soft)}
.note-label{display:block;font:700 .72rem/1 var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-bottom:.35rem}
.note p{margin:.3rem 0}

/* a diagram: rows vs columns */
.rc{display:grid;grid-template-columns:1fr;gap:.6rem;margin:1rem 0}
.rc .box{background:var(--surface);border:var(--bw) solid var(--line);border-radius:var(--radius);padding:.5rem .6rem}
.rc .box b{display:block;font-size:.85rem;margin-bottom:.3rem}
.rc .strip{display:flex;flex-wrap:wrap;gap:2px}
.rc .strip span{font:12px/1.6 var(--mono);padding:0 .3rem;border-radius:3px}
.rc .t{background:var(--a1-soft)}.rc .k{background:var(--a3-soft)}.rc .w{background:var(--a4-soft)}

/* code: small, scrolls inside its box, highlighted at build time */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:8px;padding:.7rem .8rem;margin:.8rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.5 var(--mono);background:none;padding:0;color:var(--ink)}
body pre.nb-output{background:var(--out-bg);color:var(--out-ink);font:12.5px/1.45 var(--mono);border:0;margin-top:-.4rem;white-space:pre}
.hljs-keyword,.hljs-built_in,.hljs-literal{color:var(--kw)}
.hljs-string{color:var(--str)}
.hljs-number{color:var(--num)}
.hljs-comment{color:var(--com);font-style:italic}
.hljs-type,.hljs-title{color:var(--type)}
details{margin:.6rem 0}
details summary{cursor:pointer;font-weight:700}

/* tables are tabelline's (shared look): only its variables are set here */
.tabella{--tb-table-background-color:var(--surface);--tb-table-font-color:var(--ink);--tb-table-font-names:var(--font);--tb-table-font-size:14.5px;
  --tb-heading-color:var(--ink);--tb-column-labels-color:var(--ink);
  --tb-row-striping-background-color:var(--paper);
  --tb-table-border-top-color:var(--a1);--tb-table-border-bottom-color:var(--a1);
  --tb-column-labels-border-bottom-color:var(--a1);--tb-table-body-hlines-color:var(--line);margin:.9rem 0}
.tabella td,.tabella th{vertical-align:top;line-height:1.4}
.table-wrap{overflow-x:auto}
td code,th code{font-size:12px}
"""

proc themeCss(): string =
  result = ":root{color-scheme:light;"
  for (k, v) in base: result.add k & ":" & v & ";"
  result.add "}\n"
  for t in themes:
    result.add "html[data-theme=" & t.id & "]{"
    for (k, v) in t.vars: result.add k & ":" & v & ";"
    result.add "}\n" & t.extra

proc usePuscicaStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's own
  ## CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  nb.doc.context["stylesheet"] = %(fonts & "<style>" & themeCss() & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
