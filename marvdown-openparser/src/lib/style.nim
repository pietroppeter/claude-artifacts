## The style module of the marvdown and openparser explainer: every colour and CSS rule, from named tokens.
## A proof sheet from a test lab: white paper, navy ink, nimib's whale teal for what nimib uses today
## and a lemon yellow for George Lemon's candidates. System fonts only, so the page needs nothing remote.
import std/json
import nimib

const
  tokens = {
    "--paper": "#fbfaf6", "--ink": "#1b2233", "--muted": "#5f6675", "--line": "#dcdad2",
    "--card": "#ffffff", "--teal": "#0e7490", "--teal-soft": "#dff1f5", "--lemon": "#d9b21f", "--lemon-soft": "#fbf3c7",
    "--lemon-ink": "#6b5600",
    "--aside": "#0e7490", "--careful": "#b4232a", "--nimib": "#0e7490",
    "--aside-soft": "#e9f4f7", "--careful-soft": "#f8e3e3", "--nimib-soft": "#e3f2f6",
    "--code-bg": "#ffffff", "--out-bg": "#f2f1ec",
    "--kw": "#8a1f5c", "--str": "#2d6e3a", "--num": "#9a5300", "--com": "#8a857b", "--type": "#1f5f8a",
    # the names the review mode (shared/review, tabelline's) reads, from this page's own
    "--surface": "#ffffff", "--shade": "#eeede6", "--secondary": "#5fb3c6", "--secondary-soft": "#d6edf3",
    "--primary-text": "#0e6075", "--neutral-1": "#eeede6",
    "--font": "system-ui, -apple-system, \"Segoe UI\", Roboto, sans-serif",
    "--serif": "\"Iowan Old Style\", \"Palatino Linotype\", Palatino, Georgia, serif",
    "--mono": "ui-monospace, \"SF Mono\", Menlo, Consolas, monospace"}

  css = """
html{-webkit-text-size-adjust:100%}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 17px/1.6 var(--font)}
h1{font:700 2rem/1.15 var(--serif);margin:1.2rem 0 .4rem;letter-spacing:-.01em}
h2{font:700 1.4rem/1.25 var(--serif);margin:2.6rem 0 .6rem;padding-top:.6rem;border-top:3px double var(--ink)}
h2::before{content:"";display:inline-block;width:.55em;height:.55em;margin-right:.45em;border-radius:50%;background:var(--teal);vertical-align:.08em}
h3{font:700 1.12rem/1.3 var(--serif);margin:1.8rem 0 .4rem}
h4{margin:.2rem 0 .4rem;font-size:.95rem}
a{color:var(--ink);text-decoration-color:var(--teal);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--teal-soft);padding:0 .25em;border-radius:3px}
header,footer{font-size:.85rem;color:var(--muted)}
header a,footer a{color:var(--muted)}
header code{background:none;font:inherit;padding:0}
hr{border:0;border-top:1px solid var(--line)}
table{border-collapse:collapse;width:100%;font-size:.88rem;margin:.8rem 0;display:block;overflow-x:auto}
th,td{border-bottom:1px solid var(--line);padding:.35rem .5rem .35rem 0;text-align:left;vertical-align:top}
th{border-bottom:2px solid var(--ink)}
td code,th code{font-size:12px}
.tabella{overflow-x:auto}
.tabella table{display:table;width:auto;min-width:100%}
/* code: small, scrolling inside its box, highlighted at build time (nimib-theme) */
body pre{overflow-x:auto;background:var(--code-bg);border:1px solid var(--line);border-radius:4px;padding:.6rem .7rem;margin:.6rem 0}
body pre > code{display:block;overflow-x:auto;font:13px/1.45 var(--mono);background:transparent;padding:0;white-space:pre}
body pre.nb-output,body pre.out{font:12.5px/1.45 var(--mono);background:var(--out-bg);color:var(--ink);white-space:pre;overflow-x:auto}
body pre.out > code{font:12.5px/1.45 var(--mono)}
.hljs-keyword,.hljs-selector-tag{color:var(--kw);font-weight:600}
.hljs-string,.hljs-template-string{color:var(--str)}
.hljs-number,.hljs-literal{color:var(--num)}
.hljs-comment,.hljs-meta{color:var(--com);font-style:italic}
.hljs-type,.hljs-built_in,.hljs-title{color:var(--type)}
/* blocks (blocks.nim) */
.lede{font-size:1.12rem;color:var(--muted);margin:.2rem 0 1rem}
.tldr{background:var(--card);border:1px solid var(--line);border-left:6px solid var(--lemon);padding:.4rem 1rem;margin:1rem 0}
.tldr-label,.toc-label{display:block;font-weight:700;font-size:.78rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-top:.4rem}
.tldr ul{padding-left:1.1rem;margin:.4rem 0}
.tldr li{margin:.3rem 0}
.toc{margin:1rem 0;padding:.3rem 1rem;border:1px solid var(--line);background:var(--card)}
.toc ol{margin:.4rem 0;padding-left:1.3rem}
.toc li{margin:.2rem 0}
h2 .ch-sub{display:block;font:400 .85rem/1.4 var(--font);color:var(--muted);margin-top:.2rem}
h2 .ch-top{display:inline-block;font:600 .78rem/1.4 var(--font);color:var(--teal);text-decoration:none;margin-top:.2rem}
.prompt{margin:1.4rem 0 1.6rem}
.prompt figcaption{font-size:.78rem;color:var(--muted);margin:0 0 .35rem .2rem}
.prompt .prompt-who{font-weight:700;color:var(--ink)}
.prompt blockquote{margin:0;padding:.8rem 1rem;background:var(--ink);color:var(--paper);border-radius:16px 16px 16px 4px;font-size:1.02rem;line-height:1.55;max-width:34rem}
.prompt blockquote p{margin:0}
.prompt blockquote p + p{margin-top:.6rem}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem}
aside.note.aside{border-left-color:var(--aside);background:var(--aside-soft)}
aside.note.careful{border-left-color:var(--careful);background:var(--careful-soft)}
aside.note.nimib{border-left-color:var(--nimib);background:var(--nimib-soft)}
aside.note .note-label{display:block;font-weight:700;font-size:.8rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note p{margin:.3rem 0}
aside.note ul{margin:.3rem 0;padding-left:1.1rem}
figure.scores{margin:1.2rem 0;padding:.6rem .9rem;background:var(--card);border:1px solid var(--line)}
figure.scores figcaption{font-weight:700;font-size:.95rem;margin-bottom:.4rem}
.score{margin:.35rem 0 .7rem}
.score-label{font-size:.88rem;margin-bottom:2px}
.score-line{display:flex;align-items:center;gap:6px;min-height:14px}
.score-bar{height:12px;border-radius:0 3px 3px 0;min-width:2px}
.score-bar.now{background:var(--teal)}
.score-bar.new{background:var(--lemon)}
.score-value{font:12px var(--mono);color:var(--muted);white-space:nowrap}
.scores-note{font-size:.8rem;color:var(--muted);margin:.3rem 0 0}
.renders{display:grid;gap:.8rem;margin:1rem 0}
section.render{background:var(--card);border:1px solid var(--line);border-top:4px solid var(--ink);padding:.5rem .8rem .3rem;min-width:0}
section.render pre{margin:.2rem 0 .5rem}
section.render pre.src{background:var(--card);border-style:dashed}
.render-who{display:inline-block;font:600 11px/1.6 var(--mono);text-transform:uppercase;letter-spacing:.05em;padding:0 .4em;border-radius:3px}
.render-who.now{background:var(--teal-soft);color:var(--teal)}
.render-who.new{background:var(--lemon-soft);color:var(--lemon-ink)}
"""

proc useExplainerStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's own
  ## CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  var root = ":root{"
  for (name, value) in tokens:
    root.add name & ":" & value & ";"
  root.add "}"
  nb.doc.context["stylesheet"] = %("<style>" & root & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
