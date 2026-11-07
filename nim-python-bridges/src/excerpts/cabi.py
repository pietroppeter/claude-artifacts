# mari/__init__.py: the Python half of plug A
def draw(source: str, layer: dict | None = None, **options) -> dict:
    req = json.dumps({"source": source, "layer": layer or {}, "options": options}).encode()
    p = lib.mari_draw(req)
    try:
        answer = json.loads(ctypes.string_at(p).decode())
    finally:
        lib.mari_free(p)                       # the library made it, the library frees it
    if not answer.get("ok"):
        raise DiagramError(answer)             # .code .line .column .snippet
    return answer

lib = ctypes.CDLL(str(_here / _libname))       # loaded once, at import
lib.mari_draw.argtypes = [ctypes.c_char_p]
lib.mari_draw.restype = ctypes.c_void_p        # a pointer: c_char_p would copy and lose it
lib.mari_free.argtypes = [ctypes.c_void_p]
