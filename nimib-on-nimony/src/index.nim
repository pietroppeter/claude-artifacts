## nimib on Nimony: can nimib pages be compiled by Nim 3's compiler?
## This page is written with nimiboth (./nimiboth), a minimal nimib that Nim 2 and Nimony both compile.
## Build with Nimony:  nimony c -r index.nim   (writes ../index.html; see README.md)
## Build with Nim 2:   nim r index.nim
## run.sh does the experiment and writes its results to data/, which this page reads.
import std/strutils
import nimiboth/nimiboth
import site/blocks

nbInit("nimib on Nimony: an experiment", "../index.html")
nb.useSite

proc data(name: string): string = readText("data/" & name).strip
proc firstError(name: string): string =
  ## the first error line of `nimony check` on a module, without its path
  result = ""
  for line in data("check_" & name & ".txt").splitLines:
    let k = line.find("Error: ")
    if k >= 0: return line.substr(k + 7)
    if result.len == 0: result = line
  if result.len > 90: result = result.substr(0, 86) & " …"
proc kb(bytes: string): string =
  ## "307133" -> "307": `parseInt` raises in Nimony, and this needs no `try`
  if bytes.len > 3: bytes.substr(0, bytes.len - 4) else: "0"
proc linesOf(file: string): int = readText(file).splitLines.len

let nimonyAt = data("nimony_commit.txt")
let nimonyVersion = data("nimony_version.txt").replace("Nimony Compiler. Version ", "")

nbText "# nimib on Nimony"

nbLede """
[nimib](https://github.com/pietroppeter/nimib) turns a Nim program into a web page: the text,
the code and the code's output, like a notebook. [Nimony](https://github.com/nim-lang/nimony)
is a new Nim compiler, the one [meant to become Nim 3](https://github.com/nim-lang/nimony/blob/master/doc/differences.md),
built as a chain of tools that pass **NIF** files (a text format for code) to each other.
Can a nimib page be compiled by Nimony? I tried, it can't, and so I wrote a small nimib that
both compilers accept: this page is built with it, by Nimony. Then: would a nimib for both
compilers be feasible, and a good idea?
"""
nbBuilt()
nbReview("nimib-on-nimony", "nimib on Nimony", "nimib-on-nimony/src/index.nim", 2)

nbTldr("""
- **nimib does not compile with Nimony today**, and neither does the Nimony explainer. The first
  error is an import cycle inside nimib; behind it are macros, missing stdlib modules and
  Nimony's stricter rules on exceptions and globals.
- **Patching does not get far.** Fixing one nimib module by hand clears its first errors and
  shows the next ones. nimib's dependencies (nim-markdown, jsony, parsetoml, tabelline) stop too.
- **A small nimib for both compilers works.** nimiboth is """ & $(linesOf("nimiboth/nimiboth.nim") +
  linesOf("nimiboth/shim.nim") + linesOf("nimiboth/markdown.nim") + linesOf("nimiboth/highlight.nim") +
  linesOf("nimiboth/plugins/codesource.nim")) & """ lines of Nim (not counting its JS bindings): blocks, `nbText`, `nbCode` with its
  source and output, `nbFile`, custom blocks. Nim 2 and Nimony build the same test page byte
  for byte, and Nimony builds this page.
- **Nim in the page works too.** `nbJsFromCode` compiles a block to JavaScript with the page's
  compiler; the demo is a [NIF explorer](#nif) of a small module at four stages of Nimony.
- **Feasible: yes for the core.** The cost is everything around it: Markdown, JSON, TOML,
  Karax and the rest of nimib's JS family. **Good idea: yes, in steps**, starting with changes that also make nimib better on
  Nim 2, and not before Nimony's first stable release.
""")

# ====================================================================================== 1
nbChapter("experiment", "What I tried", "Nimony " & nimonyVersion & " at " & nimonyAt)

nbText """
Building Nimony is easy: clone [nim-lang/nimony](https://github.com/nim-lang/nimony), then
`nim c -r src/hastur/hastur build all` builds the compiler and its tools with Nim 2 in about
three minutes. `nimony c -r hello.nim` works at once (`echo` lives in `std/syncio` now).

Then I pointed it at the Nimony explainer, with the same pinned dependencies (nimib, tabelline,
nim-markdown, jsony, parsetoml), and at each module on its own with `nimony check`. These are
the first errors, as `run.sh` records them:
"""

