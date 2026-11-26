## The style module of the faretto explainer: every colour and CSS rule, from named tokens.
## The motif is a lighthouse at night: a deep sea-blue page, text the colour of moonlit
## foam, the lamp's warm amber for what matters, the tower's red bands for warnings.
## Sections are numbered like a light's character on a nautical chart: Fl(1), Fl(2), ...
## and a dim beam sweeps under each section title. Fonts: Fraunces, Atkinson Hyperlegible,
## JetBrains Mono.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,700&family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--night": "#0c1828", "--deep": "#08111d", "--card": "#13253a", "--card-2": "#182d45",
    "--foam": "#e6edf5", "--muted": "#9fb0c3", "--line": "#2a4462",
    "--lamp": "#ffc94a", "--lamp-soft": "#3a3220", "--beam": "#fff2c2", "--oil": "#ffa23a",
    "--tower": "#e0574a", "--tower-soft": "#3b2027", "--sea": "#2b7486", "--sea-soft": "#13323d",
    "--pharo": "#7fb2ff", "--pharo-soft": "#18294a",
    "--link": "#ffd877", "--code-bg": "#0a1422", "--out-bg": "#050c16", "--out-ink": "#d9e4ef",
    "--kw": "#ff9e7a", "--str": "#a6e3a1", "--num": "#ffc94a", "--com": "#7d8fa6", "--type": "#8cc8ff",
    # the names the review mode (shared/review, tabelline's) reads, from this page's own
    "--paper": "#0c1828", "--ink": "#e6edf5", "--surface": "#13253a", "--shade": "#22395a",
    "--secondary": "#c99a2e", "--secondary-soft": "#4a3d1c", "--primary-text": "#ff9e7a", "--neutral-1": "#1b3150",
    "--serif": "Fraunces, Georgia, serif",
    "--font": "\"Atkinson Hyperlegible\", system-ui, sans-serif", "--mono": "\"JetBrains Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%;background:var(--night)}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--night);color:var(--foam);font:400 17px/1.62 var(--font);counter-reset:light}
h1{font:700 2.2rem/1.1 var(--serif);margin:1.2rem 0 .4rem;color:var(--lamp);text-shadow:0 0 18px rgba(255,201,74,.35)}
h2{position:relative;font:500 1.5rem/1.2 var(--serif);margin:3rem 0 .7rem;padding-top:1rem;counter-increment:light;color:var(--foam)}
h2::after{content:"";position:absolute;left:0;right:0;top:0;height:3px;border-radius:3px;
  background:linear-gradient(90deg,var(--lamp) 0,rgba(255,201,74,.45) 30%,rgba(255,201,74,0) 75%)}
h2::before{content:"Fl(" counter(light) ")";display:inline-block;font:700 .74rem/1 var(--mono);letter-spacing:.04em;
  color:var(--deep);background:var(--lamp);padding:.32rem .45rem;margin-right:.55rem;border-radius:3px;vertical-align:.3rem}
