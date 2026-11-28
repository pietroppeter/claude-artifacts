## toml-test with parsetoml: how many valid files it accepts and invalid files it rejects.
## Usage: tt_parsetoml <toml-test/tests> <files-toml-1.0.0|files-toml-1.1.0>
import std/[os, strutils], parsetoml
let base = paramStr(1)
var vok, vn, iok, inn = 0
for line in lines(base / paramStr(2)):
  if not line.endsWith(".toml"): continue
  var accepted = true
  try: discard parsetoml.parseString(readFile(base / line))
  except CatchableError, Defect: accepted = false
  if line.startsWith("valid/"):
    inc vn; (if accepted: inc vok)
  else:
    inc inn; (if not accepted: inc iok)
echo vok, "\t", vn, "\t", iok, "\t", inn
