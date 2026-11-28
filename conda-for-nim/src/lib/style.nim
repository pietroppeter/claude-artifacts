## The style module of the conda-for-nim explainer: every colour and CSS rule, from named tokens.
## The look borrows from prefix.dev and pixi's own decks: warm paper, ink-black type, one
## loud yellow (the marker that underlines "language-agnostic" on Wolf's slide), a chunky soft
## serif for titles, a handwritten kicker, and dark terminals with a yellow prompt.
## Fonts: Fraunces (titles), Caveat (handwriting), Inter (text), JetBrains Mono (code).
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght,SOFT@9..144,600..900,100&family=Caveat:wght@500;700&family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#f7f3ea", "--paper-2": "#efe9da", "--card": "#fffdf8", "--ink": "#141412", "--muted": "#5f5b51",
    "--line": "#ded6c3", "--yellow": "#ffc61a", "--yellow-soft": "#fff1c2", "--yellow-deep": "#b98a00",
    "--term": "#17171a", "--term-2": "#222226", "--term-ink": "#ecebe6", "--term-dim": "#9a988f",
    "--green": "#2f8f5b", "--green-soft": "#e3f2e8", "--red": "#c8442f", "--red-soft": "#fbe6e1",
    "--blue": "#2d5fa8", "--blue-soft": "#e4ecf8", "--crown": "#e0a100",
    "--code-bg": "#fffaf0", "--kw": "#a8361f", "--str": "#2f7a3d", "--num": "#9a6a00", "--com": "#8a857a", "--type": "#2d5fa8",
    # the names the review mode (shared/review, tabelline's) reads
    "--surface": "#fffdf8", "--shade": "#efe9da", "--secondary": "#b98a00", "--secondary-soft": "#fff1c2",
    "--primary-text": "#a8361f", "--neutral-1": "#efe9da",
    "--serif": "Fraunces, Georgia, serif", "--hand": "Caveat, \"Comic Sans MS\", cursive",
    "--font": "Inter, system-ui, sans-serif", "--mono": "\"JetBrains Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%;background:var(--paper)}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 16.5px/1.62 var(--font);counter-reset:step}
h1{font:900 2.35rem/1.05 var(--serif);font-variation-settings:"SOFT" 100;margin:.3rem 0 .5rem;letter-spacing:-.01em}
h1 .mark,.mark{background:linear-gradient(transparent 62%,var(--yellow) 62%,var(--yellow) 92%,transparent 92%);padding:0 .1em}
h2{font:800 1.55rem/1.15 var(--serif);font-variation-settings:"SOFT" 100;margin:3.2rem 0 .7rem;counter-increment:step}
h2::before{content:counter(step,decimal-leading-zero);display:block;width:max-content;font:700 .78rem/1 var(--mono);color:var(--ink);
  background:var(--yellow);padding:.3rem .5rem;border-radius:999px;margin-bottom:.5rem}
