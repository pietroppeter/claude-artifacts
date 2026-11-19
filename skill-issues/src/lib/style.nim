## The style module of the "Skill issues" explainer: every colour and CSS rule, from named tokens.
## Nim's crown gold on warm paper, IBM Plex type. Series colours are slots 1-3 of the validated default
## categorical palette (dataviz skill), as in the AI Gap explainer.
import std/json
import nimib

const
  fonts = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Condensed:wght@600;700&family=IBM+Plex+Sans:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;600&display=swap" rel="stylesheet">"""
  tokens = {
    "--paper": "#fbfaf4", "--card": "#f2efe1", "--ink": "#1c1b20", "--muted": "#5b5866",
    "--line": "#e4dfcc", "--accent": "#5a4700", "--gold": "#f4c300", "--goldsoft": "#fdf0b8", "--white": "#ffffff",
    "--one": "#2a78d6", "--two": "#eb6834", "--three": "#1baf7a",
    "--trace": "#2a78d6", "--state": "#1baf7a", "--judge": "#eb6834",
    "--paper-note": "#2a78d6", "--nimib": "#f4c300", "--reading": "#1baf7a", "--careful": "#eb6834",
    "--right": "#0ca30c", "--wrong": "#d03b3b",
    "--code-bg": "#ffffff",
    # the names the review mode (review/review.nim, tabelline's) reads, from this page's own
    "--surface": "#ffffff", "--shade": "#f2efe1", "--secondary": "#f4c300", "--secondary-soft": "#fdf0b8",
    "--primary-text": "#8a3550", "--font": "\"IBM Plex Sans\", system-ui, sans-serif", "--mono": "\"IBM Plex Mono\", monospace", "--kw": "#8a1f7a", "--str": "#2d7a3a", "--num": "#9a5b00", "--com": "#8c8676"}
  css = """
*{box-sizing:border-box}
[hidden]{display:none!important}
html{background:var(--paper)}
body{margin:0 auto;max-width:760px;padding:0 18px 48px;color:var(--ink);background:var(--paper);
  font:17px/1.6 IBM Plex Sans,system-ui,sans-serif}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;gap:12px;
  font:12px IBM Plex Sans,sans-serif;color:var(--muted);padding:12px 0}
header{border-bottom:1px solid var(--line)} footer .nb-box{border-top:1px solid var(--line);margin-top:40px}
header a,footer a{color:var(--muted)}
h1,h2,h3{font-family:"IBM Plex Sans Condensed",system-ui,sans-serif;line-height:1.12;font-weight:700}
h1{font-size:clamp(34px,8vw,54px);margin:28px 0 8px}
h2{font-size:28px;margin:52px 0 10px}
h2::before{content:"";display:block;width:44px;height:6px;border-radius:3px;background:var(--gold);margin-bottom:12px}
h1 strong{background:linear-gradient(transparent 60%,var(--gold) 60%);font-weight:700}
h3{font-size:20px;margin:28px 0 6px}
a{color:var(--accent);text-underline-offset:3px}
.lede{font-size:19px;line-height:1.55;color:var(--muted)}
.lede p{margin:8px 0}
p code,li code{font:14px "IBM Plex Mono",monospace;background:var(--card);padding:1px 5px;border-radius:4px}
blockquote{margin:16px 0;padding:8px 16px;border-left:4px solid var(--accent);background:var(--card)}
table{border-collapse:collapse;display:block;overflow-x:auto;margin:14px 0;font-size:15px}
th{text-align:left;font-weight:600;border-bottom:2px solid var(--ink);padding:6px 8px}
td{border-bottom:1px solid var(--line);padding:6px 8px;vertical-align:top}
details{margin:14px 0;border:1px solid var(--line);border-radius:8px;padding:4px 14px;background:var(--card)}
details summary{cursor:pointer;font-weight:600;color:var(--muted);padding:6px 0}

/* code: small, scrolls inside its box (nimib-theme rules) */
body pre{margin:12px 0;overflow-x:auto;max-width:100%}
body pre > code{font-variant-ligatures:none;display:block;overflow-x:auto;padding:12px 14px;font:13px/1.5 "IBM Plex Mono",monospace;
  background:var(--code-bg);border-radius:6px;border:1px solid var(--line)}
body pre.nb-output{padding:10px 14px;font:13px/1.5 "IBM Plex Mono",monospace;background:var(--ink);color:var(--paper);
  border-radius:6px;white-space:pre}
.hljs-keyword{color:var(--kw);font-weight:600}.hljs-string{color:var(--str)}
.hljs-number,.hljs-literal,.hljs-type,.hljs-built_in{color:var(--num)}.hljs-comment{color:var(--com);font-style:italic}

/* notes */
.note{margin:18px 0;padding:10px 14px 4px;border-radius:8px;background:var(--card);border-left:5px solid var(--paper-note)}
.note.nimib{border-left-color:var(--nimib)} .note.reading{border-left-color:var(--reading)} .note.careful{border-left-color:var(--careful)}
.note-label{display:block;font:600 12px IBM Plex Sans,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.note p{margin:4px 0 8px}

/* stat tiles */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:18px 0}
.stat{background:var(--white);border:1px solid var(--line);border-radius:10px;padding:12px 14px}
.stat-value{font:700 30px "IBM Plex Sans Condensed",system-ui,sans-serif}
.stat-label{font-size:14px;color:var(--muted);line-height:1.35}

/* setup knobs */
.knobs{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:8px;margin:18px 0}
.knob{border-radius:10px;padding:10px 12px;border:1px dashed var(--line);background:var(--white);display:flex;flex-direction:column;gap:2px}
.knob.yours{border:2px solid var(--ink);background:var(--goldsoft)}
.knob-tag{font:600 11px "IBM Plex Mono",monospace;text-transform:uppercase;letter-spacing:.08em;color:var(--muted)}
.knob-name{font:700 17px "IBM Plex Sans Condensed",system-ui,sans-serif}
.knob-what{font-size:14px;color:var(--muted);line-height:1.35}

/* tabs */
.tabbed{margin:18px 0;padding:12px 14px;border:1px solid var(--line);border-radius:14px;background:var(--white)}
.tabs{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px}
.tab{font:500 14px "IBM Plex Sans",sans-serif;padding:6px 12px;border-radius:999px;border:1px solid var(--line);
  background:var(--white);color:var(--ink);cursor:pointer}
.tab[aria-selected="true"]{background:var(--ink);color:var(--paper);border-color:var(--ink)}
figcaption{font-weight:600;margin:4px 0 6px}

/* lifecycle */
.steps{margin:0;padding-left:0;list-style:none;counter-reset:step}
.steps li{counter-increment:step;position:relative;padding:4px 0 4px 40px;border-bottom:1px solid var(--line)}
.steps li:last-child{border-bottom:0}
.steps li::before{content:counter(step);position:absolute;left:0;top:8px;width:28px;height:28px;border-radius:50%;
  background:var(--gold);color:var(--ink);font:700 15px "IBM Plex Mono",monospace;display:flex;align-items:center;justify-content:center}
.step-title{display:block;font-weight:700;margin-top:4px}
.steps p{margin:2px 0 6px;font-size:15px}

/* bars */
.legend{display:flex;flex-wrap:wrap;gap:12px;font-size:13px;color:var(--muted);margin-bottom:8px}
.key{display:inline-flex;align-items:center;gap:5px}
.swatch{width:12px;height:12px;border-radius:3px;display:inline-block}
.swatch.round{border-radius:50%}
.bar-row{margin:6px 0 10px}
.bar-label{font-size:14px;margin-bottom:3px;overflow-wrap:anywhere}
.bar-line{display:flex;align-items:center;gap:6px;height:12px}
.bar{height:10px;border-radius:0 4px 4px 0;min-width:2px;background:var(--one)}
.bar-value{font:12px "IBM Plex Mono",monospace;color:var(--muted);white-space:nowrap}
.chart-note{font-size:13px;color:var(--muted);margin:6px 0 0}
.bauplan{background:var(--one)} .pietro{background:var(--three)}
.estimate{background:repeating-linear-gradient(45deg,var(--one) 0 3px,var(--white) 3px 6px);outline:1px solid var(--one)}
.read{background:var(--one)} .write{background:var(--two)}
.trace{background:var(--trace)} .state{background:var(--state)} .judge{background:var(--judge)}

.bar-label .muted{color:var(--muted)}

/* curves */
svg.curve{display:block;width:100%;height:auto;max-width:560px;touch-action:manipulation}
svg.curve .grid{stroke:var(--line);stroke-width:1}
svg.curve .axis{font:10px "IBM Plex Mono",monospace;fill:var(--muted)}
svg.curve .line{fill:none;stroke-width:2}
svg.curve .line.val{stroke:var(--one)} svg.curve .line.test{stroke:var(--two)}
svg.curve .mark{stroke:var(--white);stroke-width:2}
svg.curve .mark.val{fill:var(--one)} svg.curve .mark.test{fill:var(--two)}
svg.curve .band.pick{fill:var(--goldsoft)} svg.curve .band.cursor{fill:none;stroke:var(--ink);stroke-width:1.5;stroke-dasharray:3 3}
svg.curve .hit{fill:transparent;cursor:pointer}
.swatch.val{background:var(--one)} .swatch.test{background:var(--two)} .swatch.gepa{background:var(--goldsoft);outline:1px solid var(--gold)}
.readout{font-size:15px;min-height:3em;margin:8px 0 0}

/* widgets */
.widget{margin:20px 0;padding:14px;border-radius:14px;border:2px solid var(--ink);background:var(--white);box-shadow:5px 5px 0 var(--gold)}
.widget-title{font:700 19px "IBM Plex Sans Condensed",system-ui,sans-serif}
.quiz-top{display:flex;justify-content:space-between;align-items:baseline}
.quiz-score{font:600 14px "IBM Plex Mono",monospace;color:var(--muted)}
.quiz-domain{margin:8px 0 0;font:600 12px "IBM Plex Mono",monospace;text-transform:uppercase;letter-spacing:.08em;color:var(--muted)}
.quiz-prompt{font-size:17px;min-height:4.5em;overflow-wrap:anywhere;margin-top:6px}
.quiz-buttons{display:flex;gap:8px}
.pick,.quiz-next{font:600 15px "IBM Plex Sans",sans-serif;padding:10px 0;border-radius:8px;border:2px solid;
  background:var(--white);color:var(--ink);cursor:pointer;flex:1}
.pick.trace{border-color:var(--trace)} .pick.state{border-color:var(--state)} .pick.judge{border-color:var(--judge)}
.pick:disabled{opacity:.55;cursor:default}
.pick.chosen{background:var(--goldsoft);opacity:1}
.quiz-feedback{min-height:1.6em;margin:10px 0 6px}
.quiz-feedback .right{color:var(--right);font-weight:600} .quiz-feedback .wrong{color:var(--wrong);font-weight:600}
.quiz-next{width:100%;border-color:var(--ink);background:var(--ink);color:var(--paper)}
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
