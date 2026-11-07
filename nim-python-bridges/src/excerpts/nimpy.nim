# marinp.nim: plug B, the same library through nimpy
include capi
import nimpy

proc svg(source: string, layer: string = "{}"): string {.exportpy.} =
  let a = draw(%*{"source": source, "layer": parseJson(layer), "options": {}})
  if not a["ok"].getBool:
    raise newException(ValueError, a["code"].getStr & ": " & a["message"].getStr)
  a["svg"].getStr