h3{font:700 1.15rem/1.3 var(--serif);margin:1.8rem 0 .4rem}
h2[id],h3[id]{scroll-margin-top:1rem}
.toc-up{font:600 .78rem/1 var(--font);color:var(--muted);text-decoration:none;white-space:nowrap;margin-left:.3rem;vertical-align:middle}
.toc-up:hover,.toc-up:focus-visible{color:var(--ink);text-decoration:underline}
.toc{margin:1.6rem 0;padding:.2rem 1rem .6rem;background:var(--card);border:1px solid var(--line);border-radius:14px}
.toc-label{display:block;font:700 1.35rem/1 var(--hand);margin-top:.6rem}
.toc ol{margin:.4rem 0;padding-left:1.4rem;font-size:.95rem}
.toc ol ol{list-style:disc;font-size:.9rem;margin:.15rem 0 .3rem}
.toc li{margin:.18rem 0}
.toc a{text-decoration:none}
.toc a:hover,.toc a:focus-visible{text-decoration:underline}
.kicker{font:700 1.45rem/1 var(--hand);color:var(--muted);margin:1.4rem 0 0;transform:rotate(-1.5deg);transform-origin:left}
a{color:var(--ink);text-decoration-color:var(--yellow-deep);text-decoration-thickness:2px;text-underline-offset:3px}
a:hover{background:var(--yellow-soft)}
code{font:13px/1.45 var(--mono);background:var(--paper-2);padding:.05em .3em;border-radius:4px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0;color:inherit}
hr{border:0;border-top:1px solid var(--line)}
img,svg{max-width:100%}
/* tables are tabelline's: only its variables are set, to the paper palette */
.tabella{--tb-table-background-color:var(--card);--tb-table-font-color:var(--ink);--tb-table-font-names:var(--font);--tb-table-font-size:14.5px;
  --tb-heading-color:var(--ink);--tb-column-labels-color:var(--ink);--tb-column-labels-background-color:var(--yellow-soft);
  --tb-stub-background-color:var(--paper-2);--tb-row-striping-background-color:rgba(0,0,0,.02);
  --tb-table-border-top-color:var(--ink);--tb-table-border-bottom-color:var(--ink);
  --tb-column-labels-border-bottom-color:var(--ink);--tb-table-body-hlines-color:var(--line);margin:.9rem 0}
