import std/[json, monotimes, times, os]
import qjs
const bundle = staticRead(currentSourcePath().parentDir / ".." / ".." / ".." / "src" / "mari" / "vendor" / "pele.global.js")
let srcs = parseJson(readFile(paramStr(1)))
var t = getMonoTime()
startEngine(bundle)
echo "load Pele in QuickJS: ", (getMonoTime() - t).inMilliseconds, " ms"
var outs = newJArray()
t = getMonoTime()
for s in srcs: outs.add askQjs(bundle, %*{"source": s, "options": {"idPrefix": "p-"}})["svg"]
echo "per diagram: ", (getMonoTime() - t).inMicroseconds div srcs.len, " µs"
writeFile(paramStr(2), $outs)
