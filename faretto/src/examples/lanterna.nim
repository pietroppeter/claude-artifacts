import std/syncio

type
  Lamp = ref object
    kind: string
    watts: int
  Beacon = ref object
    name: string
    lamp: Lamp
    clock: int
    flashes: int

proc halt() = discard   # faretto opens its debugger here; compiled, it does nothing

proc lit(t: int): bool =
  ## the light's character, Fl(2) 6s: two flashes, then dark
  let p = t mod 6
  p == 0 or p == 2

proc glyph(on: bool): string =
  if on: "█" else: "·"

proc tick(b: Beacon): string =
  let on = lit(b.clock)
  if on: inc b.flashes
  inc b.clock
  glyph(on)

proc night(b: Beacon; seconds: int): string =
  result = ""
  for i in 0 ..< seconds:
    result.add tick(b)

proc report(b: Beacon): string =
  b.name & ": " & $b.flashes & " flashes in " & $b.clock & "s, " & b.lamp.kind & " lamp"

var spare = Lamp(kind: "oil", watts: 60)
var capo = Beacon(name: "Capo Nif", lamp: Lamp(kind: "LED", watts: 15))
echo night(capo, 12)
echo report(capo)