var rows: seq[seq[string]] = @[]
for (name, what) in [("page", "the explainer"), ("pathutils", "nimib/pathutils"),
                     ("logging", "nimib/logging"), ("sugars", "nimib/nimibSugars"),
                     ("markdown", "nim-markdown"), ("jsony", "jsony"),
                     ("tabelline", "tabelline/colors"), ("parsetoml", "parsetoml")]:
  rows.add @[what, "✗ " & firstError(name).replace("`", "'").replace("*", "\\*")]
nbTable("First error with `nimony check`", @["module", "first error"], rows)

nbText "Two of them in full, because the shape of the errors says more than the first line:"
nbErrors data("check_sugars.txt")
nbErrors data("check_pathutils.txt")

nbText """
**Do small changes get further?** One file at a time, yes. In `nimib/pathutils.nim` I replaced
the implicit generics with explicit ones, called `std/files` instead of `os.copyFile`, and
enabled the `canraise` feature: the first 8 errors went away, and 11 different ones took their
place (calls that raise outside a `try`, conversions passed to `var` parameters). That is a
port, module by module, through nimib and four libraries.
"""

# ====================================================================================== 2
nbChapter("why", "Why it breaks", "Nim 2 and Nimony, side by side")

nbText """
None of this is a bug in Nimony. Its [differences](https://github.com/nim-lang/nimony/blob/master/doc/differences.md)
and [porting guide](https://github.com/nim-lang/nimony/blob/master/doc/porting.md) say what
changes, and nimib leans on almost all of it.
"""

nbText "### Macros"
nbPair("""
nimib reads the source of `nbCode` with a macro: `lineInfoObj` gives the lines, `readFile`
gives the text. Blocks are declared with `newNbBlock`, a macro that uses `getTypeFields`,
`genAst` and `quote do`. jsony builds its (de)serializers from `getTypeImpl`.
""", """
Macros exist "for backwards compatibility" and run as separate programs. `std/macros` is small:
no `quote do`, `genAst`, `lineInfoObj`, `toStrLit`, `newLit` or `getTypeImpl`. The new way is a
**plugin**: a program that receives the call as a NIF tree, with line info, and returns a tree.
""")

nbText "### Exceptions"
nbPair("""
`readFile` raises `IOError`, and any proc may let it through. nimib does file I/O in many
places without saying so.
""", """
Errors are an `ErrorCode`. A proc that calls `readFile` must be marked `.raises` or catch it,
and so must its callers. The `canraise` feature does not lift this.
""")

nbText "### Globals, tables, generics"
nbPair("""
Procs read the global `nb`; `table[key]` raises `KeyError`, which nobody checks; a parameter
`x: AnyPath` makes a proc generic.
""", """
A proc that reads a global `var` needs `.sync` (`let` is fine); `table[key]` is `.raises`, so
it has the same problem as `readFile`; type-class parameters without `[T]` are not supported.
""")

nbText "### The standard library"
nbPair("""
nimib imports `strformat`, `sugar`, `macrocache`, `jsonutils`, `cgi`, `browsers`, the
compiler's `pathutils` and `highlite`; nim-markdown needs `re` (PCRE) and `htmlparser`;
tabelline uses `staticRead`.
""", """
Nimony's stdlib is a rewrite: none of those modules are there, the `os` procs take a `Path`,
not a `string`, and `staticRead` is spelled `slurp`. `json`, `tables`, `strutils`, `os`,
`osproc`, `unicode` are there.
""")

nbNote(nkNim2, """
Every one of these is also a page author's problem: a nimib page that uses `&"..."` in its
`nbText` needs `strformat`, which Nimony does not have. Code inside `nbCode` is compiled by the
compiler you choose, so it has to be Nimony code.
""")

# ====================================================================================== 3
nbChapter("nimiboth", "A minimal nimib for both compilers", "nimiboth, the library this page uses")

nbText """
So instead of porting nimib I wrote the smallest thing that still is nimib, in the part of the
language both compilers agree on: **nimiboth**. It keeps nimib 0.4's design, a document as a list
of blocks with one render proc per kind, and these blocks: `nbText` (Markdown), `nbCode`,
`nbCodeSkip`, `nbFile`, `nbRawHtml`, and custom blocks like the ones on this page.
"""

