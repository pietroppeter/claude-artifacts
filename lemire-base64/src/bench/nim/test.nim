## Random round trips against std/base64: sizes 0..3000, line widths 4..100,
## CRLF / LF / no line breaks, plus invalid characters that must raise.
import std/[base64, random]
import b64scalar, b64avx2, b64avx512, simdutf
randomize(42)
proc wrap(s: string, w: int, eol: string): string =
  if w == 0: return s
  for i in countup(0, s.len - 1, w):
    result.add s[i ..< min(i + w, s.len)]
    result.add eol
var cases, bad = 0
for size in 0..3000:
  var raw = newString(size)
  for c in raw.mitems: c = char(rand(255))
  let enc = base64.encode(raw)
  for (w, eol) in [(0, ""), (76, "\r\n"), (64, "\n"), (rand(1..100), "\r\n"), (rand(1..100), " ")]:
    let s = wrap(enc, w, eol)
    doAssert decodeScalar(s) == raw, "scalar " & $size & " " & $w
    doAssert decodeAvx2(s) == raw, "avx2 " & $size & " " & $w
    doAssert decodeAvx512(s) == raw, "avx512 " & $size & " " & $w
    if eol != " ": doAssert decodeSimdutf(s) == raw
    inc cases
    if s.len > 10:
      var t = s
      t[rand(t.len - 3)] = sample({'\0', '\x01', '!', '-', '_', '\x80', '\xff', '#'})
      template mustRaise(call: untyped, name: string) =
        var raised = false
        try: discard call except ValueError: raised = true
        doAssert raised, name & " accepted bad char at size " & $size
      inc bad
      mustRaise(decodeScalar(t), "scalar")
      mustRaise(decodeAvx2(t), "avx2")
      mustRaise(decodeAvx512(t), "avx512")
echo "ok: ", cases, " round trips x 4 decoders, ", bad, " corrupted inputs rejected x 3 decoders"
