## The same library as capi.nim, exported to Python with nimpy instead of a C ABI.
include capi
import nimpy

proc draw_json(request: string): string {.exportpy.} = $draw(parseJson(request))

proc svg(source: string, layer: string = "{}"): string {.exportpy.} =
  ## Raises: nimpy turns a Nim ValueError into a Python ValueError.
  let a = draw(%*{"source": source, "layer": parseJson(layer), "options": {}})
  if not a["ok"].getBool: raise newException(ValueError, a["code"].getStr & ": " & a["message"].getStr)
  a["svg"].getStr

proc pele(): string {.exportpy.} = peleVersion
proc echo_str(s: string): string {.exportpy.} = s
