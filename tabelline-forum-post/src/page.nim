## The blocks of the page. Its look is Munari, from nimconf-schedules' `style.nim` (no other
## file here writes CSS or a colour, but for the two small rules of `postCss`).
##
##   nb.usePage(title, description)   # Munari, header and footer
##   nbTitle kicker, title, lede      # the top of the page
##   nbNote text                      # a sheet set apart
##   nbPost "post.md"                 # the post as the forum will show it
##   nbPaste "post.md"                # the text to paste, with a Copy button
import std/[os, strutils, strformat, json, base64]
import nimib except md
import style

func esc(s: string): string = s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))
func inline(md: string): string = markdownToHtml(md).strip.replace("<p>", "").replace("</p>", "")

const postCss = """
.post { margin: 1rem 0 1.6rem; padding: .2rem 1rem .6rem; background: var(--surface); border-top: 3px solid var(--secondary); overflow-wrap: anywhere; }
.post img { display: block; max-width: 100%; height: auto; margin: 1rem 0; border: 1px solid var(--line); }
.paste pre > code { white-space: pre-wrap; overflow-wrap: anywhere; max-height: 28rem; overflow-y: auto; }
.paste button { font: inherit; font-weight: 700; color: var(--paper); background: var(--ink); border: 0; min-height: 44px; padding: 0 1rem; cursor: pointer; }
"""

newNbBlock(NbTitle):
  kicker: string
  title: string
  lede: string
  toHtml:
    &"""<p class="kicker">{inline(blk.kicker)}</p>""" & "\n" & &"<h1>{inline(blk.title)}</h1>\n" &
      &"""<div class="lede">{markdownToHtml(blk.lede)}</div>"""

template nbTitle*(tkicker, ttitle, tlede: string) =
  ## The top of the page: a small line (kicker), the title and the lede, all in Markdown.
  nb.add newNbTitle(kicker = tkicker, title = ttitle, lede = tlede)

newNbBlock(NbNote):
  text: string
  toHtml:
    &"""<div class="note">{markdownToHtml(blk.text)}</div>"""

template nbNote*(ttext: string) =
  ## A sheet set apart, with its straight top edge.
  nb.add newNbNote(text = ttext)

proc forPreview(post, dir: string): string =
  ## The forum's text as Markdown nimib renders: RST images become Markdown images, and a fence
  ## with no language is text (the output of `echo t`). An image of `shots/` is inlined, so the
  ## page shows it where remote images are blocked (a claude.ai artifact).
  var inFence = false
  var lines: seq[string]
  for line in post.splitLines:
    if line.startsWith(".. image:: "):
      var url = line[".. image:: ".len .. ^1].strip
      let local = dir / "shots" / url.extractFilename
      if "/shots/" in url and fileExists(local):
        url = "data:image/png;base64," & encode(readFile(local))
      lines.add "![](" & url & ")"
    elif line.startsWith("```"):
      lines.add(if not inFence and line == "```": "```text" else: line)
      inFence = not inFence
    else: lines.add line
  lines.join("\n")

newNbBlock(NbPost):
  text: string
  toHtml:
    # the Markdown renderer escapes the `;` of a data URL
    &"""<article class="post">{markdownToHtml(blk.text).replace("data:image/png%3Bbase64", "data:image/png;base64")}</article>"""

template nbPost*(tfile: string) =
  ## The post as the forum shows it (near enough: the forum has its own theme).
  let dir = nb.doc.thisFile.string.parentDir
  nb.add newNbPost(text = forPreview(readFile(dir / tfile), dir))

newNbBlock(NbPaste):
  text: string
  toHtml:
    """<div class="paste"><p><button type="button" id="copy-post">Copy the post</button></p>""" &
      """<pre><code class="language-text" id="post-text">""" & esc(blk.text.strip) & "</code></pre></div>" &
      """<script>document.getElementById('copy-post').addEventListener('click', function (e) {
  navigator.clipboard.writeText(document.getElementById('post-text').textContent)
    .then(function () { e.target.textContent = 'Copied'; });
});</script>"""

template nbPaste*(tfile: string) =
  ## The text to paste in the forum, as it is in `tfile`, with a button that copies it.
  nb.add newNbPaste(text = readFile(nb.doc.thisFile.string.parentDir / tfile))

proc usePage*(nb: var Nb, title, description: string) =
  ## Munari, from nimconf-schedules' style; a plain header and footer.
  nb.doc.context["title"] = %title
  nb.doc.context["stylesheet"] = %(&"""<meta name="description" content="{esc(description)}">""" & "\n" &
    """<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>👑</text></svg>">""" &
    "\n<style>\n" & pageCss & postCss & "</style>")
  nb.doc.context["highlight"] = %""
  nb.doc.context["nb_style"] = %""
  nb.doc.context["disableHighlightJs"] = %true
  nb.backend.partials["header"] = proc (blk: JsonNode, nb: Nb): string =
    """<header class="page"><span>A draft for the Nim forum</span></header>"""
  nb.backend.partials["footer"] = proc (blk: JsonNode, nb: Nb): string =
    """<footer class="page">Written with Claude, in a <a href="https://github.com/pietroppeter/nimib">nimib</a> 🐳 page.
<a href="https://github.com/pietroppeter/claude-artifacts/tree/main/tabelline-forum-post/src">Source</a>.</footer>"""
  nb.backend.partials["left"] = proc (blk: JsonNode, nb: Nb): string = ""
  nb.backend.partials["right"] = proc (blk: JsonNode, nb: Nb): string = ""

newNbBlock(NbRound):
  title: string
  text: string
  toHtml:
    let lines = blk.text.splitLines.len
    &"""<details class="foldcode"><summary>{inline(blk.title)} <span>{lines} lines</span></summary>""" &
      """<pre><code class="language-text">""" & esc(blk.text) & "</code></pre></details>"

template nbRound*(tfile, ttitle: string) =
  ## A review round, as exported, folded under `ttitle` (Markdown).
  nb.add newNbRound(title = ttitle, text = readFile(nb.doc.thisFile.string.parentDir / tfile).strip)
