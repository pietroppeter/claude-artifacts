## Nim binding to simdutf's base64 decoder (the library behind the top six).
{.passL: "simdutf_wrap.o simdutf.o -lstdc++".}
proc nsu_max_len(i: cstring, n: csize_t): csize_t {.importc, cdecl.}
proc nsu_decode(i: cstring, n: csize_t, o: cstring): csize_t {.importc, cdecl.}
proc nsu_impl(): cstring {.importc, cdecl.}
proc nsu_version(): cstring {.importc, cdecl.}

proc simdutfInfo*(): string = "simdutf " & $nsu_version() & " (" & $nsu_impl() & ")"
proc maxLen*(s: string): int = int nsu_max_len(s.cstring, csize_t s.len)
proc decodeInto*(s: string, dst: var string): int =
  let r = nsu_decode(s.cstring, csize_t s.len, dst.cstring)
  if r == high(csize_t): raise newException(ValueError, "invalid base64")
  int r
proc decodeSimdutf*(s: string): string =
  result = newStringUninit(maxLen(s))
  result.setLen(decodeInto(s, result))
