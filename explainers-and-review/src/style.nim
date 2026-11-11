## The look of the page (a theatre programme, for Operetta) and its blocks.
##
##   nb.usePage(title, description)    # the look, the header and the footer
##   nbTitle kicker, title, lede       # the top of the page, like a playbill
##   nbNote text                       # a sheet set apart (Markdown)
import std/[json, strutils, strformat]
import nimib

func inline(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

const pageCss = """
:root{
  --paper:#f6efe2; --ink:#22191a; --curtain:#8e1b23; --gold:#b8892d; --muted:#6d5f57;
  --line:#d8c9b0; --shade:#e9dfcc; --surface:#efe5d2; --card:#fbf6ec;
  --secondary:#c9a24a; --secondary-soft:#f1e2b8; --primary-text:#8e1b23;
  --font:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,serif; --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;
  padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0);
}
*{box-sizing:border-box}
[hidden]{display:none!important}
html{background:var(--paper)}
body{margin:0 auto;max-width:720px;padding:0 18px 70px;color:var(--ink);font:17px/1.62 var(--font);background:var(--paper)}
header,footer .nb-box{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap;font:12px var(--mono);letter-spacing:.06em;
  text-transform:uppercase;color:var(--muted);padding:14px 0}
header{border-bottom:3px double var(--ink)} footer .nb-box{border-top:3px double var(--ink);margin-top:48px}
header a,footer a{color:var(--muted)}
.playbill{text-align:center;margin:34px 0 10px}
.playbill .kicker{font:12px var(--mono);letter-spacing:.18em;text-transform:uppercase;color:var(--curtain)}
.playbill h1{font-size:clamp(34px,8vw,54px);line-height:1.05;margin:10px 0 12px;font-weight:700;letter-spacing:-.01em}
.playbill .lede{font-size:19px;font-style:italic;color:#3b2e2a;max-width:34em;margin:0 auto}
.playbill::after{content:"✦ ✦ ✦";display:block;margin-top:18px;color:var(--gold);letter-spacing:.6em}
h2{font-size:27px;line-height:1.15;margin:48px 0 8px;padding-top:12px;border-top:1px solid var(--ink)}
h2 + p{margin-top:6px}
h3{font-size:20px;margin:28px 0 6px;color:var(--curtain)}
a{color:var(--curtain);text-underline-offset:3px;text-decoration-thickness:1px}
p code,li code,td code{font:14px var(--mono);background:var(--shade);padding:1px 5px;border-radius:3px}
blockquote{margin:16px 0;padding:4px 18px;border-left:4px solid var(--gold);font-style:italic;color:#3b2e2a}
table{border-collapse:collapse;width:100%;margin:14px 0;font-size:15px;line-height:1.4;display:block;overflow-x:auto}
th{text-align:left;font:12px var(--mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted);
  border-bottom:2px solid var(--ink);padding:6px 8px;vertical-align:bottom}
td{border-bottom:1px solid var(--line);padding:7px 8px;vertical-align:top}
td:first-child{font-weight:700;white-space:nowrap}
.note{margin:18px 0;padding:12px 16px;background:var(--card);border:1px solid var(--line);border-top:4px solid var(--curtain)}
.note p{margin:.3em 0}
pre{overflow-x:auto;margin:14px 0}
body pre > code{display:block;overflow-x:auto;padding:12px 14px;font:12.8px/1.55 var(--mono);background:var(--card);border:1px solid var(--line)}
"""

func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header><span>Il programma di sala</span><span>a nimib page</span></header>"""

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
    &"""<div class="playbill"><div class="kicker">{inline(blk.kicker)}</div><h1>{inline(blk.title)}</h1>""" &
      &"""<p class="lede">{inline(blk.lede)}</p></div>"""

template nbTitle*(tkicker, ttitle, tlede: string) =
  nb.add newNbTitle(kicker = tkicker, title = ttitle, lede = tlede)

newNbBlock(NbNote):
  text: string
  toHtml:
    &"""<div class="note">{markdownToHtml(blk.text)}</div>"""

template nbNote*(ttext: string) =
  nb.add newNbNote(text = ttext)