h3{font:500 1.15rem/1.3 var(--serif);margin:1.8rem 0 .4rem;color:var(--beam)}
a{color:var(--link);text-underline-offset:2px}
strong{color:#fff}
code{font:13px/1.45 var(--mono);background:var(--card-2);color:var(--beam);padding:0 .25em;border-radius:3px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0;color:inherit}
hr{border:0;border-top:1px solid var(--line)}
/* tables are tabelline's (shared look): only its variables are set here, to the night palette */
.tabella{--tb-table-background-color:var(--card);--tb-table-font-color:var(--foam);--tb-table-font-names:var(--font);--tb-table-font-size:14.5px;
  --tb-heading-color:var(--lamp);--tb-column-labels-color:var(--beam);--tb-stub-color:var(--beam);--tb-stub-background-color:var(--card-2);
  --tb-row-striping-background-color:rgba(255,255,255,.03);
  --tb-table-border-top-color:var(--lamp);--tb-table-border-bottom-color:var(--lamp);--tb-table-border-left-color:var(--line);--tb-table-border-right-color:var(--line);
  --tb-heading-border-bottom-color:var(--line);--tb-heading-border-lr-color:var(--line);
  --tb-column-labels-border-top-color:var(--line);--tb-column-labels-border-bottom-color:var(--lamp);--tb-column-labels-border-lr-color:var(--line);--tb-column-labels-vlines-color:var(--line);
  --tb-table-body-hlines-color:var(--line);--tb-table-body-border-top-color:var(--line);--tb-table-body-border-bottom-color:var(--line);
  --tb-stub-border-color:var(--line);--tb-stub-row-group-border-color:var(--line);
  --tb-row-group-border-color:var(--line);--tb-row-group-border-left-color:var(--line);--tb-row-group-border-right-color:var(--line);
  --tb-summary-row-border-color:var(--line);--tb-grand-summary-row-border-color:var(--line);
  --tb-footnotes-border-bottom-color:var(--line);--tb-footnotes-border-lr-color:var(--line);
  --tb-source-notes-border-bottom-color:var(--line);--tb-source-notes-border-lr-color:var(--line);margin:.9rem 0}
.tabella td,.tabella th{vertical-align:top;line-height:1.4}
td code,th code{font-size:12px}
/* code: small, scrolling inside its box, highlighted at build time (nimib-theme) */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:6px;padding:.6rem .7rem;margin:.6rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.45 var(--mono);background:transparent;color:var(--foam);padding:0;white-space:pre}
body pre.nb-output{font:12.5px/1.45 var(--mono);background:var(--out-bg);color:var(--out-ink);border-color:#1d3049;border-left:3px solid var(--lamp);white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:auto}
body pre.nb-output.err{border-left-color:var(--tower);color:#ffc2b8}
.hljs-keyword,.hljs-selector-tag{color:var(--kw);font-weight:600}
.hljs-string,.hljs-template-string{color:var(--str)}
.hljs-number,.hljs-literal{color:var(--num)}
.hljs-comment,.hljs-meta{color:var(--com);font-style:italic}
.hljs-type,.hljs-built_in,.hljs-title{color:var(--type)}
.hljs-operator,.hljs-punctuation{color:var(--foam)}
/* blocks (blocks.nim) */
.lede{font-size:1.1rem;color:var(--muted);margin:.2rem 0 1rem}
.lede strong{color:var(--beam)}
.tldr{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--lamp);border-radius:6px;padding:.4rem 1rem .4rem 1.1rem;margin:1.2rem 0;
  box-shadow:0 0 30px rgba(255,201,74,.07)}
.tldr-label{display:block;font:700 .75rem/1 var(--mono);letter-spacing:.08em;text-transform:uppercase;color:var(--lamp);margin-top:.6rem}
.tldr ul{padding-left:1.1rem;margin:.5rem 0}
.tldr li{margin:.3rem 0}
.prompt{margin:1.4rem 0 1.6rem}
.prompt figcaption{font-size:.78rem;color:var(--muted);margin:0 0 .35rem .2rem}
.prompt .prompt-who{font-weight:700;color:var(--foam)}
.prompt blockquote{margin:0;padding:.8rem 1rem;background:var(--sea);color:#fff;border-radius:16px 16px 16px 4px;font-size:1.02rem;line-height:1.55;max-width:34rem}
.prompt blockquote p{margin:0}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem;border-radius:0 6px 6px 0}
aside.note.aside{border-left-color:var(--sea);background:var(--sea-soft)}
aside.note.careful{border-left-color:var(--tower);background:var(--tower-soft)}
aside.note.nim{border-left-color:var(--lamp);background:var(--lamp-soft)}
aside.note.pharo{border-left-color:var(--pharo);background:var(--pharo-soft)}
aside.note .note-label{display:block;font:700 .74rem/1.2 var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note.pharo .note-label{color:var(--pharo)}
aside.note.nim .note-label{color:var(--lamp)}
aside.note.careful .note-label{color:var(--tower)}
aside.note p{margin:.3rem 0}
details.source,details.fold{margin:.8rem 0;border:1px solid var(--line);background:var(--card);border-radius:6px}
details.source > summary,details.fold > summary{cursor:pointer;padding:.55rem .8rem;min-height:44px;box-sizing:border-box;font-weight:700}
details.fold{padding:0 .8rem}
details.fold > summary{padding-left:0}
details.source > summary code{font-weight:400}
details.source .src-lines{font-weight:400;color:var(--muted);font-size:.85rem}
details.source pre{margin:0;border:0;border-top:1px solid var(--line);border-radius:0 0 6px 6px}
figure.snippet{margin:.8rem 0}
figure.snippet figcaption{font-size:.8rem;color:var(--muted);margin:0 0 -.3rem .2rem}
figure.term{margin:.8rem 0}
figure.term figcaption{display:inline-block;font:700 .72rem/1 var(--mono);letter-spacing:.06em;color:var(--deep);background:var(--sea);padding:.28rem .5rem;border-radius:4px 4px 0 0}
figure.term pre.nb-output{margin-top:0;border-left-color:var(--sea);border-radius:0 6px 6px 6px}
/* the coast: steps as lights */
figure.steps{margin:1.2rem 0}
figure.steps ol{list-style:none;padding:0;margin:0;display:grid;grid-template-columns:repeat(auto-fit,minmax(9.5rem,1fr));gap:.6rem}
figure.steps li{background:var(--card);border:1px solid var(--line);border-top:3px solid var(--lamp);border-radius:6px;padding:.55rem .7rem}
figure.steps .step-icon{display:block;font-size:1.5rem;line-height:1.3}
figure.steps .step-title{display:block;font-weight:700;color:var(--lamp)}
figure.steps .step-what{display:block;font-size:.92rem}
figure.steps figcaption{font-size:.85rem;color:var(--muted);margin-top:.5rem}
/* the playground: faretto in the page */
section.playground{margin:1.4rem 0;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:.7rem .8rem .9rem;box-shadow:0 0 40px rgba(255,201,74,.06)}
.pg-stage{background:var(--deep);border-radius:8px;padding:.3rem .3rem .5rem;margin-bottom:.6rem}
.pg-svg{display:block;width:100%;height:auto;max-height:15rem}
.pg-svg .sea-top{stop-color:#123247}.pg-svg .sea-bottom{stop-color:#07121d}
.pg-svg .beam-in{stop-color:var(--beam);stop-opacity:.85}.pg-svg .beam-out{stop-color:var(--beam);stop-opacity:0}
section.oil .pg-svg .beam-in{stop-color:var(--oil)}
.pg-star{fill:#cfe0f2;opacity:.7}
.pg-beams{transition:opacity .12s}
.pg-rock{fill:#1d2a36}.pg-tower{fill:#e9e4da}.pg-band{fill:var(--tower)}.pg-gallery{fill:#3a4652}.pg-room{fill:#22303c;stroke:#56687a;stroke-width:1}
.pg-roof{fill:var(--tower)}
.pg-lamp{fill:#57503a;transition:fill .12s}
.pg-lamp.on{fill:var(--beam);filter:drop-shadow(0 0 6px var(--beam))}
section.oil .pg-lamp.on{fill:var(--oil);filter:drop-shadow(0 0 6px var(--oil))}
.pg-wave{fill:none;stroke:#3d7f93;stroke-width:1.2;opacity:.6}
.pg-strip{font:15px/1.3 var(--mono);letter-spacing:.08em;color:var(--lamp);min-height:1.3em;padding:0 .4rem;overflow:hidden;white-space:nowrap}
.pg-report{margin:.2rem .4rem 0;font:12.5px/1.4 var(--mono);color:var(--muted);min-height:2.8em}
.pg-row{display:flex;flex-wrap:wrap;gap:.45rem;margin:.5rem 0}
.pg-btn,.pg-chip{font:700 .88rem var(--font);min-height:44px;padding:0 .8rem;border:1px solid var(--lamp);border-radius:22px;background:transparent;color:var(--lamp);cursor:pointer;touch-action:manipulation}
.pg-btn code{background:none;padding:0;color:inherit}
.pg-btn:disabled{opacity:.45;cursor:default}
.pg-chip[aria-pressed=true],.pg-btn[aria-pressed=true]{background:var(--lamp);color:var(--deep)}
.pg-chips{display:flex;flex-wrap:wrap;gap:.4rem}
.pg-label{margin:.7rem 0 .2rem;font:700 .76rem/1.3 var(--mono);letter-spacing:.05em;text-transform:uppercase;color:var(--muted)}
.pg-label code{text-transform:none}
.pg-insp{min-height:9em}
.pg-log{margin:.2rem 0 0;padding-left:1.3rem;font:12.5px/1.5 var(--mono);color:var(--foam)}
body code, body pre > code, body pre.nb-output{font-variant-ligatures:none}
@media (prefers-reduced-motion: reduce){.pg-beams,.pg-lamp{transition:none}}
"""

proc useExplainerStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's own
  ## CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  var root = ":root{color-scheme:dark;"
  for (name, value) in tokens:
    root.add name & ":" & value & ";"
  root.add "}"
  nb.doc.context["stylesheet"] = %(fonts & "<style>" & root & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
