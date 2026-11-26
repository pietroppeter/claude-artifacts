## faretto, the command line VM: like `pharo Pharo.image eval ...`.
##   faretto <image.nif> <proc> [arg ...] [--save]
## An argument is an integer, a global of the image (by name) or a string.
import std/[os, strutils, monotimes, times]
import faretto/vm

proc main =
  let args = commandLineParams()
  if args.len < 2: quit "usage: faretto <image.nif> <proc> [arg ...] [--save]"
  let file = args[0]
  let v = newVM(loadImage(readFile(file)))
  var callArgs: seq[Value]
  var save = false
  for a in args[2 .. ^1]:
    if a == "--save": save = true
    elif a.len > 0 and a.allCharsInSet({'0'..'9', '-'}): callArgs.add intV(parseBiggestInt(a))
    else:
      try: callArgs.add v.global(a)
      except VMError: callArgs.add strV(a)
  let t0 = getMonoTime()
  let r = v.call(args[1], callArgs)
  let ms = (getMonoTime() - t0).inMicroseconds.float / 1000
  if r.kind == vStr: echo r.s else: echo v.inspect(r)
  stderr.writeLine "faretto: ", v.steps, " nodes in ", ms.formatFloat(ffDecimal, 1), " ms"
  if save: writeFile(file, saveImage(v.img))

main()
