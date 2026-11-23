## The explainer's own blocks, written for nimiboth: a type, a render proc, a template.
## Every style is in style.css; no HTML in the page itself.
when defined(nimony):
  {.feature: "untyped".}
import std/strutils
import ../nimiboth/nimiboth

type
  NbLede* = ref object of NbBlock
    text*: string
  NbTldr* = ref object of NbBlock
    text*: string
  NoteKind* = enum nkAside, nkCareful, nkNim2
  NbNote* = ref object of NbBlock
    level*: NoteKind
    text*: string
  NbChapter* = ref object of NbBlock
    id*, title*, span*: string
  NbTable* = ref object of NbBlock
    caption*: string
    header*: seq[string]
    rows*: seq[seq[string]]   ## Markdown cells; a cell starting with ✓ or ✗ is coloured
  NbPair* = ref object of NbBlock
    nim2*, nimony*: string    ## Markdown, side by side: Nim 2 on the left
  NbVerdict* = ref object of NbBlock
    question*, text*: string
  NbErrors* = ref object of NbBlock
    text*: string             ## compiler output, shown as it is
  NbBuilt* = ref object of NbBlock
  NbReview* = ref object of NbBlock
    page*, title*, source*: string
    version*: int

proc noteLabel(k: NoteKind): string =
  case k
  of nkAside: "Aside"
  of nkCareful: "Careful"
  of nkNim2: "For Nim 2 users"

proc noteClass(k: NoteKind): string =
  case k
  of nkAside: "aside"
  of nkCareful: "careful"
  of nkNim2: "nim2"

proc renderLede(b: NbBlock): string = "<div class=\"lede\">" & markdown(NbLede(b).text) & "</div>\n"
proc renderTldr(b: NbBlock): string =
  "<div class=\"tldr\"><span class=\"label\">The short version</span>" & markdown(NbTldr(b).text) & "</div>\n"
proc renderNote(b: NbBlock): string =
  let n = NbNote(b)
  "<aside class=\"note " & noteClass(n.level) & "\"><span class=\"label\">" & noteLabel(n.level) &
    "</span>" & markdown(n.text) & "</aside>\n"
proc renderChapter(b: NbBlock): string =
  let c = NbChapter(b)
  let span = if c.span.len > 0: "<span class=\"ch-span\">" & esc(c.span) & "</span>" else: ""
  "<h2 id=\"" & c.id & "\">" & inline(c.title) & span & "</h2>\n"
proc cell(tag, md: string): string =
  let cls = if md.startsWith("✓"): " class=\"ok\"" elif md.startsWith("✗"): " class=\"no\"" else: ""
  "<" & tag & cls & ">" & inline(md) & "</" & tag & ">"
proc renderTable(b: NbBlock): string =
  let t = NbTable(b)
  result = "<table>"
  if t.caption.len > 0: result.add "<caption>" & inline(t.caption) & "</caption>"
  result.add "<thead><tr>"
  for i in 0 ..< t.header.len: result.add cell("th", t.header[i])   # by index: Nimony refuses
                                                                   # a `for` over a field behind a `ref`
  result.add "</tr></thead><tbody>"
  for i in 0 ..< t.rows.len:
    result.add "<tr>"
    for j in 0 ..< t.rows[i].len: result.add cell("td", t.rows[i][j])
    result.add "</tr>"
  result.add "</tbody></table>\n"
proc renderPair(b: NbBlock): string =
  let p = NbPair(b)
  "<div class=\"pair\"><div class=\"nim2\"><span class=\"label\">Nim 2</span>" & markdown(p.nim2) &
    "</div><div class=\"nimony\"><span class=\"label\">Nimony</span>" & markdown(p.nimony) & "</div></div>\n"
proc renderVerdict(b: NbBlock): string =
  let v = NbVerdict(b)
  "<div class=\"verdict\"><p class=\"q\">" & inline(v.question) & "</p>" & markdown(v.text) & "</div>\n"