var mods: seq[seq[string]] = @[]
for (file, what) in [("nimiboth/nimiboth.nim", "documents, blocks, `nb*` templates, rendering"),
                     ("nimiboth/shim.nim", "**everything that differs** between the compilers"),
                     ("nimiboth/plugins/codesource.nim", "the Nimony plugin that reads a block's source"),
                     ("nimiboth/markdown.nim", "a small Markdown renderer"),
                     ("nimiboth/highlight.nim", "build-time highlighting for Nim and shell"),
                     ("nimiboth/jsdom.nim", "DOM bindings for `nbJsFromCode`, both JS back ends"),
                     ("nimiboth/theme.css", "the default theme")]:
  mods.add @["`" & file & "`", $linesOf(file), what]
nbTable("nimiboth, file by file", @["file", "lines", "what it does"], mods)

nbText """
The one real difference is how `nbCode` gets its source. In Nim 2 it is a macro, as in nimib.
In Nimony it is a **template plugin**: `template codeSource(body: untyped): string
{.plugin: "plugins/codesource".}`. The compiler builds the plugin, hands it the block as a NIF
tree, and the plugin finds the first and last line in the tree's line info, reads them from the
file and returns them as a string literal. The plugin is in the sources at the end.

The rest is written so that neither compiler complains:
"""
nbTable("The rules nimiboth follows, and why", @["rule", "because Nimony"], @[
  @["file I/O only through `readText` and `writeText` in `shim.nim`, which catch errors", "makes every caller of a raising proc say `.raises`"],
  @["no proc reads a global `var`; `nb` is used by templates at top level", "asks for `.sync`"],
  @["renderers in a `seq`, not a `Table`", "has a `[]` that raises `KeyError`"],
  @["no `parseInt` and no `Table[]` in the page either: they raise", "makes their caller handle a possible error"],
  @["loops over a block's fields go by index", "refuses a `for` over a field reached through a `ref`"],
  @["`&` and `$`, no `strformat`; plain loops, no `sugar`", "has neither module"],
  @["`slurp` for files read at compile time", "has no `staticRead`"],
  @["`{.feature: \"untyped\".}` in modules whose templates use the caller's `nb`", "binds template bodies early otherwise"],
  @["stdout captured with `dup`/`dup2` through `importc`", "has no `fusion/ioutils`"],
])

nbText """
Here is `nbCode` at work. When Nimony builds this page, this block was compiled by Nimony, its
source came from the plugin, and its output was captured by nimiboth:
"""
nbCode:
  proc fib(n: int): int =
    if n < 2: n else: fib(n - 1) + fib(n - 2)
  var shown = ""
  for i in 0 .. 10:
    shown.add $fib(i) & " "
  echo "compiled by ", compilerName
  echo "fib: ", shown

nbText """
Names defined in `nbCode` stay visible, as in nimib: the next block uses `fib` again.
"""
nbCode:
  echo "fib(30) = ", fib(30)

nbText """
A custom block is a `ref object of NbBlock`, a render proc and a template, with no macro. This
is the note block of this page (from `site/blocks.nim`):
"""
nbCodeSkip:
  type NbNote* = ref object of NbBlock
    level*: NoteKind
    text*: string

  proc renderNote(b: NbBlock): string =
    let n = NbNote(b)
    "<aside class=\"note " & noteClass(n.level) & "\">" & markdown(n.text) & "</aside>"

  doc.addRenderer("note", renderNote)      # in useSite
  template nbNote*(k: NoteKind; t: string) = nb.add NbNote(kind: "note", level: k, text: t)

nbText "Is it really the same program? `run.sh` builds a small test page, `t/hello.nim`, with each compiler and compares the two files:"
nbTable("The test page, built twice", @["compiler", "result"], @[
  @[data("nim_version.txt"), "✓ `hello.html`, " & $readText("data/hello_nim2.html").len & " bytes"],
  @["Nimony " & nimonyVersion, "✓ `hello.html`, " & $readText("data/hello_nimony.html").len & " bytes"],
  @["the two files", (if data("hello_same.txt") == "same": "✓ identical" else: "✗ different")],
])

nbNote(nkCareful, """
nimiboth is an experiment, not nimib. Its JS support is one block, `nbJsFromCode` (one
program per block, see [the NIF explorer](#nif)); there is no `nbJsFromCodeInBlock`, no Karax,
no sharing code between JS blocks. It has no `nimib.toml`, no Markdown or JSON backend, no `nbImage` path rewriting, and its Markdown is a subset (headings,
paragraphs, lists, quotes, fences, code, bold, italic, links; no tables or HTML: the tables on
this page are a custom block). Its capture
uses POSIX `dup2`, so it is Linux and macOS only.
""")

