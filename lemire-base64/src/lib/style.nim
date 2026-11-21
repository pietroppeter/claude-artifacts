## The style module of the base64 benchmark page: every colour and CSS rule, from named tokens.
## Airmail: an envelope's red and blue stripes, Bricolage Grotesque and Source Sans; Nim's crown gold for Nim. Series colours are slots 1-3 of the validated default
## categorical palette (dataviz skill), as in the other explainers of this project.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Source+Sans+3:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#f6f7fb", "--card": "#eceff6", "--ink": "#14213d", "--muted": "#4f5873",
    "--line": "#d9deea", "--accent": "#1d4e9e", "--airmail-red": "#c8102e", "--airmail-blue": "#1d4e9e",
    "--gold": "#f4c300", "--goldsoft": "#fdf0b8", "--white": "#ffffff",
    "--one": "#2a78d6",
    "--nimib": "#f4c300", "--reading": "#1baf7a", "--careful": "#eb6834", "--paper-note": "#2a78d6",
    "--code-bg": "#ffffff",
    # the names the review mode (shared/review, tabelline's) reads, from this page's own
    "--surface": "#ffffff", "--shade": "#eceff6", "--secondary": "#f4c300", "--secondary-soft": "#fdf0b8",
    "--primary-text": "#8a3550", "--font": "\"Source Sans 3\", system-ui, sans-serif", "--mono": "\"JetBrains Mono\", monospace", "--kw": "#8a1f7a", "--str": "#2d7a3a", "--num": "#9a5b00", "--com": "#7d8399"}
  css = """
*{box-sizing:border-box}
[hidden]{display:none!important}
html{background:var(--paper)}
body{margin:0 auto;max-width:760px;padding:0 18px 48px;color:var(--ink);background:var(--paper);
  font:17px/1.6 "Source Sans 3",system-ui,sans-serif}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;gap:12px;
  font:12px "Source Sans 3",sans-serif;color:var(--muted);padding:12px 0}
header{border-bottom:4px solid;border-image:repeating-linear-gradient(135deg,var(--airmail-red) 0 9px,var(--paper) 9px 14px,var(--airmail-blue) 14px 23px,var(--paper) 23px 28px) 4} footer .nb-box{border-top:1px solid var(--line);margin-top:40px}
header a,footer a{color:var(--muted)}
h1,h2,h3{font-family:"Bricolage Grotesque",system-ui,sans-serif;line-height:1.12;font-weight:700}
h1{font-size:clamp(34px,8vw,54px);margin:28px 0 8px}
h2{font-size:28px;margin:52px 0 10px}
h2::before{content:"";display:block;width:72px;height:6px;margin-bottom:12px;
  background:repeating-linear-gradient(135deg,var(--airmail-red) 0 9px,var(--paper) 9px 14px,var(--airmail-blue) 14px 23px,var(--paper) 23px 28px)}
h1 strong{background:linear-gradient(transparent 60%,var(--gold) 60%);font-weight:700}
h3{font-size:20px;margin:28px 0 6px}
a{color:var(--accent);text-underline-offset:3px}
.lede{font-size:19px;line-height:1.55;color:var(--muted)}
.lede p{margin:8px 0}
p code,li code{font:14px "JetBrains Mono",monospace;background:var(--card);padding:1px 5px;border-radius:4px}
blockquote{margin:16px 0;padding:8px 16px;border-left:4px solid var(--accent);background:var(--card)}
table{border-collapse:collapse;display:block;overflow-x:auto;margin:14px 0;font-size:15px}
th{text-align:left;font-weight:600;border-bottom:2px solid var(--ink);padding:6px 8px}
td{border-bottom:1px solid var(--line);padding:6px 8px;vertical-align:top}
details{margin:14px 0;border:1px solid var(--line);border-radius:8px;padding:4px 14px;background:var(--card)}
details summary{cursor:pointer;font-weight:600;color:var(--muted);padding:6px 0}

/* code: small, scrolls inside its box (nimib-theme rules) */
body pre{margin:12px 0;overflow-x:auto;max-width:100%}
body pre > code{font-variant-ligatures:none;display:block;overflow-x:auto;padding:12px 14px;font:13px/1.5 "JetBrains Mono",monospace;
  background:var(--code-bg);border-radius:6px;border:1px solid var(--line)}
body pre.nb-output{padding:10px 14px;font:13px/1.5 "JetBrains Mono",monospace;background:var(--ink);color:var(--paper);
  border-radius:6px;white-space:pre}
.hljs-keyword{color:var(--kw);font-weight:600}.hljs-string{color:var(--str)}
.hljs-number,.hljs-literal,.hljs-type,.hljs-built_in{color:var(--num)}.hljs-comment{color:var(--com);font-style:italic}

/* files (nimib's nbFile): a name and a line count over the code, folded or not */
.nb-file{margin:12px 0}
details.nb-file{border:1px solid var(--line);border-radius:8px;background:var(--white);padding:0 12px}
details.nb-file[open]{padding-bottom:2px}
.nb-file-head{font:14px "JetBrains Mono",monospace;padding:10px 0;color:var(--ink)}
summary.nb-file-head{cursor:pointer;min-height:44px;display:list-item}
.nb-file-head code{font:600 14px "JetBrains Mono",monospace}
.nb-file-head .nb-small{color:var(--muted);font:13px "Source Sans 3",sans-serif;margin-left:6px}
details.nb-file pre{margin:0 0 10px}

/* notes */
.note{margin:18px 0;padding:10px 14px 4px;border-radius:8px;background:var(--card);border-left:5px solid var(--paper-note)}
.note.nimib{border-left-color:var(--nimib)} .note.reading{border-left-color:var(--reading)} .note.careful{border-left-color:var(--careful)}
.note-label{display:block;font:600 12px "Source Sans 3",sans-serif;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.note p{margin:4px 0 8px}

/* stat tiles */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:18px 0}
.stat{background:var(--white);border:1px solid var(--line);border-radius:10px;padding:12px 14px}
.stat-value{font:700 30px "Bricolage Grotesque",system-ui,sans-serif}
.stat-label{font-size:14px;color:var(--muted);line-height:1.35}

/* bars */
.legend{display:flex;flex-wrap:wrap;gap:12px;font-size:13px;color:var(--muted);margin-bottom:8px}
.key{display:inline-flex;align-items:center;gap:5px}
.swatch{width:12px;height:12px;border-radius:3px;display:inline-block}
.swatch.round{border-radius:50%}
.bar-row{margin:6px 0 10px}
.bar-label{font-size:14px;margin-bottom:3px;overflow-wrap:anywhere}
.bar-line{display:flex;align-items:center;gap:6px;height:12px}
.bar{height:10px;border-radius:0 4px 4px 0;min-width:2px;background:var(--one)}
.bar-value{font:12px "JetBrains Mono",monospace;color:var(--muted);white-space:nowrap}
.chart-note{font-size:13px;color:var(--muted);margin:6px 0 0}
.bar.nim{background:var(--gold)} .bar.ffi{background:var(--goldsoft);outline:1px solid var(--gold)} .bar.other{background:var(--one)}
.swatch.nim{background:var(--gold)} .swatch.ffi{background:var(--goldsoft);outline:1px solid var(--gold)} .swatch.other{background:var(--one)}
.bar-label b{font-weight:600}
.chart{margin:18px 0;padding:12px 14px;border:1px solid var(--line);border-radius:14px;background:var(--white)}
figcaption{font-weight:600;margin:4px 0 6px}
.bar-label .muted{color:var(--muted)}

"""

proc useExplainerStyle*(nb: var Nb) =
  ## Replace nimib's default theme (water.css and highlight.js from CDNs) with this page's
  ## own CSS, so the page is self-contained. Code is highlighted at build time by nimib.
  var root = ":root{"
  for (name, value) in tokens:
    root.add name & ":" & value & ";"
  root.add "}"
  nb.doc.context["stylesheet"] = %(fonts & "<style>" & root & css & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["highlightJs"] = %""
  nb.doc.context["disableHighlightJs"] = %true
