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
/* the post as the Nim forum shows it: its white page, dark bar, system font, orange links */
.forum { --f-ink: #292929; --f-muted: #5c5c5c; --f-bar: #17181f; --f-link: #f99c19; --f-tag: #6e3f8c; --f-line: #e5e5e5;
  margin: 1rem 0 1.6rem; background: #fff; color: var(--f-ink); border: 1px solid var(--f-line);
  font: 16px/24px -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif; overflow-wrap: anywhere; }
.forum .f-bar { background: var(--f-bar); color: #fff; padding: .55rem .8rem; font-weight: 700; font-size: 14px; }
.forum .f-bar span { color: #ffe953; }
.forum .f-body { padding: .6rem .8rem 1rem; }
.forum h1.f-title { font-size: 24px; font-weight: 700; line-height: 1.25; font-family: inherit; margin: .4rem 0 .2rem; color: var(--f-ink); }
.forum .f-tag { font-size: 13px; font-weight: 700; padding-bottom: .6rem; border-bottom: 1px solid var(--f-line); }
.forum .f-tag::before { content: ""; display: inline-block; width: 10px; height: 10px; margin-right: 5px; background: var(--f-tag); }
.forum .f-post { display: flex; gap: .6rem; padding-top: .6rem; }
.forum .f-avatar { flex: none; width: 40px; height: 40px; border-radius: 50%; background: #c9c9c9; color: #fff; font-weight: 700;
  display: flex; align-items: center; justify-content: center; }
.forum .f-main { flex: 1; min-width: 0; }
.forum .f-meta { display: flex; justify-content: space-between; color: var(--f-muted); font-weight: 700; }
.forum .f-meta span { font-weight: 400; }
.forum a { color: var(--f-link); text-decoration: none; }
.forum p { margin: 0 0 1rem; }
.forum img { display: block; max-width: 100%; height: auto; margin: 0 0 1rem; }
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

func autolink(line: string): string =
  ## Bare URLs become links, as the forum does.
  var i = 0
  while i < line.len:
    let j = line.find("https://", i)
    if j < 0 or (j > 0 and line[j - 1] in {'(', '<', '['}):
      result.add line[i .. ^1]; break
    var k = j
    while k < line.len and line[k] notin {' ', ')', '\n'}: inc k
    while k > j and line[k - 1] in {'.', ',', ':'}: dec k
    result.add line[i ..< j] & "<" & line[j ..< k] & ">"
    i = k

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
    elif line.startsWith("   :"): discard        # an option of the image above (its width)
    elif inFence: lines.add line
    else: lines.add autolink(line)
  lines.join("\n")

newNbBlock(NbPost):
  text: string
  title: string
  category: string
  author: string
  toHtml:
    # the Markdown renderer escapes the `;` of a data URL
    let body = markdownToHtml(blk.text).replace("data:image/png%3Bbase64", "data:image/png;base64")
    &"""<article class="forum"><div class="f-bar"><span>Nim</span> forum</div><div class="f-body">""" &
      &"""<h1 class="f-title">{esc(blk.title)}</h1><div class="f-tag">{esc(blk.category)}</div>""" &
      &"""<div class="f-post"><div class="f-avatar">{esc(blk.author[0 .. 0].toUpperAscii)}</div><div class="f-main">""" &
      &"""<div class="f-meta">{esc(blk.author)}<span>now</span></div>{body}</div></div></div></article>"""

template nbPost*(tfile, ttitle, tcategory, tauthor: string) =
  ## The post as the forum shows it: its title, category and author, and the text of `tfile`.
  let dir = nb.doc.thisFile.string.parentDir
  nb.add newNbPost(text = forPreview(readFile(dir / tfile), dir), title = ttitle, category = tcategory, author = tauthor)

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
