## Builds tabelline-in-the-browser/index.html: the demo of tabelline-polyglot (`lustre/demo/`),
## with its Gleam code shown and explained under the app. The code is read from the sources, so
## the page shows what runs.
##
##   # in tabelline-polyglot: nim r lustre/demo/build.nim   (writes lustre/demo/dist/index.html)
##   POLYGLOT=../tabelline-polyglot nim r tabelline-in-the-browser/src/build.nim
##
## Then run the post-build tools of this repository (codeblocks.py, backlink.py, phonecheck.js).
import std/[os, strutils]

let here = currentSourcePath.parentDir.parentDir
let polyglot = absolutePath(getEnv("POLYGLOT", here.parentDir.parentDir / "tabelline-polyglot"))

proc source(path: string): string = readFile(polyglot / path)

proc item(path, start: string): string =
  ## A top-level item of a Gleam file: from the line starting with `start` to the first `}`
  ## at the start of a line (or, for an `@external`, to the `fn` line under it).
  let lines = source(path).splitLines
  var i = 0
  while i < lines.len and not lines[i].startsWith(start): inc i
  if i == lines.len: quit "not found in " & path & ": " & start
  var j = i
  if start.startsWith("@external"):
    while not lines[j].startsWith("fn "): inc j
  else:
    while lines[j] != "}": inc j
  lines[i .. j].join("\n")

proc lines(path: string, first, last: string): string =
  ## The lines of a file from the one starting with `first` to the one starting with `last`.
  let ls = source(path).splitLines
  var i = 0
  while not ls[i].startsWith(first): inc i
  var j = i
  while not ls[j].startsWith(last): inc j
  ls[i .. j].join("\n")

proc esc(s: string): string =
  s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))

proc code(lang, text: string): string =
  "<pre><code class=\"language-" & lang & "\">" & esc(text) & "</code></pre>\n"

const demo = "lustre/demo/src/demo.gleam"
const view = "lustre/src/tabelline_lustre.gleam"

