# capi.nim: plug A, a C ABI
proc mari_draw(request: cstring): cstring {.exportc, dynlib, cdecl.} =
  var answer: string
  try:
    answer = $draw(parseJson($request))
  except CatchableError as e:
    answer = $(%*{"ok": false, "code": "error", "message": e.msg})
  result = cast[cstring](allocShared0(answer.len + 1))   # the library allocates...
  copyMem(result, answer.cstring, answer.len)

proc mari_free(p: cstring) {.exportc, dynlib, cdecl.} = deallocShared(p)   # ...and frees
