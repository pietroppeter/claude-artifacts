## nimiboth: a minimal nimib that Nim 2 and Nimony both compile.
## Same idea as nimib 0.4: a document is a list of blocks, each block kind has a render proc,
## `nbCode` shows its own source and the stdout it printed. What it leaves out: nimib.toml,
## nbJs, Markdown and JSON backends, themes beyond one stylesheet.
##
## How to write code for both compilers, learnt here (each rule is a Nimony error):
## - the differences live in shim.nim; the one other `when defined(nimony)` is below: templates
##   that use the caller's `nb` need the "untyped" feature in Nimony
## - no procs that read a global `var` (Nimony asks for `.sync`): pass the document in
## - file I/O raises in Nimony: shim.nim catches it once, so no proc needs `.raises`
## - no `Table[]` (it raises KeyError in Nimony): renderers are a small seq
## - no strformat, sugar or jsony: `&` and plain loops
when defined(nimony):
  {.feature: "untyped".}
import std/strutils
import shim, markdown, highlight
export shim, markdown, highlight

type
  NbBlock* = ref object of RootObj
    kind*: string
  RenderProc* = proc (b: NbBlock): string {.nimcall.}
  Doc* = object
    title*: string
    filename*: string        ## where nbSave writes the page
    head*: string            ## extra HTML for <head>
    blocks*: seq[NbBlock]
    renderers*: seq[tuple[kind: string; render: RenderProc]]

  NbText* = ref object of NbBlock
    text*: string            ## Markdown
  NbCode* = ref object of NbBlock
    code*, output*: string
  NbFile* = ref object of NbBlock
    name*, content*, lang*: string
    folded*: bool
  NbRaw* = ref object of NbBlock
    html*: string
  NbJs* = ref object of NbBlock
    id*, code*, js*, error*: string
  NbData* = ref object of NbBlock
    id*, text*: string

proc addRenderer*(doc: var Doc; kind: string; render: RenderProc) =
  ## the render proc of a block kind; a later one for the same kind wins
  doc.renderers.add (kind: kind, render: render)

proc renderBlock*(doc: Doc; b: NbBlock): string =
  result = ""
  var i = doc.renderers.len - 1
  while i >= 0:
    if doc.renderers[i].kind == b.kind:
      return doc.renderers[i].render(b)
    dec i

proc renderText(b: NbBlock): string = markdown(NbText(b).text)

proc renderCode(b: NbBlock): string =
  let c = NbCode(b)
  result = "<pre><code class=\"nim\">" & highlightCode(c.code, "nim") & "</code></pre>\n"
  if c.output.len > 0:
    result.add "<pre class=\"nb-output\">" & esc(c.output) & "</pre>\n"

proc langOf*(name: string): string =
  if name.endsWith(".nim") or name.endsWith(".nims"): "nim"
  elif name.endsWith(".sh"): "sh"
  elif name.endsWith(".css"): "css"
  else: "text"

proc renderFile(b: NbBlock): string =
  let f = NbFile(b)
  let lines = f.content.splitLines.len
  let code = "<pre><code>" & highlightCode(f.content, f.lang) & "</code></pre>"
  if f.folded:
    result = "<details class=\"nb-file\"><summary><code>" & esc(f.name) & "</code> <span>" &
      $lines & " lines</span></summary>" & code & "</details>\n"
  else:
    result = "<figure class=\"nb-file\"><figcaption><code>" & esc(f.name) & "</code></figcaption>" &
      code & "</figure>\n"

proc renderRaw(b: NbBlock): string = NbRaw(b).html

proc renderJs(b: NbBlock): string =
  ## the element the block draws in, then its program. A browser build of Nimony ends its
  ## program by throwing "nim_exit(0)": that one is not an error.
  let j = NbJs(b)
  if j.js.len == 0:
    return "<pre class=\"nb-output\">nbJs: " & esc(j.error) & "</pre>\n"
  result = "<div class=\"nb-js\" id=\"" & esc(j.id) & "\"></div>\n<script>\n(function () {\ntry {\n" &
    j.js.replace("</script", "<\\/script") &
    "\n} catch (e) { if (String(e).indexOf('nim_exit(0)') < 0) throw e; }\n})();\n</script>\n"

