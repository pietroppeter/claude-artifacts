# qjs.nim: one QuickJS runtime for the process, one call at a time
var
  engine: pointer
  engineLock: Lock
initLock engineLock

proc askQjs*(bundle: string, req: JsonNode): JsonNode =
  ...
  withLock engineLock:
    startEngine(bundle)
    let r = mari_js_call(engine, "__mari", s.cstring, s.len.csize_t, addr ok)
    ...