.tabella td,.tabella th{vertical-align:top;line-height:1.4}
td code,th code{font-size:12px}
/* code: small, scrolling inside its box, highlighted at build time (nimib-theme) */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:10px;padding:.65rem .75rem;margin:.6rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.45 var(--mono);background:transparent;color:var(--ink);padding:0;white-space:pre}
body pre.nb-output{font:12.5px/1.5 var(--mono);background:var(--term);color:var(--term-ink);border:0;white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:auto}
.hljs-keyword,.hljs-selector-tag{color:var(--kw);font-weight:600}
.hljs-string,.hljs-template-string{color:var(--str)}
.hljs-number,.hljs-literal{color:var(--num)}
.hljs-comment,.hljs-meta{color:var(--com);font-style:italic}
.hljs-type,.hljs-built_in,.hljs-title,.hljs-attr,.hljs-section{color:var(--type)}
.hljs-operator,.hljs-punctuation{color:var(--ink)}
body code, body pre > code, body pre.nb-output{font-variant-ligatures:none}
/* blocks (blocks.nim) */
.lede{font-size:1.1rem;margin:.2rem 0 1rem}
.tldr{background:var(--card);border:2px solid var(--ink);border-radius:14px;padding:.3rem 1rem .5rem;margin:1.3rem 0;box-shadow:5px 5px 0 var(--yellow)}
.tldr-label{display:block;font:700 1.35rem/1 var(--hand);margin-top:.6rem}
.tldr ul{padding-left:1.1rem;margin:.4rem 0}
.tldr li{margin:.35rem 0}
.prompt{margin:1.2rem 0}
.prompt figcaption{font-size:.78rem;color:var(--muted);margin:0 0 .35rem .2rem}
.prompt .prompt-who{font-weight:700;color:var(--ink)}
.prompt blockquote{margin:0;padding:.75rem 1rem;background:var(--ink);color:#fff;border-radius:18px 18px 18px 4px;font-size:1rem;line-height:1.5;max-width:34rem}
.prompt blockquote p{margin:0 0 .4rem}.prompt blockquote p:last-child{margin:0}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem;border-radius:0 10px 10px 0}
aside.note.aside{border-left-color:var(--blue);background:var(--blue-soft)}
aside.note.careful{border-left-color:var(--red);background:var(--red-soft)}
aside.note.nim{border-left-color:var(--crown);background:var(--yellow-soft)}
aside.note.conda{border-left-color:var(--green);background:var(--green-soft)}
aside.note .note-label{display:block;font:700 .74rem/1.2 var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note p{margin:.3rem 0}
details.source,details.fold{margin:.8rem 0;border:1px solid var(--line);background:var(--card);border-radius:10px}
details.source > summary,details.fold > summary{cursor:pointer;padding:.55rem .8rem;min-height:44px;box-sizing:border-box;font-weight:700;display:flex;align-items:center;gap:.4rem;flex-wrap:wrap}
details.fold{padding:0 .8rem}
details.fold > summary{padding-left:0}
details.source > summary code{font-weight:400}
details.source .src-lines{font-weight:400;color:var(--muted);font-size:.85rem}
details.source pre{margin:0;border:0;border-top:1px solid var(--line);border-radius:0 0 10px 10px}
figure.file{margin:.9rem 0}
figure.file figcaption{display:inline-block;font:600 .75rem/1 var(--mono);background:var(--paper-2);border:1px solid var(--line);border-bottom:0;padding:.35rem .6rem;border-radius:8px 8px 0 0}
figure.file pre{margin-top:0;border-radius:0 10px 10px 10px}
figure.term{margin:.9rem 0;background:var(--term);border-radius:12px;overflow:hidden}
figure.term figcaption{display:flex;align-items:center;gap:.35rem;padding:.45rem .7rem;background:var(--term-2);font:600 .74rem/1 var(--mono);color:var(--term-dim)}
figure.term figcaption::before{content:"";width:.6rem;height:.6rem;border-radius:50%;background:#ff5f57;box-shadow:.95rem 0 0 #febc2e,1.9rem 0 0 #28c840;margin-right:2.2rem}
figure.term pre.nb-output{margin:0;border-radius:0;padding:.7rem .8rem}
.term-cmd{color:var(--yellow);font-weight:600}
.term-cmd::before{content:"❯ ";color:var(--yellow)}
/* family of package managers: cards */
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(13rem,1fr));gap:.7rem;margin:1rem 0}
.card{background:var(--card);border:2px solid var(--ink);border-radius:14px;padding:.6rem .8rem .7rem;box-shadow:3px 3px 0 var(--ink)}
.card h4{margin:0;font:800 1.15rem/1.2 var(--serif)}
.card .card-who{font-size:.8rem;color:var(--muted);margin:.1rem 0 .4rem}
.card .card-motto{font:700 1.15rem/1.15 var(--hand);margin:.2rem 0 .4rem;color:var(--ink)}
.card p{margin:.25rem 0;font-size:.92rem}
.card.conda{border-color:var(--green);box-shadow:3px 3px 0 var(--green)}
/* the wheel */
figure.wheel{margin:1rem 0;text-align:center}
figure.wheel svg{width:100%;max-width:22rem;height:auto}
figure.wheel figcaption{font-size:.85rem;color:var(--muted)}
.wh-ring{fill:none;stroke:var(--ink);stroke-width:2.5}
.wh-spoke{stroke:var(--ink);stroke-width:1.3}
.wh-hub{fill:var(--yellow);stroke:var(--ink);stroke-width:2}
.wh-hub-t{font:800 15px var(--serif);text-anchor:middle;dominant-baseline:central}
.wh-lab{font:700 12px var(--font);text-anchor:middle;dominant-baseline:central}
.wh-nim{stroke:var(--crown);stroke-width:2.5;stroke-dasharray:5 4}
.wh-nim-lab{font:700 21px var(--hand);fill:var(--crown);text-anchor:middle;dominant-baseline:central}
/* steps */
ol.steps{list-style:none;padding:0;margin:1rem 0;counter-reset:s}
ol.steps > li{position:relative;padding:.1rem 0 .6rem 2.6rem;counter-increment:s}
ol.steps > li::before{content:counter(s);position:absolute;left:0;top:.1rem;width:1.9rem;height:1.9rem;border-radius:50%;background:var(--yellow);border:2px solid var(--ink);
  font:800 .95rem/1.9rem var(--serif);text-align:center;box-sizing:border-box;line-height:1.65rem}
