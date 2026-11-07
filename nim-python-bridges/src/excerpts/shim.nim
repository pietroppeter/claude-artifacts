# qjs.nim: what Nim sees of QuickJS
{.compile(qjsDir & "/quickjs.c", qjsFlags).}   # and libregexp.c, libunicode.c, dtoa.c
{.compile(here & "/mari_qjs.c", qjsFlags).}
proc mari_js_new(code: cstring, len: csize_t, err: ptr cstring): pointer {.importc, cdecl.}
proc mari_js_call(h: pointer, fn, arg: cstring, len: csize_t, ok: ptr cint): cstring {.importc, cdecl.}