# ====================================================================================== 4
nbChapter("evolution", "What a nimib for both could look like", "a design, from what broke")

nbText """
nimiboth suggests a shape: a small core that both compilers accept, and everything else on top.

1. **A portable core** (`nimib/core`): the document, blocks as plain `ref object`s with a render
   proc each, `nbText`, `nbCode`, `nbFile`, `nbJsFromCode`, rendering to HTML, stdout capture. No macros, no
   `strformat`, no global `var` read by procs, I/O through a few procs that catch errors.
2. **One shim module** per compiler difference, as `nimiboth/shim.nim`: source capture (macro or
   plugin), C strings, file I/O. Nimony's `std/macros` keeps growing, so the shim can shrink.
3. **Swappable Markdown.** nim-markdown is the biggest dependency that does not compile. Either
   port it off `re` and `htmlparser`, or keep a small renderer in the core and use nim-markdown
   on Nim 2 when it is there.
4. **Nim 2 extras stay where they are:** jsony and the JSON backend, `nimib.toml` with
   parsetoml, Karax and HappyX blocks, the `newNbBlock` macro as sugar over plain blocks.
   `nbJsFromCode` itself can be in the core: nimiboth compiles it with `nimony j` or `nim js`,
   whichever builds the page, and a few DOM bindings cover both (the [NIF explorer](#nif)).
5. **A Nimony canary in CI:** build one core-only example with the Nimony nightly, so breakage
   shows the day it happens.
"""

nbText """
Some of the work helps nimib on Nim 2 as well, and costs little:
"""
nbTable("Small changes to nimib that need no decision", @["change", "why it helps Nim 2 too"], @[
  @["break the `jsutils` ↔ `renders` import cycle", "a cycle is a smell in either compiler"],
  @["explicit generics in `pathutils` (`[T: AnyPath](x: T)`)", "the same code, said plainly"],
  @["`slurp` instead of `staticRead` (tabelline too)", "both compilers know `slurp`"],
  @["file I/O in one module", "one place to report a missing file well"],
  @["custom blocks possible without the `newNbBlock` macro", "easier to read, to debug and to document"],
])

# ====================================================================================== 5b
nbChapter("nif", "Something JS: a NIF explorer", "nbJsFromCode, compiled by the page's compiler")

nbText """
nimib can run Nim in the page: `nbJsFromCode` compiles a block to JavaScript. nimiboth has it
too. The block's source comes from the same plugin (or macro) as `nbCode`; nimiboth writes it to
a file after `import jsdom`, a dozen DOM bindings that both JS back ends accept, and compiles
it with the compiler that builds the page: `nimony j --browser` under Nimony (its JavaScript
back end, *jorogumo*), `nim js` under Nim 2. The JavaScript goes into the page inline.

What to show with it? The thing Nimony is made of. Nimony is a chain of tools that pass
**NIF** files to each other (see the [Nimony explainer](https://pietroppeter.github.io/claude-artifacts/nimony-evolution/)).
Here is a small module:
"""
nbFile("nif/sample.nim", tfolded = false)
nbText "Nimony compiles and runs it (`run.sh` keeps the output):"
nbOutput data("sample_output.txt")

nbText """
and on the way it writes the module as NIF four times, once per stage. These are the real
files from `nimcache`, carried in the page. The explorer below shows them; it is written in Nim
and compiled to JavaScript by the same compiler that built this page.

How to read it:

- A node is `(tag child child …)`, and the explorer shows the file exactly as Nimony wrote it.
  Tap the arrow before a `(` to fold a node to `(tag … n)`, where n counts its children; nodes
  deeper than three levels start folded, as in a code editor.
- `.` is an empty slot (a proc with no pragmas has `.` where the pragmas go).
- `@…` after a node is where it came from in the source: column, line and file, written relative
  to the node around it to keep files small.
- `name.0.` is a symbol: a name the compiler has resolved, with a number that tells it apart
  from other things with the same name.

What each stage is, and what to look for:

- **parsed** (*nifler*, `.p.nif`): the syntax only. `square` is just a name.
- **checked** (*nimsem*, `.s.nif`): names resolved and types known. `square` is the symbol
  `square.0.`, its type is `(i 64)`, and `1 .. 3` is a call of the `..` iterator.
- **lowered** (*shoggoth*, `.x.nif`): the `for` loop is gone, its iterator inlined into a `loop`,
  and a `dce` node lists what the module uses, for dead-code elimination.
- **Leng** (`.c.nif`): the low-level IR the C and native back ends read. There is now a `main`
  proc with `argc` and `argv`, ready for C.
"""
for (st, file) in [("p", "sample.p.nif"), ("s", "sample.s.nif"), ("x", "sample.x.nif"), ("c", "sample.c.nif")]:
  nbData("nif-" & st, readText("data/nif/" & file).replace("/tmp/w/", ""))

