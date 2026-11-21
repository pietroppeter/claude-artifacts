## Fast scalar MIME base64 decoder in plain Nim.
##
## Four 256-entry uint32 tables (the modp_b64 / Chromium trick) turn four
## characters into three bytes with four loads and three ORs. A bad character
## sets the top bit, so one comparison per quad validates it. Line endings
## (and spaces) are skipped wherever they occur.

const bad = 0x01FF_FFFF'u32

func charValue(c: char): int =
  case c
  of 'A'..'Z': ord(c) - ord('A')
  of 'a'..'z': ord(c) - ord('a') + 26
  of '0'..'9': ord(c) - ord('0') + 52
  of '+': 62
  of '/': 63
  else: -1

func makeTable(shift: int): array[256, uint32] =
  # Output bytes are stored little-endian: byte0 | byte1 << 8 | byte2 << 16.
  for i in 0..255:
    let v = charValue(char(i))
    if v < 0:
      result[i] = bad
    else:
      # 24-bit big-endian value (v << shift), then byte-swapped into place.
      let x = uint32(v) shl shift
      result[i] = ((x shr 16) and 0xFF) or (x and 0xFF00) or ((x and 0xFF) shl 16)

const
  d0 = makeTable(18)
  d1 = makeTable(12)
  d2 = makeTable(6)
  d3 = makeTable(0)

template isSpace(c: char): bool = c in {'\r', '\n', ' ', '\t'}

proc decodeError(i: int) {.noinline, noreturn.} =
  raise newException(ValueError, "invalid base64 character at " & $i)

func maxDecodedLen*(n: int): int = (n div 4) * 3 + 3

proc decodeTail*(src: ptr UncheckedArray[char], i0, n: int,
                 dst: ptr UncheckedArray[char], o0: int): int =
  ## Slow path: skips spaces character by character, handles padding.
  ## Returns the new output index.
  var acc = 0'u32
  var k = 0
  var o = o0
  var i = i0
  while i < n:
    let c = src[i]
    inc i
    if isSpace(c): continue
    if c == '=':   # padding: only more '=' and spaces may follow
      while i < n:
        if src[i] != '=' and not isSpace(src[i]): decodeError(i)
        inc i
      break
    let v = charValue(c)
    if v < 0: decodeError(i - 1)
    acc = (acc shl 6) or uint32(v)
    inc k
    if k == 4:
      dst[o] = char((acc shr 16) and 0xFF); dst[o+1] = char((acc shr 8) and 0xFF); dst[o+2] = char(acc and 0xFF)
      o += 3; k = 0; acc = 0
  case k
  of 0: discard
  of 2:
    dst[o] = char((acc shr 4) and 0xFF); o += 1
  of 3:
    dst[o] = char((acc shr 10) and 0xFF); dst[o+1] = char((acc shr 2) and 0xFF); o += 2
  else: decodeError(i)
  o

proc decodeScalar*(src: ptr UncheckedArray[char], n: int,
                   dst: ptr UncheckedArray[char]): int =
  ## Decodes `n` characters of (line-broken) base64 at `src` into `dst`,
  ## which needs `maxDecodedLen(n) + 1` bytes. Returns the decoded length.
  var i = 0
  var o = 0
  # Fast loop: whole quads with no space inside. 4-byte stores (3 valid).
  while i + 4 < n:
    let c0 = src[i]
    if isSpace(c0):
      inc i
      continue
    let x = d0[uint8 c0] or d1[uint8 src[i+1]] or d2[uint8 src[i+2]] or d3[uint8 src[i+3]]
    if x >= bad: break   # a space inside the quad, padding or a bad char
    copyMem(addr dst[o], unsafeAddr x, 4)
    i += 4
    o += 3
  decodeTail(src, i, n, dst, o)

proc decodeScalar*(s: string): string =
  result = newStringUninit(maxDecodedLen(s.len) + 1)
  let n = decodeScalar(cast[ptr UncheckedArray[char]](s.cstring), s.len,
                       cast[ptr UncheckedArray[char]](result.cstring))
  result.setLen(n)
