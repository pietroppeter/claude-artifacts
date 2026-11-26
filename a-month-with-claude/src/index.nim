## A month of building with Claude, as an operetta: one article in three parts, made with
## nimib and tabelline. Writes ../index.html. See README.md for how to build it.
##
## The three parts were first written as posts in tabelline's devlog (7 November 2026) by its
## 0.1 *use it* thread, and moved here on 8 November because they are about the way of working,
## not about tabelline. Each part is a file included below, so the whole is one nimib document.
import std/[os, strutils, strformat, tables, json]
import nimib
import tabelline, tabelline/nimib
import mese, style, review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "index.html"
nb.doc.context["title"] = %"A month of building with Claude, as an operetta"
nb.doc.context["stylesheet"] = %pageStyle
nb.doc.context["highlight"] = %""
nb.doc.context["disableHighlightJs"] = %true
nb.doc.context["nb_style"] = %""
func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header class="sala"><a href="../">claude-artifacts</a><span>programma di sala</span></header>"""
func pageFooter(blk: JsonNode, nb: Nb): string =
  """<footer class="sala">Written with Claude in a <a href="https://github.com/pietroppeter/nimib">nimib</a> 🐳 notebook,
tables by <a href="https://github.com/pietroppeter/tabelline">tabelline</a>.
<a href="https://github.com/pietroppeter/claude-artifacts/tree/main/a-month-with-claude/src">Source</a> ·
data from GitHub's search API, public repositories only.</footer>""" & tabsScript
func empty(blk: JsonNode, nb: Nb): string = ""
nb.backend.partials["header"] = pageHeader
nb.backend.partials["footer"] = pageFooter
nb.backend.partials["left"] = empty
nb.backend.partials["right"] = empty
nbReview(tpage = "a-month-with-claude", tsource = "a-month-with-claude/src/index.nim")

# --------------------------------------------------------------------- tabs: Nim, Python, R
const lingue = [("nim", "👑 Nim"), ("python", "🐍 Python"), ("r", "🏴‍☠️ R")]

func escapeCode(code: string): string =
  code.strip(chars = {'\n'}).multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))

func tabsHtml(panels: openArray[string]): string =
  result = """<div class="lingue"><div class="lingue-tab" role="tablist">"""
  for i, (key, label) in lingue:
    result.add &"""<button type="button" role="tab" data-lingua="{key}" aria-selected="{i == 0}">{label}</button>"""
  result.add "</div>"
  for i, (key, label) in lingue:
    result.add &"""<div class="lingue-pannello" role="tabpanel" data-lingua="{key}"{(if i == 0: "" else: " hidden")}>{panels[i]}</div>"""
  result.add "</div>"

template nbTabs(python, r: string, body: untyped) =
  ## The Nim blocks `body` adds (code that runs, and its output) in a 👑 Nim tab, next to the
  ## same example in 🐍 Python (Great Tables) and 🏴‍☠️ R (gt), shown and not run.
  let first = nb.blocks.len
  body
  var nimSide = ""
  for i in first ..< nb.blocks.len:
    nimSide.add nb.render(nb.blocks[i])
  nb.blocks.setLen(first)
  nbRawHtml: tabsHtml([nimSide, "<pre><code class=\"language-python\">" & escapeCode(python) & "</code></pre>",
                       "<pre><code class=\"language-r\">" & escapeCode(r) & "</code></pre>"])

template parte(id, numero, titolo, lede: string) =
  nbRawHtml: "<h2 class=\"parte\" id=\"" & id & "\"><small>" & numero & "</small>" & titolo &
    "</h2><p class=\"lede\">" & lede & "</p>"

# ----------------------------------------------------------------------------------- cover
nbRawHtml: """
<div class="copertina">
<p class="sopra">An operetta in three parts</p>
<h1>A month of building<br>with <em>Claude</em></h1>
<p class="lede">Seven weeks of open source made with an AI agent, mostly from a phone: what happened, the
way of working that grew out of it, and the next part of that way of working, skills.</p>
<p class="data">Pietro Peterlongo · 7 November 2026</p>
</div>
<ol class="programma">
<li><span class="atto">Parte prima</span><div><a href="#part-one">The month in seven acts</a>
<p>289 pull requests in 30 public repositories, told as seven acts with one moment each, and the nineteen parts of a way of working that grew along the way.</p></div></li>
<li><span class="atto">Parte seconda</span><div><a href="#part-two">Operetta, a first sketch</a>
<p>The parts as five groups that a project picks from, by what it is and how far along it is.</p></div></li>
<li><span class="atto">Parte terza</span><div><a href="#part-three">Skills, from the beginning</a>
<p>What an agent skill is, where skills live in an open source project, who does them well, and how to tell whether one helps.</p></div></li>
</ol>
"""
nbVersion()

nbText: """
The three parts were first written on 7 November 2026 as posts in the devlog of
[tabelline](https://github.com/pietroppeter/tabelline), great tables for Nim, by the thread that
uses each tabelline release on real data. They are about the way of working rather than about
tabelline, so they live here, as one article. Every table in it is still a tabelline table.
"""

parte "part-one", "Parte prima", "The month in seven acts",
  "Seven weeks of open source made with Claude: what happened, one moment from each act, and the parts of a way of working that grew along the way."
include part1

parte "part-two", "Parte seconda", "Operetta, a first sketch",
  "A name for the way of working that grew in the month: parts that a project picks by what it is and how far along it is, and adds to as it grows."
include part2

parte "part-three", "Parte terza", "Skills, from the beginning",
  "What an agent skill is, where skills live in an open source project, who does them well, how they work from the phone, and how to tell whether one helps."
include part3

nbSave