nbJsFromCode("nifx"):
  const stages = [("p", "parsed", "nifler: the syntax tree, .p.nif"),
                  ("s", "checked", "nimsem: types and symbols resolved, .s.nif"),
                  ("x", "lowered", "shoggoth: iterators inlined, dead code marked, .x.nif"),
                  ("c", "Leng", "the low-level IR the C and native back ends read, .c.nif")]
  const blank = {' ', '\n', '\r', '\t'}

  proc esc(s: string): string =
    result = ""
    for c in s:
      case c
      of '&': result.add "&amp;"
      of '<': result.add "&lt;"
      of '>': result.add "&gt;"
      else: result.add c

  proc splitInfo(tok: string): (string, string) =
    ## `call@6,9` -> ("call", "@6,9"): the token, and its line info
    var inStr = false
    for i in 0 ..< tok.len:
      if tok[i] == '"': inStr = not inStr
      elif tok[i] == '@' and not inStr and i > 0: return (tok.substr(0, i - 1), tok.substr(i))
    result = (tok, "")

  proc colour(tok, tagClass: string): string =
    ## a token with its line info, in the colours of its kind
    let (text, info) = splitInfo(tok)
    let cls = if tagClass.len > 0: tagClass
              elif text.len > 0 and text[0] == '"': "s"
              elif text.len > 0 and text[0] in {'0'..'9', '-'}: "n"
              elif text == ".": "e"
              elif '.' in text: "y"
              else: "i"
    result = "<span class=\"" & cls & "\">" & esc(text) & "</span>"
    if info.len > 0: result.add "<span class=\"li\">" & esc(info) & "</span>"

  proc node(src: string; i: var int; depth: int; count: var int): string =
    ## the node at `src[i]`, as the NIF text it is, with its spacing kept; a node over several
    ## lines gets a fold button and starts folded from depth 3
    if src[i] != '(':
      var tok = ""
      var inStr = false
      while i < src.len and (inStr or src[i] notin blank + {'(', ')'}):
        if src[i] == '"': inStr = not inStr
        tok.add src[i]
        inc i
      return colour(tok, "")
    inc i
    var tag = ""
    while i < src.len and src[i] notin blank + {'(', ')'}:
      tag.add src[i]
      inc i
    inc count
    var kids = ""
    var n = 0
    while i < src.len and src[i] != ')':
      if src[i] in blank:
        kids.add src[i]
        inc i
      else:
        kids.add node(src, i, depth + 1, count)
        inc n
    if i < src.len: inc i   # the `)`
    let head = "<span class=\"p\">(</span>" & colour(tag, if tag.len > 0 and tag[0] == '.': "d" else: "t")
    if '\n' notin kids:   # a node on one line is not folded, as in a code editor
      return head & kids & "<span class=\"p\">)</span>"
    result = "<span class=\"nd" & (if depth >= 3: " c" else: "") & "\"><button class=\"fold\" type=\"button\"" &
      " aria-label=\"fold\"></button>" & head & "<span class=\"kids\">" & kids &
      "</span><span class=\"dots\"> … " & $n & "</span><span class=\"p\">)</span></span>"

  proc show(st: string) =
    let src = toNim(textContent(byId(toJs("nif-" & st))))
    var i = 0
    var count = 0
    var html = ""
    while i < src.len:
      if src[i] in blank:
        html.add src[i]
        inc i
      else:
        html.add node(src, i, 0, count)
    var what = ""
    for s in stages:
      if s[0] == st: what = s[2]
    setHtml(byId("nifx-what"), toJs(esc(what) & " · " & $count & " nodes · " & $src.len & " bytes"))
    setHtml(byId("nifx-code"), toJs(html))
    removeAll(".nifx-tabs button", "aria-pressed")
    setAttr(byId(toJs("nifx-" & st)), "aria-pressed", "true")

  proc showP() = show("p")
  proc showS() = show("s")
  proc showX() = show("x")
  proc showC() = show("c")
  proc openAll() = removeClassAll("#nifx-code .nd", "c")
  proc foldAll() = addClassAll("#nifx-code .nd .nd", "c")

  var ui = "<div class=\"nifx-tabs\" role=\"group\" aria-label=\"stage\">"
  for s in stages:
    ui.add "<button id=\"nifx-" & s[0] & "\" type=\"button\">" & s[1] & "</button>"
  ui.add "</div><div class=\"nifx-file\"><div class=\"nifx-bar\"><span id=\"nifx-what\"></span>" &
    "<span class=\"nifx-acts\"><button id=\"nifx-open\" type=\"button\">open all</button>" &
    "<button id=\"nifx-fold\" type=\"button\">fold all</button></span></div>" &
    "<pre><code id=\"nifx-code\"></code></pre></div>"
  setHtml(byId("nifx"), toJs(ui))
  onClick(byId("nifx-p"), showP)
  onClick(byId("nifx-s"), showS)
  onClick(byId("nifx-x"), showX)
  onClick(byId("nifx-c"), showC)
  onClick(byId("nifx-open"), openAll)
  onClick(byId("nifx-fold"), foldAll)
  toggleParentOnClick(byId("nifx-code"), ".fold", "c")
  show("p")

