## The look of the page (an animator's desk: paper on a peg bar, timing charts, blue and red
## pencil) and its blocks. No other file writes CSS or a colour.
##
##   nb.usePage(title, description)   # the look, the header and the footer
##   nbTitle kicker, title, lede      # the top of the page
##   nbNote text                      # a sheet set apart (Markdown)
##   nbStage id, caption              # an empty box a demo fills from Nim compiled to JS
import std/[json, strutils, strformat]
import nimib

func inline(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

const pageCss = """
:root{
  --paper:#f6f4ea; --card:#fffef8; --ink:#25262b; --muted:#6a6b70; --line:#d9d6c6; --shade:#ebe8da; --surface:#efece0;
  --blue:#2f6db5; --blue-soft:#dbe7f5; --red:#cf3f35; --red-soft:#f7dcd8; --green:#3c8a5a; --gold:#d9a521;
  --secondary:#2f6db5; --secondary-soft:#dbe7f5; --primary-text:#b23128;
  --font:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;
  --round:ui-rounded,"SF Pro Rounded","Avenir Next","Nunito",system-ui,sans-serif;
  padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0);
}
*{box-sizing:border-box}
[hidden]{display:none!important}
html{background:var(--paper)}
body{margin:0 auto;max-width:760px;padding:0 18px 70px;color:var(--ink);font:16.5px/1.62 var(--font);background:var(--paper)}
/* the peg bar: three slots at the top of every animation sheet */
header{position:relative;display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap;padding:30px 0 12px;
  font:12px var(--mono);color:var(--muted);border-bottom:1px solid var(--line)}
header::before{content:"";position:absolute;top:8px;left:50%;width:150px;height:12px;transform:translateX(-50%);
  background:radial-gradient(circle at 6px 6px,var(--line) 5.5px,transparent 6px) left/24px 12px no-repeat,
  linear-gradient(var(--line),var(--line)) center/60px 11px no-repeat,
  radial-gradient(circle at 6px 6px,var(--line) 5.5px,transparent 6px) right/24px 12px no-repeat;border-radius:6px}
footer .nb-box{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap;font:12px var(--mono);color:var(--muted);
  border-top:1px solid var(--line);margin-top:48px;padding:14px 0}
header a,footer a{color:var(--muted)}
.top{margin:30px 0 8px}
.top .kicker{font:12px var(--mono);letter-spacing:.12em;text-transform:uppercase;color:var(--red)}
.top h1{font:800 clamp(34px,8.5vw,58px)/1.02 var(--round);letter-spacing:-.02em;margin:8px 0 12px}
.top h1 em{font-style:normal;color:var(--blue)}
.top .lede{font-size:18.5px;color:#3a3b40;margin:0}
/* a timing chart before every section title: the key, then the in-betweens closer and closer */
h2{font:800 26px/1.15 var(--round);margin:52px 0 8px;padding-top:30px;position:relative}
h2::before{content:"";position:absolute;top:6px;left:0;width:148px;height:14px;
  background:linear-gradient(var(--ink),var(--ink)) 0 6px/148px 2px no-repeat,
  linear-gradient(var(--ink),var(--ink)) 0 0/2px 14px no-repeat,
  linear-gradient(var(--red),var(--red)) 52px 2px/2px 10px no-repeat,
  linear-gradient(var(--red),var(--red)) 86px 2px/2px 10px no-repeat,
  linear-gradient(var(--red),var(--red)) 108px 2px/2px 10px no-repeat,
  linear-gradient(var(--red),var(--red)) 122px 2px/2px 10px no-repeat,
  linear-gradient(var(--red),var(--red)) 131px 2px/2px 10px no-repeat,
  linear-gradient(var(--ink),var(--ink)) 146px 0/2px 14px no-repeat}
h3{font:700 19px/1.25 var(--round);margin:30px 0 6px;color:var(--blue)}
a{color:var(--blue);text-underline-offset:3px;text-decoration-thickness:1px}
p code,li code,td code{font:13.5px var(--mono);background:var(--shade);padding:1px 4px;border-radius:3px}
blockquote{margin:16px 0;padding:4px 16px;border-left:4px solid var(--blue);color:#3a3b40}
table{border-collapse:collapse;width:100%;margin:14px 0;font-size:14.5px;line-height:1.42;display:block;overflow-x:auto}
th{text-align:left;font:600 12px var(--mono);color:var(--muted);border-bottom:2px solid var(--ink);padding:6px 8px;vertical-align:bottom}
td{border-bottom:1px solid var(--line);padding:7px 8px;vertical-align:top;min-width:7em}
td:first-child{font-weight:700}
.note{margin:18px 0;padding:12px 16px;background:var(--card);border:1px solid var(--line);border-left:5px solid var(--red)}
.note p,.note ul,.note ol{margin:.35em 0}
/* code: small, scrolling inside its box */
pre{overflow-x:auto;margin:12px 0}
body pre > code{display:block;overflow-x:auto;padding:12px 14px;font:12.8px/1.55 var(--mono);background:var(--card);
  border:1px solid var(--line);border-radius:6px;color:#2b2c31}
body pre.nb-output,body pre.out{display:block;overflow-x:auto;padding:10px 14px;font:12.5px/1.45 var(--mono);background:#26272c;
  color:#ecebe4;border-radius:6px;white-space:pre}
.hljs-keyword{color:#8a3fa0;font-weight:600}.hljs-type,.hljs-built_in{color:#a35f00}.hljs-string{color:#3c8a5a}
.hljs-number,.hljs-literal{color:#b23128}.hljs-comment{color:#8d8b80;font-style:italic}.hljs-meta{color:#2f6db5}
.hljs-title,.hljs-function{color:#2f6db5}
/* demos */
figure.stage{margin:20px 0;padding:10px;background:var(--card);border:1.5px solid var(--ink);border-radius:12px;box-shadow:4px 4px 0 var(--line)}
figure.stage svg{display:block;width:100%;height:auto;touch-action:none;user-select:none;-webkit-user-select:none}
figure.stage figcaption{font-size:14px;color:var(--muted);margin:8px 2px 0;line-height:1.45}
.ctl{display:flex;flex-wrap:wrap;gap:6px;margin:8px 0 0}
.ctl button,.ctl label{font:600 13px var(--mono);border:1.5px solid var(--ink);background:var(--paper);color:var(--ink);
  border-radius:999px;min-height:40px;padding:0 14px;cursor:pointer;display:inline-flex;align-items:center;gap:6px}
.ctl button.on{background:var(--blue);color:#fff;border-color:var(--blue)}
.ctl input[type=range]{flex:1;min-width:160px;accent-color:var(--red)}
.ctl .read{font:12.5px var(--mono);color:var(--muted);align-self:center}
svg .track{stroke:var(--line);stroke-width:2}
svg .lbl{font:12px var(--mono);fill:var(--muted)}
svg .tile{stroke:var(--ink);stroke-width:2}
svg .letter{font:800 22px var(--round);fill:var(--ink);text-anchor:middle;dominant-baseline:central}
svg .eye{fill:#fff;stroke:var(--ink);stroke-width:1.5} svg .pupil{fill:var(--ink)}
svg .target{fill:none;stroke:var(--red);stroke-width:2}
svg .c0{fill:#f2b8b0} svg .c1{fill:#f6d58b} svg .c2{fill:#b9dcb4} svg .c3{fill:#b1cdee} svg .c4{fill:#d5c0ea} svg .c5{fill:#f3c4dc}
svg .k0{fill:var(--muted)} svg .k1{fill:var(--blue)} svg .k2{fill:var(--red)} svg .k3{fill:var(--green)}
svg .s0{stroke:var(--muted)} svg .s1{stroke:var(--blue)} svg .s2{stroke:var(--red)} svg .s3{stroke:var(--green)}
svg .curve{fill:none;stroke-width:2.5}
svg .hint{font:13px var(--font);fill:var(--muted);text-anchor:middle}
"""

func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header><span>a nimib notebook</span><span>research · zogyn &amp; parloku</span></header>"""

proc usePage*(nb: var Nb, title, description: string) =
  nb.doc.context["title"] = %title
  nb.doc.context["description"] = %description
  nb.doc.context["stylesheet"] = %("<style>" & pageCss & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["disableHighlightJs"] = %true
  nb.backend.partials["header"] = pageHeader

newNbBlock(NbTitle):
  kicker: string
  title: string
  lede: string
  toHtml:
    &"""<div class="top"><div class="kicker">{inline(blk.kicker)}</div><h1>{inline(blk.title)}</h1>""" &
      &"""<p class="lede">{inline(blk.lede)}</p></div>"""

template nbTitle*(tkicker, ttitle, tlede: string) =
  nb.add newNbTitle(kicker = tkicker, title = ttitle, lede = tlede)

newNbBlock(NbNote):
  text: string
  toHtml:
    &"""<div class="note">{markdownToHtml(blk.text)}</div>"""

template nbNote*(ttext: string) =
  nb.add newNbNote(text = ttext)

newNbBlock(NbStage):
  id: string
  caption: string
  toHtml:
    &"""<figure class="stage"><div id="{blk.id}"></div><figcaption>{inline(blk.caption)}</figcaption></figure>"""

template nbStage*(tid, tcaption: string) =
  ## an empty box for a demo: the page's script (Nim compiled to JS) fills `#tid`
  nb.add newNbStage(id = tid, caption = tcaption)
