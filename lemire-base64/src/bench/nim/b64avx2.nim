## AVX2 MIME base64 decoder in Nim, with nimsimd.
##
## Two steps on a small (L1-sized) buffer:
## 1. compact: copy the input 32 bytes at a time, dropping line endings.
##    A clean block is one load and one store. A block with a line ending is
##    compacted 8 bytes at a time with BMI2 `pext`.
## 2. decode: the Muła–Lemire AVX2 algorithm, 32 characters to 24 bytes,
##    validating with three pshufb lookups.
## Line endings never send the decoder to a slow path.

import nimsimd/[avx2, bmi2, popcnt]
import b64scalar

when defined(gcc) or defined(clang):
  {.localPassC: "-mavx2 -mbmi -mbmi2 -mpopcnt".}

const BufSize = 4096

proc lut(a: array[16, int8]): array[32, int8] =
  for i in 0..15:
    result[i] = a[i]
    result[i+16] = a[i]

let
  lutLoA = lut([0x15'i8, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11,
                0x11, 0x11, 0x13, 0x1A, 0x1B, 0x1B, 0x1B, 0x1A])
  lutHiA = lut([0x10'i8, 0x10, 0x01, 0x02, 0x04, 0x08, 0x04, 0x08,
                0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10])
  lutRollA = lut([0'i8, 16, 19, 4, -65, -65, -71, -71,
                  0, 0, 0, 0, 0, 0, 0, 0])
  packA = lut([2'i8, 1, 0, 6, 5, 4, 10, 9, 8, 14, 13, 12, -1, -1, -1, -1])
  permA = [0'i32, 1, 2, 4, 5, 6, -1, -1]

const expand = block:   # 8-bit mask -> 0xFF in each marked byte
  var t: array[256, uint64]
  for m in 0..255:
    for k in 0..7:
      if (m shr k and 1) == 1: t[m] = t[m] or (0xFF'u64 shl (8*k))
  t

template ld(p: pointer): M256i = mm256_loadu_si256(p)

proc decodeError(i: int) {.noinline, noreturn.} =
  raise newException(ValueError, "invalid base64 character near " & $i)

proc decodeAvx2*(src: ptr UncheckedArray[char], n: int,
                 dst: ptr UncheckedArray[char]): int =
  ## `dst` needs `maxDecodedLen(n) + 32` bytes. Returns the decoded length.
  let
    lutLo = ld(lutLoA.unsafeAddr)
    lutHi = ld(lutHiA.unsafeAddr)
    lutRoll = ld(lutRollA.unsafeAddr)
    pack = ld(packA.unsafeAddr)
    perm = ld(permA.unsafeAddr)
    mask2F = mm256_set1_epi8(0x2F'i8)
    space = mm256_set1_epi8(0x20'i8)
    cr = mm256_set1_epi8(0x0D'i8)
    lf = mm256_set1_epi8(0x0A'i8)
    tab = mm256_set1_epi8(0x09'i8)
    k1 = mm256_set1_epi32(0x01400140'i32)
    k2 = mm256_set1_epi32(0x00011000'i32)
  var m = n          # the vector loops stop before trailing padding
  while m > 0 and src[m-1] in {'\r', '\n', ' ', '\t', '='}: dec m
  var buf {.noinit.}: array[BufSize + 64, char]
  var i, o, b = 0
  while true:
    # 1. compact into buf
    var bad = 0'u32
    while b < BufSize and i + 32 <= m:
      let x = ld(src[i].addr)
      let mask = cast[uint32](mm256_movemask_epi8(
        mm256_cmpeq_epi8(mm256_max_epu8(x, space), space)))  # bytes <= 0x20
      # only \r \n space tab may be dropped; anything else <= 0x20 is an error
      let exact = cast[uint32](mm256_movemask_epi8(mm256_or_si256(
        mm256_or_si256(mm256_cmpeq_epi8(x, cr), mm256_cmpeq_epi8(x, lf)),
        mm256_or_si256(mm256_cmpeq_epi8(x, space), mm256_cmpeq_epi8(x, tab)))))
      bad = bad or (exact xor mask)
      # A clean block is one 32-byte store. Otherwise drop the marked bytes
      # 8 at a time with BMI2 pext. (A branch-free version that always takes
      # the pext path measured slower: about 5.5 vs 6.7 GB/s.)
      if mask == 0:
        mm256_storeu_si256(buf[b].addr, x)
        b += 32
      else:
        for g in 0..3:
          let m8 = (mask shr (8*g)) and 0xFF
          var w: uint64
          copyMem(w.addr, src[i + 8*g].addr, 8)
          w = pext_u64(w, not expand[m8])
          # a plain 8-byte store (copyMem here became a _FORTIFY_SOURCE
          # __memcpy_chk call on Ubuntu's gcc)
          cast[ptr uint64](buf[b].addr)[] = w
          b += 8 - mm_popcnt_u32(m8).int  # (std/bitops countSetBits compiled to a call here)
      i += 32
    if bad != 0: decodeError(i)
    # 2. decode buf, 32 characters at a time
    var j = 0
    while j + 32 <= b:
      var v = ld(buf[j].addr)
      let
        hiNib = mm256_and_si256(mm256_srli_epi32(v, 4), mask2F)
        loNib = mm256_and_si256(v, mask2F)
        lo = mm256_shuffle_epi8(lutLo, loNib)
        hi = mm256_shuffle_epi8(lutHi, hiNib)
        eq2F = mm256_cmpeq_epi8(v, mask2F)
        roll = mm256_shuffle_epi8(lutRoll, mm256_add_epi8(eq2F, hiNib))
      if mm256_testz_si256(lo, hi) == 0: decodeError(i)
      v = mm256_add_epi8(v, roll)
      var w = mm256_madd_epi16(mm256_maddubs_epi16(v, k1), k2)
      w = mm256_permutevar8x32_epi32(mm256_shuffle_epi8(w, pack), perm)
      mm256_storeu_si256(dst[o].addr, w)   # 24 useful bytes
      j += 32; o += 24
    if j < b: moveMem(buf[0].addr, buf[j].addr, b - j)
    b -= j
    if i + 32 > m: break
  # leftover: < 32 clean chars in buf, then < 32 chars (+ padding) of input
  var rest = newString(b + n - i)
  if b > 0: copyMem(rest[0].addr, buf[0].addr, b)
  if n > i: copyMem(rest[b].addr, src[i].addr, n - i)
  decodeTail(cast[ptr UncheckedArray[char]](rest.cstring), 0, rest.len, dst, o)

proc decodeAvx2*(s: string): string =
  result = newStringUninit(maxDecodedLen(s.len) + 32)
  let n = decodeAvx2(cast[ptr UncheckedArray[char]](s.cstring), s.len,
                     cast[ptr UncheckedArray[char]](result.cstring))
  result.setLen(n)