ol.steps > li > strong:first-child{display:block}
/* the race (race.js) */
section.race{margin:1.3rem 0;background:var(--card);border:2px solid var(--ink);border-radius:16px;padding:.8rem .8rem 1rem;box-shadow:5px 5px 0 var(--ink)}
.rc-row{display:flex;flex-wrap:wrap;gap:.45rem;align-items:center;margin:.3rem 0 .6rem}
.rc-label{font:700 .76rem/1.3 var(--mono);letter-spacing:.05em;text-transform:uppercase;color:var(--muted);margin-right:.2rem}
.rc-btn,.rc-chip{font:700 .9rem var(--font);min-height:44px;padding:0 .9rem;border:2px solid var(--ink);border-radius:999px;background:var(--card);color:var(--ink);cursor:pointer;touch-action:manipulation}
.rc-btn.primary{background:var(--yellow)}
.rc-btn:disabled{opacity:.4;cursor:default}
.rc-chip[aria-pressed=true]{background:var(--ink);color:#fff}
.rc-lane{border:1px solid var(--line);border-radius:12px;padding:.55rem .65rem .6rem;margin:.6rem 0;background:var(--paper)}
.rc-lane.conda{background:var(--green-soft);border-color:#b9dcc6}
.rc-lane h4{margin:0 0 .1rem;font:800 1.02rem/1.25 var(--serif)}
.rc-sub{font-size:.8rem;color:var(--muted);margin:0 0 .45rem}
.rc-meters{display:flex;flex-wrap:wrap;gap:.3rem .9rem;font:12.5px/1.4 var(--mono);margin:.1rem 0 .45rem}
.rc-meters b{font-size:15px}
.rc-graph{display:flex;flex-direction:column;gap:.35rem}
.rc-level{display:flex;flex-wrap:wrap;gap:.3rem;align-items:center;min-height:1.9rem}
.rc-level-n{font:600 .68rem/1 var(--mono);color:var(--muted);width:2.2rem;flex:none}
.rc-node{font:600 12.5px/1 var(--mono);padding:.38rem .5rem;border-radius:8px;border:1.5px dashed var(--line);color:var(--line);background:transparent;transition:all .25s}
.rc-node.known{border:1.5px solid var(--ink);color:var(--ink);background:var(--card)}
.rc-node.got{border:1.5px solid var(--ink);color:var(--ink);background:var(--yellow)}
.rc-node.busy{border:1.5px solid var(--ink);color:var(--ink);background:var(--yellow-soft);animation:rc-pulse 1s infinite}
.rc-lane.conda .rc-node.got{background:#9fdcb6}
.rc-log{font:12px/1.45 var(--mono);color:var(--muted);margin:.45rem 0 0;min-height:2.9em}
.rc-verdict{font-size:.95rem;margin:.6rem .1rem 0;min-height:3em}
@keyframes rc-pulse{50%{opacity:.55}}
@media (prefers-reduced-motion: reduce){.rc-node{transition:none}.rc-node.busy{animation:none}}
/* timing bars */
figure.bars{margin:1rem 0}
figure.bars figcaption{font-size:.85rem;color:var(--muted);margin-top:.3rem}
.bar-row{display:grid;grid-template-columns:8.5rem 1fr;gap:.5rem;align-items:center;margin:.3rem 0;font-size:.85rem}
.bar-track{background:var(--paper-2);border-radius:6px;height:1.55rem;position:relative}
.bar-fill{height:100%;border-radius:6px;background:var(--ink);min-width:3px}
.bar-fill.conda{background:var(--green)}
.bar-val{position:absolute;left:.45rem;top:0;line-height:1.55rem;font:600 12px var(--mono);color:#fff;mix-blend-mode:difference}
"""

proc useExplainerStyle*(nb: var Nb) =
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
