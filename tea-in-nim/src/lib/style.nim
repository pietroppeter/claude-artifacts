## The style module of the TEA explainer: every colour and CSS rule, from named tokens.
## Elm's tangram colours (orange, green, blue, slate) mark the four parts of the loop:
## Msg, update, Model, view. Nim's crown gold marks Nim itself. Fonts: Atkinson Hyperlegible
## and JetBrains Mono.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#fbf8f1", "--ink": "#1d2430", "--muted": "#5f6672", "--line": "#d9d4c8", "--card": "#ffffff",
    "--msg": "#f0ad00", "--msg-soft": "#fdf0cc", "--upd": "#7fd13b", "--upd-soft": "#e7f6d8",
    "--mdl": "#60b5cc", "--mdl-soft": "#dcf0f5", "--viw": "#5a6378", "--viw-soft": "#e4e6ec",
    "--link": "#0b6f8a", "--nim": "#d9ad00", "--nim-soft": "#fbf1c7", "--careful": "#b3392f", "--careful-soft": "#f7e2df",
    "--code-bg": "#ffffff", "--out-bg": "#1d2430", "--out-ink": "#eef1f5", "--err-ink": "#ffb4a8",
    "--kw": "#8a1f5c", "--str": "#2d6e3a", "--num": "#9a5300", "--com": "#8a857b", "--type": "#0b6f8a",
    # the names the review mode (review/review.nim, tabelline's) reads, from this page's own
    "--surface": "#ffffff", "--shade": "#ece7dc", "--secondary": "#60b5cc", "--secondary-soft": "#dcf0f5",
    "--primary-text": "#8a3550", "--neutral-1": "#ece7dc",
    "--font": "\"Atkinson Hyperlegible\", system-ui, sans-serif", "--mono": "\"JetBrains Mono\", ui-monospace, monospace"}

  css = """
html{-webkit-text-size-adjust:100%}
body{margin:0 auto;max-width:44rem;padding:1rem max(1rem,env(safe-area-inset-right)) 3rem max(1rem,env(safe-area-inset-left));
  background:var(--paper);color:var(--ink);font:400 17px/1.6 var(--font)}
h1{font-size:2rem;line-height:1.15;margin:1.2rem 0 .4rem}
h2{font-size:1.35rem;margin:2.6rem 0 .6rem;padding-top:.6rem;border-top:3px solid var(--ink)}
h3{font-size:1.08rem;margin:1.8rem 0 .4rem}
a{color:var(--link);text-underline-offset:2px}
code{font:13px/1.45 var(--mono);background:var(--nim-soft);padding:0 .25em;border-radius:3px}
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
body pre.nb-output.wrap{white-space:pre-wrap;overflow-wrap:anywhere}
figure.snippet{margin:.8rem 0}
figure.snippet figcaption{font-size:.8rem;color:var(--muted);margin:0 0 -.3rem .2rem}
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
.tldr{background:var(--card);border:1px solid var(--line);border-left:6px solid var(--nim);padding:.4rem 1rem;margin:1rem 0}
.tldr-label{display:block;font-weight:700;font-size:.78rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-top:.4rem}
.tldr ul{padding-left:1.1rem;margin:.4rem 0}
.tldr li{margin:.25rem 0}
.prompt{margin:1.4rem 0 1.6rem}
.prompt figcaption{font-size:.78rem;color:var(--muted);margin:0 0 .35rem .2rem}
.prompt .prompt-who{font-weight:700;color:var(--ink)}
.prompt blockquote{margin:0;padding:.8rem 1rem;background:var(--ink);color:var(--paper);border-radius:16px 16px 16px 4px;font-size:1.02rem;line-height:1.55;max-width:34rem}
.prompt blockquote p{margin:0}
.prompt blockquote a{color:var(--msg-soft);overflow-wrap:anywhere}
aside.note{background:var(--card);border:1px solid var(--line);border-left:5px solid var(--muted);padding:.5rem .9rem;margin:1rem 0;font-size:.95rem}
aside.note.aside{border-left-color:var(--mdl);background:var(--mdl-soft)}
aside.note.careful{border-left-color:var(--careful);background:var(--careful-soft)}
aside.note.nim{border-left-color:var(--nim);background:var(--nim-soft)}
aside.note .note-label{display:block;font-weight:700;font-size:.8rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
aside.note p{margin:.3rem 0}
/* the loop: four parts in Elm's tangram colours */
figure.loop{margin:1.2rem 0}
figure.loop figcaption{font-size:.85rem;color:var(--muted);margin-top:.5rem}
figure.loop ol{list-style:none;padding:0;margin:0;counter-reset:none}
figure.loop li{background:var(--card);border:1px solid var(--line);border-left:8px solid var(--viw);padding:.45rem .8rem;position:relative}
figure.loop li + li{margin-top:1.4rem}
figure.loop li + li::before{content:"↓";position:absolute;top:-1.38rem;left:1rem;font-weight:700;color:var(--muted)}
figure.loop li:last-child::after{content:"↺ back to Msg: the next message, and the loop goes round again";display:block;margin-top:.45rem;font-weight:700;font-size:.85rem;color:var(--ink)}
figure.loop li.msg{border-left-color:var(--msg)}
figure.loop li.update{border-left-color:var(--upd)}
figure.loop li.model{border-left-color:var(--mdl)}
figure.loop li.view{border-left-color:var(--viw)}
figure.loop li.runtime{border-left-color:var(--ink);background:var(--shade)}
figure.loop .part{display:block;font-weight:700}
figure.loop .sig{display:block;font:12.5px/1.4 var(--mono);color:var(--muted)}
figure.loop .what{display:block;font-size:.93rem}
details.source{margin:.8rem 0;border:1px solid var(--line);background:var(--card)}
details.source > summary{cursor:pointer;padding:.55rem .8rem;min-height:44px;box-sizing:border-box;font-weight:700}
details.source > summary code{font-weight:400}
details.source .src-lines{font-weight:400;color:var(--muted);font-size:.85rem}
details.source pre{margin:0;border:0;border-top:1px solid var(--line);border-radius:0}
/* a live program, and the messages it received */
section.demo{margin:1.2rem 0;border:2px solid var(--ink);background:var(--card)}
section.demo > .demo-cap{display:flex;justify-content:space-between;gap:.5rem;align-items:baseline;padding:.35rem .8rem;background:var(--ink);color:var(--paper);font-size:.85rem}
section.demo > .demo-cap .demo-count{font:12px/1.4 var(--mono);color:var(--msg-soft)}
section.demo > .demo-app{padding:.6rem .8rem}
section.demo .app .big{font:600 2.6rem/1.1 var(--mono);margin:.2rem 0 .6rem;text-align:center}
section.demo .app .row{display:flex;flex-wrap:wrap;gap:.5rem;justify-content:center;align-items:center;margin:.5rem 0}
section.demo .app button{font:700 1rem var(--font);min-height:44px;min-width:56px;padding:0 1rem;background:var(--msg-soft);color:var(--ink);border:2px solid var(--ink);border-radius:6px;cursor:pointer}
section.demo .app button:active{background:var(--msg)}
section.demo .app input{font:16px var(--mono);width:5rem;min-height:40px;padding:0 .4rem;border:2px solid var(--ink);border-radius:6px}
section.demo .app .bars{margin:.6rem 0}
section.demo .app .bar{display:grid;grid-template-columns:1.8rem 1fr 2.6rem;gap:.4rem;align-items:center;margin:.2rem 0;font-size:1.3rem}
section.demo .app .bar .fill{display:block;height:.9rem;background:var(--mdl);border-radius:2px;min-width:2px}
section.demo .app .bar .n{font:12.5px var(--mono);text-align:right}
section.demo .app .laps{font:13px/1.5 var(--mono);margin:.4rem auto;max-width:14rem;padding-left:0;list-style:none;text-align:center}
section.demo .demo-log{border-top:1px dashed var(--line);padding:.3rem .8rem .5rem}
section.demo .demo-log-label{font-size:.78rem;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
section.demo ol.log{list-style:none;margin:.2rem 0 0;padding:0;max-height:12rem;overflow:auto;font:12px/1.45 var(--mono)}
section.demo ol.log li{white-space:normal;overflow-wrap:anywhere;padding:.15rem 0;border-bottom:1px solid var(--shade)}
section.demo ol.log li:first-child{background:var(--msg-soft)}
section.demo .demo-noscript{color:var(--muted);font-size:.9rem}
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