nbText """
The explorer parses NIF itself, in about 60 lines (in its code above, folded): the compiler's
own NIF reader uses memory-mapped files and does not compile to JavaScript.
"""

nbNote(nkCareful, """
What I saw, building this: Nimony's browser programs end by throwing `nim_exit(0)`, which
nimiboth catches; a callback that touches a global needs `{.cast(assumeSync).}` (jsdom's `sync`);
there is no `std/dom`, so the bindings are a handful of `{.importjs.}` procs. And size: the
explorer is """ & kb(data("js_bytes_nimony.txt")) & """ KB of JavaScript from Nimony,
""" & kb(data("js_bytes_nim2.txt")) & """ KB from Nim 2. Nimony's JS back end shares
its code generator with the WebAssembly one and keeps Nim's data in one linear memory buffer
([its design notes](https://github.com/nim-lang/nativenif/blob/6d40924/doc/web.md)), with its
runtime in the file; Nim 2 maps Nim's types to JavaScript's own.
""")

# ====================================================================================== 5
nbChapter("verdict", "Is it feasible? Is it a good idea?", "my answer, and what it rests on")

nbVerdict("Feasible?", """
**Yes for the core, and this page shows it**: one source builds the core with both
compilers, with one shim module and one small plugin. **The ecosystem is the real cost**: Markdown,
JSON serialization, TOML config, highlighting and the JS blocks beyond the simplest one
(Karax, shared code between blocks) are each a port or a rewrite, and
every library a page uses (tabelline here) must compile with Nimony too.
""")

nbVerdict("A good idea?", """
**Yes, in steps, and not all at once.** For it: nimib would be ready when people start writing
Nim 3, Nimony itself could document its stdlib with literate pages, and the core gets simpler
on Nim 2 too. Against it: Nimony is a moving target (this experiment ran on a commit from the
same evening), every feature would be tested on two compilers, and the macro-based
conveniences (`newNbBlock`, `&` in `nbText`) are what users like about nimib.

What I would do: the small changes above now, a portable core after Nimony's first stable
release, and no fork. A `when defined(nimony)` in every module would be the wrong way.
""")

nbNote(nkAside, """
Speed, measured once on the machine that built this page: Nimony builds it from scratch in about
5 seconds (each plugin is a program it compiles first) and again after an edit in half a
second; Nim 2 takes about a second and a half. And the two builds of this page, leaving out the
compiled JavaScript, differ in """ & data("explainer_difflines.txt") & """ lines of HTML: the ones
that print the compiler's name.
""")

# ====================================================================================== 6
nbChapter("sources", "All the sources", "folded: tap a file to open it")

nbText """
Everything this page is made of, as it was when this page was built. `run.sh` runs the
experiment; the page reads its results from `data/`.
"""
nbFile("index.nim")
nbFile("site/blocks.nim")
nbFile("site/style.css")
nbFile("nimiboth/nimiboth.nim")
nbFile("nimiboth/shim.nim")
nbFile("nimiboth/plugins/codesource.nim")
nbFile("nimiboth/markdown.nim")
nbFile("nimiboth/highlight.nim")
nbFile("nimiboth/jsdom.nim")
nbFile("nimiboth/theme.css")
nbFile("t/hello.nim")
nbFile("nif/sample.nim")
nbFile("run.sh")

nbText """
The review mode's script and styles come from this repository's `shared/review` (tabelline's
review mode), and are not shown here.
"""

nbSave()
