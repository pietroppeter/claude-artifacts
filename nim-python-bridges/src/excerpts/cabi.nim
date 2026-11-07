# capi.nim: the Nim half of plug A
proc mari_draw(request: cstring): cstring {.exportc, dynlib, cdecl.} =
  var answer: string
  try:
    answer = $draw(parseJson($request))
  except CatchableError as e:
    answer = $(%*{"ok": false, "code": "error", "message": e.msg})
  result = cast[cstring](allocShared0(answer.len + 1))
  copyMem(result, answer.cstring, answer.len)

proc mari_free(p: cstring) {.exportc, dynlib, cdecl.} = deallocShared(p)