var article = """
<article class="page explained">
<style>
.explained h2 { font-size: 1.3rem; margin: 2.2rem 0 .3rem; }
.explained h3 { font-size: 1.05rem; margin: 1.6rem 0 .3rem; }
.explained p, .explained li { line-height: 1.55; }
.explained pre { background: #fff; border: 1px solid var(--line); border-radius: .5rem;
  padding: .7rem .8rem; overflow-x: auto; }
body .explained pre > code { font: 12.5px/1.45 ui-monospace, "SF Mono", Menlo, Consolas, monospace; overflow-x: auto; }
.explained .file { font-size: .8rem; color: var(--muted); margin: .8rem 0 -.2rem; }
.explained .file code { font-size: .8rem; }
</style>
<h2>The code, explained</h2>
<p>Everything above is about 370 lines of Gleam (<code>lustre/demo/src/demo.gleam</code>), a 70-line
module that turns a table into a Lustre element, and tabelline itself, compiled from Nim to
JavaScript. Here is the code that matters, from the simplest piece to the deepest, as it is in
<a href="https://github.com/pietroppeter/tabelline-polyglot">tabelline-polyglot</a>.</p>

<h3>1. Three functions make an app</h3>
<p>A <a href="https://hexdocs.pm/lustre/">Lustre</a> app is three functions. <code>init</code>
makes the first <em>model</em> (everything the page can change), <code>update</code> makes a new
model from a <em>message</em> (something the user did), <code>view</code> turns a model into the
page. <code>main</code> ties them together and mounts the app on the page's
<code>&lt;div id="app"&gt;</code>.</p>
"""
article.add "<p class=\"file\"><code>demo.gleam</code></p>\n"
article.add code("gleam", item(demo, "pub fn main()"))
article.add """
<h3>2. The model</h3>
<p>The model is a record: one field for every control. The palette is not a string but a
<code>Palette</code>, a type with one value per palette, so a palette that does not exist cannot
be written; the same for the dataset, and for the output (HTML, text or Markdown).</p>
"""
article.add code("gleam", item(demo, "pub type Model {"))
article.add code("gleam", item(demo, "fn init("))
article.add """
<h3>3. Messages</h3>
<p>Each control sends a message, named after what the user did. <code>update</code> answers each
with a new model: <code>Model(..model, title:)</code> is the old model with a new title (and
<code>title:</code> is short for <code>title: title</code>). Nothing is changed in place.</p>
"""
article.add code("gleam", item(demo, "pub type Msg {"))
article.add code("gleam", item(demo, "fn update("))
article.add """
<h3>4. The table</h3>
<p>This is tabelline's Gleam API. A table starts from a list of records (the planets), and each
column says how to get its value from a record: <code>column.int("moons", fn(planet) {
planet.moons })</code>. Then come the verbs, one per line, named after
<a href="https://gt.rstudio.com/">gt</a>'s: a stub and groups, a title, a spanner over two columns,
labels, number formats, a colour scale, a bold style on some cells, a footnote, a source note. The
model's values go in five places: the locale, the title, the decimals of the mass, the palette and
the number of moons above which a cell is bold. Building the table only collects all this; nothing
is drawn yet.</p>
"""
article.add code("gleam", item(demo, "fn planets_table("))
article.add """
<p>The second table is shorter: one of tabelline's datasets, shown by its first and last rows.</p>
"""
article.add code("gleam", item(demo, "fn dataset_table("))
article.add """
<h3>5. The view</h3>
<p><code>view</code> is called after every message. It builds both tables from the model, draws
them, and times how long tabelline takes (the "tabelline took" line). <code>draw</code> picks the
output.</p>
"""
article.add code("gleam", item(demo, "fn view("))
article.add code("gleam", item(demo, "fn draw("))
article.add """
<p>A control is a small function too. A slider sends an <code>Int</code>, not the text the browser
gives: the message is typed, so <code>update</code> never parses anything.</p>
"""
article.add code("gleam", item(demo, "fn slider("))
article.add """
<h3>6. A table is an element</h3>
<p><code>tabelline_lustre</code> is the bridge between tabelline and Lustre, 70 lines in all. It
asks tabelline for the HTML and puts it in the page as it is
(<code>unsafe_raw_html</code>: the name warns about HTML from users; tabelline escapes every value
it writes). If tabelline cannot draw the table, the page shows why, in a paragraph, and keeps
working.</p>
<p class="file"><code>lustre/src/tabelline_lustre.gleam</code></p>
"""
article.add code("gleam", item(view, "pub fn view_with("))
article.add """
<h3>7. Across the border: Gleam to Nim</h3>
<p><code>tabelline.to_html</code> writes the table as JSON and calls one function written in
another language. Gleam declares it with <code>@external</code>, once per target: on the BEAM it
is Erlang code that calls tabelline as a native library (a NIF); in the browser it is
JavaScript.</p>
<p class="file"><code>gleam/src/tabelline.gleam</code></p>
"""
article.add code("gleam", item("gleam/src/tabelline.gleam", "@external(erlang, \"tabelline_ffi\", \"render\")"))
article.add """
<p>The JavaScript side turns tabelline's answer into a Gleam <code>Result</code>, with the
<code>Ok</code> and <code>Error</code> of Gleam's own runtime.</p>
<p class="file"><code>gleam/src/tabelline_ffi.mjs</code></p>
"""
article.add code("javascript", lines("gleam/src/tabelline_ffi.mjs", "import { Ok", "}"))
article.add """
<p>And <code>tabelline_render</code> is Nim: tabelline compiled by <code>nim js</code>, which
reads the JSON, builds the table with the same code as everywhere else, and writes the HTML: the
same HTML, byte for byte, as tabelline in Nim, C, Rust or Erlang.</p>
<p class="file"><code>js/tabelline_js.nim</code></p>
"""
article.add code("nim", lines("js/tabelline_js.nim", "proc tabellineRender", "    result.value = cstring(e.msg)"))
article.add """
<p>Gleam for the app, Lustre for the page, Nim for the tables: one file, nothing on a server.</p>
</article>
"""

let built = polyglot / "lustre" / "demo" / "dist" / "index.html"
if not fileExists(built): quit "build the demo first: nim r lustre/demo/build.nim, in " & polyglot
var page = readFile(built)
const footer = "<footer class=\"page how\">"
if footer notin page: quit "no footer in the demo page"
page = page.replace(footer, article & footer)
writeFile(here / "index.html", page)
echo "tabelline-in-the-browser/index.html: ", getFileSize(here / "index.html") div 1024, " KB"
