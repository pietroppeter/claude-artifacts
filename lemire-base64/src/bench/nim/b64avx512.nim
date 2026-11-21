## AVX-512 (VBMI + VBMI2) MIME base64 decoder in Nim.
##
## nimsimd stops at AVX2, so the dozen intrinsics needed are imported here.
## Same two steps as the AVX2 version, 64 bytes at a time:
## 1. compact: `vpcompressb` drops the line endings of a 64-byte block in one
##    instruction (no branch: every block takes the same path).
## 2. decode: Muła–Lemire AVX-512 VBMI: one `vpermi2b` translates 64
##    characters through a 128-entry table, two multiply-adds and one
##    `vpermb` pack them into 48 bytes.

import b64scalar

when defined(gcc) or defined(clang):
  {.localPassC: "-mavx512f -mavx512bw -mavx512vbmi -mavx512vbmi2 -mpopcnt".}

type M512i {.importc: "__m512i", header: "immintrin.h", bycopy.} = object

{.push header: "immintrin.h".}
func mm512_loadu_si512(p: pointer): M512i {.importc: "_mm512_loadu_si512".}
proc mm512_storeu_si512(p: pointer, a: M512i) {.importc: "_mm512_storeu_si512".}
func mm512_set1_epi8(a: int8): M512i {.importc: "_mm512_set1_epi8".}
func mm512_set1_epi32(a: int32): M512i {.importc: "_mm512_set1_epi32".}
func mm512_cmple_epu8_mask(a, b: M512i): uint64 {.importc: "_mm512_cmple_epu8_mask".}
func mm512_cmpeq_epi8_mask(a, b: M512i): uint64 {.importc: "_mm512_cmpeq_epi8_mask".}
func mm512_maskz_compress_epi8(k: uint64, a: M512i): M512i {.importc: "_mm512_maskz_compress_epi8".}
func mm512_permutex2var_epi8(a, idx, b: M512i): M512i {.importc: "_mm512_permutex2var_epi8".}
func mm512_permutexvar_epi8(idx, a: M512i): M512i {.importc: "_mm512_permutexvar_epi8".}
func mm512_or_si512(a, b: M512i): M512i {.importc: "_mm512_or_si512".}
func mm512_movepi8_mask(a: M512i): uint64 {.importc: "_mm512_movepi8_mask".}
func mm512_maddubs_epi16(a, b: M512i): M512i {.importc: "_mm512_maddubs_epi16".}
func mm512_madd_epi16(a, b: M512i): M512i {.importc: "_mm512_madd_epi16".}
func mm_popcnt_u64(a: uint64): int64 {.importc: "_mm_popcnt_u64".}
{.pop.}

const BufSize = 4096

proc tables(): (array[64, int8], array[64, int8], array[64, int8]) =
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  var t: array[128, int8]
  for i in 0..127: t[i] = int8(-128)            # 0x80 = invalid
  for v, c in alphabet: t[ord(c)] = int8(v)
  for i in 0..63:
    result[0][i] = t[i]
    result[1][i] = t[i + 64]
  # pack: keep bytes 2,1,0 of each 32-bit word (16 words -> 48 bytes)
  for k in 0..15:
    result[2][3*k] = int8(4*k + 2)
    result[2][3*k + 1] = int8(4*k + 1)
    result[2][3*k + 2] = int8(4*k)

let (lut0A, lut1A, packA) = tables()

proc decodeError(i: int) {.noinline, noreturn.} =
  raise newException(ValueError, "invalid base64 character near " & $i)

proc decodeAvx512*(src: ptr UncheckedArray[char], n: int,
                   dst: ptr UncheckedArray[char]): int =
  ## `dst` needs `maxDecodedLen(n) + 64` bytes. Returns the decoded length.
  let
    lut0 = mm512_loadu_si512(lut0A.unsafeAddr)
    lut1 = mm512_loadu_si512(lut1A.unsafeAddr)
    pack = mm512_loadu_si512(packA.unsafeAddr)
    space = mm512_set1_epi8(0x20)
    cr = mm512_set1_epi8(0x0D)
    lf = mm512_set1_epi8(0x0A)
    tab = mm512_set1_epi8(0x09)
    k1 = mm512_set1_epi32(0x01400140'i32)
    k2 = mm512_set1_epi32(0x00011000'i32)
  var m = n
  while m > 0 and src[m-1] in {'\r', '\n', ' ', '\t', '='}: dec m
  var buf {.noinit.}: array[BufSize + 128, char]
  var i, o, b = 0
  while true:
    var bad = 0'u64
    while b < BufSize and i + 64 <= m:
      let x = mm512_loadu_si512(src[i].addr)
      let ws = mm512_cmple_epu8_mask(x, space)
      let exact = mm512_cmpeq_epi8_mask(x, cr) or mm512_cmpeq_epi8_mask(x, lf) or
                  mm512_cmpeq_epi8_mask(x, space) or mm512_cmpeq_epi8_mask(x, tab)
      bad = bad or (ws xor exact)
      mm512_storeu_si512(buf[b].addr, mm512_maskz_compress_epi8(not ws, x))
      b += 64 - int(mm_popcnt_u64(ws))
      i += 64
    if bad != 0: decodeError(i)
    var j = 0
    while j + 64 <= b:
      let v = mm512_loadu_si512(buf[j].addr)
      let t = mm512_permutex2var_epi8(lut0, v, lut1)
      if mm512_movepi8_mask(mm512_or_si512(t, v)) != 0: decodeError(i)
      let w = mm512_madd_epi16(mm512_maddubs_epi16(t, k1), k2)
      mm512_storeu_si512(dst[o].addr, mm512_permutexvar_epi8(pack, w))  # 48 useful bytes
      j += 64; o += 48
    if j < b: moveMem(buf[0].addr, buf[j].addr, b - j)
    b -= j
    if i + 64 > m: break
  var rest = newString(b + n - i)
  if b > 0: copyMem(rest[0].addr, buf[0].addr, b)
  if n > i: copyMem(rest[b].addr, src[i].addr, n - i)
  decodeTail(cast[ptr UncheckedArray[char]](rest.cstring), 0, rest.len, dst, o)

proc decodeAvx512*(s: string): string =
  result = newStringUninit(maxDecodedLen(s.len) + 64)
  let n = decodeAvx512(cast[ptr UncheckedArray[char]](s.cstring), s.len,
                       cast[ptr UncheckedArray[char]](result.cstring))
  result.setLen(n)
