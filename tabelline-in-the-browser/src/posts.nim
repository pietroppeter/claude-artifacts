## Builds the two posts about tabelline in the browser, moved here from tabelline's devlog, each as
## one file, with their links pointed at this site:
##
## - ../../tabelline-from-gleam/index.html: "tabelline in the browser, from Gleam", the research
## - ../../tabelline-in-a-lustre-app/index.html: "tabelline in a Lustre app", what was built
##
##   nim r posts.nim [path to a tabelline checkout]   (default ../../../tabelline)
##
## The checkout must have the posts (docs/devlog/gleam_browser.nim, docs/devlog/gleam_lustre.nim,
## with their data) and its setup done (`sh tools/setup.sh`). Each post is built there with
## -d:singleFile, so its style, fonts and review mode are inlined.
import std/[os, osproc, strutils]

let
  here = currentSourcePath().parentDir
  root = here.parentDir.parentDir
  tabelline = absolutePath(if paramCount() > 0: paramStr(1) else: root.parentDir / "tabelline")
  tabellineSite = "https://pietroppeter.github.io/tabelline/"
  site = "https://pietroppeter.github.io/claude-artifacts/"
  demo = site & "tabelline-in-the-browser/"

proc build(source, folder, slug: string, swaps: openArray[(string, string)]) =
  let cmd = "cd " & quoteShell(tabelline) & " && nim r -d:release -d:singleFile --hints:off docs/devlog/" & source & ".nim"
  if execCmd(cmd) != 0: quit "building " & source & " failed"
  var html = readFile(tabelline / "docs" / "devlog" / folder / "index.html")
  proc swap(old, new: string) =
    if old notin html: quit source & ": not in the page: " & old
    html = html.replace(old, new)
  # the page lives here now: its header leads to tabelline's site and devlog
  swap("href=\"../../\"", "href=\"" & tabellineSite & "\"")
  swap("href=\"../\"", "href=\"" & tabellineSite & "devlog/\"")
  for (old, new) in swaps: swap(old, new)
  createDir(root / slug)
  writeFile(root / slug / "index.html", html)
  echo "wrote ", root / slug / "index.html"

build("gleam_browser", "gleam-browser", "tabelline-from-gleam", [
  ("href=\"https://claude.ai/artifact/15qsuyTtVujSYgdkZYzN3h\"", "href=\"" & demo & "\"")])

build("gleam_lustre", "gleam-lustre", "tabelline-in-a-lustre-app", [
  ("<a href=\"https://claude.ai/artifact/DXJQBmhiJBnUpoo8Vi29UN\">The demo</a> is one HTML file (on\n<a href=\"https://pietroppeter.github.io/tabelline-polyglot/\">GitHub Pages</a> once it is merged).",
   "<a href=\"" & demo & "\">The demo</a> is one HTML file, with its Gleam code explained under it."),
  ("<em>tabelline in the browser, from Gleam</em>",
   "<a href=\"" & site & "tabelline-from-gleam/\"><em>tabelline in the browser, from Gleam</em></a>")])
