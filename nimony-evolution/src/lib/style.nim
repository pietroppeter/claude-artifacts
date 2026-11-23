## The style module of the Nimony explainer: every colour and CSS rule, from named tokens.
## A Miskatonic library card: old paper, ink, one deep sea-green for the Lovecraftian tool names,
## Nim's crown gold for Nim itself. Fonts: IBM Plex Sans and Plex Mono.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,400;0,600;0,700;1,400&family=IBM+Plex+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#f4f1e8", "--ink": "#17201d", "--muted": "#5d625c", "--line": "#d5d0c2",
    "--card": "#ffffff", "--sea": "#0f6b5e", "--sea-soft": "#dcece7", "--gold": "#c99a06", "--gold-soft": "#f7ebc2",
    "--aside": "#0f6b5e", "--careful": "#b3392f", "--nim2": "#c99a06",
    "--aside-soft": "#e6f1ed", "--careful-soft": "#f6e1de", "--nim2-soft": "#faf1d4",
    "--code-bg": "#ffffff",
    "--kw": "#8a1f5c", "--str": "#2d6e3a", "--num": "#9a5300", "--com": "#8a857b", "--type": "#1f5f8a",
    # the names the review mode (review/review.nim, tabelline's) reads, from this page's own
    "--surface": "#ffffff", "--shade": "#ece6da", "--secondary": "#5fb3a3", "--secondary-soft": "#d3ebe5",
    "--primary-text": "#8a3550", "--neutral-1": "#ece6da",
    "--font": "\"IBM Plex Sans\", system-ui, sans-serif", "--mono": "\"IBM Plex Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 17px/1.6 var(--font)}
h1{font-size:2rem;line-height:1.15;margin:1.2rem 0 .4rem;letter-spacing:-.01em}
h2{font-size:1.35rem;margin:2.6rem 0 .6rem;padding-top:.6rem;border-top:3px solid var(--ink)}
h2::before{content:"";display:inline-block;width:.55em;height:.55em;margin-right:.45em;border-radius:50%;background:var(--sea);vertical-align:.08em}
h3{font-size:1.08rem;margin:1.8rem 0 .4rem}
a{color:var(--ink);text-decoration-color:var(--sea);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--sea-soft);padding:0 .25em;border-radius:3px}
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
body pre.nb-output{font:12.5px/1.45 var(--mono);background:var(--ink);color:#f3efe6;border-color:var(--ink);white-space:pre;overflow-x:auto}
.hljs-keyword,.hljs-selector-tag{color:var(--kw);font-weight:600}
.hljs-string,.hljs-template-string{color:var(--str)}
.hljs-number,.hljs-literal{color:var(--num)}
.hljs-comment,.hljs-meta{color:var(--com);font-style:italic}
.hljs-type,.hljs-built_in,.hljs-title{color:var(--type)}
/* blocks (blocks.nim) */
.lede{font-size:1.12rem;color:var(--muted);margin:.2rem 0 1rem}
.tldr{background:var(--card);border:1px solid var(--line);border-left:6px solid var(--gold);padding:.4rem 1rem;margin:1rem 0}
.tldr-label,.toc-label{display:block;font-weight:700;font-size:.78rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-top:.4rem}
.tldr ul{padding-left:1.1rem;margin:.4rem 0}
.tldr li{margin:.25rem 0}
.toc{margin:1rem 0;padding:.3rem 1rem;border:1px solid var(--line);background:var(--card)}
.toc ol{margin:.4rem 0;padding-left:1.3rem}
.toc li{margin:.2rem 0}
h2 .ch-span{display:block;font-size:.82rem;font-weight:400;color:var(--muted);margin-top:.15rem}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem}
aside.note.aside{border-left-color:var(--aside);background:var(--aside-soft)}
aside.note.careful{border-left-color:var(--careful);background:var(--careful-soft)}
aside.note.nim2{border-left-color:var(--nim2);background:var(--nim2-soft)}
aside.note .note-label{display:block;font-weight:700;font-size:.8rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note p{margin:.3rem 0}
blockquote.quote{margin:1rem 0;padding:.2rem 0 .2rem 1rem;border-left:4px solid var(--gold)}
blockquote.quote p{margin:.2rem 0;font-size:1.02rem}
blockquote.quote cite{display:block;font-style:normal;font-size:.82rem;color:var(--muted)}
section.term{background:var(--card);border:1px solid var(--line);border-top:4px solid var(--sea);padding:.45rem .9rem .5rem;margin:1rem 0;font-size:.95rem;scroll-margin-top:1rem}
section.term .term-head{display:flex;flex-wrap:wrap;gap:.1rem .6rem;align-items:baseline}
section.term .term-name{font-weight:700;font-size:1.05rem}
section.term .term-name code{font-size:14px}
section.term .term-aka{font-size:.82rem;color:var(--muted)}
section.term p{margin:.35rem 0}
section.term .term-since{display:block;font-size:.8rem;color:var(--muted);margin-top:.3rem}
ol.events{list-style:none;padding:0;margin:1rem 0;border-left:2px solid var(--line)}
ol.events li{position:relative;padding:0 0 .7rem 1rem}
ol.events li::before{content:"";position:absolute;left:-6px;top:.45rem;width:10px;height:10px;border-radius:50%;background:var(--sea)}
ol.events .ev-date{display:block;font:600 12.5px/1.4 var(--mono);color:var(--muted)}
ol.events .ev-text p{margin:.1rem 0 .3rem}
figure.pipeline{margin:1rem 0}
figure.pipeline figcaption{font-size:.85rem;color:var(--muted);margin-bottom:.4rem}
figure.pipeline ol{list-style:none;padding:0;margin:0}
figure.pipeline li{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--sea);padding:.4rem .8rem;margin:0}
figure.pipeline li + li{margin-top:1.3rem;position:relative}
figure.pipeline li + li::before{content:"↓";position:absolute;top:-1.32rem;left:1rem;color:var(--sea);font-weight:700}
figure.pipeline .st-tool{display:block;font-weight:700}
figure.pipeline .st-what{display:block;font-size:.92rem}
figure.pipeline .st-makes{display:block;font-size:.8rem;color:var(--muted)}
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
