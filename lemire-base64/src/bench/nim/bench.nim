## MIME base64 decoding benchmark for Nim, same protocol as Lemire's mimebench:
## check the bytes once, warm up 3*200 calls, best of 10 batches of 200 calls.
import std/[base64, monotimes, times, strutils]
import b64scalar, b64avx2, b64avx512, simdutf

let (expLen, expSum) = block:
  let p = readFile("../expected.txt").strip.split(' ')
  (parseInt(p[0]), parseBiggestUInt(p[1]))
let data = readFile("../mime.txt")
var sink: int

proc check(n: int, o: openArray[char], label: string) =
  var s = 0'u64
  for i in 0..<n: s += uint64(uint8(o[i]))
  if n != expLen or s != expSum: quit "bad decode " & label

proc bench(label: string, f: proc(): int) =
  const iters = 200
  for _ in 0..<3*iters: sink += f()
  var best = Inf
  for _ in 0..<10:
    let st = getMonoTime()
    for _ in 0..<iters: sink += f()
    best = min(best, float((getMonoTime() - st).inNanoseconds) / iters)
  echo "nim ", NimVersion, " mime ", label, ": ", formatFloat(data.len.float / best, ffDecimal, 2), " GB/s"

var r = base64.decode(data); check(r.len, r, "std")
bench("std/base64 decode") do () -> int: base64.decode(data).len

r = decodeScalar(data); check(r.len, r, "scalar")
bench("scalar (4 tables) decode") do () -> int: decodeScalar(data).len
var buf = newString(maxDecodedLen(data.len) + 64)
bench("scalar (4 tables) decode (preallocated)") do () -> int:
  decodeScalar(cast[ptr UncheckedArray[char]](data.cstring), data.len, cast[ptr UncheckedArray[char]](buf.cstring))

r = decodeAvx2(data); check(r.len, r, "avx2")
bench("nimsimd AVX2 decode") do () -> int: decodeAvx2(data).len
bench("nimsimd AVX2 decode (preallocated)") do () -> int:
  decodeAvx2(cast[ptr UncheckedArray[char]](data.cstring), data.len, cast[ptr UncheckedArray[char]](buf.cstring))

r = decodeAvx512(data); check(r.len, r, "avx512")
bench("AVX-512 VBMI2 decode") do () -> int: decodeAvx512(data).len
bench("AVX-512 VBMI2 decode (preallocated)") do () -> int:
  decodeAvx512(cast[ptr UncheckedArray[char]](data.cstring), data.len, cast[ptr UncheckedArray[char]](buf.cstring))

r = decodeSimdutf(data); check(r.len, r, "simdutf")
var sbuf = newString(maxLen(data))
bench(simdutfInfo() & " base64_to_binary via FFI (preallocated)") do () -> int: decodeInto(data, sbuf)