proc renderData(b: NbBlock): string =
  ## text for a nbJs block to read, in a hidden element (its `textContent`)
  let d = NbData(b)
  "<pre hidden class=\"nb-data\" id=\"" & esc(d.id) & "\">" & esc(d.text) & "</pre>\n"

const jsdomSource = slurp("jsdom.nim")

proc compileJs*(id, code: string): NbJs =
  ## writes `code` to .nimiboth/<id>.nim after `import jsdom`, compiles it to JavaScript with the
  ## compiler that builds the page, and keeps the JavaScript
  result = NbJs(kind: "js", id: id, code: code)
  discard runCommand("mkdir -p .nimiboth")
  if not writeText(".nimiboth/jsdom.nim", jsdomSource) or
     not writeText(".nimiboth/" & id & ".nim", "import jsdom\n" & code & "\n"):
    result.error = "cannot write .nimiboth/"
    return
  let cmd = "cd .nimiboth && " & jsCommand & id & ".js " & id & ".nim > " & id & ".log 2>&1"
  if runCommand(cmd) != 0:
    result.error = "`" & cmd & "` failed:\n" & readText(".nimiboth/" & id & ".log")
    return
  result.js = readText(".nimiboth/" & id & ".js")

const themeCss* = slurp("theme.css")
  ## the default stylesheet, read at compile time (`slurp` works in both compilers)

proc initDoc*(title, filename: string): Doc =
  result = Doc(title: title, filename: filename, head: "<style>\n" & themeCss & "</style>\n")
  result.addRenderer("text", renderText)
  result.addRenderer("code", renderCode)
  result.addRenderer("file", renderFile)
  result.addRenderer("raw", renderRaw)
  result.addRenderer("js", renderJs)
  result.addRenderer("data", renderData)

proc render*(doc: Doc): string =
  result = "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">\n" &
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" &
    "<title>" & esc(doc.title) & "</title>\n" & doc.head & "</head>\n<body><main>\n"
  for b in doc.blocks:
    result.add renderBlock(doc, b)
  result.add "</main></body></html>\n"

proc add*(doc: var Doc; b: NbBlock) = doc.blocks.add b

# ------------------------------------------------------------------------------- the nb* API

template nbInit*(ttitle, tfilename: string) =
  ## creates `nb`, the document (a global of the page, used by templates only)
  var nb {.inject.} = initDoc(ttitle, tfilename)

template nbText*(ttext: string) =
  nb.add NbText(kind: "text", text: ttext)

template nbCode*(body: untyped) =
  ## runs `body` at top level (its names stay visible), shows its source and its stdout
  let cap = startCapture(".nimiboth-capture.txt")
  body
  nb.add NbCode(kind: "code", code: codeSource(body), output: stopCapture(cap))

template nbCodeSkip*(body: untyped) =
  ## shows `body` without compiling it
  nb.add NbCode(kind: "code", code: codeSource(body))

template nbFile*(tname: string; tfolded = true) =
  ## shows the file `tname` (read when the page is built), folded by default
  nb.add NbFile(kind: "file", name: tname, content: readText(tname), lang: langOf(tname),
                folded: tfolded)

template nbJsFromCode*(tid: string; body: untyped) =
  ## compiles `body` to JavaScript (`nimony j` under Nimony, `nim js` under Nim 2) and runs it
  ## in the page, in an element with id `tid`; its code follows, folded. `body` is not
  ## compiled into the page: only its source is taken.
  nb.add compileJs(tid, codeSource(body))
  nb.add NbFile(kind: "file", name: "the code of this block (nbJsFromCode)",
                content: codeSource(body), lang: "nim", folded: true)

template nbOutput*(ttext: string) =
  ## text shown as program output, like the output of nbCode
  nb.add NbRaw(kind: "raw", html: "<pre class=\"nb-output\">" & esc(ttext) & "</pre>\n")

template nbData*(tid, ttext: string) =
  ## text the page carries for nbJs blocks: `byId(tid).textContent`
  nb.add NbData(kind: "data", id: tid, text: ttext)

template nbRawHtml*(thtml: string) =
  nb.add NbRaw(kind: "raw", html: thtml)

template nbSave*() =
  if writeText(nb.filename, render(nb)):
    echo "nimiboth: wrote ", nb.filename, " (", compilerName, ")"
  else:
    echo "nimiboth: could not write ", nb.filename
