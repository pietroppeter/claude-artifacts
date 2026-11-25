## The style module of the futureverse explainer: every colour and CSS rule, from named tokens.
## The motif is a Paris cloakroom (le vestiaire), where a future is a numbered ticket: cream
## card stock, bordeaux ink, brass. Sections are numbered like tickets (N° 1, N° 2, ...).
## A hint of time travel: the timeline's dates glow in amber digits on a dark panel.
## R's own blue marks the R side of a comparison. Fonts: DM Serif Display, Source Sans 3,
## JetBrains Mono.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=Source+Sans+3:ital,wght@0,400;0,700;1,400&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#f6f0e4", "--card": "#fffdf8", "--ink": "#2a1d1f", "--muted": "#6d5f5a", "--line": "#dccfbd",
    "--bordeaux": "#7b1e34", "--bordeaux-soft": "#f3dfe2", "--brass": "#b0851f", "--brass-soft": "#f6ebcd",
    "--panel": "#1f1a1b", "--glow": "#ffb000", "--rblue": "#2766b0", "--rblue-soft": "#e1ebf7", "--careful": "#a33a1c", "--careful-soft": "#f8e1d8",
    "--link": "#7b1e34", "--code-bg": "#fffdf8", "--out-bg": "#2a1d1f", "--out-ink": "#f6f0e4", "--err-ink": "#ffb7a3",
    "--kw": "#7b1e34", "--str": "#3d6b2a", "--num": "#9a5a00", "--com": "#8b7f76", "--type": "#2766b0",
    # the names the review mode (shared/review, tabelline's) reads, from this page's own
    "--surface": "#fffdf8", "--shade": "#ece3d3", "--secondary": "#b0851f", "--secondary-soft": "#f6ebcd",
    "--primary-text": "#7b1e34", "--neutral-1": "#ece3d3",
    "--serif": "\"DM Serif Display\", Georgia, serif",
    "--font": "\"Source Sans 3\", system-ui, sans-serif", "--mono": "\"JetBrains Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 17.5px/1.6 var(--font);counter-reset:ticket}
h1{font:400 2.15rem/1.12 var(--serif);margin:1.2rem 0 .4rem;color:var(--bordeaux)}
h2{font:400 1.55rem/1.2 var(--serif);margin:2.8rem 0 .6rem;padding-top:.7rem;border-top:2px dashed var(--bordeaux);counter-increment:ticket}
h2::before{content:"N° " counter(ticket);display:inline-block;font:700 .72rem/1 var(--font);letter-spacing:.08em;
  color:var(--card);background:var(--bordeaux);padding:.32rem .5rem;margin-right:.55rem;border-radius:3px;vertical-align:.3rem}
