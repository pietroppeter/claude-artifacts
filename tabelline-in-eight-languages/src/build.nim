# Builds ../index.html: tabelline's devlog post "tabelline in eight languages", as one file,
# with Pietro's Bluesky post about it before the title.
#
#   nim r build.nim [path to a tabelline checkout]   (default ../../../tabelline)
#
# The checkout must have the post (docs/devlog/polyglot.nim) and its setup done
# (`sh tools/setup.sh`); this builds the post there with -d:singleFile, so its style, fonts and
# review mode are inlined, then adds the image and points the post's relative links at
# tabelline's site.
import std/[os, osproc, strutils, base64]

let
  here = currentSourcePath().parentDir
  tabelline = absolutePath(if paramCount() > 0: paramStr(1) else: here / ".." / ".." / ".." / "tabelline")
  site = "https://pietroppeter.github.io/tabelline/"

let cmd = "cd " & quoteShell(tabelline) & " && nim r -d:release -d:singleFile --hints:off docs/devlog/polyglot.nim"
if execCmd(cmd) != 0: quit "building the post failed"

var html = readFile(tabelline / "docs" / "devlog" / "polyglot" / "index.html")

proc swap(old, new: string) =
  if old notin html: quit "not in the page: " & old
  html = html.replace(old, new)

# The post's links to the rest of tabelline's site (the page lives elsewhere now).
swap("href=\"../polyglot-survey/\"", "href=\"" & site & "devlog/polyglot-survey/\"")
swap("href=\"../../\"", "href=\"" & site & "\"")
swap("href=\"../\"", "href=\"" & site & "devlog/\"")

# The image, first: a figure before the date line.
let img = "data:image/jpeg;base64," & encode(readFile(here / "bluesky.jpg"))
const style = """
<style>
figure.prefix{margin:0 0 2.5rem;padding:0 0 1.5rem;border-bottom:1px solid var(--line)}
figure.prefix img{display:block;width:100%;max-width:26rem;height:auto;margin:0 auto;border:1px solid var(--line);border-radius:12px}
figure.prefix figcaption{max-width:34rem;margin:1rem auto 0;color:var(--muted);font-size:.95rem;line-height:1.45}
</style>
"""
let figure = """<figure class="prefix">
<img src="$1" width="780" height="1201" alt="Pietro Peterlongo on Bluesky: “I still have to look at it, but this was just one of the various threads I launched to consume my sub before the weekly reset (since I used my extra reset). IT IS CRAZY 🤯”, quoting the summary Claude wrote at the end of the thread: tabelline now draws the same table from 8 languages, C, Zig, Rust, Julia, Java, Erlang, Gleam and Elixir, and each prints byte-identical HTML.">
<figcaption>Pietro on Bluesky, 11 November 2026, before reading the post below. The post is the
result of a one-shot experiment: one request to Claude, one thread, published here as it came
out, unedited. It is tabelline's devlog post, under review in
<a href="https://github.com/pietroppeter/tabelline/pull/96">tabelline#96</a>.</figcaption>
</figure>
""" % img
swap("</head>", style & "</head>")
swap("<p class=\"kicker\">", figure & "<p class=\"kicker\">")

writeFile(here / ".." / "index.html", html)
echo "wrote ", here / ".." / "index.html"