proc renderErrors(b: NbBlock): string = "<pre class=\"nb-err\">" & esc(NbErrors(b).text) & "</pre>\n"
proc renderBuilt(b: NbBlock): string =
  ## which compiler built the page you are reading: the page says it, it is not written by hand
  "<p class=\"built\"><span class=\"label\">This page was built by</span><span class=\"by\">" &
    esc(compilerName) & "</span><span>with nimiboth</span></p>\n"

# The review mode is the repository's one copy, in shared/review (tabelline's): its script, and
# the styles that review.nim keeps in a string (read from that file, so nothing is copied here).
const
  reviewJs = slurp("../../../shared/review/assets/review.js")
  reviewNim = slurp("../../../shared/review/review.nim")

proc reviewRules(): string =
  ## the `reviewRules` CSS of shared/review/review.nim
  let start = reviewNim.find("const reviewRules = \"\"\"")
  if start < 0: return ""
  let a = start + "const reviewRules = \"\"\"".len
  let b = reviewNim.find("\"\"\"", a)
  result = if b > a: reviewNim.substr(a, b - 1) else: ""
proc renderReview(b: NbBlock): string =
  let r = NbReview(b)
  "<p class=\"rv-enter\"><span class=\"rv-version\">Version " & $r.version & "</span></p>\n" &
    "<div id=\"review\" hidden data-page=\"" & esc(r.page) & "\" data-version=\"" & $r.version &
    "\" data-title=\"" & esc(r.title) & "\" data-source=\"" & esc(r.source) & "\" data-versions=\"\"></div>\n" &
    "<script>\ndocument.addEventListener('DOMContentLoaded', function () {\n" & reviewJs & "});\n</script>\n"

const
  fonts = "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n" &
    "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n" &
    "<link href=\"https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,400;0,600;0,700;1,400&family=IBM+Plex+Mono:wght@400;600&display=swap\" rel=\"stylesheet\">\n"
  styleCss = slurp("style.css")

proc useSite*(doc: var Doc) =
  ## the page's blocks and theme (after nimiboth's)
  doc.head.add fonts & "<style>\n" & styleCss & reviewRules() & "</style>\n"
  doc.addRenderer("lede", renderLede)
  doc.addRenderer("tldr", renderTldr)
  doc.addRenderer("note", renderNote)
  doc.addRenderer("chapter", renderChapter)
  doc.addRenderer("table", renderTable)
  doc.addRenderer("pair", renderPair)
  doc.addRenderer("verdict", renderVerdict)
  doc.addRenderer("errors", renderErrors)
  doc.addRenderer("built", renderBuilt)
  doc.addRenderer("review", renderReview)

template nbLede*(t: string) = nb.add NbLede(kind: "lede", text: t)
template nbTldr*(t: string) = nb.add NbTldr(kind: "tldr", text: t)
template nbNote*(k: NoteKind; t: string) = nb.add NbNote(kind: "note", level: k, text: t)
template nbChapter*(tid, ttitle: string; tspan = "") =
  nb.add NbChapter(kind: "chapter", id: tid, title: ttitle, span: tspan)
template nbTable*(tcaption: string; theader: seq[string]; trows: seq[seq[string]]) =
  nb.add NbTable(kind: "table", caption: tcaption, header: theader, rows: trows)
template nbPair*(tnim2, tnimony: string) = nb.add NbPair(kind: "pair", nim2: tnim2, nimony: tnimony)
template nbVerdict*(tq, t: string) = nb.add NbVerdict(kind: "verdict", question: tq, text: t)
template nbErrors*(t: string) = nb.add NbErrors(kind: "errors", text: t)
template nbBuilt*() = nb.add NbBuilt(kind: "built")
template nbReview*(tpage, ttitle, tsource: string; tversion = 1) =
  nb.add NbReview(kind: "review", page: tpage, title: ttitle, source: tsource, version: tversion)