h3{font-size:1.1rem;margin:1.8rem 0 .4rem}
a{color:var(--link);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--brass-soft);padding:0 .25em;border-radius:3px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0}
hr{border:0;border-top:1px solid var(--line)}
table{border-collapse:collapse;width:100%;font-size:.88rem;margin:.8rem 0;display:block;overflow-x:auto}
th,td{border-bottom:1px solid var(--line);padding:.35rem .5rem .35rem 0;text-align:left;vertical-align:top}
th{border-bottom:2px solid var(--ink)}
td code,th code{font-size:12px}
/* code: small, scrolling inside its box, highlighted at build time (nimib-theme) */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:4px;padding:.6rem .7rem;margin:.6rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.45 var(--mono);background:transparent;padding:0;white-space:pre}
body pre.nb-output{font:12.5px/1.45 var(--mono);background:var(--out-bg);color:var(--out-ink);border-color:var(--out-bg);white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:auto}
body pre.nb-output.err{color:var(--err-ink)}
figure.snippet{margin:.8rem 0}
figure.snippet figcaption{font-size:.8rem;color:var(--muted);margin:0 0 -.3rem .2rem}
figure.rcode{margin:.8rem 0}
figure.rcode figcaption{display:inline-block;font:700 .72rem/1 var(--font);letter-spacing:.08em;color:var(--card);background:var(--rblue);padding:.25rem .45rem;border-radius:3px 3px 0 0}
figure.rcode pre{margin-top:0;border-color:var(--rblue);border-left-width:4px;background:var(--rblue-soft)}
figure.rcode pre.nb-output{background:#1d2a3b;border-color:#1d2a3b}
details.fold{margin:.8rem 0;border:1px solid var(--line);background:var(--card);padding:0 .8rem}
details.fold > summary{cursor:pointer;min-height:44px;box-sizing:border-box;padding:.55rem 0;font-weight:700}
details.fold[open]{padding-bottom:.4rem}
.hljs-keyword,.hljs-selector-tag{color:var(--kw);font-weight:600}
.hljs-string,.hljs-template-string{color:var(--str)}
.hljs-number,.hljs-literal{color:var(--num)}
.hljs-comment,.hljs-meta{color:var(--com);font-style:italic}
.hljs-type,.hljs-built_in,.hljs-title{color:var(--type)}
/* blocks (blocks.nim) */
.lede{font-size:1.12rem;color:var(--muted);margin:.2rem 0 1rem}
.tldr{position:relative;background:var(--card);border:2px solid var(--bordeaux);border-radius:6px;padding:.4rem 1rem .4rem 1.4rem;margin:1.2rem 0;
  background-image:radial-gradient(circle at 0 50%,var(--paper) .55rem,transparent .6rem)}
.tldr-label{display:block;font-weight:700;font-size:.78rem;letter-spacing:.08em;text-transform:uppercase;color:var(--bordeaux);margin-top:.4rem}
.tldr ul{padding-left:1.1rem;margin:.4rem 0}
.tldr li{margin:.25rem 0}
.prompt{margin:1.4rem 0 1.6rem}
.prompt figcaption{font-size:.78rem;color:var(--muted);margin:0 0 .35rem .2rem}
.prompt .prompt-who{font-weight:700;color:var(--ink)}
.prompt blockquote{margin:0;padding:.8rem 1rem;background:var(--bordeaux);color:var(--card);border-radius:16px 16px 16px 4px;font-size:1.02rem;line-height:1.55;max-width:34rem}
.prompt blockquote p{margin:0}
.prompt blockquote a{color:var(--brass-soft);overflow-wrap:anywhere}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem}
aside.note.aside{border-left-color:var(--brass);background:var(--brass-soft)}
aside.note.careful{border-left-color:var(--careful);background:var(--careful-soft)}
aside.note.nim{border-left-color:var(--bordeaux);background:var(--bordeaux-soft)}
aside.note.r{border-left-color:var(--rblue);background:var(--rblue-soft)}
aside.note .note-label{display:block;font-weight:700;font-size:.8rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note p{margin:.3rem 0}
details.source{margin:.8rem 0;border:1px solid var(--line);background:var(--card)}
details.source > summary{cursor:pointer;padding:.55rem .8rem;min-height:44px;box-sizing:border-box;font-weight:700}
details.source > summary code{font-weight:400}
details.source .src-lines{font-weight:400;color:var(--muted);font-size:.85rem}
details.source pre{margin:0;border:0;border-top:1px solid var(--line);border-radius:0}
/* the time-travel log: dates in amber digits */
figure.timeline{margin:1.2rem 0;background:var(--panel);border-radius:8px;padding:.7rem .8rem;color:var(--paper)}
figure.timeline figcaption{font:700 .75rem/1 var(--font);letter-spacing:.08em;text-transform:uppercase;color:#bfb3a6;margin-bottom:.55rem}
figure.timeline ol{list-style:none;margin:0;padding:0;display:grid;grid-template-columns:repeat(auto-fit,minmax(9rem,1fr));gap:.5rem}
figure.timeline li{border:1px solid #4a3f3f;border-radius:5px;padding:.4rem .5rem;background:#2b2425}
figure.timeline .tl-date{display:block;font:600 1.05rem/1.2 var(--mono);color:var(--glow);text-shadow:0 0 6px rgba(255,176,0,.55);letter-spacing:.06em}
figure.timeline .tl-what{display:block;font-size:.88rem;line-height:1.35}
/* the cloakroom: steps as tickets */
figure.steps{margin:1.2rem 0}
figure.steps ol{list-style:none;padding:0;margin:0;display:grid;grid-template-columns:repeat(auto-fit,minmax(9.5rem,1fr));gap:.6rem}
figure.steps li{background:var(--card);border:2px dashed var(--brass);border-radius:8px;padding:.55rem .7rem}
figure.steps .step-icon{display:block;font-size:1.6rem;line-height:1.2}
figure.steps .step-title{display:block;font-weight:700;color:var(--bordeaux)}
figure.steps .step-what{display:block;font-size:.92rem}
figure.steps figcaption{font-size:.85rem;color:var(--muted);margin-top:.5rem}
"""

proc useExplainerStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's own
  ## CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  var root = ":root{"
  for (name, value) in tokens:
    root.add name & ":" & value & ";"
  root.add "}"
  nb.doc.context["stylesheet"] = %(fonts & "<style>" & root & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
