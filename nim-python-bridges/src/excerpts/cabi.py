# mari/__init__.py: the Python half of plug A
lib = ctypes.CDLL(str(_here / _libname))
lib.mari_draw.argtypes = [ctypes.c_char_p]
lib.mari_draw.restype = ctypes.c_void_p      # a pointer, so Python does not copy and lose it
lib.mari_free.argtypes = [ctypes.c_void_p]

def draw(source, layer=None, **options):
    req = json.dumps({"source": source, "layer": layer or {}, "options": options}).encode()
    p = lib.mari_draw(req)
    try:
        answer = json.loads(ctypes.string_at(p).decode())
    finally:
        lib.mari_free(p)
    if not answer.get("ok"):
        raise DiagramError(answer)            # code, line, column, snippet
    return answer
